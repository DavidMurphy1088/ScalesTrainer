import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import AudioKitEX
import AudioToolbox

import AudioKit
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioEngine: AudioEngine?
    
    private var samplerForKeyboard:MIDISampler?
    private var samplerForBacking:MIDISampler?
    private var mixer:Mixer?
    private var mic:AudioEngine.InputNode? = nil
    
    ///AudioKit Cookbook example
    private var pitchTaps: [PitchTap] = []
    private var tappableNodeA: Fader?
//    private var tappableNodeB: Fader?
//    private var tappableNodeC: Fader?
//    private var tappableNodeD: Fader?
//    private var tappableNodeE: Fader?
//    private var tappableNodeF: Fader?
    private var silencer: Fader?
    //private let oneInit = false
    
    var recordedFileSequenceNum = 0
    var audioPlayer:AudioPlayer?
    var nodeRecorder: NodeRecorder?

    init() {
        ///Enable just midi at app start, other more complex audio configs will be made depending on user actions (like recording)
        configureAudio(withMic: false, recordAudio: false)
    }
    
    func getSamplerForKeyboard() -> MIDISampler? {
        return self.samplerForKeyboard
    }
    
    func getSamplerForBacking() -> MIDISampler? {
        return self.samplerForBacking
    }

    func configureAudio(withMic:Bool, recordAudio:Bool, soundEventHandlers:[SoundEventHandlerProtocol] = []) {
        
        func configureAudioKit(withMic:Bool, recordAudio:Bool) {
            do {
                if self.audioEngine != nil {
                    self.audioEngine?.stop()
                    self.audioEngine?.output = nil
                }
                self.audioEngine = AudioEngine()
                guard let engine = self.audioEngine else {
                    AppLogger.shared.reportError(self, "No engine")
                    return
                }
                
                self.samplerForKeyboard = MIDISampler()
                var preset = 2 ///Yamaha-Grand-Lite-SF-v1.1 has three presets and Polyphone list bright =1 , dark = 2, grandpiano = 0
                self.samplerForKeyboard = loadSampler(num: 0, preset: preset)
                if let user = Settings.shared.getCurrentUser() {
                    switch user.settings.backingSamplerPreset {
                    case 1: preset = 28
                    case 2: preset = 37
                    case 3: preset = 49
                    case 4: preset = 33
                    case 5: preset = 39
                    case 6: preset = 43
                    case 7: preset = 2
                    case 8: preset = 4
                    default: preset = 0
                    }
                }
                self.samplerForBacking = loadSampler(num: 1, preset: preset)
                
                self.mixer = Mixer()
                self.mixer!.addInput(self.samplerForKeyboard!)
                self.mixer!.addInput(self.samplerForBacking!)
                
                if withMic {
                    self.mic = self.audioEngine?.input
                    self.tappableNodeA = Fader(mic!)
                    ///Multiple nodes allow multiple tap handlers - if required
    //                self.tappableNodeB = Fader(tappableNodeA!)
    //                self.tappableNodeC = Fader(tappableNodeB!)
    //                self.tappableNodeD = Fader(tappableNodeC!)
    //                self.tappableNodeE = Fader(tappableNodeD!)
    //                self.tappableNodeF = Fader(tappableNodeE!)
                    self.silencer = Fader(tappableNodeA!, gain: 0)
                    self.mixer!.addInput(silencer!)
                    if recordAudio {
                        self.nodeRecorder = try NodeRecorder(node: tappableNodeA!)
                    }
                }
                
                engine.output = self.mixer
//                Logger.shared.log(self, "Configured AudioKit mic:\(withMic)")
            } catch {
                AppLogger.shared.reportError(self, "Can't configure AudioKit \(error)")
            }
        }

        ///It appears that we cannot both record the mic and install a tap on it at the same time
        ///Error is reason: 'required condition is false: nullptr == Tap()' when the record starts.
        checkMicPermission(completion: {granted in
            if !granted {
                AppLogger.shared.reportError(self, "No microphone permission")
            }
        })
        setSession()
        configureAudioKit(withMic: true, recordAudio: recordAudio)
        
//        if oneInit {
//            self.pitchTaps = []
//        }
        if soundEventHandlers.count > 0 {
            self.pitchTaps.append(installTapHandler(node: self.tappableNodeA!,
                                                    tapHandler: soundEventHandlers[0] as! AcousticSoundEventHandler,
                                                    asynch: true))
            for tap in self.pitchTaps {
                tap.start()
            }
        }
        
//        if oneInit {
//            self.audioEngine!.stop()
//        }
        do {
            ///As per the order in Cookbook Recorder example
            try self.audioEngine!.start()
            if recordAudio {
                try self.nodeRecorder?.record()
            }
        }
        catch {
            AppLogger.shared.reportError(self, "Error starting engine: \(error)")
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
            AppLogger.shared.reportError(self, "Cannot prepare AVAudioPlayer")
        }

        AppLogger.shared.log(self, "Loaded audio players")
        return nil
    }
    
    func stopPlayingRecordedFile() {
        if let audioPlayer = self.audioPlayer {
            audioPlayer.stop()
            //self.resetAudioKit()
            DispatchQueue.main.async {
                ScalesModel.shared.recordingIsPlaying = false
            }
        }
    }
    
    func playRecordedFile() {
        //if let recorder = nodeRecorder {
        if let audioFile = ScalesModel.shared.recordedAudioFile { //recorder.audioFile {
                self.audioPlayer = AudioPlayer(file: audioFile)
                self.audioPlayer?.volume = 1.0  // Set volume to maximum
                audioEngine?.output = self.audioPlayer
                AppLogger.shared.log(self, "Recording Duration: \(audioFile.duration) seconds")
                audioPlayer?.completionHandler = {
                    DispatchQueue.main.async {
                        ScalesModel.shared.recordingIsPlaying = false
                    }
                }
                self.audioPlayer?.play()
                DispatchQueue.main.async {
                    ScalesModel.shared.recordingIsPlaying = true
                }
            }
        //}
    }
    
