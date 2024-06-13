import SwiftUI
import AudioKit
import AVFoundation

class AudioRecorder: ObservableObject {
    var engine: AudioEngine?
    var mic: AudioEngine.InputNode?
    var recorder: NodeRecorder?
    var player: AudioPlayer?
    var file: AVAudioFile?

    func setupEngine() {
        engine = AudioEngine()
        mic = engine?.input
        if let mic = mic {
            do {
                // Initialize the recorder with the microphone as the input
                recorder = try NodeRecorder(node: mic)
                let silentMixer = Mixer(mic)
                silentMixer.volume = 0.0 // Mute the microphone input
                engine?.output = silentMixer
                try engine?.start()
                print("Audio engine started")
            } catch {
                print("AudioKit Error during setup: \(error.localizedDescription)")
            }
        }
    }

    func startRecording() {
        do {
            // Reinitialize the engine and recorder to ensure a fresh start
            setupEngine()
            try recorder?.reset()
            print("Recorder reset")
            try recorder?.record()
            print("Recording started")
        } catch {
            print("Recording Error: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        do {
            try recorder?.stop()
            print("Recording stopped")
            if let file = recorder?.audioFile {
                self.file = file
                print("Recorded file: \(file.url)")
                print("File length: \(file.length) frames")
                setupPlayer(url: file.url)
            } else {
                print("No audio file found after stopping recording")
            }
            engine?.stop()
        } catch {
            print("Stop Recording Error: \(error.localizedDescription)")
        }
    }

    func setupPlayer(url: URL) {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            player = AudioPlayer(file: audioFile)
            player?.volume = 1.0  // Set volume to maximum
            engine?.output = player
            print("Player setup with file: \(file?.url)")
        } catch {
            print("Player Setup Error: \(error.localizedDescription)")
        }
    }

    func startPlayback() {
        do {
            try engine?.start()
            player?.play()
            print("Playback started")
        } catch {
            print("Playback Error: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        player?.stop()
        do {
            try engine?.stop()
            print("Playback stopped")
        } catch {
            print("Stop Playback Error: \(error.localizedDescription)")
        }
    }
}

struct TestView: View {
    @ObservedObject var audioRecorder = AudioRecorder()

    var body: some View {
        VStack {
            Button(action: {
                audioRecorder.startRecording()
            }) {
                Text("Start Recording")
            }
            .padding()

            Button(action: {
                audioRecorder.stopRecording()
            }) {
                Text("Stop Recording")
            }
            .padding()

            Button(action: {
                audioRecorder.startPlayback()
            }) {
                Text("Play Recording")
            }
            .padding()

            Button(action: {
                audioRecorder.stopPlayback()
            }) {
                Text("Stop Playback")
            }
            .padding()
        }
    }
}

