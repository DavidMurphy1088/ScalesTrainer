import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class AudioManager {
    static let shared = AudioManager()
    public var engine: AudioEngine?
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
    //var initialDevice: Device?
    var pitchTaps: [PitchTap] = []
    var tappableNodeA: Fader?
    var tappableNodeB: Fader?
    var tappableNodeC: Fader?
    var tappableNodeD: Fader?
    var tappableNodeE: Fader?
    var silencer: Fader?

    init() {
        ///Enable just midi at app start, other more complex audio configs will be made depending on user actions (like recording)
        resetAudioKit()
    }
    
//    func configureAudioOld() {
//        //WARNING do not change a single character of this setup. It took hours to get to and is very fragile
//        //Record on mic will never work on simulator - dont even try 😡😡😡😡
//        self.engine = AudioEngine() 
//        guard let engine = self.engine else {
//            Logger.shared.log(self, "Engine is nil")
//            return
//        }
//
//        guard let input = engine.input else {
//            Logger.shared.log(self, "Engine has no input")
//            return
//        }
//        mic = input
//        do {
//            recorder = try NodeRecorder(node: input)
//        } catch let err {
//            Logger.shared.reportError(self, "\(err)")
//            return
//        }
//        //mic.gain = 1.0
//        checkMicPermission(completion: {granted in
//            if !granted {
//                Logger.shared.reportError(self, "No microphone permission")
//            }
//        })
//    
//    ///In AudioKit, the engine.output = mixer line of code sets the final node in the audio processing chain to be the mixer node. This means that the mixer node's output is what will be sent to the speakers or the output device.
//    ///When you set engine.output = mixer, you are specifying that the mixer's output should be the final audio output of the entire audio engine. This is crucial because:
//    
//    ///Signal Routing: It determines where the processed audio should go. Without setting the engine.output, the audio engine doesn't know which node's output should be routed to the speakers or headphones.
//    ///Start of Audio Processing: Setting the engine.output is necessary before starting the engine with engine.start(). If the output is not set, there will be no audio output even if the engine is running.
//    ///End Point: It effectively makes the mixer the end point of your audio signal chain. All audio processing done in the nodes connected to this mixer will be heard in the final output.
//    
//        simulator = false
//#if targetEnvironment(simulator)
//        simulator = true
//#endif
//        if simulator {
//            //setupSampler()
//            engine.output = midiSampler
//        }
//        else {
//            self.mixer = Mixer(input)
//            ///Without this the recorder causes a fatal error when it starts recording - no idea why 😣
//            let silencer = Fader(input, gain: 0)
//            self.silencer = silencer
//            mixer?.addInput(silencer)
//            
//            self.audioPlayer = AudioPlayer()
//            mixer?.addInput(self.audioPlayer!)
//            //setupSampler()
//            //mixer?.addInput(midiSampler ?? <#default value#>)
//            
//            //self.speechManager = SpeechManager.shared
//            engine.output = mixer
//            setSession()
//        }
//        do {
//            try engine.start()
//        }
//        catch {
//            Logger.shared.reportError(self, "Could not start engine", error)
//        }
//
//    }
    
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
    
    func resetAudioKit() {
        setSession()
        self.engine = AudioEngine()
        guard let engine = self.engine else {
            Logger.shared.reportError(self, "No engine")
            return
        }
        //if self.midiSampler == nil {
            self.midiSampler = loadSampler()
        //}
        //self.midiSampler = setupSampler()
        engine.output = self.midiSampler
        do {
            try engine.start()
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }

    func startRecordingMicWithTapHandlers(tapHandlers:[TapHandlerProtocol], recordAudio:Bool) {
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
        guard let engineInput = engine.input else {
            Logger.shared.reportError(self, "No input")
            return
        }
//        if recordAudio {
//            do {
//                self.recorder = try NodeRecorder(node: engineInput)
//            } catch let err {
//                Logger.shared.reportError(self, "Recorder \(err.localizedDescription)")
//            }
//        }
//        else {
//            self.recorder = nil
//        }
//        guard let device = engine.inputDevice else {
//            Logger.shared.reportError(self, "No input device")
//            return
//        }
//        self.initialDevice = device
        self.mic = engineInput
        
        if true { 
            self.tappableNodeA = Fader(mic!)
            self.tappableNodeB = Fader(tappableNodeA!)
            self.tappableNodeC = Fader(tappableNodeB!)
            self.tappableNodeD = Fader(tappableNodeC!)
            self.tappableNodeE = Fader(tappableNodeD!)
            self.silencer = Fader(tappableNodeE!, gain: 0)
            ///If a node with an installed tap is not connected to the engine's output (directly or indirectly), the audio data will not flow through that node, and consequently, the tap closure will not be called.
            engine.output = self.silencer
        }
        else {
            ///Cant include sampler for backer
            ///This setup wont work since the ampl and freq passed to the PitchTap is garbage.
            ///Maybe its not required anyway - anytime another node is generating output and a pitch tap is connected it will pick up output from that node in addition to the microphone.
            ///Whereas the pitch tap should only ever include input from the user's instrument.
            self.silencer = Fader(engineInput, gain: 0)
            self.mixer = Mixer(engineInput)
            mixer?.addInput(self.silencer!)
            self.audioPlayer = AudioPlayer()
            mixer?.addInput(self.audioPlayer!)
            //if let midiSampler = setupSampler() {
            if let midiSampler = self.midiSampler {
                mixer?.addInput(midiSampler)
            }
            //}
            engine.output = self.mixer
        }
        
        if recordAudio {
            if let fader = self.tappableNodeC {
                do {
                    self.recorder = try NodeRecorder(node: fader)
                } catch let err {
                    Logger.shared.reportError(self, "Recorder \(err.localizedDescription)")
                }
            }
            else {
                self.recorder = nil
            }
        }

        self.pitchTaps.append(installTapHandler(node: self.tappableNodeA!,
                                                tapHandler: tapHandlers[0],
                                                asynch: true))
        if tapHandlers.count > 1 {
            self.pitchTaps.append(installTapHandler(node: self.tappableNodeB!,
                                                    tapHandler: tapHandlers[1],
                                                    asynch: true))
        }
        if tapHandlers.count > 2 {
            self.pitchTaps.append(installTapHandler(node: self.tappableNodeC!,
                                                    tapHandler: tapHandlers[2],
                                                    asynch: true))
        }
        if tapHandlers.count > 3 {
            self.pitchTaps.append(installTapHandler(node: self.tappableNodeD!,
                                                    tapHandler: tapHandlers[3],
                                                    asynch: true))
        }

        for tap in self.pitchTaps {
            tap.start()
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
        for pitchTap in self.pitchTaps {
            pitchTap.stop()
        }
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
    
    private func loadSampler() -> MIDISampler? {
        do {
            let samplerFileName = "Yamaha-Grand-Lite-SF-v1.1"
            //let samplerFileName = "Abbey-Steinway-D-bs16i-v1.9"
            let sampler = MIDISampler()
            try sampler.loadSoundFont(samplerFileName, preset: 0, bank: 0)
            //Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
            return sampler
        }
        catch {
            Logger.shared.reportError(self, error.localizedDescription)
            return nil
        }
    }
    
    ///Return a list of tap events recorded previously in a file
    func readTestDataFile() -> [TapEventSet] {
        
        let scalesModel = ScalesModel.shared
        var tapEventSets:[TapEventSet] = []
        var tapNum = 0
        
        if let filePath = Bundle.main.path(forResource: "RecordedTapData", ofType: "txt") {
            let contents:String
            do {
                contents = try String(contentsOfFile: filePath, encoding: .utf8)
            }
            catch {
                Logger.shared.log(self, "cannot read file \(error.localizedDescription)")
                return tapEventSets
            }
            let lines = contents.split(separator: "\r\n")
            
            //var tapEvents:[TapEvent] = []
            //var lastBufferSize:Int? = nil
            var currentTapSet:TapEventSet? = nil
            
            for i in 0..<lines.count+1 {
                var line:String
                if i<lines.count {
                    line = String(lines[i])
                }
                else {
                    line = "--"
                }
                
                let fields = line.split(separator: " ")
                if line.starts(with: "--"){
                    ///e.g. --TapSet BufferSize 4096
                    if let currentTapSet = currentTapSet {
                        tapEventSets.append(currentTapSet)
                        //let newTapSet = TapEventSet(bufferSize: lastBufferSize, events: [] )
//                        for tap in tapEvents {
//                            newTapSet.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: tap/, amplitude: <#Float#>))
//                        }
                        //tapEventSets.append(newTapSet)
                        Logger.shared.log(self, "Read \(currentTapSet.events.count) events from file for bufferSize:\(currentTapSet.bufferSize)")
                        //tapEvents = []
                        tapNum = 0
                    }
                    if i>=lines.count {
                        break
                    }
                    currentTapSet = TapEventSet(bufferSize: Int(fields[2]) ?? 0, events: [])
                    continue
                }
                
                let freq = fields[1].split(separator: ":")[1]
                let ampl = fields[2].split(separator: ":")[1]
                let f = Float(freq)
                let a = Float(ampl)
                if let f = f {
                    if let a = a {
                        currentTapSet?.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: f, amplitude: a))
//                        currentTapSet.tapEvents.append(TapEvent(tapNum: tapNum, frequency: f, amplitude: a, ascending: true, status: .none,
//                                                  expectedMidis: [], midi: 0, tapMidi: 0, consecutiveCount: 1))
                        tapNum += 1
                    }
                }
            }
        }
        else {
            Logger.shared.reportError(self, "Cant open file bundle")
        }
        return tapEventSets
    }
    
    func playbackTapEvents(tapEventSets:[TapEventSet], tapHandlers:[TapHandlerProtocol]) {
        var tapHandlerIndex = 0
        for tapEventSet in tapEventSets {
            Logger.shared.log(self, "Start play back \(tapEventSet.events.count) tap events for bufferSize:\(tapEventSet.bufferSize)")
            for tIndex in 0..<tapEventSet.events.count {
                let tapEvent = tapEventSet.events[tIndex]
                let f:AUValue = tapEvent.frequency
                let a:AUValue = tapEvent.amplitude
                tapHandlers[tapHandlerIndex].tapUpdate([f, f], [a, a])
            }
            tapHandlerIndex += 1
            if tapHandlerIndex >= tapHandlers.count {
                break
            }
        }

//        let events = tapHandlers[0].stopTappingProcess("AudioMgr.playbackEvents")
//        ScalesModel.shared.setTapHandlerEventSet(events, publish: true) ///WARNING😡😡😡😡😡😡 - off breaks READ_TEST_DATA (AT LEAST), ON breaks callibration
        Logger.shared.log(self, "Played back \(tapHandlerIndex) tap event sets")
        ScalesModel.shared.setRunningProcess(.none)
    }
    
    func installTapHandler(node:Node, tapHandler:TapHandlerProtocol, asynch : Bool) -> PitchTap {
        let s = String(describing: type(of: tapHandler))
        
        let installedTap = PitchTap(node, bufferSize:UInt32(tapHandler.getBufferSize())) { pitch, amplitude in
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
        }
        Logger.shared.log(self, "Installed tap handler type:\(s) bufferSize:\(tapHandler.getBufferSize())")
        return installedTap
    }
    
    func checkMicPermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            // Permission already granted
            completion(true)
        case .denied:
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