//    func startRecordingMicToRecordOLD() {
//        checkMicPermission(completion: {granted in
//            if !granted {
//                Logger.shared.reportError(self, "No microphone permission")
//                return
//            }
//        })
//        setSession()
//
//        ///Based on CookBook Tuner
//        //self.audioEngine = AudioEngine()
//        guard let engine = self.audioEngine else {
//            Logger.shared.reportError(self, "No engine")
//            return
//        }
//        guard let engineInput = engine.input else {
//            Logger.shared.reportError(self, "No input")
//            return
//        }
//        self.mic = engineInput
//        self.tappableNodeA = Fader(self.mic!)
//        self.silencer = Fader(tappableNodeA!, gain: 0)
//        ///If a node with an installed tap is not connected to the engine's output (directly or indirectly), the audio data will not flow through that node, and consequently, the tap closure will not be called.
//        engine.output = self.silencer
//
//        do {
//            let fader = self.tappableNodeA
//            //self.nodeRecorder = try NodeRecorder(node: self.mic!) //Does not work. Absolutley no idea why...
//            self.nodeRecorder = try NodeRecorder(node: fader!)
//            ///The recorded file is stored in the temporary directory of your app by default. This means that the file is placed in a location that can be cleared
//            ///by the system when the app is terminated or when storage space is needed.
//            if let recorder = self.nodeRecorder {
//                try engine.start()
//                try recorder.record()
//                Logger.shared.log(self, "Recording started: \(recorder.isRecording)")
//            }
//        } catch let err {
//            Logger.shared.reportError(self, "Recorder \(err.localizedDescription)")
//        }
//    }
    
    func stopListening() {
        for pitchTap in self.pitchTaps {
            pitchTap.stop()
        }
        if let recorder = self.nodeRecorder {
            recorder.stop()
            if let audioFile = recorder.audioFile {
                ScalesModel.shared.setRecordedAudioFile(recorder.audioFile)
                let log = "Stopped recording, len:\(audioFile.length) duration:\(audioFile.duration) recorded file: \(audioFile.url) "
                AppLogger.shared.log(self, log)
            } else {
                AppLogger.shared.reportError(self, "No audio file found after stopping recording")
            }
        }
        //audioEngine?.stop() NO 🥵
    }
    
    func setSession() {
        ///nightmare
        do {
            let audioSession = AVAudioSession.sharedInstance()
            //try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true) //EXTREME WARNING - without this death 😡
        }
        catch {
            AppLogger.shared.reportError(self, "Error setting audio session: \(error)")
        }
    }
    
    private func loadSampler(num:Int, preset:Int) -> MIDISampler? {
        do {
            let samplerFileName = num == 0 ? "Yamaha-Grand-Lite-SF-v1.1" : "david_ChateauGrand_polyphone"
            //let samplerFileName = num == 0 ? "UprightPianoKW" : "david_ChateauGrand_polyphone"
            let sampler = MIDISampler()
            try sampler.loadSoundFont(samplerFileName, preset: preset, bank: 0)
            AppLogger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
            return sampler
        }
        catch {
            AppLogger.shared.reportError(self, error.localizedDescription)
            return nil
        }
    }
    
