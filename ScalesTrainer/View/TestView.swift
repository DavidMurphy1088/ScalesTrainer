import SwiftUI
import AudioKit
import AVFoundation
import CSoundpipeAudioKit
import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX
import Speech

class AudioRecorder: ObservableObject {
    var engine: AudioEngine?
    var mic: AudioEngine.InputNode?
    var recorder: NodeRecorder?
    var player: AudioPlayer?
    var file: AVAudioFile?
    var installedTap:BaseTap?
    
    func setupEngine(start:Bool) {
        engine = AudioEngine()
        mic = engine?.input
        if let mic = mic {
            do {
                // Initialize the recorder with the microphone as the input
                recorder = try NodeRecorder(node: mic)
                let silentMixer = Mixer(mic)
                silentMixer.volume = 0.0 // Mute the microphone input
                engine?.output = silentMixer
                if start {
                    try engine?.start()
                }
                print("Audio engine started")
            } catch {
                print("AudioKit Error during setup: \(error.localizedDescription)")
            }
        }
    }

    func startRecording1() {
        engine = AudioEngine()
        mic = engine?.input
        guard let mic = mic else {
            return
        }
        do {
            recorder = try NodeRecorder(node: mic)
            let silentMixer = Mixer(mic)
            silentMixer.volume = 0.0 // Mute the microphone input
            engine?.output = silentMixer
            //try engine?.start()
            //print("Audio engine started")
        } catch {
            print("AudioKit Error during setup: \(error.localizedDescription)")
        }
        
        //let audioManager = AudioManager.shared
        //let tapHandler = ScaleTapHandler(amplitudeFilter: Settings.shared.amplitudeFilter, hilightPlayingNotes: false)
        installedTap = PitchTap(mic, bufferSize:UInt32(1024)) { pitch, amplitude in
            DispatchQueue.main.async {
                print("Inside tap....")
            }
        }
        do {
            try engine?.start()
            try recorder?.record()
            if let tap = self.installedTap {
                tap.start()
            }
            print("Recording started")
        } catch {
            print("Recording Error: \(error.localizedDescription)")
        }
    }

    func startRecording() {
        engine = AudioEngine()
        mic = engine?.input
        guard let mic = mic else {
            return
        }
        
        do {
            // Initialize the recorder with the mic node
            recorder = try NodeRecorder(node: mic)
            
            // Create a silent mixer to mute the microphone input in the output
            let silentMixer = Mixer(mic)
            //silentMixer.volume = 0.0
            engine?.output = silentMixer
            
            // Setup the pitch tap with a separate mixer
            //let tapMixer = Mixer(mic)
            if true {
                installedTap = PitchTap(mic, bufferSize: UInt32(1024)) { pitch, amplitude in
                    DispatchQueue.main.async {
                        print("Inside tap....", pitch, amplitude)
                    }
                }
            }
            else {
                let audioManager = AudioManager.shared
                let tapHandler = PracticeTapHandler(amplitudeFilter: 0, hilightPlayingNotes: true)
                audioManager.installTapHandler(node: silentMixer,
                                  bufferSize: 4096,
                                  tapHandler: tapHandler,
                                  asynch: true)
                installedTap = audioManager.installedTap
            }
            
            // Start the audio engine
            try engine?.start()
            print("Audio engine started")
            
            // Start recording
            try recorder?.record()
            print("Recording started")
            
            // Start the tap
            if let tap = installedTap {
                tap.start()
                print("Tap started")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        if let tap = installedTap {
            tap.stop()
        }
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
        } catch {
            print("Error stopping recording: \(error.localizedDescription)")
        }
        engine?.stop()
    }


//    func stopRecording() {
//        do {
//            try recorder?.stop()
//            print("Recording stopped")
//            if let file = recorder?.audioFile {
//                self.file = file
//                print("Recorded file: \(file.url)")
//                print("File length: \(file.length) frames")
//                setupPlayer(url: file.url)
//            } else {
//                print("No audio file found after stopping recording")
//            }
//            engine?.stop()
//        } catch {
//            print("Stop Recording Error: \(error.localizedDescription)")
//        }
//    }

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

