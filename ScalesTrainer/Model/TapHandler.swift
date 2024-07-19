import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit

///The key parameter that determines the frequency at which the closure (handler) is called is the bufferSize.
///The bufferSize parameter specifies the number of audio samples that will be processed in each iteration before calling the closure with the detected pitch and amplitude values.
///By default, the bufferSize is set to 4096 samples. Assuming a typical sample rate of 44,100 Hz, this means that the closure will be called approximately 10.7 times per second (44,100 / 4096).
///To increase the frequency at which the closure is called, you can decrease the bufferSize value when initializing the PitchTap instance. For example:

protocol TapHandlerProtocol {
    init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool, filterStartOfTapping:Bool)
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stopTapping(_ ctx:String) -> TapEventSet
}

class PracticeTapHandler : TapHandlerProtocol {
    let amplitudeFilter:Double
    let startTime:Date = Date()
    let fromProcess:RunningProcess
    let minMidi:Int
    let maxMidi:Int
    var tapNum = 0
    var hilightPlayingNotes:Bool
    var lastMidi:Int? = nil
    var lastMidiHiliteTime:Double? = nil
    let logTaps:Bool
    var tapHandlerEventSet:TapEventSet
    
    required init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool, filterStartOfTapping:Bool) {
        self.amplitudeFilter = amplitudeFilter
        minMidi = ScalesModel.shared.scale.getMinMax().0
        maxMidi = ScalesModel.shared.scale.getMinMax().1
        tapNum = 0
        self.hilightPlayingNotes = hilightPlayingNotes
        self.logTaps = logTaps
        self.fromProcess = fromProcess
        self.tapHandlerEventSet = TapEventSet(amplitudeFilter: amplitudeFilter, description: "PracticeTapHandler")
        Logger.shared.log(self, "PracticeTapHandler amplFilter:\(self.amplitudeFilter)")
    }

    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        let keyboardModel = PianoKeyboardModel.shared
        let scalesModel = ScalesModel.shared

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
        
        let aboveFilter =  amplitude > AUValue(self.amplitudeFilter)
        let midi = Util.frequencyToMIDI(frequency: frequency)
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0

        if aboveFilter {
            if let index = keyboardModel.getKeyIndexForMidi(midi: midi, direction: scalesModel.selectedDirection) {
                let keyboardKey = keyboardModel.pianoKeyModel[index]
                let hilightKey = true
                ///Dont hilite same note just echoing ...
//                if let lastMidi = lastMidi {
//                    if keyboardKey.midi != lastMidi {
//                        hilightKey = true
//                    }
//                    else {
//                        if let lastMidiHiliteTime = lastMidiHiliteTime {
//                            let diff = secs - lastMidiHiliteTime
//                            if diff > 1.2 {
//                                hilightKey = true
//                            }
//                        }
//                    }
//                }
//                else {
//                    hilightKey = true
//                }
                if hilightKey {
                    keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: self.hilightPlayingNotes)
                    lastMidiHiliteTime = secs
                }
                lastMidi = keyboardKey.midi
            }
        }
        tapHandlerEventSet.events.append(TapEvent(tapNum: tapNum,
                                                 frequency: frequency,
                                                 amplitude: amplitude,
                                                 ascending: true,
                                                 status: TapEventStatus.none,
                                                 expectedScaleNoteStates: nil,
                                                 midi: 0, tapMidi: midi))
//        if false {
//            if tapNum % 20 == 0 || !aboveFilter {
//                var msg = ""
//                msg += "secs:\(String(format: "%.2f", secs))"
//                msg += " ampFilter:\(String(format: "%.4f", self.amplitudeFilter))"
//                msg += " amp:\(String(format: "%.4f", amplitude))"
//                msg += " >amplFilter:\(aboveFilter)"
//                msg += "  \t\tfreq:\(String(format: "%.0f", frequency))"
//                msg += "  MIDI \(String(describing: midi))"
//                Logger.shared.log(self, msg)
//            }
//        }
        tapNum += 1
    }
    
    func stopTapping(_ ctx:String) -> TapEventSet {
        Logger.shared.log(self, "Practice tap handler recorded \(String(describing: tapHandlerEventSet.events.count)) tap events")
        return tapHandlerEventSet
    }
}

class ScaleTapHandlerOld : TapHandlerProtocol  {
    let amplitudeFilter:Double
    var startTime:Date = Date()
    let scale:Scale
    let fromProcess:RunningProcess
    var wrongNoteFound = false
    var tapNumber = 0

