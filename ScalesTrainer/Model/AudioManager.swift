import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX
import Speech

class AudioManager : MetronomeTimerNotificationProtocol {
    static let shared = AudioManager()
    public var engine = AudioEngine()
    var installedTap: BaseTap?
    var tapHandler: TapHandlerProtocol?
    let midiSampler = MIDISampler()
    //let scalesModel = ScalesModel.shared ///Causes start up exception
    var microphoneRecorder: NodeRecorder?
    var silencer: Fader?
    var mixer = Mixer()
    var fader:Fader?
    var mic:AudioEngine.InputNode? = nil
    var speechManager:SpeechManager?
    let speech = SpeechManager.shared
    var recordedFileSequenceNum = 0
    var metronomeAudioPlayerLow:AVAudioPlayer?
    var metronomeAudioPlayerHigh:AVAudioPlayer?
    var metronomeCount = 0
    
    init() {
        //WARNING do not change a single character of this setup. It took hours to get to and is very fragile
        //Record on mic will never work on simulator - dont even try 😡
        guard let input = engine.input else {
            Logger.shared.log(self, "Engine has no input")
            return
        }
        mic = input
        do {
            microphoneRecorder = try NodeRecorder(node: mic!)
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
        
        if true {
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
            //mixer.addInput(audioPlayer)
            setupSampler()
            mixer.addInput(midiSampler)
            
            self.speechManager = SpeechManager.shared
            
            engine.output = mixer
            setSession()
            startEngine()
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
    
    func metronomeStart() {
        metronomeAudioPlayerLow = loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerHigh = loadAudioPlayer(name: "metronome_mechanical_high")
        metronomeCount = 0
    }
    
    func metronomeTicked(timerTickerNumber: Int, userScale: Bool) -> Bool {
        if metronomeCount % 4 == 0 {
            metronomeAudioPlayerHigh!.play()
        }
        else {
            metronomeAudioPlayerLow!.play()
        }
        metronomeCount += 1
        return metronomeCount >= 8
    }
    
    func metronomeStop() {        
    }

    func startRecordingMicrophone(tapHandler:TapHandlerProtocol, recordAudio:Bool) {
        Logger.shared.clearLog()
        Logger.shared.log(self, "startRecordingMicrophone with ampl filter:\(ScalesModel.shared.amplitudeFilter)")
        //engine.removeTap(onBus: 0)
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            try AudioManager.shared.engine.start()
            installTapHandler(node: mic!,
                              bufferSize: 4096,
                              tapHandler: tapHandler,
                              asynch: true)
            //WARNING 😣 - .record must come before tap.start
            if recordAudio {
                try microphoneRecorder?.record() ///😡Causes exception if tap handler is Callibration
                if microphoneRecorder != nil && microphoneRecorder!.isRecording {
                    Logger.shared.log(self, "Recording started...")
                }
            }
            self.installedTap?.start()
            //currentTapHandler = tapHandler
        } catch let err {
            print(err)
        }
    }
    
    func stopRecording() {
        microphoneRecorder?.stop()
        self.installedTap?.stop()
        self.tapHandler?.stopTapping()
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
        var fileName:String
        switch ScalesModel.shared.selectedOctavesIndex {
        case 0:
            fileName = "05_05_C_Major_1_60_iPad_Desc"
            //fileName = "05_09_C_Major_1_60_iPad_0"
        case 1:
            //fileName = "05_05_C_MelodicMinor_2_60_iPad_17.txt"
            fileName = "05_09_C_Major_2_60_iPad_3"
            fileName = "05_09_C_HarmonicMinor_2_60_iPad_4"
        case 2:
            //fileName = "05_05_C_MelodicMinor_2_60_iPad_17.txt"
            fileName = "05_09_C_Minor_3_48_iPad_8"
            fileName = "05_09_C_Major_3_48_iPad_MISREAD_63"
            fileName = "05_09_C_Major_3_48_iPad_0"
        default:
            fileName = ""
        }
        fileName += ".txt"
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
                    //let time = fields[0].split(separator: ":")[1]
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
                //PianoKeyboardModel.shared.debug("End test read")
                Logger.shared.log(self, "Read test data \(lines.count-1) lines")
                
            } catch {
                Logger.shared.reportError(self, "Error reading file: \(fileName) \(error)")
            }
        } else {
            Logger.shared.reportError(self, "File not found \(fileName)")
        }
    }

    func installTapHandler(node:Node, bufferSize:Int, tapHandler:TapHandlerProtocol, asynch : Bool) {
        self.tapHandler = tapHandler
        self.installedTap = PitchTap(node, bufferSize:UInt32(bufferSize)) { pitch, amplitude in
            if Double(amplitude[0]) > ScalesModel.shared.amplitudeFilter || tapHandler is CallibrationTapHandler  {
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
    
//    func playRecordedFile() {
//        if let file = recorder?.audioFile {
//            startEngine()
//            try? audioPlayer.load(file: file)
//            audioPlayer.volume = 1.0
//            //AudioManager.shared.engine.output = audioPlayer
//            //AudioManager.shared.mixer.addInput(audioPlayer)
//            audioPlayer.play()
//        }
//    }

//    func stopPlaySampleFile() {
//        audioPlayer.stop()
//        self.tap?.stop()
//        currentTapHandler?.stopTapping()
//    }
    
