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
    var ascending = true
    var matchCount = 0
    var scaleStartAmplitudes:[Float] = []
    var scalePotentialStartAmplitudes:[Float] = []
    var allowableOctaveOffsets:[Int] = []
    var lastKeyPressedMidi:Int?
    var unmatchedCount:Int? = nil
    var maxScaleMidi = 0
    var minScaleMidi = 0
    var keyboard:PianoKeyboardModel = PianoKeyboardModel.shared
    var savedTapsFileURL:URL?
    //var savedTapsFileName:String?
    
    required init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool) {
        self.recordedTapEvents = []
        self.inputScale = scalesModel.scale
        self.amplitudeFilter = amplitudeFilter
        self.hilightPlayingNotes = hilightPlayingNotes
        (self.minScaleMidi, self.maxScaleMidi) = inputScale.getMinMax()
        self.fromProcess = fromProcess
    }
    
    func resetState(scale:Scale, octaveLenient:Bool) {
        self.matchCount = 0
        self.eventNumber = 0
        self.unmatchedCount = nil
        self.scaleStartAmplitudes = []
        self.scalePotentialStartAmplitudes = []
        self.ascending = true
        self.lastKeyPressedMidi = nil
        (self.minScaleMidi, self.maxScaleMidi) = scale.getMinMax()
        if octaveLenient {
            self.allowableOctaveOffsets = [0, 12, -12]
        }
        else {
            self.allowableOctaveOffsets = [0]
        }

        keyboard.configureKeyboardSize(scale: scale)
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
        let event = TapEvent(tapNum: eventNumber, frequency: frequency, amplitude: amplitude, ascending: ascending, status: .none, 
                             expectedScaleNoteStates: nil, midi: tapMidi, tapMidi: 0, key: nil)
        self.recordedTapEvents.append(event)
        var midiSet:Set<Int> = []
        for event in self.recordedTapEvents {
            if event.midi >= self.minScaleMidi && event.midi < self.maxScaleMidi {
                midiSet.insert(event.midi)
            }
        }
        self.eventNumber += 1
    }
    
    func stopTapping(_ ctx: String) -> TapEventSet {
        ///Determine which scale range the user played. e.g. for C Maj RH they have started on midi 60 or 72 or 48. All would be correct.
        ///Analyse the tapping aginst different scale starts to determine which has the least errors.
        ///Update the app state after tapping based on the selected scale start.
        
        let scaleRootOffsets = [0, 12, -12, 24, -24]
        var minErrorResult:Result? = nil
        var bestOffset:Int? = nil
        
        func applyEvents(scale:Scale, octaveLenient:Bool, score:Score?, updateKeyboard:Bool, eventSet:[TapEvent]) -> (Result, TapEventSet) {
            ///Apply the tapped events to a given scale start
            self.resetState(scale: scale, octaveLenient: octaveLenient)
            self.keyboard.linkScaleFingersToKeyboardKeys(scale: scale, direction: 0)
            let tapEventSet = TapEventSet(amplitudeFilter: scalesModel.amplitudeFilter, description: "scaleStart:\(scale.getMinMax().0) lenient:\(octaveLenient)")
            for recordedTapEvent in eventSet {
                let processedtapEvent = processTap(scale: scale, octaveLenient: octaveLenient, updateKeyboard: updateKeyboard, amplitude: recordedTapEvent.amplitude, frequency: recordedTapEvent.frequency)
                tapEventSet.events.append(processedtapEvent)
            }
            let result = Result(scale: scale, fromProcess: self.fromProcess, amplitudeFilter: scalesModel.amplitudeFilter, userMessage: "")
            result.buildResult(score: score)
            return (result, tapEventSet)
        }
        
        ///Find the best fit scale
        for rootOffsetMidi in scaleRootOffsets {
            ///Set the trial scale for the scale offset
            let trialScale = self.inputScale.makeNewScale(offset: rootOffsetMidi)
            let result = applyEvents(scale: trialScale, octaveLenient: false, score: nil, updateKeyboard: false, eventSet: self.recordedTapEvents).0
            if minErrorResult == nil || minErrorResult!.isBetter(compare: result) {
                minErrorResult = result
                bestOffset = rootOffsetMidi
            }
            print("=============================stop tapping", "scaleOffset", rootOffsetMidi, "Result info:", result.getInfo(),
                  "MIDIrange:", trialScale.getMinMax())
        }
        
        ///Replay the best fit scale to set the app's display state
        if let bestOffset = bestOffset {
            let bestScale = inputScale.makeNewScale(offset: bestOffset)
            let score = scalesModel.createScore(scale: bestScale)
            scalesModel.setScale(scale: bestScale, score: score )
            let (result, eventSet) = applyEvents(scale: bestScale, octaveLenient: true, score: score, updateKeyboard: true, eventSet: self.recordedTapEvents)
            print("========================================Set Best", "scaleOffset", bestOffset, "Result info:", result.getInfo())
            scalesModel.setResultInternal(result, "stop Tapping")
            if result.noErrors() {
                score.setNormalizedValues(scale: bestScale)
            }
            if ScalesModel.shared.runningProcess == .recordingScale && Settings.shared.recordDataMode{ //} && self.tapRecords.count > 0 {
                self.saveTapsToFile(result: result)
            }
            return eventSet
        }
        else {
            return TapEventSet(amplitudeFilter: amplitudeFilter, description: "Empty")
        }
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
        fileName += "_"+String(result.wrongCountAsc)+","+String(result.wrongCountDesc)+","+String(result.missedCountAsc)+","+String(result.missedCountDesc)
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
    
    func processTap(scale:Scale, octaveLenient:Bool, updateKeyboard:Bool, amplitude:Float, frequency:Float) -> TapEvent {
        let tapMidi = Util.frequencyToMIDI(frequency: frequency)
        self.eventNumber += 1
        
        ///Require a large change in amplitude to start the scale
        ///Compare averages of amplitudes to detect the major change over averaged tap events
        if matchCount == 0 {
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
            let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
            let secs = Double(ms) / 1000.0
            
            if diff < 2.0 {
                let event = TapEvent(tapNum: eventNumber,
                                     frequency: frequency,
                                     amplitude: amplitude,
                                     ascending: false,
                                     status: .beforeScaleStart,
                                     expectedScaleNoteStates: nil,
                                     midi: tapMidi, tapMidi: tapMidi,
                                     key: nil)
                return event
            }
        }
        guard amplitude > AUValue(self.amplitudeFilter) else {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: frequency,
                                 amplitude: amplitude,
                                 ascending: false,
                                  status: .belowAmplitudeFilter,
                                 expectedScaleNoteStates: nil,
                                 midi: tapMidi, tapMidi: tapMidi,
                                 key: nil)
            return event
        }
        
        //let keyboardModel = PianoKeyboardModel.shared
        //let nextExpectedNotes = scale.getNextExpectedNotes(count: 2)
        let nextExpectedNotes = scale.getNextExpectedNotes(count: 1)
        guard nextExpectedNotes.count > 0 else {
            ///All scales notes are already matched
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: frequency,
                                 amplitude: amplitude,
                                 ascending: false,
                                 status: .pastEndOfScale,
                                 expectedScaleNoteStates: nextExpectedNotes,
                                 midi: tapMidi, tapMidi: tapMidi,
                                 key: nil)
            return event
        }
        
        var midi = tapMidi
        
        ///Adjust to the pitch in the expected octave. e.g. A middle C = 60 might arrive as 72 or 48. 72 matches the scale and causes a note played at key 72
        ///So treat the 72 as middle C = 60 so its not treated as the top of the scale (and then that everything that follows is descending)
        ///octaveOffsets = [0, 12, -12, 24, -24, 36, -36]
        var minDist = 1000000
        var minIndex = 0
        //reduce spread size before scale starts, or at lower pitches? its missing the last note at 0.02, play with filters more on this 3 octave C
        for i in 0..<self.allowableOctaveOffsets.count {
            let dist = abs((tapMidi  + self.allowableOctaveOffsets[i]) - nextExpectedNotes[0].midi)
            if dist < minDist {
                minDist = dist
                minIndex = i
            }
        }
        midi = tapMidi + self.allowableOctaveOffsets[minIndex]
        let ascending = nextExpectedNotes[0].sequence <= scale.scaleNoteState.count / 2
        
        let atTop = nextExpectedNotes[0].sequence == scale.scaleNoteState.count / 2 && midi == nextExpectedNotes[0].midi
        
        ///Does the notification represents a key that could be pressed on the keyboard?
        guard let keyboardIndex = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) else {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: frequency,
                                 amplitude: amplitude,
                                 ascending: ascending,
                                 status: .keyNotOnKeyboard,
                                 expectedScaleNoteStates: nextExpectedNotes,
                                 midi: midi, tapMidi: tapMidi,
                                 key: nil)
            return event
        }
        
        ///Same as last note?
        if let lastKeyPressedMidi = lastKeyPressedMidi {
            if unmatchedCount == nil {
                guard midi != lastKeyPressedMidi else {
                    let event = TapEvent(tapNum: eventNumber,
                                          frequency: frequency,
                                          amplitude: amplitude,
                                          ascending: ascending,
                                          status: .continued,
                                          expectedScaleNoteStates: nextExpectedNotes,
                                          midi: midi, tapMidi: tapMidi,
                                          key: nil)
                    return event
                }
            }
        }
        
        ///Within the scale highest and lowest?
        guard midi >= minScaleMidi && midi <= maxScaleMidi else {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: frequency,
                                 amplitude: amplitude,
                                 ascending: ascending,
                                 status: .outsideScale,
                                 expectedScaleNoteStates: nextExpectedNotes,
                                 midi: midi, tapMidi: tapMidi,
                                 key: nil)
            return event
        }
        
        ///We assume now that errors will be only off by a note or two so any midi's that are different than the expected by too much are treated as noise.
        ///Harmonics, bumps, noise etc. They should not cause key presses or scale note matches.
        
        ///If the key maps to a scale note update the scale note's matched state
        ///Also update the key's clickedState
        
        var tapEventStatus:TapEventStatus = .none
        let diffToExpected = abs(midi - nextExpectedNotes[0].midi)
        if diffToExpected > 2 {
            tapEventStatus = .farFromExpected
        }
        else {
            var match = false
            if nextExpectedNotes[0].midi == 83 {
                match = false
            }
            for i in [0,1] {
                if i < nextExpectedNotes.count {
                    if nextExpectedNotes[i].midi == midi {
                        nextExpectedNotes[i].matchedTime = Date()
                        nextExpectedNotes[i].matchedAmplitude = Double(amplitude)
                        tapEventStatus = i == 0 ? .pressNextScaleMatch : .pressFollowingScaleMatch
                        unmatchedCount = nil
                        match = true
                        if i > 0 {
                            ///Set any previously expected note unmatched
                            nextExpectedNotes[0].unmatchedTime = Date()
                        }
                        matchCount += 1
                        if tapEventStatus == .pressNextScaleMatch {
                            ///Open up octave overtones/harmonics match after first good reliable scales match
                            if octaveLenient {
                                self.allowableOctaveOffsets = [0, 12, -12, 24, -24, 36, -36]
                            }
                        }
                        break
                    }
                }
            }

            if !match {
                ///Only advance the expected next note when one note was missed.
                ///e.g. they play E instead of E♭ advance the expected next to F but dont advance it further
                if unmatchedCount == nil {
                    unmatchedCount = 1
                    tapEventStatus = .wrongButWaitForNext
                }
                else {
                    tapEventStatus = .pressWithoutScaleMatch
                    unmatchedCount = nil
                    //if unmatchedCount == 0 {
                        nextExpectedNotes[0].unmatchedTime = Date()
                    //}
                }
            }
            
            ///Update key tapped state
            
            let keyboardKey = keyboard.pianoKeyModel[keyboardIndex]
            if updateKeyboard {
                if unmatchedCount == nil {
                    if ascending || atTop {
                        keyboardKey.keyWasPlayedState.tappedTimeAscending = Date()
                        keyboardKey.keyWasPlayedState.tappedAmplitudeAscending = Double(amplitude)
                    }
                    if !ascending || atTop  {
                        keyboardKey.keyWasPlayedState.tappedTimeDescending = Date()
                        keyboardKey.keyWasPlayedState.tappedAmplitudeDescending = Double(amplitude)
                    }
                    keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: self.hilightPlayingNotes)
                }
            }
            
            lastKeyPressedMidi = keyboardKey.midi
            if atTop {
                DispatchQueue.main.async {
                    //ScalesModel.shared.setDirection(1)
                    //keyboardModel.redraw()
                }
            }
        }
        let keyboardKey = keyboard.pianoKeyModel[keyboardIndex]
        let event = TapEvent(tapNum: eventNumber,
                             frequency: frequency,
                             amplitude: amplitude,
                             ascending: ascending,
                             status: tapEventStatus,
                             expectedScaleNoteStates: nextExpectedNotes,
                             midi: midi, tapMidi: tapMidi,
                             key: keyboardKey)


        return event
    }
    

}
