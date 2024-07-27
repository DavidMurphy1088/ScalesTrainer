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
    let recordedTapEventSets:[TapEventSet]
    let keyboard:PianoKeyboardModel
    let fromProcess: RunningProcess
    let amplitudeFilter:Double
    
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
 
    init (scale: Scale, recordedTapEventSets: [TapEventSet], amplitudeFilter:Double, keyboard: PianoKeyboardModel, fromProcess: RunningProcess) {
        self.scale = scale
        self.keyboard = keyboard
        self.fromProcess = fromProcess
        self.scaleMidis = scale.getMidisInScale()
        self.recordedTapEventSets = recordedTapEventSets
        self.amplitudeFilter = amplitudeFilter
    }
    
    func resetState(scale:Scale, octaveLenient:Bool) {
        self.matchCount = 0
        self.eventNumber = 0
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
        
//
//        print("======= TAPS")
//        for event in self.recordedTapEvents {
//            print(event.tapNum, Util.frequencyToMIDI(frequency: event.frequency),   "   AMpl:", event.amplitude)
//        }
//        print("======= END TAPS")

        ///Reversed - if lots of errors make sure the 0 offset is the final one displayed
        let scaleRootOffsets = [0] //[0, 12, -12, 24, -24].reversed()
        let compressingFactors = [2, 0]  //[4,3,2,1,0] {
        
        var bestResult:Result? = nil
        var bestTapEventSet:TapEventSet? = nil
        
        ///Find the best fit scale
        for tapEventSet in self.recordedTapEventSets {
            let recordedTapEvents = tapEventSet.events
            for rootOffsetMidi in scaleRootOffsets {
                for compressingFactor in compressingFactors {
                    let offsetScale = scale.makeNewScale(offset: rootOffsetMidi)
                    let keyboard = PianoKeyboardModel()
                    keyboard.configureKeyboardForScale(scale: offsetScale)
                    let filterStarts = compressingFactor == 0
                    let (result, eventSet) = applyEvents(ctx: "TryOffset",
                                                         bufferSize: tapEventSet.bufferSize,
                                                         recordedTapEvents: tapEventSet.events,
                                                         offset: rootOffsetMidi,
                                                         scale: offsetScale, 
                                                         keyboard: keyboard,
                                                         compressingFactor: compressingFactor,
                                                         octaveLenient: false,
                                                         score: nil,
                                                         updateKeyboard: false)

                    if bestResult == nil || bestResult!.isBetter(compare: result) {
                        bestResult = result
                        bestTapEventSet = tapEventSet
                    }
                    Logger.shared.log(self, "===> Assessed events. ResultingEvents:\(eventSet.events.count) BufferSize:\(tapEventSet.bufferSize) Offset:\(rootOffsetMidi) Errors:\(result.getInfo())")
                }
            }
        }
        return (bestResult, bestTapEventSet)
    }
    
    func applyEvents(ctx:String,
                     bufferSize:Int,
                     recordedTapEvents:[TapEvent],
                     offset:Int, scale:Scale, keyboard:PianoKeyboardModel,
                     compressingFactor:Int,
                     octaveLenient:Bool,
                     score:Score?,
                     updateKeyboard:Bool
                     ) -> (Result, TapStatusRecordSet) {
        ///Apply the tapped events to a given scale start
        resetState(scale: scale, octaveLenient: false)
        let tapStatusRecordSet = TapStatusRecordSet(description: "bufferSize:\(bufferSize) ampFilter:\(self.amplitudeFilter) offset:\(offset) compress:\(compressingFactor)", events: [])
        let tapEvents:[TapEvent]
        if compressingFactor > 0 {
            tapEvents = compressEvents(events: recordedTapEvents, requiredConsecutiveCount: compressingFactor, bufferSize: bufferSize)
        }
        else {
            tapEvents = recordedTapEvents
        }
        for event in tapEvents {
            let processedtapEvent = processTap(ctx: ctx, scale: scale, 
                                               keyboard: keyboard,
                                               eventToProcess: event,
                                               discardSingletons: compressingFactor == 0,
                                               filterStart: true, 
                                               //octaveLenient: octaveLenient,
                                               updateKeyboardDisplay: updateKeyboard)
            tapStatusRecordSet.events.append(processedtapEvent)
        }
        let result = Result(scale: scale, keyboard: keyboard, fromProcess: self.fromProcess, amplitudeFilter: self.amplitudeFilter, bufferSize: bufferSize,
                            compressingFactor: compressingFactor, userMessage: "")
        result.buildResult(offset: offset, score: score)
        return (result, tapStatusRecordSet)
    }
    
    ///Build an event record that describes how this tap was handled. The record has various states to describe the handling.
    ///The event shows how the decision to mark each keyboard key as played was made.
    ///For a tap that is considered an actual note played update the keyboard key with the current datetime.
    ///The keyboard keys timestamp is the state that determines the final result of the scale recording as it is applied to the scale.
    ///The events become part of the viewable log of the scale recording.
    ///Filter out spurios tap event frequencies.
    func processTap(ctx:String, scale:Scale, 
                    keyboard:PianoKeyboardModel,
                    eventToProcess:TapEvent,
                    discardSingletons:Bool, filterStart:Bool,
                    //octaveLenient:Bool,
                    updateKeyboardDisplay:Bool) -> TapStatusRecord {
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
                    let event = TapStatusRecord(
                                        tapNum: eventNumber,
                                         frequency: eventToProcess.frequency,
                                         amplitude: eventToProcess.amplitude,
                                         ascending: self.ascending,
                                         status: .beforeScaleStart,
                                         expectedMidis: [],
                                         midi: nil,
                                         tapMidi: eventToProcess.tapMidi,
                                         consecutiveCount: 0)
                    return event
                }
            }
        }
        
        //After scale end
        if self.atEnd {
            let event = TapStatusRecord(tapNum: eventNumber,
                                 frequency: eventToProcess.frequency,
                                 amplitude: eventToProcess.amplitude,
                                 ascending: self.ascending,
                                 status: .afterScaleEnd,
                                 expectedMidis: [],
                                 midi: nil,
                                 tapMidi: eventToProcess.tapMidi,
                                 consecutiveCount: 0)
            return event
        }
        
        guard eventToProcess.amplitude > AUValue(self.amplitudeFilter) else {
            let event = TapStatusRecord(tapNum: eventNumber,
                                 frequency: eventToProcess.frequency,
                                 amplitude: eventToProcess.amplitude,
                                 ascending: self.ascending,
                                 status: .belowAmplitudeFilter,
                                 expectedMidis: [],
                                 midi: nil,
                                 tapMidi: eventToProcess.tapMidi,
                                 consecutiveCount: 0)
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
                    let event = TapStatusRecord(tapNum: eventNumber,
                                         frequency: eventToProcess.frequency,
                                         amplitude: eventToProcess.amplitude,
                                         ascending: self.ascending,
                                         status: .waitForMore,
                                         expectedMidis: [],
                                         midi: nil,
                                         tapMidi: eventToProcess.tapMidi,
                                         consecutiveCount: eventToProcess.consecutiveCount)
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

        for possibleMidi in tappedMidiPossibles {
            let diff = abs(possibleMidi - expectedMidiByLastKeyPlayed)
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

        if eventToProcess.tapMidi == scale.getMinMax().0  && midi == scale.getMinMax().0 {

            ///End of scale if the midi is the root and the root has already been played
            if let index = keyboard.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
                let keyboardKey = keyboard.pianoKeyModel[index]
                if keyboardKey.keyWasPlayedState.tappedTimeDescending != nil {
                    self.atEnd = true
                    let event = TapStatusRecord(tapNum: eventNumber,
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
            let event = TapStatusRecord(tapNum: eventNumber,
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
               keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: true)
            }
        }
        
        let event = TapStatusRecord(tapNum: eventNumber,
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
    func compressEvents(events:[TapEvent], requiredConsecutiveCount:Int, bufferSize:Int) -> [TapEvent] {
        var filtered:[TapEvent] = []
        var lastEvent:TapEvent?
        var maxCount:Int = 0
        
        for event in events {
            guard let last = lastEvent else {
                lastEvent = TapEvent(tapNum: 0, consecutiveCount: 1, frequency: event.frequency, amplitude: event.amplitude)
                continue
            }
            if event.tapMidi == last.tapMidi {
                last.consecutiveCount += 1
                continue
            }
            if last.consecutiveCount >= requiredConsecutiveCount {
                if last.consecutiveCount > maxCount {
                    maxCount = last.consecutiveCount
                }
                filtered.append(last)
            }
            lastEvent = TapEvent(tapNum: filtered.count, consecutiveCount: 1, frequency: event.frequency, amplitude: event.amplitude)
        }
        if let lastEvent = lastEvent {
            filtered.append(lastEvent)
        }
        Logger.shared.log(self, "EventsReduce. buffer:\(bufferSize) eventsIn:\(events.count) eventsOut:\(filtered.count) maxCount:\(maxCount)")
        return filtered
    }

}
