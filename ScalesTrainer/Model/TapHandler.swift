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

protocol TapHanderProtocol {
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stop()
}

class TapHandler : TapHanderProtocol {
    var startTime:Date
    
    init() {
        startTime = Date()
    }
    
    func tapUpdate(_ frequency: [AudioKit.AUValue], _ amplitude: [AudioKit.AUValue]) {
    }
    
    func tapUpdate(_ frequencys: [Float]) {
    }

    func showConfig() {
    }
    
    func stop(){
    }
    
    func log(_ m:String, _ value:Double? = nil) {
        //if false {
            Logger.shared.log(self, m, value)
        //}
    }
}

public enum CallibrationType {
    case startAmplitude
    case amplitudeFilter
    case none
}

class CallibrationTapHandler : TapHandler {
    let type:CallibrationType
    private var amplitudes:[Float] = []
    
    init(type: CallibrationType) {
        self.type = type
    }
    
    override func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudesIn: [AudioKit.AUValue]) {
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

        log(msg, Double(amplitudesIn[0]))
    }
    
    override func stop() {
        if type != .none {
            ScalesModel.shared.doCallibration(type: type, amplitudes: amplitudes)
        }
        log("ended callibration, type:\(self.type)")
        Logger.shared.calcValueLimits()
    }
}

class PitchTapHandler : TapHandler {
    let scaleMatcher:ScaleMatcher?
    let scale:Scale?
    var wrongNoteFound = false
    var tapNumber = 0
    var requiredStartAmplitude:Double
    let recordData:Bool
    
    var ascending = true
    var matchNotInScale:[UnMatchedType]=[]
    var fileURL:URL?
    
    init(requiredStartAmplitude:Double, recordData:Bool, scaleMatcher:ScaleMatcher?, scale:Scale?) {
        self.scaleMatcher = scaleMatcher
        self.scale = scale
        self.recordData = recordData
        self.requiredStartAmplitude = requiredStartAmplitude

        super.init()
        if recordData {
            if let scale = scale {
                let calendar = Calendar.current
                let month = calendar.component(.month, from: Date())
                let day = calendar.component(.day, from: Date())
                let device = UIDevice.current
                let modelName = device.model
                var keyName = scale.key.name + "_" 
                keyName += String(Scale.getTypeName(type: scale.scaleType))
                keyName = keyName.replacingOccurrences(of: " ", with: "")
                var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"
                fileName += keyName + "_"+String(scale.octaves) + "_" + String(scale.scaleNoteStates[0].midi) + "_" + modelName + ".txt"
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
            }
        }
    }
    
    override func showConfig() {
        let s = String(format: "%.2f", requiredStartAmplitude)
        let m = "PitchTapHandler required_start_amplitude:\(s)"
        log(m)
    }
    
    override func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        if recordData {
            recordTapData(frequencies, amplitudes)
        }
        else {
            processTapData(frequencies, amplitudes)
        }
    }
    
    func recordTapData(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        let timeInterval = Date().timeIntervalSince1970
        var tapData = "time:\(timeInterval)\tfreq:\(frequencies[0])\tampl:\(amplitudes[0])\n"
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
        //if scaleMatcher != nil {
            if tapNumber == 0 {
                guard amplitude > AUValue(self.requiredStartAmplitude) else { return }
            }
        //}
        
        let midi = Util.frequencyToMIDI(frequency: frequency)

        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        var msg = ""
        msg += "secs:\(String(format: "%.2f", secs))"
        msg += " amp:\(String(format: "%.4f", amplitude))"
        msg += "  fr:\(String(format: "%.0f", frequency))"
        msg += "  MIDI \(String(describing: midi))"
        
//        if let scaleMatcher = scaleMatcher {
//            let matchedStatus = scaleMatcher.match(timestamp: Date(), midis: [midi], ampl: amplitudes)
//            msg += "\t\(matchedStatus.dispStatus())"
//            if let message = matchedStatus.msg {
//                msg += "  " + message //"\t \(message)"
//            }
//            if matchedStatus.status == .wrongNote {
//                wrongNoteFound = true
//            }
//        }
//        
        var scaleForNote:Scale?
        ///Listening has a scale but not a matcher
        if scale == nil {
            scaleForNote = scaleMatcher?.scale
        }
        else {
            scaleForNote = scale
        }
        ///1May - Matcher no longer used. Tap handler must update scale with matched notes
        if let scale = scaleForNote {
            if let index = scale.getMidiIndex(midi: midi, direction: ascending ? 0 : 1) {
                let scaleNote = scale.scaleNoteStates[index]
                if ascending {
                    if scaleNote.matchedTimeAscending == nil {
                        scaleNote.matchedTimeAscending = Date()
                        scaleNote.matchedAmplitudeAscending = Double(amplitude)
                    }
                }
                else {
                    if scaleNote.matchedTimeDescending == nil {
                        scaleNote.matchedTimeDescending = Date()
                        scaleNote.matchedAmplitudeDescending = Double(amplitude)
                    }
                }
                scaleNote.pianoKey?.setPlayingMidi("tap handler scale note")
                if index == scale.scaleNoteStates.count / 2 {
                    ascending = false
                }
            }
            else {
                var found = false
                for unMatch in matchNotInScale {
                    if unMatch.midi == midi && unMatch.ascending == ascending {
                        found = true
                        break
                    }
                }
                if !found {
                    matchNotInScale.append(UnMatchedType(notePlayedSequence: tapNumber, midi: midi, amplitude: Double(amplitude), time: Date(), ascending: ascending))
                }
                if let keyNumber = PianoKeyboardModel.shared.getKeyIndexForMidi(midi) {
                    PianoKeyboardModel.shared.pianoKeyModel[keyNumber].setPlayingMidi("tap handler out of scale")
                }
            }
        }
        
        log(msg, Double(amplitude))
        tapNumber += 1
    }
    
    override func stop() {
        if let scaleMatcher = scaleMatcher {
            log("PitchTapHandler:" + scaleMatcher.stats())
            ScalesModel.shared.setStatusMessage(scaleMatcher.stats())
        }
        else {
            if let scale = self.scale {
                ScalesModel.shared.setStatusMessage("from Tap Handler")
                ScalesModel.shared.result = Result(scale: scale, notInScale: self.matchNotInScale)
            }
        }
        log("PitchTapHandler in stop()")
        Logger.shared.calcValueLimits()
    }
}