    //var lastAmplitude:Float?
    var lastKeyPressedMidi:Int?
    var tapRecords:[String] = []
    var unmatchedCount:Int? = nil
    var maxScaleMidi = 0
    var minScaleMidi = 0
    var matchCount = 0
    var hilightPlayingNotes:Bool
    let logTaps:Bool
    var result:Result?
    var octaveOffsets:[Int] = []
    var scaleStartAmplitudes:[Float] = []
    var scalePotentialStartAmplitudes:[Float] = []
    var tapHandlerEventSet:TapEventSet
    
    required init(fromProcess:RunningProcess, amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool, filterStartOfTapping:Bool) {
        self.scale = ScalesModel.shared.scale
        self.amplitudeFilter = amplitudeFilter
        tapHandlerEventSet = TapEventSet(amplitudeFilter: amplitudeFilter, description: "")
        (minScaleMidi, maxScaleMidi) = scale.getMinMax()
        ScalesModel.shared.recordedTapsFileURL = nil
        ScalesModel.shared.recordedTapsFileName = nil
        self.hilightPlayingNotes = hilightPlayingNotes
        self.logTaps = logTaps
        self.result = nil
        ///Keep offsets relativly contrained until the first match to avoid premature matches at the recording start
        ///self.octaveOffsets = [0, 12, -12, 24, -24, 36, -36]
        self.octaveOffsets = [0, 12, -12]
        let info = "Starting, amplFilter:\(String(format: "%.4f", amplitudeFilter))"
        tapHandlerEventSet.events.append(TapEvent(infoMsg: info))
        self.fromProcess = fromProcess
        Logger.shared.log(self, "ScaleTapHandler starting. AmplFilter:\(String(format:"%.4f", self.amplitudeFilter)) logging?:\(self.logTaps)")
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        if Settings.shared.recordDataMode {
            if ScalesModel.shared.runningProcess == .recordingScale {
                let timeInterval = Date().timeIntervalSince1970
                let tapData = "time:\(timeInterval)\tfreq:\(frequencies[0])\tampl:\(amplitudes[0])\n"
                tapRecords.append(tapData)
            }
        }
        processTapData(frequencies, amplitudes)
    }
        
    func processTapData(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
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
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        
        if false {
            if self.logTaps {
                if tapNumber % 10 == 0 {
                    var logMsg = ""
                    logMsg += "secs:\(String(format: "%.2f", secs))"
                    logMsg += " amp:\(String(format: "%.4f", amplitude))"
                    logMsg += "  freq:\(String(format: "%.0f", frequency))"
                    logMsg += "  MIDI \(String(describing: tapMidi))"
                    Logger.shared.log(self, logMsg)
                }
            }
        }
        tapNumber += 1
        
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
            //let secs = Double(ms) / 1000.0

            if diff < 2.0 {
                tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                             frequency: frequency,
                                                                             amplitude: amplitude,
                                                                             ascending: false,
                                                                             status: .beforeScaleStart,
                                                                             expectedScaleNoteStates: nil,
                                                                             midi: tapMidi, tapMidi: tapMidi))
                return
            }
            ///The student can play the scale at whichever octave they choose. Adjust the scale accordinlgy.
