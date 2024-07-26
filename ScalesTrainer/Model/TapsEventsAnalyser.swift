import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit
import Foundation

class TapsEventsAnalyser {
    let scale:Scale
    let recordedTapEvents:[TapEvent]
    let keyboard:PianoKeyboardModel
    let fromProcess: RunningProcess
    let bufferSize:Int
    
    var eventNumber:Int = 0
    var matchCount:Int = 0
    var scaleStartAmplitudes:[Float] = []
    var scalePotentialStartAmplitudes:[Float] = []
    var lastMatchedMidi:Int? = nil
    var minScaleMidi = 0
    var maxScaleMidi = 0
    var allowableOctaveOffsets:[Int] = []
    var startTappingAmplitudes:[Int] = []
    var startTappingAvgAmplitude:Double? = nil
    var endTappingLowAmplitudeCount = 0
    var lastTappedMidi:Int? = nil
    var lastTappedMidiCount = 0
    var ascending = true
    var atEnd = false
    var lastMatchedScaleIndex:Int? = nil
    
    ///When on require a large increase in amplitude to start the scale matching (avoids false starts from noise before tapping)
    ///But settable since tapping after a lead in has minimal taps at start to measure the increase.
    var filterStartOfTapping:Bool = false
    
    var scaleMidis:[Int]
    
    init(scale:Scale, bufferSize:Int, recordedTapEvents:[TapEvent], keyboard:PianoKeyboardModel, fromProcess: RunningProcess) {
        self.scale = scale
        self.bufferSize = bufferSize
        self.recordedTapEvents = recordedTapEvents
        self.keyboard = keyboard
        self.fromProcess = fromProcess
        self.scaleMidis = scale.getMidisInScale()
    }
    