//    func showPresets() {
//        let presetRange = 0..<128
//        for preset in presetRange {
//            do {
//                let samplerFileName = "Yamaha-Grand-Lite-SF-v1.1"
//                let sampler = MIDISampler()
//                try sampler.loadSoundFont(samplerFileName, preset: preset, bank: 0)
//                // Log the successfully loaded preset number
//                print("Loaded preset: \(preset) from sound font \(samplerFileName)")
//            } catch {
//                // If the preset can't be loaded, skip and continue
//                print("Preset \(preset) not found or failed to load.")
//            }
//        }
//    }
    
    ///Return a list of tap events recorded previously in a file
    func readTestDataFile() -> [TapEventSet] {
        
        //let scalesModel = ScalesModel.shared
        var tapEventSets:[TapEventSet] = []
        var tapNum = 0
        
        if let filePath = Bundle.main.path(forResource: "RecordedTapData", ofType: "txt") {
            let contents:String
            do {
                contents = try String(contentsOfFile: filePath, encoding: .utf8)
            }
            catch {
                AppLogger.shared.log(self, "cannot read file \(error.localizedDescription)")
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
                if line.starts(with: "--") {
                    if line.starts(with: "--TapSet") {
                        ///e.g. --TapSet BufferSize 4096
                        if let currentTapSet = currentTapSet {
                            tapEventSets.append(currentTapSet)
                            //let newTapSet = TapEventSet(bufferSize: lastBufferSize, events: [] )
                            //                        for tap in tapEvents {
                            //                            newTapSet.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: tap/, amplitude: <#Float#>))
                            //                        }
                            //tapEventSets.append(newTapSet)
                            AppLogger.shared.log(self, "Read \(currentTapSet.events.count) events from file for bufferSize:\(currentTapSet.bufferSize)")
                            //tapEvents = []
                            tapNum = 0
                        }
                        if i>=lines.count {
                            break
                        }
                        currentTapSet = TapEventSet(bufferSize: Int(fields[2]) ?? 0, events: [])
                    }
                    continue
                }
                
                let freq = fields[1].split(separator: ":")[1]
                let ampl = fields[2].split(separator: ":")[1]
                let f = Float(freq)
                let a = Float(ampl)
                if let f = f {
                    if let a = a {
                        currentTapSet?.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: f, amplitude: a, status: .none))
//                        currentTapSet.tapEvents.append(TapEvent(tapNum: tapNum, frequency: f, amplitude: a, ascending: true, status: .none,
//                                                  expectedMidis: [], midi: 0, tapMidi: 0, consecutiveCount: 1))
                        tapNum += 1
                    }
                }
            }
        }
        else {
            AppLogger.shared.reportError(self, "Cant open file bundle")
        }
        return tapEventSets
    }
    
    func playbackTapEvents(tapEventSets:[TapEventSet], tapHandlers:[TapHandlerProtocol]) {
        var tapHandlerIndex = 0
        for tapEventSet in tapEventSets {
            AppLogger.shared.log(self, "Start play back \(tapEventSet.events.count) tap events for bufferSize:\(tapEventSet.bufferSize)")
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
        AppLogger.shared.log(self, "Played back \(tapHandlerIndex) tap event sets")
        ScalesModel.shared.setRunningProcess(.none)
    }
    
    func installTapHandler(node:Node, tapHandler:AcousticSoundEventHandler, asynch : Bool) -> PitchTap {
        let installedTap = PitchTap(node, bufferSize:UInt32(tapHandler.getBufferSize())) { pitch, amplitude in
            if asynch {
                DispatchQueue.main.async {
                    tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
                }
            }
            else {
                tapHandler.tapUpdate([pitch[0], pitch[1]], [amplitude[0], amplitude[1]])
            }
        }
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
        if let sampler = samplerForKeyboard {
            sampler.play(noteNumber: MIDINoteNumber(keyNumber), velocity: 64, channel: 0)
        }
    }

    func pianoKeyUp(_ keyNumber: Int) {
        if let sampler = samplerForKeyboard {
            sampler.stop()
        }
    }
}
