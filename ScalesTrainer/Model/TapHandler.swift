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
    init(amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool)
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stopTapping()
}

//public enum CallibrationType {
//    case startAmplitude
//    case amplitudeFilter
//    case none
//}

//class CallibrationTapHandler : TapHandlerProtocol {
//    let type:CallibrationType
//    private var amplitudes:[Float] = []
//    let startTime:Date = Date()
//    
//    init(type:CallibrationType) {
//        self.type = type
//    }
//    
//    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudesIn: [AudioKit.AUValue]) {
//        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
//        let secs = Double(ms) / 1000.0
//        var msg = ""
//        msg += "secs:\(String(format: "%.2f", secs))"
//        msg += " \tAmpl:"+String(format: "%.4f", amplitudesIn[0])
//        amplitudes.append(amplitudesIn[0])
//        let frequency:Float = frequencies[0]
//        let midi = Util.frequencyToMIDI(frequency: frequency)
//        msg += " \tMidi:"+String(midi)
//        Logger.shared.log(self, msg)
//    }
//    
//    func stopTapping() {
//        ScalesModel.shared.doCallibration(type: type, amplitudes: amplitudes)
//        Logger.shared.log(self, "ended callibration")
//        Logger.shared.calcValueLimits()
//    }
//}

class PracticeTapHandler : TapHandlerProtocol {
    let amplitudeFilter:Double
    let startTime:Date = Date()
    let minMidi:Int
    let maxMidi:Int
    var tapNum = 0
    var hilightPlayingNotes:Bool
    var lastMidi:Int? = nil
    var lastMidiHiliteTime:Double? = nil
    let logTaps:Bool
    
    required init(amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool) {
        self.amplitudeFilter = amplitudeFilter
        minMidi = ScalesModel.shared.scale.getMinMax().0
        maxMidi = ScalesModel.shared.scale.getMinMax().1
        tapNum = 0
        ScalesModel.shared.tapHandlerEventSet = TapEventSet()
        self.hilightPlayingNotes = hilightPlayingNotes
        self.logTaps = logTaps
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
        ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNum,
                                                                     frequency: frequency,
                                                                     amplitude: amplitude,
                                                                     ascending: true,
                                                                     status: TapEventStatus.none,
                                                                     expectedScaleNoteState: nil,
                                                                     midi: 0, tapMidi: midi,
                                                                     amplDiff: 0,
                                                                     key: nil))
        if false {
            if tapNum % 20 == 0 || !aboveFilter {
                var msg = ""
                msg += "secs:\(String(format: "%.2f", secs))"
                msg += " ampFilter:\(String(format: "%.4f", self.amplitudeFilter))"
                msg += " amp:\(String(format: "%.4f", amplitude))"
                msg += " >amplFilter:\(aboveFilter)"
                msg += "  \t\tfreq:\(String(format: "%.0f", frequency))"
                msg += "  MIDI \(String(describing: midi))"
                Logger.shared.log(self, msg)
            }
        }
        tapNum += 1
    }
    
    func stopTapping() {
        Logger.shared.log(self, "Practice tap handler recorded \(String(describing: ScalesModel.shared.tapHandlerEventSet?.events.count)) tap events")
    }
}

class ScaleTapHandler : TapHandlerProtocol  {
    var startTime:Date = Date()
    let scale:Scale
    let amplitudeFilter:Double
    var wrongNoteFound = false
    var tapNumber = 0
    var savedTapsFileURL:URL?
    var lastAmplitude:Float?
    var lastKeyPressedMidi:Int?
    var tapRecords:[String] = []
    var unmatchedCount = 0
    var maxScaleMidi = 0
    var minScaleMidi = 0
    var matchCount = 0
    var hilightPlayingNotes:Bool
    let logTaps:Bool
    
