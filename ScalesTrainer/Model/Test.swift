import SwiftUI
import AudioKit
import AudioKitEX

import SwiftUI
import AudioKit
import AudioKitEX

class FFTAnalyzer: ObservableObject {
    var engine: AudioEngine!
    var mic: AudioEngine.InputNode!
    var fftTap: FFTTap!
    var silence: Fader!
    
    @Published var magnitudes: [Float] = Array(repeating: 0, count: 50)
    @Published var detectedPitch: Float = 0.0
    @Published var amplitude: Float = 0.0
    
    let sampleRate: Float = 44100.0 // Standard sample rate, adjust if different
    
    init() {
        setupAudioEngine()
        setupTap()
    }
    
    func setupAudioEngine() {
        engine = AudioEngine()
        guard let input = engine.input else {
            fatalError("Microphone not available")
        }
        mic = input
        silence = Fader(mic, gain: 0)
        engine.output = silence
    }
    
    func setupTap() {
        fftTap = FFTTap(mic) { fftData in
            DispatchQueue.main.async {
                self.magnitudes = Array(fftData.prefix(50))
                self.detectedPitch = self.calculatePitch(fftData: fftData)
                self.amplitude = self.calculateAmplitude(fftData: fftData)
            }
        }
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
    func calculateAmplitude(fftData: [Float]) -> Float {
        // Calculate the power spectrum (square of magnitudes)
        let powerSpectrum = fftData.map { $0 * $0 }
        
        // Sum the power spectrum
        let totalPower = powerSpectrum.reduce(0, +)
        
        // Calculate RMS amplitude
        let rms = sqrt(totalPower / Float(fftData.count))
        
        // Normalize RMS value based on FFT normalization
        // Assuming fftData is normalized by N/2 (N = number of samples)
        let normalizationFactor = 2.0 / Float(fftData.count)
        let amplitude = rms / normalizationFactor
        print("==============", rms)
        return amplitude
    }

    
    func startAnalysis() {
        do {
            print("Starting audio engine")
            try engine.start()
            print("Starting FFT tap")
            fftTap.start()
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
                Text("Detected Pitch: \(fftAnalyzer.detectedPitch, specifier: "%.4f") Hz")
                    .font(.headline)
                    .padding()
                
                Text("Amplitude: \(fftAnalyzer.amplitude, specifier: "%.4f")")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(0..<min(50, magnitudes.count), id: \.self) { index in
                            Text("Magnitude[\(index)]: \(magnitudes[index], specifier: "%.2f")")
                        }
                    }
                }
            }
        }
    }
}


