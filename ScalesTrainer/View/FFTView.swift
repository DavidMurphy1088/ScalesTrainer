//import SwiftUI
//import AudioKit
//import AudioKitEX
//import SoundpipeAudioKit   // Ensure SoundpipeAudioKit is added to your project
//import AVFoundation
//
//// A struct representing a detected pitch event.
//// - acceptedMidi: the MIDI note after any harmonic (octave) adjustment.
//// - rawMidi: if a harmonic adjustment occurred, this holds the raw detected MIDI value.
//// - amplitude: the measured amplitude.
//// - isRepeat: if the same accepted note repeats consecutively.
//struct PitchEvent: Identifiable {
//    let id = UUID()
//    let acceptedMidi: Int
//    let rawMidi: Int?
//    let amplitude: Float
//    let isRepeat: Bool
//}
//
//// MARK: - Pitch Tracker (Using PitchTap Only)
//class FastPitchTracker: ObservableObject {
//    
//    var engine = AudioEngine()
//    var mic: AudioEngine.InputNode!
//    var mixer: Mixer!
//    
//    // Only PitchTap is used.
//    var pitchTap: PitchTap?
//    
//    // Published values for display.
//    @Published var detectedFrequency: Double = 0.0
//    @Published var detectedMIDINote: Int? = nil
//    @Published var detectedAmplitude: Float = 0.0
//    @Published var pitchHistory: [Double] = Array(repeating: 0.0, count: 50)
//    @Published var detectedPitchEvents: [PitchEvent] = []
//    
//    // The slider now controls the minimum amplitude.
//    // Default sensitivity is now 0.03; allowed range: 0.01 to 0.1.
//    @Published var rmsThreshold: Float = 0.03
//    
//    // For tempo detection and smoothing.
//    var lastNoteTime: TimeInterval?
//    var smoothedFrequency: Double?
//    @Published var currentTempo: Double = 0.0  // notes per second
//    @Published var smoothingAlpha: Double = 1.0  // smoothing factor computed each time
//    
//    // Scale management.
//    // We generate a two–octave scale starting at MIDI 60.
//    // nextExpectedMidi holds the next note that is expected.
//    @Published var nextExpectedMidi: Int = 60
//    var scale: [Int] = []
//    
//    init() {
//        // Generate scale from MIDI 60 (e.g., [60, 62, 64, 65, 67, 69, 71, 72, 74, 75, 77, 79, 81, 83, 84]).
//        scale = generateScale(from: 60)
//        nextExpectedMidi = scale.first ?? 60
//        startAudioEngine()
//    }
//    
//    func startAudioEngine() {
//        mic = engine.input
//        mixer = Mixer(mic)
//        mixer.volume = 0
//        engine.output = mixer
//        
//        do {
//            try engine.start()
//            updateTap()
//        } catch {
//            print("Engine start failed: \(error)")
//        }
//    }
//    
//    /// Initializes PitchTap with a buffer size of 512 so that callbacks occur more frequently.
//    func updateTap() {
//        pitchTap?.stop()
////        pitchTap = PitchTap(mic, bufferSize: 512) { [weak self] pitch, amplitude in
//            self?.processPitchTap(pitch: pitch, amplitude: amplitude)
//        }
//        pitchTap?.start()
//    }
//    
//    /// Processes incoming pitch from PitchTap.
//    /// • Smoothing is applied with a factor (alpha) that is adjusted based on the time between notes.
//    /// • If the detected pitch (in MIDI) is within ±4 semitones of the nextExpectedMidi, it is accepted normally.
//    /// • If it is within ±4 semitones of nextExpectedMidi+12 or +24, it is treated as a harmonic adjustment.
//    /// • The accepted note is only added if it is ascending (or equal to the previous accepted note, which is then marked as a repeat).
//    func processPitchTap(pitch: [Float], amplitude: [Float]) {
//        guard let firstPitch = pitch.first, let firstAmplitude = amplitude.first else { return }
//        
//        // Use the slider threshold as the minimum amplitude.
//        guard firstAmplitude > rmsThreshold else {
//            DispatchQueue.main.async {
//                self.detectedFrequency = 0.0
//                self.detectedMIDINote = nil
//                self.detectedAmplitude = 0.0
//            }
//            return
//        }
//        
//        let currentTime = CACurrentMediaTime()
//        let rawFrequency = Double(firstPitch)
//        
//        // Adjust smoothing based on the time (dt) since the last accepted note.
//        if let prevSmoothed = smoothedFrequency, let lastTime = lastNoteTime {
//            let dt = currentTime - lastTime
//            let desiredInterval = 0.25  // desired interval for 4 notes/sec
//            let alpha = min(1.0, dt / desiredInterval)
//            self.smoothingAlpha = alpha
//            smoothedFrequency = alpha * rawFrequency + (1 - alpha) * prevSmoothed
//        } else {
//            smoothedFrequency = rawFrequency
//            smoothingAlpha = 1.0
//        }
//        guard let smoothedFreq = smoothedFrequency else { return }
//        
//        // Compute detected MIDI note from the smoothed frequency.
//        let detectedMidi = frequencyToMIDI(smoothedFreq)
//        
//        // Determine the accepted MIDI note.
//        // Check if the detected MIDI is within ±4 of nextExpectedMidi.
//        // Otherwise, if it is within ±4 of nextExpectedMidi+12 or +24, treat it as a harmonic.
//        var acceptedMidi: Int = 0
//        var harmonicRaw: Int? = nil  // holds the raw detected MIDI if a harmonic adjustment occurred
//        if abs(detectedMidi - nextExpectedMidi) <= 4 {
//            acceptedMidi = nextExpectedMidi
//        } else if abs(detectedMidi - (nextExpectedMidi + 12)) <= 4 {
//            acceptedMidi = nextExpectedMidi + 12
//            harmonicRaw = detectedMidi
//        } else if abs(detectedMidi - (nextExpectedMidi + 24)) <= 4 {
//            acceptedMidi = nextExpectedMidi + 24
//            harmonicRaw = detectedMidi
//        } else {
//            // Discard pitches that are not in any acceptable range.
//            return
//        }
//        
//        // Enforce ascending order.
//        // If the accepted note equals the last accepted note, mark it as a repeat.
//        var isRepeat = false
//        if let lastEvent = detectedPitchEvents.last {
//            if acceptedMidi < lastEvent.acceptedMidi {
//                return  // discard if lower than the previous accepted note
//            }
//            if acceptedMidi == lastEvent.acceptedMidi {
//                isRepeat = true
//            }
//        }
//        
//        // Accept the note.
//        DispatchQueue.main.async {
//            self.detectedFrequency = smoothedFreq
//            self.detectedMIDINote = acceptedMidi
//            self.detectedAmplitude = firstAmplitude
//            let event = PitchEvent(acceptedMidi: acceptedMidi,
//                                   rawMidi: harmonicRaw,
//                                   amplitude: firstAmplitude,
//                                   isRepeat: isRepeat)
//            self.detectedPitchEvents.append(event)
//            self.pitchHistory.append(smoothedFreq)
//            if self.pitchHistory.count > 50 {
//                self.pitchHistory.removeFirst()
//            }
//        }
//        
//        // Update tempo.
//        if let lastTime = lastNoteTime {
//            let dt = currentTime - lastTime
//            self.currentTempo = 1.0 / dt
//        }
//        lastNoteTime = currentTime
//        
//        // If the note is not a repeat, update nextExpectedMidi to the next note in the scale.
//        if !isRepeat, let index = scale.firstIndex(of: nextExpectedMidi), index < scale.count - 1 {
//            nextExpectedMidi = scale[index + 1]
//        }
//    }
//    
//    /// Converts a frequency (in Hz) to a MIDI note number.
//    func frequencyToMIDI(_ frequency: Double) -> Int {
//        return Int(round(69 + 12 * log2(frequency / 440.0)))
//    }
//    
//    /// Generates a two–octave scale from a starting MIDI note.
//    /// For example, generateScale(from: 60) returns [60, 62, 64, 65, 67, 69, 71, 72, 74, 75, 77, 79, 81, 83, 84].
//    func generateScale(from base: Int) -> [Int] {
//        let offsets = [0, 2, 4, 5, 7, 9, 11, 12, 14, 15, 17, 19, 21, 23, 24]
//        return offsets.map { base + $0 }
//    }
//}
//
//// MARK: - Main View
//struct FFTView: View {
//    @StateObject var pitchTracker = FastPitchTracker()
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            // Display tempo and smoothing info on its own line.
//            Text("Tempo: \(pitchTracker.currentTempo, specifier: "%.2f") notes/sec, Smoothing: \(pitchTracker.smoothingAlpha, specifier: "%.2f")")
//                .font(.subheadline)
//                .padding([.leading, .trailing, .top])
//            
//            // Single-line display of detected MIDI, amplitude, frequency, and the next expected note.
//            HStack {
//                Text("MIDI: \(pitchTracker.detectedMIDINote.map(String.init) ?? "Silent")")
//                Text("Amp: \(String(format: "%.4f", pitchTracker.detectedAmplitude))")
//                Text("Freq: \(String(format: "%.2f", pitchTracker.detectedFrequency)) Hz")
//                Text("Next: \(pitchTracker.nextExpectedMidi)")
//            }
//            .font(.headline)
//            .padding(.horizontal)
//            
//            // Sensitivity slider.
//            HStack {
//                Text("Sensitivity: \(pitchTracker.rmsThreshold, specifier: "%.3f")")
//                Slider(value: $pitchTracker.rmsThreshold, in: 0.01...0.1, step: 0.001)
//            }
//            .padding()
//            .background(Color.gray.opacity(0.2))
//            .cornerRadius(10)
//            .padding(.horizontal)
//            
//            // (The pitch graph is commented out.)
//            /*
//            PitchGraph(pitchHistory: pitchTracker.pitchHistory)
//            */
//            
//            // Expanded scrollable list of pitch events.
//            ScrollViewReader { proxy in
//                ScrollView {
//                    VStack(alignment: .leading) {
//                        ForEach(Array(pitchTracker.detectedPitchEvents.enumerated()), id: \.element.id) { index, event in
//                            // Build the display string.
//                            // If a harmonic adjustment occurred, show both accepted and raw values.
//                            let displayText: String = {
//                                if let raw = event.rawMidi {
//                                    return "\(index + 1). Accepted: \(event.acceptedMidi) (Harmonic from \(raw)), Amp: \(String(format: "%.4f", event.amplitude))"
//                                } else {
//                                    return "\(index + 1). MIDI: \(event.acceptedMidi), Amp: \(String(format: "%.4f", event.amplitude))"
//                                }
//                            }()
//                            
//                            // Color: if the note is a repeat, use gray; otherwise, use dark green.
//                            let textColor: Color = event.isRepeat ? .gray : .gray
//                            
//                            Text(displayText)
//                                .foregroundColor(textColor)
//                                .padding(.vertical, 2)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .id(index)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                .frame(maxHeight: .infinity)
//                .background(Color.gray.opacity(0.1))
//                .cornerRadius(10)
//                .padding()
//                .onChange(of: pitchTracker.detectedPitchEvents.count) { _ in
//                    withAnimation {
//                        proxy.scrollTo(pitchTracker.detectedPitchEvents.count - 1, anchor: .bottom)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            AVAudioSession.sharedInstance().requestRecordPermission { granted in
//                guard granted else { return }
//            }
//        }
//    }
//}
//
