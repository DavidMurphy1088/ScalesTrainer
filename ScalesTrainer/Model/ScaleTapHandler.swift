import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit
import Foundation

class ScaleTapHandler : TapHandlerProtocol  {
    let scalesModel = ScalesModel.shared
    let inputScale:Scale
    let fromProcess:RunningProcess
    let startTime:Date = Date()
    let amplitudeFilter:Double
    var hilightPlayingNotes:Bool
    
    var recordedTapEvents:[TapEvent]
    var eventNumber = 0
    var matchCount = 0
    
    var lastMatchedMidi:Int? = nil
    var lastTappedMidi:Int? = nil
    var lastTappedMidiCount = 0

    var scaleStartAmplitudes:[Float] = []
    var scalePotentialStartAmplitudes:[Float] = []
    var allowableOctaveOffsets:[Int] = []

    var unmatchedCount:Int? = nil
    var maxScaleMidi = 0
    var minScaleMidi = 0
    var appKeyboard:PianoKeyboardModel = PianoKeyboardModel.shared
    var savedTapsFileURL:URL?
    
    var startTappingAmplitudes:[Float] = []
    var startTappingAvgAmplitude:Float? = nil
    var endTappingLowAmplitudeCount = 0
    var noteAmplitudeHeardCount = 0
    var startTappingTime:Date? = nil
    var ascending = true
    
    ///When on require a large increase in amplitude to start the scale matching (avoids false starts from noise before tapping)
    ///But settable since tappiong after a lead in has minimal taps at start to measure the increase.
    var filterStartOfTapping:Bool
    
