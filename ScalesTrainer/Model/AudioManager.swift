import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX
import Speech

class AudioManager {
    static let shared = AudioManager()
    var audioPlayer = AudioPlayer()
    private  var engine = AudioEngine()
    var tap: BaseTap?
    var amplitudeFilter = 0.0
    let midiSampler = MIDISampler()
    var recorder: NodeRecorder?
    var silencer: Fader?
    let mixer = Mixer()
    var currentTapHandler:TapHandler? = nil
    var mic:AudioEngine.InputNode? = nil
    var speechManager:SpeechManager?
    let speech = SpeechManager.shared
    
    init() {
        //WARNING do not change a single character of this setup. It took hours to get to and is very fragile
        //Record on mic will never work on simulator - dont even try 😡
        guard let input = engine.input else {
            Logger.shared.log(self, "Engine has no input")
            return
        }
        mic = input
        do {
            recorder = try NodeRecorder(node: mic!)
        } catch let err {
            Logger.shared.reportError(self, "\(err)")
            return
        }
        checkMicPermission(completion: {granted in
            if !granted {
                Logger.shared.reportError(self, "No microphone permission")
            }
        })
        var simulator = false
        #if targetEnvironment(simulator)
        simulator = true
        #endif
        if !simulator {
            ///Without this the recorder causes a fatal error when it sttarts recording - no idea why 😣
            let silencer = Fader(input, gain: 0)
            self.silencer = silencer
            mixer.addInput(silencer)
        }
        mixer.addInput(audioPlayer)
        setupSampler()
        mixer.addInput(midiSampler)
        
        //if false {
            self.speechManager = SpeechManager.shared
            speechManager!.installSpeechTap()
            speechManager!.startSpeechRecognition()
        //}
        
        engine.output = mixer
        setSession()
        startEngine()

    }
    
    func startEngine() {
        do {
            try engine.start()
            //Logger.shared.log(self, "Engine started \n\(engine.connectionTreeDescription)")
            Logger.shared.log(self, "Engine started")
        } catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }
    
    func setSession() {
        ///nightmare
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true) //EXTREME WARnING - without this death
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }
    
    private func setupSampler() {
        do {
            let samplerFileName = "akai_steinway"
            try midiSampler.loadSoundFont(samplerFileName, preset: 0, bank: 0)
            Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
        }
        catch {
            Logger.shared.reportError(self, error.localizedDescription)
        }
    }

    func startRecordingMicrophone(tapHandler:TapHandler) {
        Logger.shared.clearLog()
        Logger.shared.log(self, "startRecordingMicrophone")
        ScalesModel.shared.result.reset()

        do {
            installTapHandler(node: mic!,
                              bufferSize: 4096,
                              tapHandler: tapHandler,
                              asynch: true)
            //WARNING 😣 - .record must come before tap.start
            try recorder?.record()
            tap!.start()
            currentTapHandler = tapHandler
        } catch let err {
            print(err)
        }
    }
    
    func stopRecording() {
        recorder?.stop()
        self.tap?.stop()
        currentTapHandler?.stop()
    }

    func playSampleFile(fileName:String, tapHandler: TapHandler) {
        Logger.shared.clearLog()
        ScalesModel.shared.result.reset()
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            Logger.shared.reportError(self, "Audio file not found \(fileName)")
            return
        }
        //startEngine()
        do {
            //try engine.start()
            let file = try AVAudioFile(forReading: fileURL)
            try? audioPlayer.load(file: file)
        }
        catch {
            Logger.shared.reportError(self, "File cannot load \(error.localizedDescription)")
        }
        installTapHandler(node: audioPlayer, bufferSize: 4096,
                          tapHandler: tapHandler,
                          asynch: true)
        audioPlayer.play()
        tap!.start()
        currentTapHandler = tapHandler
        //audioPlayer.play()
    }
    
    func playRecordedFile() {
        
        if let file = recorder?.audioFile {
            startEngine()
            try? audioPlayer.load(file: file)
            audioPlayer.play()
        }
    }

    func stopPlaySampleFile() {
        audioPlayer.stop()
        self.tap?.stop()
        currentTapHandler?.stop()
    }
    
    func installTapHandler(node:Node, bufferSize:Int, tapHandler:TapHandler, asynch : Bool) {
        if tapHandler is CallibrationTapHandler {
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
            //tap?.start()
        }
        if tapHandler is PitchTapHandler {
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
            //tap?.start()
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
    
    func checkMicPermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            // Permission already granted
            //setupRecording()
            completion(true)
        case .denied:
            // Permission denied
            completion(false)
        case .undetermined:
            // Request permission
            AVAudioApplication.requestRecordPermission { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
}

extension AudioManager: PianoKeyboardDelegate {
    func pianoKeyDown(_ keyNumber: Int) {
        //sampler.startNote(UInt8(keyNumber), withVelocity: 64, onChannel: 0)
        midiSampler.play(noteNumber: MIDINoteNumber(keyNumber), velocity: 64, channel: 0)
    }

    func pianoKeyUp(_ keyNumber: Int) {
        //sampler.stopNote(UInt8(keyNumber), onChannel: 0)
        midiSampler.stop()
    }
}

//    func configureMixer1(useMicrophone:Bool) {
//        ///Here’s the proper sequence:
//        ///Create and configure nodes: Set up your NodeRecorder and any other nodes you might be using (like AudioEngine.InputNode for microphone input).
//        ///Connect nodes: Make sure all your nodes are connected appropriately in the AudioKit graph.
//        ///Start the engine: Start the AudioKit engine with try engine.start().
//        ///Start recording: After the engine is running, you can safely start the recorder using recorder.record().
//
//        ///The engine.output property is used to specify the final output node of the audio processing graph. This output node is responsible for sending the processed audio to the audio hardware,
//        ///such as speakers or headphones, or to an audio file for recording.
//        ///
//        //setSession()
//
//        if useMicrophone {
//            //mixer.addInput(mic)
//            setSession()
//
//            //engine.output = nil //WARNING - remove any existing mixer from output else engine wont start
//        }
//        else {
//            //engine.stop()
//            mixer.removeAllInputs()
//
//            setupSampler()
//            mixer.addInput(midiSampler)
//
//            //if let audioPlayer = audioPlayer {
//                mixer.addInput(audioPlayer)
//            //}
//            //engine.output = mixer //WARNING - dont add in mic mode - it causes engine not to start when recording
//        }
//        //engine.output = mixer //WARNING - dont add in mic mode - it causes engine not to start when recording
//
//        do {
//            try engine.start()
//            //Logger.shared.log(self, "Engine started mic:\(useMicrophone) \n\(engine.connectionTreeDescription)")
//            Logger.shared.log(self, "Engine started useMic:\(useMicrophone)")
//        } catch {
//            Logger.shared.reportError(self, "Error starting engine: \(error)")
//        }
//    }