//            if scale.scaleNoteState.count > 0 {
//                let scaleStartMidi = scale.scaleNoteState[0].midi
//                let startDiff = tapMidi - scaleStartMidi
//                print("========= >>>", tapMidi, startDiff, scaleWasAdjusted)
//
//                ///Only adjust the scale for a potential correct scale start
//                if scaleWasAdjusted == false {
//                    if startDiff % 12 == 0 {
//                        if startDiff != 0 {
//                            scale.incrementNotes(offset: startDiff)
//                            scaleWasAdjusted = true
//                        }
//                    }
//                }
//            }
        }
        
        guard amplitude > AUValue(self.amplitudeFilter) else {
            tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: false,
                                                                          status: .belowAmplitudeFilter,
                                                                         expectedScaleNoteStates: nil,
                                                                         midi: tapMidi, tapMidi: tapMidi))
            return
        }
        
        let keyboardModel = PianoKeyboardModel.shared
        //let nextExpectedNotes = scale.getNextExpectedNotes(count: 2)
        let nextExpectedNotes = scale.getNextExpectedNotes(count: 1)
        guard nextExpectedNotes.count > 0 else {
            ///All scales notes are already matched
            tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: false,
                                                                         status: .pastEndOfScale,
                                                                         expectedScaleNoteStates: nextExpectedNotes,
                                                                         midi: tapMidi, tapMidi: tapMidi))
            return
        }
        
        var midi = tapMidi
        
        ///Adjust to the pitch in the expected octave. e.g. A middle C = 60 might arrive as 72 or 48. 72 matches the scale and causes a note played at key 72
        ///So treat the 72 as middle C = 60 so its not treated as the top of the scale (and then that everything that follows is descending)
        ///octaveOffsets = [0, 12, -12, 24, -24, 36, -36]
        var minDist = 1000000
        var minIndex = 0
        //reduce spread size before scale starts, or at lower pitches? its missing the last note at 0.02, play with filters more on this 3 octave C
        for i in 0..<self.octaveOffsets.count {
            let dist = abs((tapMidi  + self.octaveOffsets[i]) - nextExpectedNotes[0].midi)
            if dist < minDist {
                minDist = dist
                minIndex = i
            }
        }
        midi = tapMidi + self.octaveOffsets[minIndex]
        let ascending = nextExpectedNotes[0].sequence <= scale.scaleNoteState.count / 2
        
        let atTop = nextExpectedNotes[0].sequence == scale.scaleNoteState.count / 2 && midi == nextExpectedNotes[0].midi
        
        ///Does the notification represents a key that could be pressed on the keyboard?
        guard let keyboardIndex = keyboardModel.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) else {
            tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: ascending,
                                                                         status: .keyNotOnKeyboard,
                                                                         expectedScaleNoteStates: nextExpectedNotes,
                                                                         midi: midi, tapMidi: tapMidi))
            return
        }
        
        ///Same as last note?
        if let lastKeyPressedMidi = lastKeyPressedMidi {
            if unmatchedCount == nil {
                guard midi != lastKeyPressedMidi else {
                    tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                                  frequency: frequency,
                                                                                  amplitude: amplitude,
                                                                                  ascending: ascending,
                                                                                  status: .continued,
                                                                                  expectedScaleNoteStates: nextExpectedNotes,
                                                                                  midi: midi, tapMidi: tapMidi))
                    return
                }
            }
        }
        
        ///Within the scale highest and lowest?
        guard midi >= minScaleMidi && midi <= maxScaleMidi else {
            tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: ascending,
                                                                         status: .outsideScale,
                                                                         expectedScaleNoteStates: nextExpectedNotes,
                                                                         midi: midi, tapMidi: tapMidi))
            return
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
                            self.octaveOffsets = [0, 12, -12, 24, -24, 36, -36]
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
            
            ///Update key tapped state on the keyboard
            let keyboardKey = keyboardModel.pianoKeyModel[keyboardIndex]
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
            
            lastKeyPressedMidi = keyboardKey.midi
            if atTop {
                DispatchQueue.main.async {
                    //ScalesModel.shared.setDirection(1)
                    //keyboardModel.redraw()
                }
            }
        }
        
        let keyboardKey = keyboardModel.pianoKeyModel[keyboardIndex]
        tapHandlerEventSet.events.append(TapEvent(tapNum: tapNumber,
                                                                     frequency: frequency,
                                                                     amplitude: amplitude,
                                                                     ascending: ascending,
                                                                     status: tapEventStatus,
                                                                 expectedScaleNoteStates: nextExpectedNotes,
                                                                 midi: midi, tapMidi: tapMidi))

        ///Stop the recording if at end of scale.
        if tapEventStatus == .pressNextScaleMatch {
            if matchCount > scale.scaleNoteState.count / 2 {
                if midi == scale.scaleNoteState[0].midi {
                    ScalesModel.shared.setRunningProcess(.none)
                }
            }
        }
    }
    
    func stopTapping(_ ctx:String) -> TapEventSet {
        Logger.shared.log(self, "ScaleTapHandler stop. ctx: \(ctx)")
        if self.result != nil {
            return self.tapHandlerEventSet
        }
        Logger.shared.calcValueLimits()

        self.result = Result(scale: self.scale, fromProcess: self.fromProcess, amplitudeFilter: self.amplitudeFilter, userMessage: "")
        self.result!.buildResult(score: ScalesModel.shared.score)
        
//        if ScalesModel.shared.runningProcess == .recordingScale {
//            if result.correctNotes == 0 {
//                ///Discard a quick throwaway attempt
//                return
//            }
//        }

        ScalesModel.shared.setResultInternal(result, "TapHandlerAtEnd")
//        guard let result = self.result else {
//            return self.tapHandlerEventSet
//        }

        return self.tapHandlerEventSet
    }
}

