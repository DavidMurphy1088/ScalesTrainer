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
    var atEnd = false
    var tapBufferSize:Int
    var lastMatchedScaleIndex:Int? = nil
    
    ///When on require a large increase in amplitude to start the scale matching (avoids false starts from noise before tapping)
    ///But settable since tappiong after a lead in has minimal taps at start to measure the increase.
    var filterStartOfTapping:Bool
    var scaleMidis:[Int]
    
    required init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool,
                  filterStartOfTapping:Bool, bufferSize:Int) {
        self.recordedTapEvents = []
        self.inputScale = scalesModel.scale
        self.amplitudeFilter = amplitudeFilter
        self.hilightPlayingNotes = hilightPlayingNotes
        (self.minScaleMidi, self.maxScaleMidi) = inputScale.getMinMax()
        self.fromProcess = fromProcess
        self.startTappingTime = nil
        self.filterStartOfTapping = filterStartOfTapping
        self.tapBufferSize = bufferSize
        self.scaleMidis = self.inputScale.getMidisInScale()
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
        self.atEnd = false
        self.lastMatchedScaleIndex = nil
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
                             expectedMidis: [], midi: 0, tapMidi: tapMidi, consecutiveCount: 1)
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
                                scalesModel.setRunningProcess(.none, tapBufferSize: self.tapBufferSize)
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
    
    ///On stop tapping test which scale offset best fits the user's scale recording. This is required so that if a scale is say starting on middle C (60) the user may elect to record it at another octave.
    ///The set of tap frequences, amplitudes and times is processed against each scale offset. For each event set process the keyboard must be configured to the scale octave range being tested.
    ///This analysis is 'fuzzy' becuase a piano key tap produces a range of pitches (e.g. octaves) and so its not straightforward to know which scale offset best fits.
    ///Pick the scale offset with the lowest errors and assume that is the scale the user played. Run the tap events past that scale and keyboard configuration one more time to have the UI updated with the correct result.
    func stopTapping(_ ctx: String) -> TapEventSet {
        ///Determine which scale range the user played. e.g. for C Maj RH they have started on midi 60 or 72 or 48. All would be correct.
        ///Analyse the tapping aginst different scale starts to determine which has the least errors.
        ///Update the app state after tapping based on the selected scale start.
        
        class Config {
            var scaleOffset:Int
            var discardSingletons:Bool
            var reducedEventSetFactor:Int
            var filterStarts:Bool
            
            init(scaleOffset:Int, discardSingletons:Bool, reducedEventSetFactor:Int, filterStarts:Bool) {
                self.scaleOffset = scaleOffset
                self.discardSingletons = discardSingletons
                self.reducedEventSetFactor = reducedEventSetFactor
                self.filterStarts = filterStarts
            }
        }
        
        if self.recordedTapEvents.isEmpty {
            let empty = TapEventSet(amplitudeFilter: 0, description: "")
            return empty
        }
        
//        print("======= TAPS")
//        for event in self.recordedTapEvents {
//            print(event.tapNum, Util.frequencyToMIDI(frequency: event.frequency),   "   AMpl:", event.amplitude)
//        }
//        print("======= END TAPS")

        ///Reversed - if lots of errors make sure the 0 offset is the final one displayed
        let scaleRootOffsets = [0] //[0, 12, -12, 24, -24].reversed()
        var minErrorResult:Result? = nil
        var bestConfiguration:Config? = nil
                
        func applyEvents(ctx:String, recordedTapEvents:[TapEvent],
                         offset:Int, scale:Scale, keyboard:PianoKeyboardModel,
                         reducing:Int,
                         discardSingletons:Bool, filterStart:Bool,
                         octaveLenient:Bool, score:Score?, updateKeyboard:Bool
                         ) -> (Result, TapEventSet) {
            ///Apply the tapped events to a given scale start
            self.resetState(scale: scale, octaveLenient: octaveLenient)
            let tapEventSet = TapEventSet(amplitudeFilter: scalesModel.amplitudeFilter,
                                          description: "scaleStart:\(scale.getMinMax().0) lenient:\(octaveLenient) bufSize:\(self.tapBufferSize)")
            let tapEvents:[TapEvent]
            if reducing > 0 {
                tapEvents = reduceEvents(events: recordedTapEvents, requiredConsecutiveCount: reducing)
            }
            else {
                tapEvents = recordedTapEvents
            }
            for event in tapEvents {
                let processedtapEvent = processTap(ctx: ctx, scale: scale, keyboard: keyboard, eventToProcess: event,
                                                   discardSingletons: discardSingletons, filterStart: filterStart, octaveLenient: octaveLenient,
                                                   updateKeyboardDisplay: updateKeyboard)
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
            ///for discardSingletons in [false, true] {
            //for reducing in [4,3,2,1,0] {
            for reducing in [3] {
                
                let trialScale = self.inputScale.makeNewScale(offset: rootOffsetMidi)
                let keyboard = PianoKeyboardModel()
                keyboard.configureKeyboardForScale(scale: trialScale)
                let discardSingletons = reducing == 0
                let filterStarts = reducing == 0
                let result = applyEvents(ctx: "TryOffset", recordedTapEvents: 
                                         self.recordedTapEvents, offset: rootOffsetMidi, scale: trialScale, keyboard: keyboard,
                                         reducing: reducing,
                                         discardSingletons: discardSingletons,
                                         filterStart: filterStarts,
                                         octaveLenient: false, score: nil, updateKeyboard: false).0
                if minErrorResult == nil || minErrorResult!.isBetter(compare: result) {
                    minErrorResult = result
                    bestConfiguration = Config(scaleOffset: rootOffsetMidi, discardSingletons: discardSingletons, reducedEventSetFactor: reducing, filterStarts: filterStarts)
                }
                Logger.shared.log(self, "Assessed at offset:\(rootOffsetMidi) reduced:\(reducing) discardSingles:\(discardSingletons) errors:\(result.getResultsString())")
            }
        }
        
        ///Replay the best fit scale to set the app's display state
        if let bestConfiguration = bestConfiguration {
            ///If there are too many errors just display the scale at the octaves it was shown as
            let bestScale:Scale
            if minErrorResult == nil || minErrorResult!.getTotalErrors() > 3 {
                bestScale = inputScale.makeNewScale(offset: 0)
            }
            else {
                bestScale = inputScale.makeNewScale(offset: bestConfiguration.scaleOffset)
            }
            
            ///Score note status is updated during result build, keyboard key status is updated by tap processing
            let score = scalesModel.createScore(scale: bestScale)
            self.scalesModel.setScaleAndScore(scale: bestScale, score: score, ctx: "ScaleTapHandler:bestOffset")
            
            ///Ensure keyboard visible key statuses are updated during events apply
            let keyboard = PianoKeyboardModel.shared
            keyboard.configureKeyboardForScale(scale: bestScale)
            //keyboard.debugSize("useBest")
            let (result, eventSet) = applyEvents(ctx: "useBest", recordedTapEvents: self.recordedTapEvents,
                                                 offset: bestConfiguration.scaleOffset, scale: bestScale, keyboard: keyboard, 
                                                 reducing: bestConfiguration.reducedEventSetFactor,
                                                 discardSingletons: bestConfiguration.discardSingletons,
                                                 filterStart: bestConfiguration.filterStarts,
                                                 octaveLenient: true,
                                                 score: score, updateKeyboard: true)
            Logger.shared.log(self, "Applied recording for ** best ** scale at offset \(bestConfiguration.scaleOffset) reduced:\(bestConfiguration.reducedEventSetFactor) discardSingletons:\(bestConfiguration.discardSingletons) result:\(result.getResultsString())")
            //keyboard.debug11("best")
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
    
    ///Build an event record that describes how this tap was handled. The record has various states to describe the handling.
    ///The events show how the decision to mark each keyboard key as played was made.
    ///For a tap that is considered an actual note played update the keyboard key with the current datetime.
    ///The keyboard keys timestamp is the state that determines the final result of the scale recording as it is applied to the scale.
    ///The events become part of the viewable log of the scale recording.
    ///Filter out spurios tap event frequencies.
    func processTap(ctx:String, scale:Scale, keyboard:PianoKeyboardModel, eventToProcess:TapEvent,
                    discardSingletons:Bool, filterStart:Bool,
                    octaveLenient:Bool, updateKeyboardDisplay:Bool) -> TapEvent {
                    //amplitude:Float, frequency:Float, recordedTimestamp:Date) -> TapEvent {
        //let tapMidi = Util.frequencyToMIDI(frequency: event.frequency)
        self.eventNumber += 1
        //print ("============>>>", self.eventNumber, "Midi", tapMidi, amplitude)
        
        ///Require a large change in amplitude to start the scale
        ///This avoids false starts and scale note matches with noise before playing notes
        ///Compare averages of amplitudes to detect the major change over averaged tap events
        if filterStart {
            if self.filterStartOfTapping && matchCount == 0 {
                scaleStartAmplitudes.append(eventToProcess.amplitude)
                scalePotentialStartAmplitudes.append(eventToProcess.amplitude)
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
                                         frequency: eventToProcess.frequency,
                                         amplitude: eventToProcess.amplitude,
                                         ascending: self.ascending,
                                         status: .beforeScaleStart,
                                         expectedMidis: [],
                                         midi: nil,
                                         tapMidi: eventToProcess.tapMidi,
                                         consecutiveCount: eventToProcess.consecutiveCount)
                    return event
                }
            }
        }
        
        //After scale end
        if self.atEnd {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: eventToProcess.frequency,
                                 amplitude: eventToProcess.amplitude,
                                 ascending: self.ascending,
                                 status: .afterScaleEnd,
                                 expectedMidis: [],
                                 midi: nil, 
                                 tapMidi: eventToProcess.tapMidi,
                                 consecutiveCount: eventToProcess.consecutiveCount)
            return event
        }
        
        guard eventToProcess.amplitude > AUValue(self.amplitudeFilter) else {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: eventToProcess.frequency,
                                 amplitude: eventToProcess.amplitude,
                                 ascending: self.ascending,
                                 status: .belowAmplitudeFilter,
                                 expectedMidis: [],
                                 midi: nil, 
                                 tapMidi: eventToProcess.tapMidi,
                                 consecutiveCount: eventToProcess.consecutiveCount)
            return event
        }
        
        ///Ensure the tap is not a singleton, i.e. we need to see > 0 occurrences of it to proceed so we dont take the first
        
        if discardSingletons {
            if let lastTappedMidi = lastTappedMidi {
                if eventToProcess.tapMidi == lastTappedMidi {
                    self.lastTappedMidiCount += 1
                }
                else {
                    self.lastTappedMidiCount = 1
                }
                self.lastTappedMidi = eventToProcess.tapMidi
                if self.lastTappedMidiCount == 1 {
                    let event = TapEvent(tapNum: eventNumber,
                                         frequency: eventToProcess.frequency,
                                         amplitude: eventToProcess.amplitude,
                                         ascending: self.ascending,
                                         status: .waitForMore,
                                         expectedMidis: [],
                                         midi: nil,
                                         tapMidi: eventToProcess.tapMidi,
                                         consecutiveCount: 1)
                    return event
                }
            }
            else {
                self.lastTappedMidi = eventToProcess.tapMidi
                self.lastTappedMidiCount = 1
            }
        }
        
        var midi = eventToProcess.tapMidi
        var bestDiff:Int? = nil
        
        ///A note's pitch can arrive as octave harmonics of the expected pitch.
        ///Determine the actual midi based on the nearest key that to the last one the user played.
        //let tappedMidiPossibles = [midi-24, midi - 12, midi, midi + 12, midi + 24]
        let tappedMidiPossibles = [midi - 48, midi - 36, midi-24, midi - 12, midi, midi + 12, midi + 24, midi + 36, midi + 48]
        
