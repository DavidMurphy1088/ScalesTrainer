import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class AudioKit_AudioManager: ObservableObject {
    @Published var audioPlayer: AudioPlayer?
    private var engine = AudioEngine()
    var tap: BaseTap?
    var amplitudeFilter = 0.0
    var mic: AudioEngine.InputNode
    let mixer: Mixer
    let midiSampler = MIDISampler()
    
    init() {
        mixer = Mixer()

        guard let input = engine.input else {
            fatalError("Microphone input is not available.")
        }
        mic = input

        do {
            let samplerFileName = "akai_steinway"
            try midiSampler.loadSoundFont(samplerFileName, preset: 0, bank: 0)
            Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
        }
        catch { 
            Logger.shared.reportError(self, error.localizedDescription)
        }
        setupAudioFile()
        
        mixer.addInput(midiSampler)
        mixer.addInput(audioPlayer!)
        engine.output = mixer
        
        do {
            try engine.start()
        } catch {
            print("Error setting up midi sampler with AudioKit: \(error)")
        }
    }
    
    func setupAudioFile() {
        //let f = "church_4_octave_Cmajor_RH"
        //let f = "4_octave_fast"
        let f = "1_octave_slow"
        
        guard let fileURL = Bundle.main.url(forResource: f, withExtension: "m4a") else {
            Logger.shared.reportError(self, "Audio file not found \(f)")
            return
        }
        do {
            // Use AudioKit's AudioFile class to handle the audio file
            let audioFile = try AVAudioFile(forReading: fileURL)
            audioPlayer = AudioPlayer(file: audioFile)
            audioPlayer?.volume = 0.5 //0.5
            //try engine.start()
        } catch {
            print("Error setting up audio player with AudioKit: \(error)")
        }
    }
    
    func installTapHandler(bufferSize:Int, tapHandler:TapHandler, asynch : Bool) {
        //self.ctr += 1
//        self.tapHandler = tapHandler
//        self.tapHandler?.showConfig()
        if tapHandler is PitchTapHandler {
            let node:Node
            if let audioPlayer = audioPlayer {
                node = audioPlayer
            }
            else {
                node = mic
            }
            tap = PitchTap(node,
                           bufferSize:UInt32(bufferSize)) { pitch, amplitude in
                //if Double(amplitude[0]) > self.amplitudeFilter {
                    if asynch {
                        DispatchQueue.main.async {
                            tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                        }
                    }
                    else {
                        tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                    }
                //}
            }
            tap?.start()
        }
//        if tapHandler is FFTTapHandler {
//            let node:Node
//            if let filePlayer = self.filePlayer {
//                node = filePlayer
//            }
//            else {
//                node = mic
//            }
//            tap = FFTTap(node, bufferSize:UInt32(bufferSize)) { freqs in
//                if asynch {
//                    DispatchQueue.main.async {
//                        tapHandler.tapUpdate(freqs)
//                    }
//                }
//                else {
//                    tapHandler.tapUpdate(freqs)
//                }
//            }
//            (tap as! FFTTap).isNormalized = false
//        }
    }

    func playFile() {
        installTapHandler(bufferSize: 4096,
                          tapHandler: PitchTapHandler(requiredStartAmplitude: 0.0,
                                                      scaleMatcher: nil), asynch: true)
        audioPlayer?.play()
    }

    func stopPlayFile() {
        audioPlayer?.stop()
        self.tap?.stop()

    }
}

extension AudioKit_AudioManager: PianoKeyboardDelegate {
    func pianoKeyDown(_ keyNumber: Int) {
        //sampler.startNote(UInt8(keyNumber), withVelocity: 64, onChannel: 0)
        midiSampler.play(noteNumber: MIDINoteNumber(keyNumber), velocity: 64, channel: 0)
    }

    func pianoKeyUp(_ keyNumber: Int) {
        //sampler.stopNote(UInt8(keyNumber), onChannel: 0)
        midiSampler.stop()
    }
}
