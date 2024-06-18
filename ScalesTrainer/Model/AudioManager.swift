import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX
//import Speech

class AudioManager {
    static let shared = AudioManager()
    public var engine: AudioEngine?
    var installedTap: BaseTap?
    var midiSampler:MIDISampler?
    var recorder: NodeRecorder?
    var mixer:Mixer?
    var fader:Fader?
    var mic:AudioEngine.InputNode? = nil

    var recordedFileSequenceNum = 0
    var metronomeCount = 0
    var simulator = false
    var blockTaps = false
    var audioPlayer:AudioPlayer?
    
    ///AudioKit Cookbook example
    var initialDevice: Device?
    var pitchTap: PitchTap?
    var tappableNodeA: Fader?
    var tappableNodeB: Fader?
    var tappableNodeC: Fader?
    var silencer: Fader?
    var tapHandler: TapHandlerProtocol?

    init() {
//        if false {
//            configureAudio(start: true)
//        }
    }
//    func configureAudio(start:Bool) {
//        engine = AudioEngine()
//        mic = engine?.input
//        if let mic = mic {
//            do {
//                // Initialize the recorder with the microphone as the input
//                recorder = try NodeRecorder(node: mic)
//                let silentMixer = Mixer(mic)
//                silentMixer.volume = 0.0 // Mute the microphone input
//                engine?.output = silentMixer
//                if start {
//                    try engine?.start()
//                    Logger.shared.log(self, "configureAudio =================================> Audio engine started")
//                }
//                
//            } catch {
//                print("AudioKit Error during setup: \(error.localizedDescription)")
//            }
//        }
//    }
    
    func configureAudioOld() {
        //WARNING do not change a single character of this setup. It took hours to get to and is very fragile
        //Record on mic will never work on simulator - dont even try 😡😡😡😡
        self.engine = AudioEngine() 
        guard let engine = self.engine else {
            Logger.shared.log(self, "Engine is nil")
            return
        }

        guard let input = engine.input else {
            Logger.shared.log(self, "Engine has no input")
            return
        }
        mic = input
        do {
            recorder = try NodeRecorder(node: input)
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
    
    ///In AudioKit, the engine.output = mixer line of code sets the final node in the audio processing chain to be the mixer node. This means that the mixer node's output is what will be sent to the speakers or the output device.
    ///When you set engine.output = mixer, you are specifying that the mixer's output should be the final audio output of the entire audio engine. This is crucial because:
    
    ///Signal Routing: It determines where the processed audio should go. Without setting the engine.output, the audio engine doesn't know which node's output should be routed to the speakers or headphones.
    ///Start of Audio Processing: Setting the engine.output is necessary before starting the engine with engine.start(). If the output is not set, there will be no audio output even if the engine is running.
    ///End Point: It effectively makes the mixer the end point of your audio signal chain. All audio processing done in the nodes connected to this mixer will be heard in the final output.
    
        simulator = false
#if targetEnvironment(simulator)
        simulator = true
#endif
        if simulator {
            setupSampler()
            engine.output = midiSampler
        }
        else {
            self.mixer = Mixer(input)
            ///Without this the recorder causes a fatal error when it starts recording - no idea why 😣
            let silencer = Fader(input, gain: 0)
            self.silencer = silencer
            mixer?.addInput(silencer)
            
            self.audioPlayer = AudioPlayer()
            mixer?.addInput(self.audioPlayer!)
            setupSampler()
            //mixer?.addInput(midiSampler ?? <#default value#>)
            
            //self.speechManager = SpeechManager.shared
            engine.output = mixer
            setSession()
        }
        do {
            try engine.start()
        }
        catch {
            Logger.shared.reportError(self, "Could not start engine", error)
        }

    }
    func playRecordedFile(audioFile:AVAudioFile) {
        do {
            //try audioPlayer.load(file: audioFile)
            Logger.shared.log(self, "Playing file len:\(audioFile.length) duration:\(audioFile.duration)")
            //audioPlayer = AudioPlayer(file: audioFile)!
            //audioPlayer.volume = 1.0
            //engine?.output = audioPlayer
            try engine?.start()
            audioPlayer?.play()
        }
        catch {
            Logger.shared.reportError(self, "Cannot load file len:\(audioFile.length) duration:\(audioFile.duration)")
        }
    }
    
    func loadAudioPlayer(name:String) -> AVAudioPlayer? {
        let clapURL = Bundle.main.url(forResource: name, withExtension: "aiff")

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: clapURL!)
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0 // Set the volume to full
            audioPlayer.rate = 2.0
            return audioPlayer
        }
        catch  {
            Logger.shared.reportError(self, "Cannot prepare AVAudioPlayer")
        }

