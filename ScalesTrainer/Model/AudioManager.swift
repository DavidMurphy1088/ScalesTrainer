import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import AudioKitEX
import AudioToolbox

import AudioKit
import AVFoundation

class AudioManager {
    ///See https://musical-artifacts.com/artifacts?utf8=%E2%9C%93&q=Logic+Pro+Steinway+D
    //let samplerFileName = num == 0 ? "UprightPianoKW" : "david_ChateauGrand_polyphone"
    //let samplerFileName = num == 0 ? "Yamaha-Grand-Lite-SF-v1.1" : "david_ChateauGrand_polyphone"
    //static let samplerFileName = "NEW_Timbres of Heaven" ///‼️ B and B♭ sound wrong - an octave too low. Bad for piano preset 0
    //static let samplerFileName = "NEW_FluidR3_GM" ///🟢 22Sep25 Claude recommended best for mix of instruments
    static let keyboardSamplerFileName = "Steinway_D" ///🟢 22Sep25 Claude recommended best for piano
    //static let backingSamplerFileName = "FluidR3_GM" ///🟢 22Sep25 Claude recommended best for multiple instruments
    static let backingSamplerFileName = "FluidGM_Bank_0"
    
    static let shared = AudioManager()
    private var audioEngine: AudioEngine?
    
    private var samplerForKeyboard:MIDISampler?
    private var samplerForBacking:MIDISampler?
    private var mixer:Mixer?
    private var mic:AudioEngine.InputNode? = nil
    var backingInstrumentNumber = 0 //Sampler sound preset number for backing
    
    ///AudioKit Cookbook example
    private var pitchTaps: [PitchTap] = []
    private var tappableNodeA: Fader?
//    private var tappableNodeB: Fader?
//    private var tappableNodeC: Fader?
//    private var tappableNodeD: Fader?
//    private var tappableNodeE: Fader?
//    private var tappableNodeF: Fader?
    private var silencer: Fader?
    
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
                guard let audioEngine = self.audioEngine else {
                    AppLogger.shared.reportError(self, "No audio engine")
                    return
                }
                
                self.samplerForKeyboard = MIDISampler()
                //let preset = 2 ///Yamaha-Grand-Lite-SF-v1.1 has three presets and Polyphone list bright =1 , dark = 2, grandpiano = 0
                let preset = 0  ///NEW_Timbres of Heaven
                self.samplerForKeyboard = loadSampler(forKeyboard: true, preset: preset)
                //var backingInstrument = 2
//                switch self.backingInstrumentNumber {
//                    case 1: backingInstrument = 28
//                    case 2: backingInstrument = 37
//                    case 3: backingInstrument = 49
//                    case 4: backingInstrument = 33
//                    case 5: backingInstrument = 39
//                    case 6: backingInstrument = 43
//                    case 7: backingInstrument = 2
//                    case 8: backingInstrument = 4
//                    default: backingInstrument = 0
//                }
                self.samplerForBacking = loadSampler(forKeyboard: false, preset: self.backingInstrumentNumber)
                
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
                
                audioEngine.output = self.mixer
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
        
        if let audioEngine = self.audioEngine {
            do {
                ///As per the order in Cookbook Recorder example
                try audioEngine.start()
                if recordAudio {
                    try self.nodeRecorder?.record()
                }
            }
            catch {
                AppLogger.shared.reportError(self, "Error starting engine: \(error)")
            }
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
    
    private func loadSampler(forKeyboard:Bool, preset:Int) -> MIDISampler? {
        do {
            let sampler = MIDISampler()
            let fileName = forKeyboard ? AudioManager.keyboardSamplerFileName : AudioManager.backingSamplerFileName
            try sampler.loadSoundFont(fileName, preset: preset, bank: 0)
            AppLogger.shared.log(self, "midiSampler loaded sound font:\(fileName) forKeyboard:\(forKeyboard)")
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
    
//    func playbackTapEvents(tapEventSets:[TapEventSet], tapHandlers:[TapHandlerProtocol]) {
//        var tapHandlerIndex = 0
//        for tapEventSet in tapEventSets {
//            AppLogger.shared.log(self, "Start play back \(tapEventSet.events.count) tap events for bufferSize:\(tapEventSet.bufferSize)")
//            for tIndex in 0..<tapEventSet.events.count {
//                let tapEvent = tapEventSet.events[tIndex]
//                let f:AUValue = tapEvent.frequency
//                let a:AUValue = tapEvent.amplitude
//                tapHandlers[tapHandlerIndex].tapUpdate([f, f], [a, a])
//            }
//            tapHandlerIndex += 1
//            if tapHandlerIndex >= tapHandlers.count {
//                break
//            }
//        }
//
////        let events = tapHandlers[0].stopTappingProcess("AudioMgr.playbackEvents")
////        ScalesModel.shared.setTapHandlerEventSet(events, publish: true) ///WARNING😡😡😡😡😡😡 - off breaks READ_TEST_DATA (AT LEAST), ON breaks callibration
//        AppLogger.shared.log(self, "Played back \(tapHandlerIndex) tap event sets")
//        ScalesModel.shared.setRunningProcess(.none)
//    }
    
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
            print("============== Sampler 🟢 key:\(keyNumber) midi:\(MIDINoteNumber(keyNumber))")
        }
    }

    func pianoKeyUp(_ keyNumber: Int) {
        if let sampler = samplerForKeyboard {
            sampler.stop()
        }
    }
}
