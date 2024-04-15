import UIKit
import AVFoundation

class KeyboardAudioEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    //private let reverb = AVAudioUnitReverb()
    //private let delay = AVAudioUnitDelay()
    //let midiAudioUnitSampler:AVAudioUnitSampler = AVAudioUnitSampler()
    
    func start() {
        engine.attach(sampler)
        //engine.attach(reverb)
        //engine.attach(delay)

//        engine.connect(sampler, to: delay, format: nil)
//        engine.connect(delay, to: reverb, format: nil)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        // Reverb
        //reverb.loadFactoryPreset(.mediumHall)
        //reverb.wetDryMix = 30.0

//        // Delay
//        delay.wetDryMix = 15.0
//        delay.delayTime = 0.50
//        delay.feedback = 75.0
//        delay.lowPassCutoff = 16000.0

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("Error: AudioSession couldn't set category")
        }

        do {
            try audioSession.setActive(true)
        } catch {
            print("Error: AudioSession couldn't set category active")
        }

        if engine.isRunning {
            print("Audio engine already running")
            return
        }
        startSampler()
        do {
            try engine.start()
            print("Audio engine started")
        } catch {
            print("Error: couldn't start audio engine")
            return
        }
    }
    
    func startSampler() {
        let samplerFileName = "akai_steinway"
        if let url = Bundle.main.url(forResource: samplerFileName, withExtension: "sf2") {
            let ins = 0
            for instrumentProgramNumber in ins..<256 {
                do {
                    try sampler.loadSoundBankInstrument(at: url,
                                                                 program: UInt8(instrumentProgramNumber),
                                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB))
                    break
                }
                catch {
                    break
                }
            }
        }
        else {
            Logger.shared.reportError(self, "Cannot loadSoundBankInstrument \(samplerFileName)")
        }
    }
}

extension KeyboardAudioEngine: PianoKeyboardDelegate {
    func pianoKeyDown(_ keyNumber: Int) {
        sampler.startNote(UInt8(keyNumber), withVelocity: 64, onChannel: 0)
    }

    func pianoKeyUp(_ keyNumber: Int) {
        sampler.stopNote(UInt8(keyNumber), onChannel: 0)
    }
}