    required init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool, filterStartOfTapping:Bool) {
        self.recordedTapEvents = []
        self.inputScale = scalesModel.scale
        self.amplitudeFilter = amplitudeFilter
        self.hilightPlayingNotes = hilightPlayingNotes
        (self.minScaleMidi, self.maxScaleMidi) = inputScale.getMinMax()
        self.fromProcess = fromProcess
        self.startTappingTime = nil
        self.filterStartOfTapping = filterStartOfTapping
    }
    
    func resetState(scale:Scale, octaveLenient:Bool) {
        self.matchCount = 0
        self.eventNumber = 0
        self.unmatchedCount = nil
        self.scaleStartAmplitudes = []
        self.scalePotentialStartAmplitudes = []
        self.lastMatchedMidi = nil
        (self.minScaleMidi, self.maxScaleMidi) = scale.getMinMax()
        if octaveLenient {
            self.allowableOctaveOffsets = [0, 12, -12]
        }
        else {
            self.allowableOctaveOffsets = [0]
        }
        startTappingAmplitudes = []
        startTappingAvgAmplitude = nil
        endTappingLowAmplitudeCount = 0
        self.lastTappedMidi = nil
        self.lastTappedMidiCount = 0
        self.eventNumber = 0
        self.ascending = true
        ///Warning⚠️ don't update keyboard published state here.
        ///Tap processing has now been improved to be keyboard stateless
        //keyboard.configureKeyboardSize(scale: scale)
        //keyboard.linkScaleFingersToKeyboardKeys(scale: scale, direction: 0)
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        var frequency:Float
        var amplitude:Float
        if amplitudes[0] > amplitudes[1] {
            frequency = frequencies[0]
            amplitude = amplitudes[0]
        }
        else {
            frequency = frequencies[1]
            amplitude = amplitudes[1]
        }
        let tapMidi = Util.frequencyToMIDI(frequency: frequency)
        let event = TapEvent(tapNum: eventNumber, frequency: frequency, amplitude: amplitude, ascending: true, status: .none,
                             expectedScaleNoteStates: nil, midi: tapMidi, tapMidi: 0)
        self.recordedTapEvents.append(event)
        self.eventNumber += 1
        
        ///Try to figure out when the recording should stop without the user stopping it with a button push
        ///Wait for at least a few likely actual taps with enough amplitude
        if self.startTappingTime == nil {
            self.startTappingTime = Date()
        }
        if self.startTappingAvgAmplitude == nil {
            if startTappingAmplitudes.count < 20 {
                startTappingAmplitudes.append(amplitude)
            }
            else {
                let sum = startTappingAmplitudes.reduce(0, +)
                self.startTappingAvgAmplitude = sum / Float(startTappingAmplitudes.count)
            }
        }
        if amplitude > 0.02 {
            self.noteAmplitudeHeardCount += 1
        }
        
        if let startTime = self.startTappingTime {
            let seconds = Date().timeIntervalSince(startTime)
            if seconds > 4 {
                if self.noteAmplitudeHeardCount > 4 {
                    if let startingAmplitude = self.startTappingAvgAmplitude {
                        if amplitude < startingAmplitude {
                            endTappingLowAmplitudeCount += 1
                            if endTappingLowAmplitudeCount > 10 {
                                scalesModel.setRunningProcess(.none)
                            }
                        }
                        else {
                            endTappingLowAmplitudeCount = 0
                        }
                    }
                }
            }
        }
    }
    
    func stopTapping(_ ctx: String) -> TapEventSet {
        ///Determine which scale range the user played. e.g. for C Maj RH they have started on midi 60 or 72 or 48. All would be correct.
        ///Analyse the tapping aginst different scale starts to determine which has the least errors.
        ///Update the app state after tapping based on the selected scale start.
        if self.recordedTapEvents.isEmpty {
            let empty = TapEventSet(amplitudeFilter: 0, description: "")
            return empty
        }
        
        ///Reversed - if lots of errors make sure the 0 offset is the final one displayed
        let scaleRootOffsets = [0, 12, -12, 24, -24].reversed()
        var minErrorResult:Result? = nil
        var bestOffset:Int? = nil
        
        func applyEvents(offset:Int, scale:Scale, keyboard:PianoKeyboardModel, octaveLenient:Bool, score:Score?, updateKeyboard:Bool, eventSet:[TapEvent]) -> (Result, TapEventSet) {
            ///Apply the tapped events to a given scale start
            self.resetState(scale: scale, octaveLenient: octaveLenient)
            
            let tapEventSet = TapEventSet(amplitudeFilter: scalesModel.amplitudeFilter, description: "scaleStart:\(scale.getMinMax().0) lenient:\(octaveLenient)")
            for recordedTapEvent in eventSet {
                let processedtapEvent = processTap(scale: scale, keyboard: keyboard, octaveLenient: octaveLenient, updateKeyboardDisplay: updateKeyboard, amplitude: recordedTapEvent.amplitude, frequency: recordedTapEvent.frequency, timestamp: recordedTapEvent.timestamp)
                tapEventSet.events.append(processedtapEvent)
            }
            let result = Result(scale: scale, keyboard: keyboard, fromProcess: self.fromProcess,
                                amplitudeFilter: scalesModel.amplitudeFilter, userMessage: "", score: score)
            result.buildResult(score: score, offset: offset)
            return (result, tapEventSet)
        }
        
        ///Find the best fit scale
        for rootOffsetMidi in scaleRootOffsets {
            ///Set the trial scale for the scale offset
            let trialScale = self.inputScale.makeNewScale(offset: rootOffsetMidi)
            //Logger.shared.log(self, "Assessing recording for scale at offset:\(rootOffsetMidi)")
            let keyboard = PianoKeyboardModel()
            keyboard.configureKeyboardForScale(scale: trialScale)
            let result = applyEvents(offset: rootOffsetMidi, scale: trialScale, keyboard: keyboard, octaveLenient: false, 
                                     score: nil, updateKeyboard: false, eventSet: self.recordedTapEvents).0
            if minErrorResult == nil || minErrorResult!.isBetter(compare: result) {
                minErrorResult = result
                bestOffset = rootOffsetMidi
            }
            Logger.shared.log(self, "Assessed at offset:\(rootOffsetMidi) errors:\(result.getErrorString())")
        }
        
        ///Replay the best fit scale to set the app's display state
        if let bestOffset = bestOffset {
            ///If there are too many errors just display the scale at the octaves it was shown as
            let bestScale:Scale
            if minErrorResult == nil || minErrorResult!.getTotalErrors() > 3 {
                bestScale = inputScale.makeNewScale(offset: 0)
            }
            else {
                bestScale = inputScale.makeNewScale(offset: bestOffset)
            }
            
            ///Score note status is updated during result build, keyboard key status is updated by tap processing
            let score = scalesModel.createScore(scale: bestScale)
            Logger.shared.log(self, "Applying recording for ** best ** scale at offset \(bestOffset)")
            scalesModel.setScaleAndScore(scale: bestScale, score: score, ctx: "ScaleTapHandler:bestOffset")
            
            ///Ensure keyboard visible key statuses are updated during events apply
            let keyboard = PianoKeyboardModel.shared
            keyboard.configureKeyboardForScale(scale: bestScale)
            let (result, eventSet) = applyEvents(offset: bestOffset, scale: bestScale, keyboard: keyboard, octaveLenient: true,
                                                 score: score, updateKeyboard: true, eventSet: self.recordedTapEvents)
            scalesModel.setResultInternal(result, "stop Tapping")
            if result.noErrors() {
                score.setNormalizedValues(scale: bestScale)
            }
            PianoKeyboardModel.shared.redraw()
            if ScalesModel.shared.runningProcess == .recordingScale && Settings.shared.recordDataMode{
                self.saveTapsToFile(result: result)
            }
            return eventSet
        }
        else {
            return TapEventSet(amplitudeFilter: amplitudeFilter, description: "Empty")
        }
    }
    
    ///Set the a keyboard key to the played state based on the frequency input.
    ///Filter out spurios tap event frequencies.
    ///Return a tap event that describes how this tap notification was handled. The tap event is used for logging and describes if and how a keyboard key was played.
    func processTap(scale:Scale, keyboard:PianoKeyboardModel, octaveLenient:Bool,
                    updateKeyboardDisplay:Bool, amplitude:Float, frequency:Float, timestamp:Date) -> TapEvent {
        let tapMidi = Util.frequencyToMIDI(frequency: frequency)
        self.eventNumber += 1
        //print ("============>>>", self.eventNumber, "Midi", tapMidi, amplitude)
        
        ///Require a large change in amplitude to start the scale
        ///This avoids false starts and scale note matches with noise before playing notes
        ///Compare averages of amplitudes to detect the major change over averaged tap events
        if self.filterStartOfTapping && matchCount == 0 {
            scaleStartAmplitudes.append(amplitude)
            scalePotentialStartAmplitudes.append(amplitude)
            if scalePotentialStartAmplitudes.count > 4 {
                scalePotentialStartAmplitudes.removeFirst()
            }
            var sum = scaleStartAmplitudes.reduce(0, +)
            let startAverage = sum / Float(scaleStartAmplitudes.count)
            sum = scalePotentialStartAmplitudes.reduce(0, +)
            let potentialAverage = sum / Float(scalePotentialStartAmplitudes.count)
            let diff = (potentialAverage - startAverage) / startAverage
            
            if diff < 2.0 {
                let event = TapEvent(tapNum: eventNumber,
                                     frequency: frequency,
                                     amplitude: amplitude,
                                     ascending: self.ascending,
                                     status: .beforeScaleStart,
                                     expectedScaleNoteStates: nil,
                                     midi: tapMidi, tapMidi: tapMidi)
                return event
            }
        }
        
        guard amplitude > AUValue(self.amplitudeFilter) else {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: frequency,
                                 amplitude: amplitude,
                                 ascending: self.ascending,
                                  status: .belowAmplitudeFilter,
                                 expectedScaleNoteStates: nil,
                                 midi: tapMidi, tapMidi: tapMidi)
            return event
        }
        
        ///Ensure the tap is not a singleton, i.e. we need to see > 0 occurrences of it to proceed so we dont take the first
        if let lastTappedMidi = lastTappedMidi {
            if tapMidi == lastTappedMidi {
                self.lastTappedMidiCount += 1
            }
            else {
                self.lastTappedMidiCount = 1
            }
            self.lastTappedMidi = tapMidi
            if self.lastTappedMidiCount == 1 {
                let event = TapEvent(tapNum: eventNumber,
                                     frequency: frequency,
                                     amplitude: amplitude,
                                     ascending: self.ascending,
                                     status: .discardedSingleton,
                                     expectedScaleNoteStates: nil,
                                     midi: tapMidi, tapMidi: tapMidi)
                return event
            }
        }
        else {
            self.lastTappedMidi = tapMidi
            self.lastTappedMidiCount = 1
        }
        
        var midi = tapMidi
        var bestDiff:Int? = nil

        ///A note's pitch can arrive as octave harmonics of the expected pitch.
        ///Determine the actual midi based on the nearest key that to the last one the user played.
        let tappedMidiPossibles = [midi-24, midi - 12, midi, midi + 12, midi + 24]
        let expectedMidi:Int = self.lastMatchedMidi == nil ? scale.getMinMax().0 : self.lastMatchedMidi!
        for possibleMidi in tappedMidiPossibles {
            let diff = abs(possibleMidi - expectedMidi)
            if bestDiff == nil || diff < bestDiff! {
                bestDiff = diff
                midi = possibleMidi
            }
        }
        
        ///At top of scale. At end of scale?
        self.matchCount += 1
        var atTop = false
        if midi == scale.getMinMax().1 {
            atTop = true
            self.ascending = false
        }
        if midi == scale.getMinMax().0 {
            ///End of scale if the midi is the root and the root has already been played
            if let index = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
                let keyboardKey = keyboard.pianoKeyModel[index]
                if keyboardKey.keyWasPlayedState.tappedTimeDescending != nil {
                    let event = TapEvent(tapNum: eventNumber,
                                         frequency: frequency,
                                         amplitude: amplitude,
                                         ascending: self.ascending,
                                         status: .afterScaleEnd,
                                         expectedScaleNoteStates: [],
                                         midi: midi, tapMidi: midi)
                    return event
                }
            }
        }

