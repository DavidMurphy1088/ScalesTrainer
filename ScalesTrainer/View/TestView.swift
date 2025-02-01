//import SwiftUI
//import AVFoundation
//import AudioKit
//import AudioKitEX
//import SoundpipeAudioKit
//
///// A helper class that loads an audio file, plays it, and uses PitchTap to detect pitch using median filtering.
//class FilePitchDetector: ObservableObject {
//    let engine = AudioEngine()
//    var audioPlayer: AudioPlayer!  // Audio player for the recorded file.
//    var pitchTap: PitchTap!
//    
//    @Published var currentPitch: Double = 0.0
//    @Published var currentNote: String = "—"
//    @Published var currentMIDINote: Int = 0  // Stores the current MIDI note number.
//    
//    // Variables to track note changes.
//    private var previousMIDINote: Int?
//    private var lastNoteChangeTime: Date?
//    
//    // Buffer for smoothing: store recent pitch values.
//    private var pitchBuffer: [Double] = []
//    private let bufferSize = 5  // Experiment with this value.
//    
//    /// Computes the median of an array of Double values.
//    private func median(of array: [Double]) -> Double? {
//        let sorted = array.sorted()
//        guard !sorted.isEmpty else { return nil }
//        let count = sorted.count
//        if count % 2 == 1 {
//            return sorted[count / 2]
//        } else {
//            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
//        }
//    }
//    
//    init() {
//        do {
//            // 1. Load the audio file "scale.wav" from the app bundle.
//            guard let fileURL = Bundle.main.url(forResource: "scale_4_oct", withExtension: "wav") else {
//                fatalError("Audio file 'scale.wav' not found in the bundle.")
//            }
//            let audioFile = try AVAudioFile(forReading: fileURL)
//            
//            // 2. Create an AudioPlayer with the loaded file.
//            audioPlayer = AudioPlayer(file: audioFile)
//            audioPlayer.isLooping = false  // Change to true if you want the file to loop.
//            
//            // 3. Set the audioPlayer as the engine’s output.
//            engine.output = audioPlayer
//            
//            // 4. Create a PitchTap on the audioPlayer node.
//            pitchTap = PitchTap(audioPlayer, handler: { [weak self] pitchValues, amplitudeValues in
//                guard let self = self,
//                      let pitch = pitchValues.first, pitch > 0,
//                      let amplitude = amplitudeValues.first, amplitude > 0.1
//                else {
//                    return
//                }
//                
//                // Append the new pitch value to the buffer and maintain its size.
//                self.pitchBuffer.append(Double(pitch))
//                if self.pitchBuffer.count > self.bufferSize {
//                    self.pitchBuffer.removeFirst()
//                }
//                
//                // Compute the median pitch from the buffer.
//                guard let medianPitch = self.median(of: self.pitchBuffer) else { return }
//                
//                // Compute the MIDI note using the formula:
//                // MIDI note = 69 + 12 * log2(frequency / 440)
//                let midiNote = 69 + 12 * log2(medianPitch / 440.0)
//                let roundedMIDINote = Int(round(midiNote))
//                let noteName = FilePitchDetector.frequencyToNoteName(frequency: medianPitch)
//                
//                DispatchQueue.main.async {
//                    self.currentPitch = medianPitch
//                    self.currentNote = noteName
//                    self.currentMIDINote = roundedMIDINote
//                    
//                    let now = Date()
//                    if let previous = self.previousMIDINote, let lastChange = self.lastNoteChangeTime {
//                        if previous != roundedMIDINote {
//                            let elapsed = now.timeIntervalSince(lastChange)
//                            // Only update if the new note remains stable for at least 0.1 seconds.
//                            if elapsed >= 0.1 {
//                                print("Detected note: \(noteName) (MIDI: \(roundedMIDINote)) - elapsed: \(String(format: "%.2f", elapsed)) seconds since last change")
//                                self.lastNoteChangeTime = now
//                                self.previousMIDINote = roundedMIDINote
//                            }
//                        }
//                    } else {
//                        // First detection.
//                        self.previousMIDINote = roundedMIDINote
//                        self.lastNoteChangeTime = now
//                        print("Detected note: \(noteName) (MIDI: \(roundedMIDINote)) - initial detection")
//                    }
//                }
//            })
//            pitchTap.start()
//            
//            // 5. Start the audio engine.
//            try engine.start()
//            
//            // 6. Begin playback of the audio file.
//            audioPlayer.play()
//        } catch {
//            print("Error initializing FilePitchDetector: \(error.localizedDescription)")
//        }
//    }
//    
//    deinit {
//        engine.stop()
//    }
//    
//    /// Converts a frequency (in Hz) to a note name (e.g., "A4").
//    static func frequencyToNoteName(frequency: Double) -> String {
//        let midiNote = 69 + 12 * log2(frequency / 440.0)
//        let roundedNote = Int(round(midiNote))
//        
//        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
//        let noteIndex = roundedNote % 12
//        let octave = (roundedNote / 12) - 1
//        
//        return "\(noteNames[noteIndex])\(octave)"
//    }
//}
//
//struct TestView: View {
//    @StateObject private var pitchDetector = FilePitchDetector()
//    
//    var body: some View {
//        VStack(spacing: 30) {
//            Text("File Pitch Detection")
//                .font(.title)
//                .padding(.top, 40)
//            
//            Text("Frequency: \(pitchDetector.currentPitch, specifier: "%.2f") Hz")
//                .font(.headline)
//            
//            Text("Detected Note: \(pitchDetector.currentNote)")
//                .font(.largeTitle)
//                .bold()
//            
//            Text("MIDI Note: \(pitchDetector.currentMIDINote)")
//                .font(.title2)
//            
//            Spacer()
//            
//            Text("Playing recorded scales and detecting pitch...")
//                .multilineTextAlignment(.center)
//                .padding()
//        }
//        .padding()
//    }
//}
//