    required init(amplitudeFilter:Double, hilightPlayingNotes:Bool, logTaps:Bool) {
        self.amplitudeFilter = amplitudeFilter
        self.scale = ScalesModel.shared.scale
        ScalesModel.shared.tapHandlerEventSet = TapEventSet()
        (minScaleMidi, maxScaleMidi) = scale.getMinMax()
        ScalesModel.shared.recordedTapsFileURL = nil
        self.hilightPlayingNotes = hilightPlayingNotes
        self.logTaps = logTaps
        Logger.shared.log(self, "ScaleTapHandler starting. AmplFilter:\(self.amplitudeFilter) logging?:\(self.logTaps)")
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
        guard amplitude > AUValue(amplitudeFilter) else { return }
        
        var amplDiff:Float = 0.0
        if let lastAmplitude:Float = lastAmplitude {
            if lastAmplitude > 0 {
                amplDiff = 100 * (amplitude - lastAmplitude) / lastAmplitude
            }
        }
        
        let keyboardModel = PianoKeyboardModel.shared
        let nextExpectedNotes = scale.getNextExpectedNotes(count: 2)
        guard nextExpectedNotes.count > 0 else {
            ///All scales notes are already matched
            ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNumber, 
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: false,
                                                                         status: .pastEndOfScale,
                                                                         expectedScaleNoteState: nil,
                                                                         midi: tapMidi, tapMidi: tapMidi,
                                                                         amplDiff: Double(amplDiff), key: nil))
            return
        }
        
        var midi = tapMidi
        
        ///Adjust to the pitch in the expected octave. e.g. A middle C = 60 might arrive as 72. 72 matches the scale and causes a note played at key 72
        ///So treat the 72 as middle C = 60 so its not treated as the top of the scale (and then that everything that follows is descending)
        //let offsets = [0, 12, -12, 24, -24]
        let offsets = [0, 12, -12]
        var minDist = 1000000
        var minIndex = 0
        
        for i in 0..<offsets.count {
            let dist = abs((tapMidi  + offsets[i]) - nextExpectedNotes[0].midi)
            if dist < minDist {
                minDist = dist
                minIndex = i
            }
        }
        midi = tapMidi + offsets[minIndex]
        let ascending = nextExpectedNotes[0].sequence <= scale.scaleNoteState.count / 2
        let atTop = nextExpectedNotes[0].sequence == scale.scaleNoteState.count / 2 && midi == nextExpectedNotes[0].midi
        
        ///Does the notification represents a key that could be pressed on the keyboard?
        guard let keyboardIndex = keyboardModel.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) else {
            ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNumber, 
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: ascending,
                                                                         status: .keyNotOnKeyboard,
                                                                         expectedScaleNoteState: nil,
                                                                         midi: midi, tapMidi: tapMidi,
                                                                         amplDiff: Double(amplDiff), key: nil))
            return
        }
        
        ///Same as last note?
        if let lastKeyPressedMidi = lastKeyPressedMidi {
            guard midi != lastKeyPressedMidi else {
                ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNumber,
                                                                             frequency: frequency,
                                                                             amplitude: amplitude,
                                                                             ascending: ascending,
                                                                             status: .continued,
                                                                             expectedScaleNoteState: nil,
                                                                             midi: midi, tapMidi: tapMidi,
                                                                             amplDiff: Double(amplDiff), key: nil))
                return
            }
        }
        
        ///Within the scale?
        guard midi >= minScaleMidi && midi <= maxScaleMidi else {
            ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNumber, 
                                                                         frequency: frequency,
                                                                         amplitude: amplitude,
                                                                         ascending: ascending,
                                                                         status: .outsideScale,
                                                                         expectedScaleNoteState: nil,
                                                                         midi: midi, tapMidi: tapMidi,
                                                                         amplDiff: Double(amplDiff), key: nil))
            return
        }

        let keyboardKey = keyboardModel.pianoKeyModel[keyboardIndex]

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
            for i in [0,1] {
                if i < nextExpectedNotes.count {
                    if nextExpectedNotes[i].midi == midi {
                        nextExpectedNotes[i].matchedTime = Date()
                        nextExpectedNotes[i].matchedAmplitude = Double(amplitude)
                        tapEventStatus = i == 0 ? .keyPressWithNextScaleMatch : .keyPressWithFollowingScaleMatch
                        unmatchedCount = 0
                        match = true
                        if i > 0 {
                            ///Set any previously expected note unmatched
                            nextExpectedNotes[0].unmatchedTime = Date()
                        }
                        matchCount += 1
                        break
                    }
                }
            }

            if !match {
                ///Only advance the expected next note when one note was missed.
                ///e.g. they play E instead of E♭ advance the expected next to F but dont advance it further
                if unmatchedCount == 0 {
                    nextExpectedNotes[0].unmatchedTime = Date()
                }
                unmatchedCount += 1
                tapEventStatus = .keyPressWithoutScaleMatch
            }
            
            ///Update key tapped state
            if ascending || atTop {
                keyboardKey.keyWasPlayedState.tappedTimeAscending = Date()
                keyboardKey.keyWasPlayedState.tappedAmplitudeAscending = Double(amplitude)
            }
            if !ascending || atTop  {
                keyboardKey.keyWasPlayedState.tappedTimeDescending = Date()
                keyboardKey.keyWasPlayedState.tappedAmplitudeDescending = Double(amplitude)
            }
            keyboardKey.setKeyPlaying(ascending: ascending ? 0 : 1, hilight: self.hilightPlayingNotes)
            
            lastKeyPressedMidi = keyboardKey.midi
            if atTop {
                DispatchQueue.main.async {
                    //ScalesModel.shared.setDirection(1)
                    //keyboardModel.redraw()
                }
            }
        }
        ScalesModel.shared.tapHandlerEventSet?.events.append(TapEvent(tapNum: tapNumber, 
                                                                     frequency: frequency,
                                                                     amplitude: amplitude,
                                                                     ascending: ascending,
                                                                     status: tapEventStatus,
                                                                 expectedScaleNoteState: nextExpectedNotes[0],
                                                                 midi: midi, tapMidi: tapMidi,
                                                                 amplDiff: Double(amplDiff),
                                                                 key: keyboardKey))

        ///Stop the recording if at end of scale.
        if tapEventStatus == .keyPressWithNextScaleMatch {
            if matchCount > scale.scaleNoteState.count / 2 {
                if midi == scale.scaleNoteState[0].midi {
                    ScalesModel.shared.setRunningProcess(.none)
                }
            }
        }
        lastAmplitude = amplitude
    }
    
    func stopTapping() {
        Logger.shared.log(self, "ScaleTapHandler stop")
        Logger.shared.calcValueLimits()
        
        let result = Result(runningProcess: .recordingScale, userMessage: "")
        result.buildResult()
//        if ScalesModel.shared.runningProcess == .recordingScale {
//            if result.correctNotes == 0 {
//                ///Discard a quick throwaway attempt
//                return
//            }
//        }
    
        ScalesModel.shared.setResult(result, "TapHandlerAtEnd")
        
        if ScalesModel.shared.runningProcess == .recordingScale && Settings.shared.recordDataMode && self.tapRecords.count > 0 {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: Date())
            let day = calendar.component(.day, from: Date())
            let hour = calendar.component(.hour, from: Date())
            let minute = calendar.component(.minute, from: Date())
            let device = UIDevice.current
            let modelName = device.model
            var keyName = self.scale.getScaleName()
            keyName = keyName.replacingOccurrences(of: " ", with: "")
            var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"+String(format: "%02d", hour)+"_"+String(format: "%02d", minute)
            fileName += "_"+keyName + "_"+String(self.scale.octaves) + "_" + String(self.scale.scaleNoteState[0].midi) + "_" + modelName
            fileName += "_"+String(result.wrongCountAsc)+","+String(result.wrongCountDesc)+","+String(result.missedCountAsc)+","+String(result.missedCountDesc)
            fileName += "_"+String(AudioManager.shared.recordedFileSequenceNum)
            
            fileName += ".txt"
            AudioManager.shared.recordedFileSequenceNum += 1
            let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.savedTapsFileURL = documentDirectoryURL.appendingPathComponent(fileName)
            do {
                if let fileURL = self.savedTapsFileURL {
                    var config = "config:\t\(ScalesModel.shared.amplitudeFilter)"
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
                    for record in self.tapRecords {
                        let data = record.data(using: .utf8)!
                        fileHandle.seekToEndOfFile()        // Move to the end of the file
                        fileHandle.write(data)              // Append the data
                    }
                    ScalesModel.shared.recordedTapsFileURL = fileURL
                    try fileHandle.close()
                    Logger.shared.log(self, "Wrote \(self.tapRecords.count) taps to \(fileURL)")
                } catch {
                    Logger.shared.reportError(self, "Error writing to file: \(error)")
                }
            }
        }
    }
}

///Handle a raw FFT
//class FFTTapHandler :: TapHanderProtocol  {
//    //let scaleMatcher:ScaleMatcher?
//    var wrongNoteFound = false
//    var canStartAnalysis = false
//    var requiredStartAmplitude:Double
//    var firstTap = true
//    
//    init(requiredStartAmplitude:Double) {
//        //self.scaleMatcher = scaleMatcher
//        self.requiredStartAmplitude = requiredStartAmplitude
//        super.init()
//        startTime = Date()
//    }
//
//    override func showConfig() {
//        let s = String(format: "%.2f", requiredStartAmplitude)
//        let m = "FFTTapHandler required_start_amplitude:\(s)"
//        log(m)
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
//    override func tapUpdate(_ frequencyAmplitudes: [Float]) {
////        if wrongNoteFound {
////            return
////        }
//        
//        let n = 3
//        let fftSize = frequencyAmplitudes.count //1024
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
//        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
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
//            //print("", String(format: "%.2f", secs), "\t", amps, "\t", ind)
//            log(logMsg, Double(maxAmplitudes[0].element))
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

//}
    