//        print ("  ============>>> ", self.eventNumber, "Use", midi, "Tapped:", tapMidi, "expected", expectedMidi, "diff:", bestDiff ?? "None",
//               "atTop", atTop, "ascending", ascending)
        
        ///Same as last note?
        if midi == lastMatchedMidi {
            let event = TapEvent(tapNum: eventNumber,
                                  frequency: frequency,
                                  amplitude: amplitude,
                                 ascending: self.ascending,
                                  status: .sameMidiContinued,
                                  expectedScaleNoteStates: [],
                                  midi: midi, tapMidi: midi)
            return event
        }

        self.lastMatchedMidi = midi
    
        ///Update key tapped state
        
        if let keyboardIndex = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
            let keyboardKey = keyboard.pianoKeyModel[keyboardIndex]
            if unmatchedCount == nil {
                if self.ascending || atTop {
                    keyboardKey.keyWasPlayedState.tappedTimeAscending = Date()
                    keyboardKey.keyWasPlayedState.tappedAmplitudeAscending = Double(amplitude)
                }
                if !self.ascending || atTop  {
                    keyboardKey.keyWasPlayedState.tappedTimeDescending = Date()
                    keyboardKey.keyWasPlayedState.tappedAmplitudeDescending = Double(amplitude)
                }
                if updateKeyboardDisplay {
                    keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: self.hilightPlayingNotes)
                }
            }
        }
        
        let event = TapEvent(tapNum: eventNumber,
                             frequency: frequency,
                             amplitude: amplitude,
                             ascending: self.ascending,
                             status: .keyPressed,
                             expectedScaleNoteStates: [],
                             midi: midi, tapMidi: tapMidi)
        
        ///Only require timestamp on scale matched taps becuase they are used to calculate tempo (but only on correct notes)
        event.timestamp = timestamp
        return event
    }
    
    func saveTapsToFile(result:Result) {
        let scale = self.inputScale
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let day = calendar.component(.day, from: Date())
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let device = UIDevice.current
        let modelName = device.model
        var keyName = scale.getScaleName()
        keyName = keyName.replacingOccurrences(of: " ", with: "")
        var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"+String(format: "%02d", hour)+"_"+String(format: "%02d", minute)
        fileName += "_"+keyName + "_"+String(scale.octaves) + "_" + String(scale.scaleNoteState[0].midi) + "_" + modelName
        fileName += "_"+String(result.playedAndWrongCountAsc)+","+String(result.playedAndWrongCountDesc)+","+String(result.missedFromScaleCountAsc)+","+String(result.missedFromScaleCountDesc)
        fileName += "_"+String(AudioManager.shared.recordedFileSequenceNum)
        ScalesModel.shared.recordedTapsFileName = fileName
        
        fileName += ".txt"
        AudioManager.shared.recordedFileSequenceNum += 1
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.savedTapsFileURL = documentDirectoryURL.appendingPathComponent(fileName)
        do {
            if let fileURL = self.savedTapsFileURL {
                var config = "config:\t\(self.amplitudeFilter)"
                config += "\n"
                try config.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
        catch {
            Logger.shared.reportError(self, "Error creating file: \(error)")
        }
        if let fileURL = self.savedTapsFileURL {
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                for record in self.recordedTapEvents {
                    let timeInterval = record.timestamp.timeIntervalSince1970
                    let tapData = "time:\(timeInterval)\tfreq:\(record.frequency)\tampl:\(record.amplitude)\n"
                    if let data = tapData.data(using: .utf8) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                    }
                }
                ScalesModel.shared.recordedTapsFileURL = fileURL
                try fileHandle.close()
                Logger.shared.log(self, "Wrote \(self.recordedTapEvents.count) taps to \(fileURL)")
            } catch {
                Logger.shared.reportError(self, "Error writing to file: \(error)")
            }
        }
    }
}