//        if eventToProcess.tapMidi == 38 && ascending == false {
//            print("==================================== ", ctx, "tapped:", eventToProcess.tapMidi, midi, "lastMidi:", self.lastMatchedMidi!, "asc", ascending,
//                  "discardSingletons:", discardSingletons)
//        }
        var expectedMidiByLastKeyPlayed:Int
        if self.lastMatchedMidi == nil {
            expectedMidiByLastKeyPlayed = self.scaleMidis[0]
        }
        else {
            //let delta = abs(self.lastMatchedMidi! - ) ...block big changes in expectged
            expectedMidiByLastKeyPlayed = self.lastMatchedMidi!
            if ascending {
                expectedMidiByLastKeyPlayed += 2
            }
            else {
                expectedMidiByLastKeyPlayed -= 2
            }
        }
        var expectedMidiByTheScale:Int = 0
        if let lastMatchedScaleIndex = self.lastMatchedScaleIndex {
            if lastMatchedScaleIndex < self.scaleMidis.count {
                expectedMidiByTheScale = self.scaleMidis[lastMatchedScaleIndex]
            }
        }
//        if event.tapMidi == 67 && ascending == false {
//            print("==================================== ", ctx, "tapped:", event.tapMidi, midi, "asc", ascending, "expect", expectedMidiByLastKeyPlayed, "expectInScale",
//                  expectedMidiByLastKeyPlayed, "discardSingletons:", discardSingletons)
//        }
        if true {
            for possibleMidi in tappedMidiPossibles {
                let diff = abs(possibleMidi - expectedMidiByLastKeyPlayed)
                if bestDiff == nil || diff < bestDiff! {
                    bestDiff = diff
                    midi = possibleMidi
                }
            }
        }
        else {
            for possibleMidi in tappedMidiPossibles {
                let diff = abs(possibleMidi - expectedMidiByTheScale)
                if bestDiff == nil || diff < bestDiff! {
                    bestDiff = diff
                    midi = possibleMidi
                }
            }
        }