        Logger.shared.log(self, "Loaded audio players")
        return nil
    }
    
//    func initSampler() {
//        setSession()
//        self.engine = AudioEngine()
//        guard let engine = self.engine else {
//            Logger.shared.reportError(self, "No engine")
//            return
//        }
//        self.midiSampler = setupSampler()
//        engine.output = self.midiSampler
//        do {
//            try engine.start()
//        }
//        catch {
//            Logger.shared.reportError(self, "Error starting engine: \(error)")
//        }
//    }
    
    func resetAudioKitToMIDISampler() {
        setSession()
        self.engine = AudioEngine()
        guard let engine = self.engine else {
            Logger.shared.reportError(self, "No engine")
            return
        }
        self.midiSampler = setupSampler()
        engine.output = self.midiSampler
        do {
            try engine.start()
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }

    func startRecordingMicWithTapHandler(tapHandler:TapHandlerProtocol, recordAudio:Bool) {
        ///It appears that we cannot both record the mic and install a tap on it at the same time
        ///Error is reason: 'required condition is false: nullptr == Tap()' when the record starts.
        checkMicPermission(completion: {granted in
            if !granted {
                Logger.shared.reportError(self, "No microphone permission")
            }
        })
        setSession()
        
        ///Based on CookBook Tuner
        self.engine = AudioEngine()
        guard let engine = self.engine else {
            Logger.shared.reportError(self, "No engine")
            return
        }
        guard let input = engine.input else {
            Logger.shared.reportError(self, "No input")
            return
        }
        if recordAudio {
            do {
                self.recorder = try NodeRecorder(node: input)
            } catch let err {
                Logger.shared.reportError(self, "Recorder \(err.localizedDescription)")
            }
        }
        else {
            self.recorder = nil
        }
        guard let device = engine.inputDevice else {
            Logger.shared.reportError(self, "No input device")
            return
        }

        self.initialDevice = device
        self.mic = input
        
        if true { 
            self.tappableNodeA = Fader(mic!)
            self.tappableNodeB = Fader(tappableNodeA!)
            self.tappableNodeC = Fader(tappableNodeB!)
            self.silencer = Fader(tappableNodeC!, gain: 0)
            ///If a node with an installed tap is not connected to the engine's output (directly or indirectly), the audio data will not flow through that node, and consequently, the tap closure will not be called.
            engine.output = self.silencer
        }
        else {
            ///Cant inlcude sampler for backer
            ///This setup wont work since the ampl and freq passed to the PitchTap is garbage.
            ///Maybe its not required anyway - anytime another node is generating output and a pitch tap is connected it will pick up output from that node in addition to the microphone.
            ///Whereas the pitch tap should only ever include input from the user's instrument.
            self.silencer = Fader(input, gain: 0)
            self.mixer = Mixer(input)
            mixer?.addInput(self.silencer!)
            self.audioPlayer = AudioPlayer()
            mixer?.addInput(self.audioPlayer!)
            if let midiSampler = setupSampler() {
                self.midiSampler = midiSampler
                mixer?.addInput(midiSampler)
            }
            engine.output = self.mixer
        }

//        self.pitchTap = PitchTap(mic!) { pitch, amp in
//            DispatchQueue.main.async {
//                print("============>>", pitch, amp)
//            }
//        }
        self.pitchTap = installTapHandler(node: mic!,
                          bufferSize: 4096,
                          tapHandler: tapHandler,
                          asynch: true)
        self.tapHandler = tapHandler
        if let pitchTap = self.pitchTap {
            pitchTap.start()
        }
        
        do {
            ///As per the order in Cookbook Recorder example
            try engine.start()
            if recordAudio {
                try recorder?.record()
            }
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }

    func stopRecording() {
        if let tap = self.installedTap {
            tap.stop()
        }
        self.tapHandler?.stopTapping()
        if let recorder = recorder {
            recorder.stop()
            print("Recording stopped")
            if let audioFile = recorder.audioFile {
                ScalesModel.shared.setRecordedAudioFile(recorder.audioFile)
                let log = "Stopped recording, recorded file: \(audioFile.url) len:\(audioFile.length) duration:\(audioFile.duration)"
                Logger.shared.log(self, log)
                self.audioPlayer = AudioPlayer(file: audioFile)
                self.audioPlayer?.volume = 1.0  // Set volume to maximum
                engine?.output = self.audioPlayer
                //print("Player setup with file: \(file?.url)")
            } else {
                print("No audio file found after stopping recording")
            }
        }
        engine?.stop()
    }
    
    func setSession() {
        ///nightmare
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true) //EXTREME WARNING - without this death 😡
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }
    
    private func setupSampler() -> MIDISampler? {
        do {
            //let samplerFileName = "akai_steinway"
            let samplerFileName = "Yamaha-Grand-Lite-SF-v1.1"
            //let samplerFileName = "Abbey-Steinway-D-bs16i-v1.9"
            let sampler = MIDISampler()
            try sampler.loadSoundFont(samplerFileName, preset: 0, bank: 0)
//            let filter = LowPassFilter(midiSampler)
//            Cut reverb
//            filter.cutoffFrequency = 800.0 // Adjust this value to reduce reverb effect
//
//            let gate = DynamicsProcessor(filter)
//            gate.threshold = -20.0 // Adjust this value
//            gate.headRoom = 0.1 // Adjust this value

            Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
            return sampler
        }
        catch {
            Logger.shared.reportError(self, error.localizedDescription)
            return nil
        }
    }
    
    func readTestData(tapHandler:ScaleTapHandler) {
        var fileName:String
        let scalesModel = ScalesModel.shared
        if scalesModel.selectedHandIndex == 0 {
            switch scalesModel.selectedOctavesIndex {
            case 0:
                //fileName = "05_16_17_37_C_MelodicMinor_1_60_iPad_2,3,2,4_7"
                fileName = "05_02_C_Major_1_60_iPad"
                //fileName = "06_01_20_28_CMajor,RightHand_1_60_iPad_1,0,0,0_0"
            case 1:
                fileName = "05_18_11_22_B♭_Major_2_58_iPad_0,0,0,7_33"
            case 2:
                fileName = "05_09_C_Minor_3_48_iPad_8"
                fileName = "05_09_C_Major_3_48_iPad_MISREAD_63"
                fileName = "05_09_C_Major_3_48_iPad_0"
                fileName = "05_22_14_32_A_Major_2_33_iPad_0,0,0,0_1"
            default:
                fileName = ""
            }
        }
        else {
            switch scalesModel.selectedOctavesIndex {
            case 0:
                fileName = "05_18_17_35_C_Major_1_48_iPad_0,0,1,1_5"
            case 1:
                fileName = "05_18_17_37_C_Major_2_36_iPad_0,0,1,1_9"
            default:
                fileName = ""
            }
        }
        fileName += ".txt"

        if let filePath = Bundle.main.path(forResource: fileName, ofType: nil) {
            do {
                let contents = try String(contentsOfFile: filePath, encoding: .utf8)
                let lines = contents.split(separator: "\n")
                
                var ctr = 0
                var freqs:[Float] = []
                var amps:[Float] = []
                for line in lines {
                    if ctr == 0 {
                        ctr += 1
                        let fields = line.split(separator: "\t")
                        let ampFilter = Double(fields[1])
                        //let reqStartAmpl = Double(fields[2])
                        if let ampFilter = ampFilter {
                            //if reqStartAmpl != nil  {
                                DispatchQueue.main.async {
                                    Settings.shared.amplitudeFilter = ampFilter
                                    //Settings.shared.requiredScaleRecordStartAmplitude = reqStartAmpl ?? 0
                                }
                            //}
                        }
                        continue
                    }
                    let fields = line.split(separator: "\t")
                    //let time = fields[0].split(separator: ":")[1]
                    let freq = fields[1].split(separator: ":")[1]
                    let ampl = fields[2].split(separator: ":")[1]
                    let f = Float(freq)
                    let a = Float(ampl)
                    if let f = f {
                        if let a = a {
                            freqs.append(f)
                            amps.append(a)
                        }
                    }
                    ctr += 1
                }
                
                let backgroundQueue = DispatchQueue.global(qos: .background)
                    
                backgroundQueue.async {
                    for tIndex in 0..<freqs.count {
                        let semaphore = DispatchSemaphore(value: 0)
                        let queue = DispatchQueue(label: "com.example.timerQueue.\(tIndex)")
                        let timer = DispatchSource.makeTimerSource(queue: queue)
                        timer.schedule(deadline: .now() + 0.04, repeating: .never)
                        timer.setEventHandler {
                            semaphore.signal()
                            timer.cancel() // Cancel the timer after it fires once
                        }
                        timer.resume()
                        semaphore.wait()
                        let f:AUValue = AUValue(freqs[tIndex])
                        let a:AUValue = amps[tIndex]
                        tapHandler.tapUpdate([f, f], [a, a])
                    }
                    
                    tapHandler.stopTapping()
                    scalesModel.forceRepaint()
                    Logger.shared.log(self, "Read test data \(lines.count-1) lines")
                }
            } catch {
                Logger.shared.reportError(self, "Error reading file: \(fileName) \(error)")
            }
        } else {
            Logger.shared.reportError(self, "File not found \(fileName)")
        }
    }

    func installTapHandler(node:Node, bufferSize:Int, tapHandler:TapHandlerProtocol, asynch : Bool) -> PitchTap {
        //self.tapHandler = tapHandler
        let s = String(describing: type(of: tapHandler))
        Logger.shared.log(self, "Installed tap handler type:\(s)")
        let installedTap = PitchTap(node, bufferSize:UInt32(bufferSize)) { pitch, amplitude in
            //if Double(amplitude[0]) > ScalesModel.shared.amplitudeFilter {
            if !self.blockTaps {
                if asynch {
                    DispatchQueue.main.async {
                        tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                    }
                }
                else {
                    tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                }
            }
            //}
        }
        return installedTap
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
        if let sampler = midiSampler {
            sampler.play(noteNumber: MIDINoteNumber(keyNumber), velocity: 64, channel: 0)
        }
        
    }

    func pianoKeyUp(_ keyNumber: Int) {
        //sampler.stopNote(UInt8(keyNumber), onChannel: 0)
        if let sampler = midiSampler {
            sampler.stop()
        }
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

//    func playSampleFile(fileName:String, tapHandler: TapHandler) {
//        Logger.shared.clearLog()
//        //ScalesModel.shared.result = nil
//        //ScalesModel.shared.scale.resetMatches()
//        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
//            Logger.shared.reportError(self, "Audio file not found \(fileName)")
//            return
//        }
//        //startEngine()
//        do {
//            //try engine.start()
//            let file = try AVAudioFile(forReading: fileURL)
//            try? audioPlayer.load(file: file)
//        }
//        catch {
//            Logger.shared.reportError(self, "File cannot load \(error.localizedDescription)")
//        }
//        installTapHandler(node: audioPlayer, bufferSize: 4096,
//                          tapHandler: tapHandler,
//                          asynch: true)
//        audioPlayer.play()
//        tap!.start()
//        currentTapHandler = tapHandler
//        //audioPlayer.play()
//    }
    


//    func stopPlaySampleFile() {
//        audioPlayer.stop()
//        self.tap?.stop()
//        currentTapHandler?.stopTapping()
//    }
    
//    func startRecordingMicWithTapHandlerOld1(tapHandler:TapHandlerProtocol, recordAudio:Bool) {
//        self.engine = AudioEngine()
//        guard let engine = self.engine else {
//            return
//        }
//        mic = engine.input
//        guard let mic = mic else {
//            return
//        }
//        checkMicPermission(completion: {granted in
//            if !granted {
//                Logger.shared.reportError(self, "No microphone permission")
//            }
//        })
//        setSession()
//        do {
//            if recordAudio {
//                recorder = try NodeRecorder(node: mic)
//            }
//
//            if true {
//                self.mixer = Mixer(mic)
//            //            //if tap handler attached to mixer the pitches it gets are wrong
//            //            //if tap handler attached to mic the pitches it gets are rigth
//            //
//            //            //if volume is zero and tap handler attached to mixer tap handler gets zero amplitudes
//            //            //silentMixer.volume = 0.0
//                engine.output = self.mixer
//            }
//
//            if false {
//                let silencer = Fader(mic, gain: 0)
//                self.silencer = silencer
//                self.mixer = Mixer()
//                mixer!.addInput(silencer)
//
//                //mixer.addInput(audioPlayer)
//                setupSampler()
//                mixer!.addInput(midiSampler)
//
//                //mixer.addInput(audioPlayer)
//
//                self.speechManager = SpeechManager.shared
//
//                engine.output = mixer
//            }
//            // Setup the pitch tap with the same mixer
//            //installTapHandler(node: silentMixer,
//            installTapHandler(node: mic,
//                              bufferSize: 4096,
//                              tapHandler: tapHandler,
//                              asynch: true)
//
//            // Start the audio engine
//            try engine.start()
//            print("Audio engine started")
//
//            // Start recording
//            if recordAudio {
//                try recorder?.record()
//                print("Recording started")
//            }
//
//            // Start the tap
//            if let tap = installedTap {
//                tap.start()
//                print("Tap started")
//            }
//        } catch {
//            print("Error: \(error.localizedDescription)")
//        }
//    }

//    func startRecordingMicWithTapHandlerOld(tapHandler:TapHandlerProtocol, recordAudio:Bool) {
//        Logger.shared.log(self, "startRecordingMicrophone")
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.playAndRecord, mode: .default)
//            try session.setActive(true)
//           // AudioManager.shared.configureAudio(start: false)
//
//            //WARNING 😣 - .record must come before tap.start
//            if recordAudio {
//                //self.microphoneRecorder = try NodeRecorder(node: mic!)
//                if let recorder = self.recorder {
//                    do {
//                        //try self.microphoneRecorder!.reset()
//                        try recorder.record() ///😡Causes exception if tap handler is Callibration
//                        if false {
//                            if recorder.isRecording {
//                                ///Never, never, never access the URL of the audio file here or before stopping recording. This is BRAIN DEAD after hours of research 😡
//                                ///Any attempt to read the URL causes the file to be zero length at recording end 😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡😡
//                                Logger.shared.log(self, "Recording started... file:\(String(describing: recorder.audioFile?.url))")
//                            }
//                        }
//                    }
//                    catch {
//                        Logger.shared.reportError(self, "Error starting recording: \(error)")
//                    }
//                }
//            }
//            try engine?.start()
//            ///Moved install tap handler after record otherwise the record always records zero len file
//            installTapHandler(node: mic!,
//                              bufferSize: 4096,
//                              tapHandler: tapHandler,
//                              asynch: true)
//            try engine?.start()
//            if let tap = self.installedTap {
//                tap.start()
//            }
//            else {
//                Logger.shared.reportError(self, "No tap handler")
//            }
//        } catch let err {
//            Logger.shared.reportError(self, err.localizedDescription)
//        }
//    }
