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
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stopTapping()
}

//class TapHandler : TapHanderProtocol {
//    var startTime:Date
//    
//    init() {
//        startTime = Date()
//    }
//    
//    func tapUpdate(_ frequency: [AudioKit.AUValue], _ amplitude: [AudioKit.AUValue]) {
//    }
//    
//    func tapUpdate(_ frequencys: [Float]) {
//    }
//
//    func showConfig() {
//    }
//    
//    func stopTapping(){
//    }
//    
//    func log(_ m:String, _ value:Double? = nil) {
//        //if false {
//            Logger.shared.log(self, m, value)
//        //}
//    }
//}

public enum CallibrationType {
    case startAmplitude
    case amplitudeFilter
    case none
}

class CallibrationTapHandler : TapHandlerProtocol {
    let type:CallibrationType
    private var amplitudes:[Float] = []
    let startTime:Date = Date()
    
    init(type:CallibrationType) {
        self.type = type
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudesIn: [AudioKit.AUValue]) {
        //let n = 3
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        var msg = ""
        msg += "secs:\(String(format: "%.2f", secs))"
        msg += " \tAmpl:"+String(format: "%.4f", amplitudesIn[0])
        amplitudes.append(amplitudesIn[0])
        let frequency:Float = frequencies[0]
        let midi = Util.frequencyToMIDI(frequency: frequency)
        msg += " \tMidi:"+String(midi)

        Logger.shared.log(self, msg)
    }
    
    func stopTapping() {
        ScalesModel.shared.doCallibration(type: type, amplitudes: amplitudes)
        Logger.shared.log(self, "ended callibration")
        Logger.shared.calcValueLimits()
    }
}

class PracticeTapHandler : TapHandlerProtocol {
    let startTime:Date = Date()

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
        let midi = Util.frequencyToMIDI(frequency: frequency)
        
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        var msg = ""
        msg += "secs:\(String(format: "%.2f", secs))"
        msg += " amp:\(String(format: "%.4f", amplitude))"
        msg += "  fr:\(String(format: "%.0f", frequency))"
        msg += "  MIDI \(String(describing: midi))"
        let keyboardModel = PianoKeyboardModel.shared
        let scalesModel = ScalesModel.shared

        if let index = keyboardModel.getKeyIndexForMidi(midi: midi, direction: scalesModel.selectedDirection) {
            let keyboardKey = keyboardModel.pianoKeyModel[index]
            keyboardKey.setPlayingMidi()
            keyboardKey.setPlayingKey()
//            if let score = scalesModel.score {
//                score.setScoreNotePlayed(midi: keyboardKey.midi, direction: scalesModel.selectedDirection, clear: false)
//            }
        }
        Logger.shared.log(self, msg)
    }
    
    func stopTapping() {
    }
}

class PitchTapHandler : TapHandlerProtocol  {
    var startTime:Date = Date()
    let scale:Scale
    var wrongNoteFound = false
    var tapNumber = 0
    var requiredStartAmplitude:Double
    let saveTappingToFile:Bool
    var fileURL:URL?
    var lastAmplitude:Float?
    
    init(requiredStartAmplitude:Double, saveTappingToFile:Bool, scale:Scale) {
        self.scale = scale
        self.saveTappingToFile = saveTappingToFile
        self.requiredStartAmplitude = requiredStartAmplitude
        ScalesModel.shared.recordedEvents = TapEvents()

        if saveTappingToFile {
            //if let scale = scale {
                let calendar = Calendar.current
                let month = calendar.component(.month, from: Date())
                let day = calendar.component(.day, from: Date())
                let device = UIDevice.current
                let modelName = device.model
                var keyName = scale.key.name + "_" 
                keyName += String(Scale.getTypeName(type: scale.scaleType))
                keyName = keyName.replacingOccurrences(of: " ", with: "")
                var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"
                fileName += keyName + "_"+String(scale.octaves) + "_" + String(scale.scaleNoteState[0].midi) + "_" + modelName
                fileName += "_"+String(AudioManager.shared.recordedFileSequenceNum)
                fileName += ".txt"
                AudioManager.shared.recordedFileSequenceNum += 1
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                // Create the file URL by appending the file name to the directory
                fileURL = documentDirectoryURL.appendingPathComponent(fileName)
                do {
                    if let fileURL = fileURL {
                        let config = "config:\t\(ScalesModel.shared.amplitudeFilter)\t\(ScalesModel.shared.requiredStartAmplitude ?? 0)\n"
                        try config.write(to: fileURL, atomically: true, encoding: .utf8)
                    }
                }
                catch {
                    Logger.shared.reportError(self, "Error creating file: \(error)")
                }
            //}
        }
    }
    
    func showConfig() {
        let s = String(format: "%.2f", requiredStartAmplitude)
        let m = "PitchTapHandler required_start_amplitude:\(s)"
        Logger.shared.log(self, m)
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        if saveTappingToFile {
            recordTapDataToFile(frequencies, amplitudes)
        }
        else {
            processTapData(frequencies, amplitudes)
        }
    }
    
