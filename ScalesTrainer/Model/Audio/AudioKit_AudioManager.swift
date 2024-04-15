import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

//class AudioManager {
//    static let shared = AudioManager()
//    public var audioEngine = AudioEngine()
//    
//    private init() {
//        guard let input = AudioEngine().input else {
//            fatalError("Microphone input is not available.")
//        }
//    }
//    
//    func reset() {
//        audioEngine = AudioEngine()
//    }
//    func start() {
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Failed to start AudioEngine: \(error)")
//        }
//    }
//    
//    func stop() {
//        audioEngine.stop()
//    }
//}
//
//class AudioProcessor: ObservableObject {
//    let engine = AudioEngine()
//    var mic: AudioEngine.InputNode
//    var tap: BaseTap?
//    var ctr = 0
//    var tapHandler:TapHandler? = nil
//    var amplitudeFilter = 0.0
//    let silenceMixer: Mixer
//    var filePlayer: AudioPlayer?
//    var fileName:String?
//    
//    init(fileName:String?) {
//        silenceMixer = Mixer()
//
//        //else {
//            guard let input = engine.input else {
//                fatalError("Microphone input is not available.")
//            }
//            mic = input
//            //            silenceMixer.volume = 0
//            //            silenceMixer.addInput(mic!)
//            //engine.output = silenceMixer
//            //        }
//       // }
//        if let fileName = fileName {
//            self.fileName = fileName
//            setFilePlayer(recordedFileName: fileName)
//            silenceMixer.addInput(filePlayer!)
//        }
//    }
//
//    func setFilePlayer(recordedFileName:String?) {
//        if let fileName = recordedFileName {
//            do {
//                guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
//                    Logger.shared.reportError(self, "Error loading audio file: \(fileName)")
//                    return
//                }
//                let file = try AVAudioFile(forReading: fileURL)
//                filePlayer = AudioPlayer(file: file)
//            }
//            catch {
//                Logger.shared.reportError(self, "Error loading audio file: \(error.localizedDescription)")
//            }
//            guard let filePlayer = filePlayer else { return }
//            filePlayer.completionHandler = {
//                self.stopEngine()
//            }
//            //silenceMixer.addInput(filePlayer)
//            //AudioManager.shared.audioEngine.output = filePlayer
//        }
//    }
//    
//    func installTapHandler(bufferSize:Int, tapHandler:TapHandler, asynch : Bool) {
//        self.ctr += 1
//        self.tapHandler = tapHandler
//        self.tapHandler?.showConfig()
//        if tapHandler is PitchTapHandler {
//            let node:Node
////            if self.mic == nil {
////                node = self.filePlayer!
////            }
////            else {
////                node = mic
////            }
//            if let filePlayer = self.filePlayer {
//                node = filePlayer
//            }
//            else {
//                node = mic
//            }
//            tap = PitchTap(node,
//                           bufferSize:UInt32(bufferSize)) { pitch, amplitude in
//                if Double(amplitude[0]) > self.amplitudeFilter {
//                    if asynch {
//                        DispatchQueue.main.async {
//                            tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
//                        }
//                    }
//                    else {
//                        tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
//                    }
//                }
//            }
//        }
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
//    }
//    
//    func startEngine(fileName:String?, bufferSize:Int, ampitudeFilter:Double, tapHandler:TapHandler, asynch : Bool) {
//        self.amplitudeFilter = ampitudeFilter
//        stopEngine()
//        setFilePlayer(recordedFileName: fileName)
//        installTapHandler(bufferSize: bufferSize, tapHandler: tapHandler, asynch: asynch)
//        
//        ///How to connect a 2nd tap - https://stackoverflow.com/questions/68944356/audiokit-v5-using-multiple-taps
//        ///let playerCopy = Mixer(tapPlayer)
//        ///ampTap = AmplitudeTap(playerCopy)
//        
//        if let filePlayer = filePlayer {
//            silenceMixer.volume = 1
//            silenceMixer.addInput(filePlayer)
//        }
//        else {
//            silenceMixer.volume = 0
//            silenceMixer.addInput(mic)
//        }
//        do {
//            try engine.start()
//            tap?.start()
//            self.filePlayer?.play()
//
//            Logger.shared.clearLog()
//            Logger.shared.log(self,"Engine started")
//        } catch {
//            Logger.shared.reportError(self, "Could not start the engine: \(error)")
//        }
//    }
//
//    func stopEngine() {
//        engine.stop()
//        Logger.shared.log(self,"Engine stopped")
//        tap?.stop()
//        self.tapHandler?.end()
//    }
//}

class AudioKit_AudioManager: ObservableObject {
    @Published var audioPlayer: AudioPlayer?
    var engine = AudioEngine()
    var tap: BaseTap?
    var amplitudeFilter = 0.0
    var mic: AudioEngine.InputNode
    let silenceMixer: Mixer
    
    init() {
        silenceMixer = Mixer()

//        if let fileName = fileName {
//            self.fileName = fileName
//            //setFilePlayer(recordedFileName: fileName)
//            //silenceMixer.addInput(filePlayer!)
//        }
//        else {
            guard let input = engine.input else {
                fatalError("Microphone input is not available.")
            }
            mic = input
//            silenceMixer.volume = 0
//            silenceMixer.addInput(mic!)
//        }
        engine.output = silenceMixer
    }
    
    func setupAudioSession() {
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
            engine.output = audioPlayer
            try engine.start()
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
        //if engine.isRunning {
            //engine.stop()
        //}
    }
}