//        
//        if tapMidi == 65 {
//            print("============= ", tapMidi, midi, "expect", expectedMidiByLastKeyPlayed, tappedMidiPossibles, "asc", ascending)
//        }

        ///At top of scale. At end of scale?
        self.matchCount += 1
        var atTop = false
        if midi == scale.getMinMax().1 {
            atTop = true
            self.ascending = false
        }
        //if midi == scale.getMinMax().0 {
        if eventToProcess.tapMidi == scale.getMinMax().0  && midi == scale.getMinMax().0 {

            ///End of scale if the midi is the root and the root has already been played
            if let index = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
                let keyboardKey = keyboard.pianoKeyModel[index]
                if keyboardKey.keyWasPlayedState.tappedTimeDescending != nil {
                    self.atEnd = true
                    let event = TapEvent(tapNum: eventNumber,
                                         frequency: eventToProcess.frequency,
                                         amplitude: eventToProcess.amplitude,
                                         ascending: self.ascending,
                                         status: .afterScaleEnd,
                                         expectedMidis: [expectedMidiByLastKeyPlayed, expectedMidiByTheScale],
                                         midi: midi, 
                                         tapMidi: eventToProcess.tapMidi,
                                         consecutiveCount: eventToProcess.consecutiveCount)
                    return event
                }
            }
        }