    func recordTapDataToFile(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        let timeInterval = Date().timeIntervalSince1970
        let tapData = "time:\(timeInterval)\tfreq:\(frequencies[0])\tampl:\(amplitudes[0])\n"
        if let fileURL = fileURL {
            do {
                let data = tapData.data(using: .utf8)!
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()        // Move to the end of the file
                fileHandle.write(data)              // Append the data
                fileHandle.closeFile()              // Close the file
                print("========== data written", fileURL)
            } catch {
                print("Error writing to file: \(error)")
            }
        }
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
        if tapNumber == 0 {
            guard amplitude > AUValue(self.requiredStartAmplitude) else { return }
        }
        
        let tapMidi = Util.frequencyToMIDI(frequency: frequency)
        
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        var msg = ""
        msg += "secs:\(String(format: "%.2f", secs))"
        msg += " amp:\(String(format: "%.4f", amplitude))"
        msg += "  fr:\(String(format: "%.0f", frequency))"
        msg += "  MIDI \(String(describing: tapMidi))"
        
        var amplDiff:Float = 0.0
        if let lastAmplitude:Float = lastAmplitude {
            if lastAmplitude > 0 {
                amplDiff = 100 * (amplitude - lastAmplitude) / lastAmplitude
            }
        }
        let keyboardModel = PianoKeyboardModel.shared
        var pressedKey = false
        
        var midi = tapMidi
        
        ///Adjust to expected octave. e.g. A middle C = 60 might arrive as 72. 72 matches the scale and causes a note played at key 72
        ///So treat the 72 as middle C = 60 so its not treated as the top of the scale (and then that everything that follows is descending)
        //let offsets = [0, 12, -12, 24, -24]
        let offsets = [0, 12, -12]
        var minDist = 1000000
        var minIndex = 0
        let nextExpectedNote = scale.getNextExpectedNote()
        
        if let nextExpectedNote = nextExpectedNote {
            for i in 0..<offsets.count {
                let dist = abs((tapMidi  + offsets[i]) - nextExpectedNote.midi)
                if dist < minDist {
                    minDist = dist
                    minIndex = i
                }
            }
            midi = tapMidi + offsets[minIndex]
        }
        
        let ascending = nextExpectedNote == nil || nextExpectedNote!.sequence <= scale.scaleNoteState.count / 2
        let atTop = nextExpectedNote != nil && nextExpectedNote!.sequence == scale.scaleNoteState.count / 2 && midi == nextExpectedNote!.midi

        if let index = keyboardModel.getKeyIndexForMidi(midi: midi, direction: ascending ? 0 : 1) {
            let keyboardKey = keyboardModel.pianoKeyModel[index]
            
            if ascending || atTop {
                if keyboardKey.keyMatchedState.matchedTimeAscending == nil {
                    keyboardKey.keyMatchedState.matchedTimeAscending = Date()
                    keyboardKey.keyMatchedState.matchedAmplitudeAscending = Double(amplitude)
                    pressedKey = true
                    if let nextExpectedNote = nextExpectedNote {
                        nextExpectedNote.matchedTime = Date()
                        nextExpectedNote.matchedAmplitude = Double(amplitude)
                    }
                }
            }
            if !ascending || atTop  {
                if keyboardKey.keyMatchedState.matchedTimeDescending == nil {
                    keyboardKey.keyMatchedState.matchedTimeDescending = Date()
                    keyboardKey.keyMatchedState.matchedAmplitudeDescending = Double(amplitude)
                    pressedKey = true
                    if let nextExpectedNote = nextExpectedNote {
                        nextExpectedNote.matchedTime = Date()
                        nextExpectedNote.matchedAmplitude = Double(amplitude)
                    }
                }
            }

            keyboardKey.setPlayingMidi()
            ScalesModel.shared.recordedEvents?.event.append(TapEvent(tapNum: tapNumber, onKeyboard: true,
                                                                     scaleSequence: nextExpectedNote?.sequence,
                                                                     midi: midi, tapMidi: tapMidi, amplitude: amplitude,
                                                                     pressedKey:pressedKey, amplDiff: Double(amplDiff), ascending: ascending, key: keyboardKey))
        }
        else {
            ScalesModel.shared.recordedEvents?.event.append(TapEvent(tapNum: tapNumber, onKeyboard: false,
                                                                     scaleSequence: nil,
                                                                     midi: midi, tapMidi: tapMidi, amplitude: amplitude,
                                                                     pressedKey:false, amplDiff: Double(amplDiff), ascending: ascending, key: nil))
        }
        //print("\n============== tapped", tapMidi, "midi", midi, "expected:", nextExpectedNote?.midi ?? "None", "asc", ascending, "top", atTop)
        //scale.debug1("herex")
        //keyboardModel.debug1("herex")

        Logger.shared.log(self,msg)
        tapNumber += 1
        lastAmplitude = amplitude
    }
    
    func stopTapping() {
        Logger.shared.log(self, "PitchTapHandler stop")
        Logger.shared.calcValueLimits()
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
    
