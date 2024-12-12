import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
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

    var nodeRecorder: NodeRecorder?
    var fader:Fader?
    var mic:AudioEngine.InputNode? = nil
    var recordedFileSequenceNum = 0
    var blockTaps = false
    var audioPlayer:AudioPlayer?
    
    ///AudioKit Cookbook example
    var pitchTaps: [PitchTap] = []
    var tappableNodeA: Fader?
    var tappableNodeB: Fader?
    var tappableNodeC: Fader?
    var tappableNodeD: Fader?
    var tappableNodeE: Fader?
    var tappableNodeF: Fader?
    var silencer: Fader?

    init() {
        ///Enable just midi at app start, other more complex audio configs will be made depending on user actions (like recording)
        initAudioKit()
    }
    func getSamplerForKeyboard() -> MIDISampler? {
        return self.samplerForKeyboard
    }
    func getSamplerForBacking() -> MIDISampler? {
        return self.samplerForKeyboard
    }

    private func initAudioKit() {
        do {
            if self.audioEngine != nil {
                return
            }
            self.audioEngine = AudioEngine()
            guard let engine = self.audioEngine else {
                Logger.shared.reportError(self, "No engine")
                return
            }
            
            self.samplerForKeyboard = MIDISampler()
            var preset = 2 ///Yamaha-Grand-Lite-SF-v1.1 has three presets and Polyphone list bright =1 , dark = 2, grandpiano = 0
            self.samplerForKeyboard = loadSampler(num: 0, preset: preset)
            
            switch Settings.shared.backingSamplerPreset {
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
            self.samplerForBacking = loadSampler(num: 1, preset: preset)

            self.mixer = Mixer()
            self.mixer!.addInput(samplerForKeyboard!)
            self.mixer!.addInput(samplerForBacking!)
            engine.output = self.mixer
            
            try engine.start()
            Logger.shared.log(self, "Started audio engine")
        } catch {
            Logger.shared.reportError(self, "Can't setup AudioKit \(error)")
        }
    }
    
//    func resetAudioKitOld() {
//        if let sampler = self.samplerForKeyboard {
//            sampler.stop()
//        }
//        
//        setSession()
//        if self.audioEngine == nil {
//            ///Dont create a new engine every time. If every time at least process crashes - stopping a 'Follow the Scale' prematurely
//            self.audioEngine = AudioEngine()
//        }
//        else {
//            audioEngine!.stop() ///NO 👹
//        }
//        guard let engine = self.audioEngine else {
//            Logger.shared.reportError(self, "No engine")
//            return
//        }
//        var preset = 2 ///Yamaha-Grand-Lite-SF-v1.1 has three presets and Polyphone list bright =1 , dark = 2, grandpiano = 0
//        //if self.keyboardMidiSampler == nil {
//            self.samplerForKeyboard = loadSampler(num: 0, preset: preset)
//        //}
//        //let preset:Int
//        switch Settings.shared.backingSamplerPreset {
//        case 1: preset = 28
//        case 2: preset = 37
//        case 3: preset = 49
//        case 4: preset = 33
//        case 5: preset = 39
//        case 6: preset = 43
//        case 7: preset = 2
//        case 8: preset = 4
//        default: preset = 0
//        }
//        
//        if self.samplerForBacking == nil {
//            self.samplerForBacking = loadSampler(num: 1, preset: preset)
//        }
//
//        if self.mixer == nil {
//            self.mixer = Mixer()
//            if let sampler = self.samplerForKeyboard {
//                self.mixer!.addInput(sampler)
//            }
//            if let sampler = self.samplerForBacking {
//                self.mixer!.addInput(sampler)
//            }
//            engine.output = self.mixer
//        }
//        do {
//            try engine.start()
//        }
//        catch {
//            Logger.shared.reportError(self, "Error starting engine: \(error)")
//        }
//    }

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
        if let recorder = nodeRecorder {
            if let audioFile = recorder.audioFile {
                self.audioPlayer = AudioPlayer(file: audioFile)
                self.audioPlayer?.volume = 1.0  // Set volume to maximum
                audioEngine?.output = self.audioPlayer
                Logger.shared.log(self, "Recording Duration: \(recorder.audioFile?.duration ?? 0) seconds")
                audioPlayer?.completionHandler = {
                    //self.resetAudioKit()
                    DispatchQueue.main.async {
                        ScalesModel.shared.recordingIsPlaying = false
                    }
                }
                self.audioPlayer?.play()
                DispatchQueue.main.async {
                    ScalesModel.shared.recordingIsPlaying = true
                }
            }
        }
    }
    
    
    func startRecordingMicWithTapHandlers(soundEventHandlers:[SoundEventHandlerProtocol], recordAudio:Bool) {
        ///It appears that we cannot both record the mic and install a tap on it at the same time
        ///Error is reason: 'required condition is false: nullptr == Tap()' when the record starts.
        checkMicPermission(completion: {granted in
            if !granted {
                Logger.shared.reportError(self, "No microphone permission")
            }
        })
        setSession()
        
        ///Based on CookBook Tuner
        self.audioEngine = AudioEngine()
        guard let engine = self.audioEngine else {
            Logger.shared.reportError(self, "No engine")
            return
        }
        guard let engineInput = engine.input else {
            Logger.shared.reportError(self, "No input")
            return
        }

        self.mic = engineInput
        
        if true { 
            self.tappableNodeA = Fader(mic!)
            self.tappableNodeB = Fader(tappableNodeA!)
            self.tappableNodeC = Fader(tappableNodeB!)
            self.tappableNodeD = Fader(tappableNodeC!)
            self.tappableNodeE = Fader(tappableNodeD!)
            self.tappableNodeF = Fader(tappableNodeE!)
            self.silencer = Fader(tappableNodeF!, gain: 0)
            ///If a node with an installed tap is not connected to the engine's output (directly or indirectly), the audio data will not flow through that node, and consequently, the tap closure will not be called.
            engine.output = self.silencer
        }
        
        if soundEventHandlers.count > 4 {
            Logger.shared.reportError(self, "Too many pitch tap handlers to install \(soundEventHandlers.count)")
            return
        }
        self.pitchTaps.append(installTapHandler(node: self.tappableNodeA!,
                                                tapHandler: soundEventHandlers[0] as! AcousticSoundEventHandler,
                                                asynch: true))
//        if tapHandlers.count > 1 {
//            self.pitchTaps.append(installTapHandler(node: self.tappableNodeB!,
//                                                    tapHandler: tapHandlers[1],
//                                                    asynch: true))
//        }
//        if tapHandlers.count > 2 {
//            self.pitchTaps.append(installTapHandler(node: self.tappableNodeC!,
//                                                    tapHandler: tapHandlers[2],
//                                                    asynch: true))
//        }
//        if tapHandlers.count > 3 {
//            self.pitchTaps.append(installTapHandler(node: self.tappableNodeD!,
//                                                    tapHandler: tapHandlers[3],
//                                                    asynch: true))
//        }

        for tap in self.pitchTaps {
            tap.start()
        }
        
        do {
            ///As per the order in Cookbook Recorder example
            try engine.start()
        }
        catch {
            Logger.shared.reportError(self, "Error starting engine: \(error)")
        }
    }
    
    func startRecordingMicToRecord() {
        checkMicPermission(completion: {granted in
            if !granted {
                Logger.shared.reportError(self, "No microphone permission")
                return
            }
        })
        setSession()
        
        ///Based on CookBook Tuner
        self.audioEngine = AudioEngine()
        guard let engine = self.audioEngine else {
            Logger.shared.reportError(self, "No engine")
            return
        }
        guard let engineInput = engine.input else {
            Logger.shared.reportError(self, "No input")
            return
        }
        self.mic = engineInput
        self.tappableNodeA = Fader(self.mic!)
        self.silencer = Fader(tappableNodeA!, gain: 0)
        ///If a node with an installed tap is not connected to the engine's output (directly or indirectly), the audio data will not flow through that node, and consequently, the tap closure will not be called.
        engine.output = self.silencer

        do {
            let fader = self.tappableNodeA
            //self.nodeRecorder = try NodeRecorder(node: self.mic!) //Does not work. Absolutley no idea why...
            self.nodeRecorder = try NodeRecorder(node: fader!)
            ///The recorded file is stored in the temporary directory of your app by default. This means that the file is placed in a location that can be cleared
            ///by the system when the app is terminated or when storage space is needed.
            if let recorder = self.nodeRecorder {
                try engine.start()
                try recorder.record()
                Logger.shared.log(self, "Recording started: \(recorder.isRecording)")
            }
        } catch let err {
            Logger.shared.reportError(self, "Recorder \(err.localizedDescription)")
        }
    }
    
    func stopRecording() {
        for pitchTap in self.pitchTaps {
            pitchTap.stop()
        }
        if let recorder = nodeRecorder {
            recorder.stop()
            if let audioFile = recorder.audioFile {
                ScalesModel.shared.setRecordedAudioFile(recorder.audioFile)
                let log = "Stopped recording, len:\(audioFile.length) duration:\(audioFile.duration) recorded file: \(audioFile.url) "
                Logger.shared.log(self, log)
            } else {
                Logger.shared.reportError(self, "No audio file found after stopping recording")
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
            Logger.shared.reportError(self, "Error setting audio session: \(error)")
        }
    }
    
//    private func loadSampler() -> MIDISampler? {
//        do {
//            let samplerFileName = "Yamaha-Grand-Lite-SF-v1.1"
//            let sampler = MIDISampler()
//            let preset = 2 ///Yamaha-Grand-Lite-SF-v1.1 has three presets and Polyphone list bright =1 , dark = 2, grandpinao = 0
//            try sampler.loadSoundFont(samplerFileName, preset: preset, bank: 0)
//            //Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
//            //showPresets()
//            return sampler
//        }
//        catch {
//            Logger.shared.reportError(self, "loadSampler:"+error.localizedDescription)
//            return nil
//        }
//    }
    
    private func loadSampler(num:Int, preset:Int) -> MIDISampler? {
        do {
            let samplerFileName = num == 0 ? "Yamaha-Grand-Lite-SF-v1.1" : "david_ChateauGrand_polyphone"
            //let samplerFileName = num == 0 ? "UprightPianoKW" : "david_ChateauGrand_polyphone"
            let sampler = MIDISampler()
            try sampler.loadSoundFont(samplerFileName, preset: preset, bank: 0)
            Logger.shared.log(self, "midiSampler loaded sound font \(samplerFileName)")
            return sampler
        }
        catch {
            Logger.shared.reportError(self, error.localizedDescription)
            return nil
        }
    }
    
    func showPresets() {
        let presetRange = 0..<128
        for preset in presetRange {
            do {
                let samplerFileName = "Yamaha-Grand-Lite-SF-v1.1"
                let sampler = MIDISampler()
                try sampler.loadSoundFont(samplerFileName, preset: preset, bank: 0)
                // Log the successfully loaded preset number
                print("Loaded preset: \(preset) from sound font \(samplerFileName)")
            } catch {
                // If the preset can't be loaded, skip and continue
                print("Preset \(preset) not found or failed to load.")
            }
        }
    }
    
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
                            Logger.shared.log(self, "Read \(currentTapSet.events.count) events from file for bufferSize:\(currentTapSet.bufferSize)")
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
    
    func installTapHandler(node:Node, tapHandler:AcousticSoundEventHandler, asynch : Bool) -> PitchTap {
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
        //sampler.stopNote(UInt8(keyNumber), onChannel: 0)
        if let sampler = samplerForKeyboard {
            sampler.stop()
        }
    }
}