///Handle a raw FFT
//class FFTTapHandler : TapHandlerProtocol  {
//    //let scaleMatcher:ScaleMatcher?
//    var wrongNoteFound = false
//    var canStartAnalysis = false
//    var requiredStartAmplitude:Double
//    var firstTap = true
//    
//    required init(hilightPlayingNotes: Bool, logTaps: Bool) {
//        self.requiredStartAmplitude = self.amplitudeFilter
//    }
//    
//    func stopTapping(_ ctx: String) {
//        
//    }
//    
//    func frequencyForBin(forBinIndex binIndex: Int, sampleRate: Double = 44100.0, fftSize: Int = 1024) -> Double {
//        return Double(binIndex) * sampleRate / Double(fftSize)
//    }
//    
//    func frequencyToMIDINote(frequency: Double) -> Int {
//        let midiNote = 69 + 12 * log2(frequency / 440)
//        return Int(round(midiNote))
//    }
//    
//    func tapUpdate(_ frequency: [AudioKit.AUValue], _ amplitude: [AudioKit.AUValue]) {
//        let n = 3
//        let fftSize = 1024 //frequencyAmplitudes.count //1024
//        let sampleRate: Double = 44100  // 44.1 kHz
//        
//        let maxAmplitudes = frequencyAmplitudes.enumerated()
//            .sorted { $0.element > $1.element }
//            .prefix(n)
////        for i in 0..<maxAmplitudes.count {
////            maxAmplitudes[i].element *= 1
////        }
//        let indicesOfMaxAmplitudes = maxAmplitudes
//            .map { $0.offset }
//        let magic = 13.991667622214578 //56.545038167938931 //somehow makes the frequencies right?
//        // Calculate the corresponding frequencies
//        let frequencies = indicesOfMaxAmplitudes.map { index in
//            Double(index) * sampleRate / (Double(fftSize) * magic)
//        }
//
//        //if scaleMatcher != nil {
//            if firstTap {
//                guard maxAmplitudes[0].element > AUValue(self.requiredStartAmplitude) else { return }
//            }
//        //}
//        firstTap = false
//        
//        var logMsg = ""
//        let ms = 0 //Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
//        let secs = Double(ms) / 1000.0
//        logMsg += "secs:\(String(format: "%.2f", secs))"
//        logMsg += "  ind:  "
//        for idx in indicesOfMaxAmplitudes {
//            logMsg += " " + String(idx)
//        }
//        //var log = ""
//        logMsg += "    ampl: "
//        for a in maxAmplitudes  {
//            logMsg += "  " + String(format: "%.2f", a.element * 1000)
//        }
//        
////
////        log += " ampl:"
////        for ampl in maxAmplitudes {
////            log += String(format: "%.2f", ampl.element * 1000)+","
////        }
//        logMsg += "    freq:"
//        for freq in frequencies {
//            logMsg += String(format: "%.2f", freq)+","
//        }
//        logMsg += "    mid:"
//        var midisToTest:[Int] = []
//        for freq in frequencies {
//            let midi = Util.frequencyToMIDI(frequency: Float(freq)) + 10
//            logMsg += String(midi)+","
//            midisToTest.append(midi)
//        }
//
//        if maxAmplitudes[0].element > 4.0 / 1000.0 {
//            print("", String(format: "%.2f", secs), "\t", amps, "\t", ind)
//            //log(logMsg, Double(maxAmplitudes[0].element))
//        }
//        
//        logMsg += " midis:\(midisToTest) "
//        if midisToTest.count == 0 {
//            logMsg += " NONE"
//        }
//        else {
////            if let scaleMatcher = scaleMatcher {
////                let matchedStatus = scaleMatcher.match(timestamp: Date(), midis: midisToTest, ampl: frequencyAmplitudes)
////                logMsg += "\t\(matchedStatus.dispStatus())"
////                if let message = matchedStatus.msg {
////                    logMsg += "  " + message //"\t \(message)"
////                }
////                if matchedStatus.status == .wrongNote {
////                    wrongNoteFound = true
////                }
////            }
//        }
//
//        //Logger.shared.log(self, log, Double(maxAmplitudes[0].element))
//    }
//    
//
//}
//    