///Handle a raw FFT
class FFTTapHandler :TapHandler {
    let scaleMatcher:ScaleMatcher?
    var wrongNoteFound = false
    var canStartAnalysis = false
    var requiredStartAmplitude:Double
    var firstTap = true
    
    init(requiredStartAmplitude:Double, scaleMatcher:ScaleMatcher?) {
        self.scaleMatcher = scaleMatcher
        self.requiredStartAmplitude = requiredStartAmplitude
        super.init()
        startTime = Date()
    }

    override func showConfig() {
        let s = String(format: "%.2f", requiredStartAmplitude)
        let m = "FFTTapHandler required_start_amplitude:\(s)"
        log(m)
    }
    
    func frequencyForBin(forBinIndex binIndex: Int, sampleRate: Double = 44100.0, fftSize: Int = 1024) -> Double {
        return Double(binIndex) * sampleRate / Double(fftSize)
    }
    
    func frequencyToMIDINote(frequency: Double) -> Int {
        let midiNote = 69 + 12 * log2(frequency / 440)
        return Int(round(midiNote))
    }
    
    override func tapUpdate(_ frequencyAmplitudes: [Float]) {
//        if wrongNoteFound {
//            return
//        }
        
        let n = 3
        let fftSize = frequencyAmplitudes.count //1024
        let sampleRate: Double = 44100  // 44.1 kHz
        
        let maxAmplitudes = frequencyAmplitudes.enumerated()
            .sorted { $0.element > $1.element }
            .prefix(n)
//        for i in 0..<maxAmplitudes.count {
//            maxAmplitudes[i].element *= 1
//        }
        let indicesOfMaxAmplitudes = maxAmplitudes
            .map { $0.offset }
        let magic = 13.991667622214578 //56.545038167938931 //somehow makes the frequencies right?
        // Calculate the corresponding frequencies
        let frequencies = indicesOfMaxAmplitudes.map { index in
            Double(index) * sampleRate / (Double(fftSize) * magic)
        }

        if scaleMatcher != nil {
            if firstTap {
                guard maxAmplitudes[0].element > AUValue(self.requiredStartAmplitude) else { return }
            }
        }
        firstTap = false
        
        var logMsg = ""
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        logMsg += "secs:\(String(format: "%.2f", secs))"
        logMsg += "  ind:  "
        for idx in indicesOfMaxAmplitudes {
            logMsg += " " + String(idx)
        }
        //var log = ""
        logMsg += "    ampl: "
        for a in maxAmplitudes  {
            logMsg += "  " + String(format: "%.2f", a.element * 1000)
        }
        
//
//        log += " ampl:"
//        for ampl in maxAmplitudes {
//            log += String(format: "%.2f", ampl.element * 1000)+","
//        }
        logMsg += "    freq:"
        for freq in frequencies {
            logMsg += String(format: "%.2f", freq)+","
        }
        logMsg += "    mid:"
        var midisToTest:[Int] = []
        for freq in frequencies {
            let midi = Util.frequencyToMIDI(frequency: Float(freq)) + 10
            logMsg += String(midi)+","
            midisToTest.append(midi)
        }

        if maxAmplitudes[0].element > 4.0 / 1000.0 {
            //print("", String(format: "%.2f", secs), "\t", amps, "\t", ind)
            log(logMsg, Double(maxAmplitudes[0].element))
        }
        
        logMsg += " midis:\(midisToTest) "
        if midisToTest.count == 0 {
            logMsg += " NONE"
        }
        else {
            if let scaleMatcher = scaleMatcher {
                let matchedStatus = scaleMatcher.match(timestamp: Date(), midis: midisToTest, ampl: frequencyAmplitudes)
                logMsg += "\t\(matchedStatus.dispStatus())"
                if let message = matchedStatus.msg {
                    logMsg += "  " + message //"\t \(message)"
                }
                if matchedStatus.status == .wrongNote {
                    wrongNoteFound = true
                }
            }
        }

        //Logger.shared.log(self, log, Double(maxAmplitudes[0].element))
    }
    

}
    
