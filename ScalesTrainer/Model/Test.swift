import SwiftUI
import AudioKit
import AudioKitEX

import SwiftUI
import AudioKit
import AudioKitEX
import SoundpipeAudioKit

class FFTAnalyzer: ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode!
    var fftTap: FFTTap!
    var pitchTap: PitchTap!
    var ampTap: AmplitudeTap!
    var silence: Fader!
    var mixerA:Mixer!
    var mixerB:Mixer!
    var mixerC:Mixer!
    var showFFT = 0
    
    @Published var magnitudes: [Float] = Array(repeating: 0, count: 50)
    @Published var detectedPitch: Float = 0.0
    @Published var amplitude: Float = 0.0
    var cnt = 0
    var startTime = Date()
    var maxAmp:Double = 0
    
    let sampleRate: Float = 44100.0 // Standard sample rate, adjust if different
    
    init() {
        setupAudioEngine()
        setupTap()
    }
    
    func setupAudioEngineOld() {
        engine = AudioEngine()
        guard let input = engine.input else {
            fatalError("Microphone not available")
        }
        mic = input
        silence = Fader(mic, gain: 0)
        engine.output = silence
    }

    func setupAudioEngine() {
        engine = AudioEngine()
//        guard let input = engine.input else {
//            fatalError("Microphone not available")
//        }
        mic = engine.input
        // Create two separate mixers
        mixerA = Mixer(mic)
        mixerB = Mixer(mic)
        mixerC = Mixer(mic)
        // Create a final mixer to combine both
        let finalMixer = Mixer(mixerA, mixerB, mixerC)
        finalMixer.volume = 0
        engine.output = finalMixer
    }

    func getTime() -> String {
        let currentDate = Date()
        let timeDifference = currentDate.timeIntervalSince(self.startTime)
        let secondsDifference = Int(timeDifference)
        var millisecondsDifference = (timeDifference.truncatingRemainder(dividingBy: 1)) * 1000
        let multiplier = 100.0
        millisecondsDifference = (millisecondsDifference * multiplier).rounded() / multiplier
        let s = "\(secondsDifference).\(String(format: "%.0f", millisecondsDifference))"
        return s
    }
    
    func mostFreqInArray(inArr:[Int]) -> (key: Int, value: Int)? {
        var frequencyDict: [Int: Int] = [:]
        for value in inArr {
            frequencyDict[value, default: 0] += 1
        }
        let m = frequencyDict.max(by: { a, b in a.value < b.value })
        return m
    }
        
    func setupTap() {
        let bufferSize:UInt32 = 4096 * 1//* 4 * 4
        let minAmp:Double = 0.007
        
        if false {
            self.ampTap = AmplitudeTap(mixerC, bufferSize: bufferSize) { [self]amp in
                if Double(amp) > self.maxAmp {
                    self.maxAmp = Double(amp)
                }
                
                if Double(amp) > minAmp {
                    print(String(format: "%.4f", amp), String(format: "%.4f", maxAmp))
                    //let timeStamp = self.getTime()
                    self.showFFT = 12
                }
            }
        }
        
        if false {
            self.pitchTap = PitchTap(mixerB, bufferSize: bufferSize) {f,a in
                if Double(a[0]) > minAmp {
                }
            }
        }
        
        if true {
            if let input = engine.input {
                pitchTap = PitchTap(input) { pitch, amplitude in
                    if Double(amplitude[0]) > 0.05 { // Filter out low-amplitude noise
                        let midiNote = self.frequencyToMIDI_GPT(pitch[0])
                        print("MIDI Note: \(String(format: "%.4f", amplitude[0])) GPT:\(midiNote), OLD:\(self.frequencyToMIDI(frequencyHz: pitch))")
                    }
                }
                pitchTap.start()
            }
        }
        
        if false {
            fftTap = FFTTap(mixerA, bufferSize: bufferSize) { fftData in
                ///FFTTap uses Hann smoothing internally
                ///FFTTap: BaseTap
                self.cnt += 1
                if self.showFFT > 0 {
                    let topFreqs = self.calculateTopFrequencies(fftData: fftData)
                    let midis = self.frequencyToMIDI(frequencyHz: topFreqs)
                    
                    //if midis[0] >= 60 {
                    if Set(midis).count <= 2 {
                        //print("======= FFTTap MIDIS", self.cnt,  midis)
                        //let timeStamp = self.getTime()
                        //let topFreqInt = topFreqs.map { Int($0) }
                        //let mf = self.mostFreqInArray(inArr: midis)
                        self.showFFT -= 1
                        DispatchQueue.main.async {
                            self.magnitudes = Array(fftData.prefix(50))
                            self.detectedPitch = self.calculatePitch(fftData: fftData)
                            //self.amplitude = self.calculateAmplitude(fftData: fftData)
                        }
                    }
                    //}
                }
            }
        }

    }
    
    func frequencyToMIDI_GPT(_ frequency: Float) -> Int {
        return Int(69 + 12 * log2(frequency / 440.0))
    }
    
    func calculateTopFrequencies(fftData: [Float]) -> [Float] {
        let fftSize = fftData.count
        let sampleRate = self.sampleRate
        
        // Calculate magnitudes
        let magnitudes = fftData.enumerated().map { (index, value) -> (Int, Float) in
            let magnitude = sqrt(value * value)
            return (index, magnitude)
        }
        
        // Sort magnitudes in descending order and get top 3
        let topMagnitudes = magnitudes.sorted { $0.1 > $1.1 }.prefix(3)
        
        // Convert indices to frequencies and round to 3 decimal places
        let topFrequencies = topMagnitudes.map { index, _ -> Float in
            let frequency = Float(index) * sampleRate / (2.0 * Float(fftSize))
//            let rounded = (frequency * 1000).rounded() / 1000
//            //make ints??
//            return (frequency * 100000).rounded() / 100000 // Round to 3 decimal places
            return frequency
        }
        return topFrequencies
    }

    func frequencyToMIDI(frequencyHz: [Float]) -> [Int] {
        let midiReference:Float = 69.0
        let standardA440:Float = 440.0
        var midis:[Int] = []
        for f in frequencyHz {
            let midi = midiReference + 12.0 * log2(f / standardA440)
            if !(midi.isNaN || midi.isInfinite) {
                midis.append( Int(midi))
            }
        }
        return midis
    }
    
    func calculatePitch(fftData: [Float]) -> Float {
        let binCount = fftData.count
        let nyquistFrequency = sampleRate / 2
        
        // Find the peak magnitude and its index
        var peakMagnitude: Float = 0
        var peakIndex = 0
        for i in 0..<binCount {
            if fftData[i] > peakMagnitude {
                peakMagnitude = fftData[i]
                peakIndex = i
            }
        }
        
        // Calculate the frequency of the peak
        let frequencyResolution = nyquistFrequency / Float(binCount)
        let peakFrequency = Float(peakIndex) * frequencyResolution
        return peakFrequency
    }
    
    func startAnalysis() {
        do {
            print("Starting audio engine")
            try engine.start()
            print("Starting FFT tap")
//            if let tap = fftTap {
//                tap.start()
//            }
//            if let tap = pitchTap {
//                tap.start()
//            }
//            if let tap = ampTap {
//                tap.start()
//            }
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopAnalysis() {
        print("Stopping FFT tap")
        fftTap.stop()
        print("Stopping audio engine")
        engine.stop()
    }
}

struct FFTContentView: View {
    @StateObject private var fftAnalyzer = FFTAnalyzer()
    @State private var isAnalyzing = false
    
    var magnitudes: [Float] {
        fftAnalyzer.magnitudes
    }
    
    var body: some View {
        VStack {
            Text("FFT Analyzer")
                .font(.title)
            
            Button(action: {
                if isAnalyzing {
                    fftAnalyzer.stopAnalysis()
                } else {
                    fftAnalyzer.startAnalysis()
                }
                isAnalyzing.toggle()
            }) {
                Text(isAnalyzing ? "Stop Analysis" : "Start Analysis")
            }
            .padding()
            
            if isAnalyzing {
                Text("Detected Pitch: \(fftAnalyzer.detectedPitch, specifier: "%.0f") Hz")
                    .font(.headline)
                    .padding()
                
                Text("Amplitude: \(fftAnalyzer.amplitude, specifier: "%.4f")")
                    .font(.headline)
                    .padding()
                
//                ScrollView {
//                    VStack(alignment: .leading) {
//                        ForEach(0..<min(50, magnitudes.count), id: \.self) { index in
//                            Text("Magnitude[\(index)]: \(magnitudes[index], specifier: "%.2f")")
//                        }
//                    }
//                }
            }
        }
    }
}

import AudioKit
import AudioKitEX
import SoundpipeAudioKit

class AudioAnalyzer {
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode!
    var mixerA, mixerB: Mixer!
    var pitchTap: PitchTap!
    var fftTap: FFTTap!
    let bufferSize: Int = 4096
    
    init() {
        do {
            mic = engine.input
            
            // Create two separate mixers
            mixerA = Mixer(mic)
            mixerB = Mixer(mic)
            
            // Create a final mixer to combine both
            let finalMixer = Mixer(mixerA, mixerB)
            engine.output = finalMixer
            
            // Create PitchTap on mixerA
            pitchTap = PitchTap(mixerA) { pitch, amplitude in
                self.processPitch(pitch: pitch[0], amplitude: amplitude[0])
            }
            
            // Create FFTTap on mixerB
            fftTap = FFTTap(mixerB, bufferSize: UInt32(bufferSize)) { fftData in
                self.processFFT(fftData: fftData)
            }
            
            // Start the taps
            pitchTap.start()
            fftTap.start()
            
            try engine.start()
        } catch {
            print("AudioKit failed to start: \(error)")
        }
    }
    
    func processPitch(pitch: Float, amplitude: Float) {
        print("Pitch: \(pitch) Hz, Amplitude: \(amplitude)")
    }
    
    func processFFT(fftData: [Float]) {
        // Here you would apply the Hann window and perform FFT if needed
        print("Processing FFT data of size: \(fftData.count)")
    }
}

// Usage
let analyzer = AudioAnalyzer()