//        print ("  ============>>> ", self.eventNumber, "Use", midi, "Tapped:", tapMidi, "expected", expectedMidi, "diff:", bestDiff ?? "None",
//               "atTop", atTop, "ascending", ascending)
        
        ///Same as last note?
        if midi == lastMatchedMidi {
            let event = TapEvent(tapNum: eventNumber,
                                 frequency: eventToProcess.frequency,
                                 amplitude: eventToProcess.amplitude,
                                 ascending: self.ascending,
                                  status: .sameMidiContinued,
                                 expectedMidis: [expectedMidiByLastKeyPlayed, expectedMidiByTheScale],
                                  midi: midi, 
                                 tapMidi: eventToProcess.tapMidi,
                                 consecutiveCount: eventToProcess.consecutiveCount)
            return event
        }

        ///Update the state to figure out the next expected MIDI
        self.lastMatchedMidi = midi
        if self.lastMatchedScaleIndex == nil {
            self.lastMatchedScaleIndex = 0
        }
        self.lastMatchedScaleIndex! += 1
        
        ///Update key tapped state
        
        if let keyboardIndex = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
            let keyboardKey = keyboard.pianoKeyModel[keyboardIndex]
            if unmatchedCount == nil {
                if self.ascending || atTop {
                    keyboardKey.keyWasPlayedState.tappedTimeAscending = eventToProcess.timestamp //Date()
                    keyboardKey.keyWasPlayedState.tappedAmplitudeAscending = Double(eventToProcess.amplitude)
                }
                if !self.ascending || atTop  {
                    keyboardKey.keyWasPlayedState.tappedTimeDescending = eventToProcess.timestamp
                    keyboardKey.keyWasPlayedState.tappedAmplitudeDescending = Double(eventToProcess.amplitude)
                }
                if updateKeyboardDisplay {
                    keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: self.hilightPlayingNotes)
                }
            }
        }
        
        let event = TapEvent(tapNum: eventNumber,
                             frequency: eventToProcess.frequency,
                             amplitude: eventToProcess.amplitude,
                             ascending: self.ascending,
                             status: .keyPressed,
                             expectedMidis: [expectedMidiByLastKeyPlayed, expectedMidiByTheScale],
                             midi: midi,
                             tapMidi: eventToProcess.tapMidi,
                             consecutiveCount: eventToProcess.consecutiveCount)
        
        ///Only require timestamp on scale matched taps becuase they are used to calculate tempo (but only on correct notes)
        event.timestamp = eventToProcess.timestamp
        return event
    }
    
    ///Reduce the set of events by excluding any that dont occur requiredConsecutiveCount times consecutively
    func reduceEvents(events:[TapEvent], requiredConsecutiveCount:Int) -> [TapEvent] {
        var filtered:[TapEvent] = []
        var lastEvent:TapEvent?
        var count = 0
        var eventCount = 0
        var maxCount:Int = 0
        
        for event in events {
            if eventCount == 149 {
                eventCount = eventCount - 0
            }
            if lastEvent == nil {
                lastEvent = TapEvent(tap: event)
                eventCount += 1
                continue
            }
            if event.tapMidi == lastEvent!.tapMidi {
                count += 1
                eventCount += 1
                continue
            }
            var keepTap = count >= requiredConsecutiveCount
//                if self.scaleMidis.contains(lastEvent!.tapMidi) {
//                    keepTap = true
//                }
            if keepTap {
                if count > maxCount {
                    maxCount = count
                }
                lastEvent!.consecutiveCount = count
                filtered.append(lastEvent!)
                count = 0
            }
            lastEvent = TapEvent(tap: event)
            count += 1
            eventCount += 1
        }
        if let lastEvent = lastEvent {
            filtered.append(lastEvent)
        }
        Logger.shared.log(self, "Event Reduce eventsIn:\(events.count) eventsOut:\(filtered.count) maxCount:\(maxCount)")
        return filtered
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
                var config = "config:\t\(self.amplitudeFilter) tapBufferSize:\t\(self.tapBufferSize)"
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
