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
    public var engine = AudioEngine()
    var tap: BaseTap?
    let midiSampler = MIDISampler()
    //let scalesModel = ScalesModel.shared ///Causes start up exception
    var recorder: NodeRecorder?
    var silencer: Fader?
    let mixer = Mixer()
    var currentTapHandler:TapHandler? = nil
    var mic:AudioEngine.InputNode? = nil
    var speechManager:SpeechManager?
    let speech = SpeechManager.shared
    var recordedFileSequenceNum = 0
    
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
        //mic.gain = 1.0
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
            ///Without this the recorder causes a fatal error when it starts recording - no idea why 😣
            let silencer = Fader(input, gain: 0)
            self.silencer = silencer
            mixer.addInput(silencer)
        }
        mixer.addInput(audioPlayer)
        setupSampler()
        mixer.addInput(midiSampler)
        
        self.speechManager = SpeechManager.shared
        
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
    
    func readTestData(tapHandler:PitchTapHandler) {
        let fileName:String
        switch ScalesModel.shared.selectedOctavesIndex {
        case 0:
            fileName = "05_05_C_Major_1_60_iPad_Desc.txt"
        case 1:
            fileName = "05_05_C_MelodicMinor_2_60_iPad_17.txt"
        default:
            fileName = ""
        }
        let scalesModel = ScalesModel.shared
        //scalesModel.scale.resetMatches()
        //scalesModel.result = nil
        
        if let filePath = Bundle.main.path(forResource: fileName, ofType: nil) {
            do {
                let contents = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = contents.split(separator: "\n")
                
                var ctr = 0
                for line in lines {
                    if ctr == 0 {
                        ctr += 1
                        let fields = line.split(separator: "\t")
                        let ampFilter = Double(fields[1])
                        let reqStartAmpl = Double(fields[2])
                        if let ampFilter = ampFilter {
                            if let startAmple = reqStartAmpl  {
                                scalesModel.amplitudeFilter = ampFilter
                                scalesModel.requiredStartAmplitude = reqStartAmpl
                                tapHandler.requiredStartAmplitude = reqStartAmpl ?? 0
                            }
                        }
                        continue
                    }
                    let fields = line.split(separator: "\t")
                    let time = fields[0].split(separator: ":")[1]
                    let freq = fields[1].split(separator: ":")[1]
                    let ampl = fields[2].split(separator: ":")[1]
                    let f = Float(freq)
                    let a = Float(ampl)
                    if let f = f {
                        if let a = a {
                            tapHandler.tapUpdate([f, f], [a, a])
                        }
                    }
                    ctr += 1
                }
                tapHandler.stopTapping()
                scalesModel.stopRecordingScale("End of Test Data")
                //PianoKeyboardModel.shared.mapPianoKeysToScaleNotes(direction: 0)
                scalesModel.forceRepaint()
                PianoKeyboardModel.shared.debug("End test read")
                Logger.shared.log(self, "Read test data \(lines.count-1) lines")
                
            } catch {
                Logger.shared.reportError(self, "Error reading file: \(fileName) \(error)")
            }
        } else {
            Logger.shared.reportError(self, "File not found \(fileName)")
        }
    }

    func startRecordingMicrophone(tapHandler:TapHandler, recordAudio:Bool) {
        Logger.shared.clearLog()
        Logger.shared.log(self, "startRecordingMicrophone")
        //ScalesModel.shared.result = nil
        //engine.removeTap(onBus: 0)
        
        do {
            installTapHandler(node: mic!,
                              bufferSize: 4096,
                              tapHandler: tapHandler,
                              asynch: true)
            //WARNING 😣 - .record must come before tap.start
            if recordAudio {
                try recorder?.record() ///😡Causes exception if tap handler is Callibration
                if recorder != nil && recorder!.isRecording {
                    Logger.shared.log(self, "Recording started...")
                }
            }
            tap!.start()
            currentTapHandler = tapHandler
        } catch let err {
            print(err)
        }
    }
    
    func stopRecording() {
        recorder?.stop()
        self.tap?.stop()
        currentTapHandler?.stopTapping()
    }

    func playSampleFile(fileName:String, tapHandler: TapHandler) {
        Logger.shared.clearLog()
        //ScalesModel.shared.result = nil
        //ScalesModel.shared.scale.resetMatches()
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
            audioPlayer.volume = 1.0
            //AudioManager.shared.engine.output = audioPlayer
            //AudioManager.shared.mixer.addInput(audioPlayer)
            audioPlayer.play()
        }
    }

    func stopPlaySampleFile() {
        audioPlayer.stop()
        self.tap?.stop()
        currentTapHandler?.stopTapping()
    }
    
    func installTapHandler(node:Node, bufferSize:Int, tapHandler:TapHandler, asynch : Bool) {
        if tapHandler is CallibrationTapHandler {
            tap = PitchTap(node,
                           bufferSize:UInt32(bufferSize)) { pitch, amplitude in
                //if Double(amplitude[0]) > ScalesModel.shared.amplitudeFilter {
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
        if tapHandler is PitchTapHandler {
            tap = PitchTap(node,
                           bufferSize:UInt32(bufferSize)) { pitch, amplitude in
                if Double(amplitude[0]) > ScalesModel.shared.amplitudeFilter {
                    if asynch {
                        DispatchQueue.main.async {
                            tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                        }
                    }
                    else {
                        tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                    }
                }
            }
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