    func resetState(scale:Scale, octaveLenient:Bool) {
        self.matchCount = 0
        self.eventNumber = 0
        //self.unmatchedCount = nil
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
    

    ///On stop tapping test which scale offset best fits the user's scale recording. This is required so that if a scale is say starting on middle C (60) the user may elect to record it at another octave.
    ///The set of tap frequences, amplitudes and times is processed against each scale offset. For each event set process the keyboard must be configured to the scale octave range being tested.
    ///This analysis is 'fuzzy' becuase a piano key tap produces a range of pitches (e.g. octaves) and so its not straightforward to know which scale offset best fits.
    ///Pick the scale offset with the lowest errors and assume that is the scale the user played. Run the tap events past that scale and keyboard configuration one more time to have the UI updated with the correct result.
    
    func getBestResult() -> (Result?, TapEventSet?) {
        ///Determine which scale range the user played. e.g. for C Maj RH they have started on midi 60 or 72 or 48. All would be correct.
        ///Analyse the tapping aginst different scale starts to determine which has the least errors.
        ///Update the app state after tapping based on the selected scale start.
        
        if recordedTapEvents.isEmpty {
            return (nil, nil)
        }
//
//        print("======= TAPS")
//        for event in self.recordedTapEvents {
//            print(event.tapNum, Util.frequencyToMIDI(frequency: event.frequency),   "   AMpl:", event.amplitude)
//        }
//        print("======= END TAPS")

        ///Reversed - if lots of errors make sure the 0 offset is the final one displayed
        let scaleRootOffsets = [0] //[0, 12, -12, 24, -24].reversed()
        let compressingFactors = [2]  //[4,3,2,1,0] {
        
        var bestResult:Result? = nil
        var bestTapSet:TapEventSet? = nil
        
        ///Find the best fit scale
        for rootOffsetMidi in scaleRootOffsets {
            for compressingFactor in compressingFactors {
                let trialScale = scale.makeNewScale(offset: rootOffsetMidi)
                let keyboard = PianoKeyboardModel()
                keyboard.configureKeyboardForScale(scale: trialScale)
                let filterStarts = compressingFactor == 0
                let (result, eventSet) = applyEvents(ctx: "TryOffset", bufferSize: bufferSize,
                                         recordedTapEvents:recordedTapEvents,
                                         offset: rootOffsetMidi, scale: trialScale, keyboard: keyboard,
                                         compressingFactor: compressingFactor,
                                         //discardSingletons: discardSingletons,
                                         //filterStart: filterStarts,
                                         octaveLenient: false, score: nil, updateKeyboard: false)
                if bestResult == nil || bestResult!.isBetter(compare: result) {
                    bestResult = result
                    bestTapSet = eventSet
                }
                Logger.shared.log(self, "Assessed events. ResultingEvents:\(eventSet.events.count) BufferSize:\(self.bufferSize) Offset:\(rootOffsetMidi) Compress:\(compressingFactor) Errors:\(result.getResultsString())")
            }
        }
        
        guard let bestResult = bestResult else {
            return (nil, nil)
        }
        
        ///Replay the best fit scale to set the app's display state

        ///If there are too many errors just display the scale at the octaves it was shown as
        let bestScale:Scale = self.scale
//            if bestResult == nil || bestResult!.getTotalErrors() > 3 {
//                bestScale = self.scale.makeNewScale(offset: 0)
//            }
//            else {
//                bestScale = self.scale.makeNewScale(offset: bestConfiguration.scaleOffset)
//            }
            
            ///Score note status is updated during result build, keyboard key status is updated by tap processing
//            let score = scalesModel.createScore(scale: bestScale)
//            self.scalesModel.setScaleAndScore(scale: bestScale, score: score, ctx: "ScaleTapHandler:bestOffset")
            
            ///Ensure keyboard visible key statuses are updated during events apply
            //let keyboard = PianoKeyboardModel.shared
        self.keyboard.configureKeyboardForScale(scale: bestScale)
            //keyboard.debugSize("useBest")
        let (result, eventSet) = applyEvents(ctx: "useBest", bufferSize: self.bufferSize,
                                             recordedTapEvents: self.recordedTapEvents,
                                             offset: 0, scale: bestScale, keyboard: keyboard,
                                             compressingFactor: bestResult.compressingFactor,
                                             //discardSingletons: true,
                                             //filterStart: false,
                                             octaveLenient: true,
                                             score: nil,
                                             updateKeyboard: true)
            Logger.shared.log(self, "Applied best events. Offset:\(0) Compress:\(bestResult.compressingFactor) Result:\(result.getResultsString())")
            //scalesModel.setResultInternal(result, "stop Tapping")
//            if result.noErrors() {
//                score.setNormalizedValues(scale: bestScale)
//            }
//            PianoKeyboardModel.shared.redraw()
//            if ScalesModel.shared.runningProcess == .recordingScale && Settings.shared.recordDataMode{
//                self.saveTapsToFile(result: result)
//            }
        return (bestResult, bestTapSet)
    }
    
    func applyEvents(ctx:String,
                     bufferSize:Int,
                     recordedTapEvents:[TapEvent],
                     offset:Int, scale:Scale, keyboard:PianoKeyboardModel,
                     compressingFactor:Int,
                     octaveLenient:Bool,
                     score:Score?,
                     updateKeyboard:Bool
                     ) -> (Result, TapEventSet) {
        ///Apply the tapped events to a given scale start
        resetState(scale: scale, octaveLenient: false)
        let tapEventSet = TapEventSet(bufferSize: bufferSize,
                                      description: "Start:\(scale.getMinMax().0) Compress:\(compressingFactor) Lenient:\(octaveLenient)")
        let tapEvents:[TapEvent]
        if compressingFactor > 0 {
            tapEvents = compressEvents(events: recordedTapEvents, requiredConsecutiveCount: compressingFactor)
        }
        else {
            tapEvents = recordedTapEvents
        }
        for event in tapEvents {
            let processedtapEvent = processTap(ctx: ctx, scale: scale, 
                                               keyboard: keyboard,
                                               eventToProcess: event,
                                               discardSingletons: compressingFactor == 0,
                                               filterStart: true, octaveLenient: octaveLenient,
                                               updateKeyboardDisplay: updateKeyboard)
            tapEventSet.events.append(processedtapEvent)
        }
        let result = Result(scale: scale, keyboard: keyboard, fromProcess: self.fromProcess,
                            amplitudeFilter: Settings.shared.tapMinimunAmplificationFilter, compressingFactor: compressingFactor, userMessage: "")
        result.buildResult(offset: offset)
        return (result, tapEventSet)
    }
    
    ///Build an event record that describes how this tap was handled. The record has various states to describe the handling.
    ///The event shows how the decision to mark each keyboard key as played was made.
    ///For a tap that is considered an actual note played update the keyboard key with the current datetime.
    ///The keyboard keys timestamp is the state that determines the final result of the scale recording as it is applied to the scale.
    ///The events become part of the viewable log of the scale recording.
    ///Filter out spurios tap event frequencies.
    func processTap(ctx:String, scale:Scale, keyboard:PianoKeyboardModel, eventToProcess:TapEvent,
                    discardSingletons:Bool, filterStart:Bool,
                    octaveLenient:Bool, updateKeyboardDisplay:Bool) -> TapEvent {
                    //amplitude:Float, frequency:Float, recordedTimestamp:Date) -> TapEvent {
        self.eventNumber += 1
        
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
        
        guard eventToProcess.amplitude > AUValue(Settings.shared.tapMinimunAmplificationFilter) else {
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
//        if [60, 62, 64].contains(midi) {
//            midi = midi + 0
//        }
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
            if self.ascending || atTop {
                keyboardKey.keyWasPlayedState.tappedTimeAscending = eventToProcess.timestamp
                keyboardKey.keyWasPlayedState.tappedAmplitudeAscending = Double(eventToProcess.amplitude)
            }
            if !self.ascending || atTop  {
                keyboardKey.keyWasPlayedState.tappedTimeDescending = eventToProcess.timestamp
                keyboardKey.keyWasPlayedState.tappedAmplitudeDescending = Double(eventToProcess.amplitude)
            }
            if updateKeyboardDisplay {
               // keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: self.hilightPlayingNotes)
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

    ///Compress events for the same tap midi that occur conurrently
    ///Discard midi events that dont concurrently occur the required number of times
    func compressEvents(events:[TapEvent], requiredConsecutiveCount:Int) -> [TapEvent] {
        var filtered:[TapEvent] = []
        var lastEvent:TapEvent?
        var count = 0
        var eventCount = 0
        var maxCount:Int = 0
        
        for event in events {
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

}
