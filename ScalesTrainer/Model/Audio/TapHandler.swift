import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation

///The key parameter that determines the frequency at which the closure (handler) is called is the bufferSize.
///The bufferSize parameter specifies the number of audio samples that will be processed in each iteration before calling the closure with the detected pitch and amplitude values.
///By default, the bufferSize is set to 4096 samples. Assuming a typical sample rate of 44,100 Hz, this means that the closure will be called approximately 10.7 times per second (44,100 / 4096).
///To increase the frequency at which the closure is called, you can decrease the bufferSize value when initializing the PitchTap instance. For example:
///
protocol TapHanderProtocol {
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func end()
}

class TapHandler : TapHanderProtocol {
    //let amplitudeFilter:Double
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
    
    func end(){
    }
}

class PitchTapHandler : TapHandler {
    let scaleMatcher:ScaleMatcher?
    var wrongNoteFound = false
    var firstTap = true
    let requiredStartAmplitude:Double
    
    init(requiredStartAmplitude:Double, scaleMatcher:ScaleMatcher?) {
        self.scaleMatcher = scaleMatcher
        self.requiredStartAmplitude = requiredStartAmplitude
        super.init()
    }
    
    override func showConfig() {
        let s = String(format: "%.2f", requiredStartAmplitude)
        let m = "PitchTapHandler required_start_amplitude:\(s)"
        Logger.shared.log(self, m)
    }
    
    override func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        // Reduces sensitivity to background noise to prevent random / fluctuating data.
        
        if wrongNoteFound {
            return
        }
        
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
        if scaleMatcher != nil {
            if firstTap {
                guard amplitude > AUValue(self.requiredStartAmplitude) else { return }
            }
        }
        firstTap = false
        let midi = Util.frequencyToMIDI(frequency: frequency)

        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        //let midi = Util.frequencyToMIDI(frequency: frequency)
        var msg = ""
        msg += "secs:\(String(format: "%.2f", secs))"
        msg += " amp:\(String(format: "%.2f", amplitude))"
        msg += "  fr:\(String(format: "%.0f", frequency))"
        msg += "  MIDI \(String(describing: midi))"
        
        if let scaleMatcher = scaleMatcher {
            let matchedStatus = scaleMatcher.match(timestamp: Date(), midis: [midi])
            //        if Logger.shared.logLevel  == .short {
            //            if matchedStatus.status == .dataIgnored {
            //                return
            //            }
            //        }
            msg += "\t\(matchedStatus.dispStatus())"
            if let message = matchedStatus.msg {
                msg += "  " + message //"\t \(message)"
            }
            if matchedStatus.status == .wrongNote {
                wrongNoteFound = true
            }
        }
        Logger.shared.log(self, msg, Double(amplitude))
    }
    
    override func end() {
        if let scaleMatcher = scaleMatcher {
            Logger.shared.log(self, scaleMatcher.stats())
        }
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
        Logger.shared.log(self, m)
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
        
        var log = ""
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0
        log += "secs:\(String(format: "%.2f", secs))"
        log += "  ind:  "
        for idx in indicesOfMaxAmplitudes {
            log += " " + String(idx)
        }
        //var log = ""
        log += "    ampl: "
        for a in maxAmplitudes  {
            log += "  " + String(format: "%.2f", a.element * 1000)
        }
        
//
//        log += " ampl:"
//        for ampl in maxAmplitudes {
//            log += String(format: "%.2f", ampl.element * 1000)+","
//        }
        log += "    freq:"
        for freq in frequencies {
            log += String(format: "%.2f", freq)+","
        }
        log += "    mid:"
        var midisToTest:[Int] = []
        for freq in frequencies {
            let midi = Util.frequencyToMIDI(frequency: Float(freq)) + 10
            log += String(midi)+","
            midisToTest.append(midi)
        }

        if maxAmplitudes[0].element > 4.0 / 1000.0 {
            //print("", String(format: "%.2f", secs), "\t", amps, "\t", ind)
            Logger.shared.log(self, log, Double(maxAmplitudes[0].element))
        }
        
        log += " midis:\(midisToTest) "
        if midisToTest.count == 0 {
            log += " NONE"
        }
        else {
            if let scaleMatcher = scaleMatcher {
                let matchedStatus = scaleMatcher.match(timestamp: Date(), midis: midisToTest)
                log += "\t\(matchedStatus.dispStatus())"
                if let message = matchedStatus.msg {
                    log += "  " + message //"\t \(message)"
                }
                if matchedStatus.status == .wrongNote {
                    wrongNoteFound = true
                }
            }
        }

        //Logger.shared.log(self, log, Double(maxAmplitudes[0].element))
    }
    
    override func end() {
        if let scaleMatcher = scaleMatcher {
            Logger.shared.log(self, scaleMatcher.stats())
        }
    }
}
    
