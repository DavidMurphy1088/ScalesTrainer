import Foundation
import Speech
import Combine

///None -> user can see finger numbers and tap virtual keyboard - notes are hilighted if in scale
///Practice -> user can use acoustic piano. keyboard display same as .none
///assessWithScale -> acoustic piano, note played and unplayed in scale are marked. Result is gradable. Result is displayed

enum AppMode {
    case none
    case practiceMode
    case scaleFollow
    case assessWithScale
}

public class ScalesModel : ObservableObject {
    static public var shared = ScalesModel()
    var scale:Scale
    
    @Published var appMode:AppMode
    @Published var requiredStartAmplitude:Double? = nil
    @Published var amplitudeFilter:Double = 0.0
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    @Published var recordingScale = false
    @Published var selectedDirection = 0
    var selectedTempoIndex = 2
    
    @Published var score:Score?
    var scoreHidden = false
    var recordedEvents:TapEvents? = nil
    var staffHidden = false
    var recordedTapsFileURL:URL? //File where recorded taps were written
    
    //let pianoKeyboardModel = PianoKeyboardModel.shared
    
    let keyNameValues = ["C", "G", "D", "A", "E", "B", "", "F", "B♭", "E♭", "A♭", "D♭"]
    var selectedKeyNameIndex = 0
    //var selectedKey = Key(name: "C", keyType: .major)

    let scaleTypeNames = ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Arpeggio", "Chromatic"]
    var selectedScaleTypeNameIndex = 0
    
    var directionTypes = ["⬆", "⬇"]
    
    var handTypes = ["Right", "Left"]

    var tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120"]
    var selectedHandIndex = 0
    
    ///More than two cannot fit comforatably on screen. Keys are too narrow and score has too many ledger lines
    let octaveNumberValues = [1,2,3,4]
    var selectedOctavesIndex = 0
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler:ScaleTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    var recordDataMode = true
    var onRecordingDoneCallback:(()->Void)?
    
    ///Speech
    @Published var speechListenMode = false
    @Published var speechLastWord = ""
    let speechManager = SpeechManager.shared
    var speechWords:[String] = []
    var speechCommandsReceived = 0
    
    @Published var result:Result?
    
    init() {
        appMode = .none
        scale = Scale(key: Key(name: "C", keyType: .major), scaleType: .major, octaves: 1, hand: 0)
        DispatchQueue.main.async {
            PianoKeyboardModel.shared.configureKeyboardSize()
        }
        var value = UserDefaults.standard.double(forKey: "requiredStartAmplitude")
        if value > 0 {
            self.requiredStartAmplitude = value
        }
        value = UserDefaults.standard.double(forKey: "amplitudeFilter")
        if value > 0 {
            self.amplitudeFilter = value
        }
        self.callibrationTapHandler = nil
    }
    
    func scaleFollow() {
        DispatchQueue.global(qos: .background).async {
            ///Play first note only. Tried play all notes in scale but the app then listens to itself via the mic and responds to its own sounds
            if self.scale.scaleNoteState.count > 0 {
                self.audioManager.midiSampler.play(noteNumber: UInt8(self.scale.scaleNoteState[0].midi), velocity: 64, channel: 0)
                sleep(1)
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            let keyboard = PianoKeyboardModel.shared
            var scaleIndex = 0
            while true {
                if scaleIndex >= self.scale.scaleNoteState.count {
                    break
                }
                let note = self.scale.scaleNoteState[scaleIndex]
                guard let keyIndex = keyboard.getKeyIndexForMidi(midi:note.midi, direction:0) else {
                    scaleIndex += 1
                    continue
                }
                let pianoKey = keyboard.pianoKeyModel[keyIndex]
                pianoKey.hilightKey = true

                ///Listen for piano key pressed
                keyboard.clearAllKeyHilights(except: keyIndex)
                pianoKey.callback = {
                    semaphore.signal()
                    keyboard.redraw()
                    pianoKey.callback = nil
                }

                ///Listen for cancel activity
                DispatchQueue.global(qos: .background).async {
                    ///appmode is None at start since its set (for publish)  in main thread
                    while true {
                        sleep(1)
                        if self.appMode != .scaleFollow {
                            break
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                
                ///Change direction
                let highest = self.scale.getMinMax().1
                if pianoKey.midi == highest {
                    self.setDirection(1)
                }
                scaleIndex += 1
//                if scaleIndex > 2 {
//                    break
//                }
            }
            self.setAppMode(.none, "endOfFollow")
            DispatchQueue.main.async {
                self.result = Result(type: .scaleFollow)
                keyboard.clearAllKeyHilights(except: nil)
            }
        }
    }
    
    func setAppMode(_ mode:AppMode, _ ctx:String) {
        Logger.shared.log(self, "Set app mode ctx:\(ctx) mode:\(mode)")
        //self.appMode = mode
        self.audioManager.stopRecording()
        
        if mode == AppMode.practiceMode || mode == AppMode.scaleFollow {
            self.recordedEvents = nil
            DispatchQueue.main.async {
                ScalesModel.shared.result = nil
            }
            let practiceTapHandler = PracticeTapHandler()
            self.audioManager.startRecordingMicrophone(tapHandler: practiceTapHandler, recordAudio: false)
        }
        
        DispatchQueue.main.async {
            self.appMode = mode
            if let score = self.score {
                DispatchQueue.main.async {
                    score.resetTapToValueRatios()
                    self.setScore()
                }
            }
            self.scale.resetMatchedData()
            let keyboard = PianoKeyboardModel.shared
            keyboard.resetScaleMatchState()
            keyboard.clearAllKeyHilights(except: nil)
            self.setDirection(0)
            PianoKeyboardModel.shared.redraw()
            if mode == .scaleFollow {
                self.scaleFollow()
            }
        }
    }
    
    func getTempo() -> Int {
        let selected = self.tempoSettings[self.selectedTempoIndex]
        return Int(selected) ?? 60
    }
    
    func setScore() {
        let staffType:StaffType = self.selectedHandIndex == 0 ? .treble : .bass
        let staffKeyType:StaffKey.KeyType = scale.key.keyType == .major ? .major : .minor
        let keyName = scale.key.name
        let keySignature = KeySignature(keyName: keyName, keyType: staffKeyType)
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)
        score = Score(key: staffKey, timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
        
        guard let score = score else {
            return
        }
        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
        var inBarCount = 0
        var lastNote:Note?
        
        for i in 0..<scale.scaleNoteState.count {
            if i % 8 == 0 && i > 0 {
                score.addBarLine()
                inBarCount = 0
            }
            let noteState = scale.scaleNoteState[i]
            let ts = score.createTimeSlice()
            let note = Note(timeSlice: ts, num: noteState.midi, value: Note.VALUE_QUARTER, staffNum: 0)
            note.setValue(value: 0.5)
            ts.addNote(n: note)
            inBarCount += 1
            lastNote = note
        }
        if let lastNote = lastNote {
            if inBarCount == 3 {
                lastNote.setValue(value: 2)
            }
            if inBarCount == 1 {
                lastNote.setValue(value: 4)
            }
        }
    }
    
    func setKeyAndScale() {
        let name = self.keyNameValues[self.selectedKeyNameIndex]
        let scaleTypeName = self.scaleTypeNames[self.selectedScaleTypeNameIndex]
        let keyType:KeyType = scaleTypeName.range(of: "minor", options: .caseInsensitive) == nil ? .major : .minor
        self.scale = Scale(key: Key(name: name, keyType: keyType),
                           scaleType: Scale.getScaleType(name: scaleTypeName),
                           octaves: self.octaveNumberValues[self.selectedOctavesIndex],
                           hand: self.selectedHandIndex)
        //self.scale.debug("")
        
        PianoKeyboardModel.shared.configureKeyboardSize()
        setDirection(0)

        PianoKeyboardModel.shared.redraw()
        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.setScore()
            }
        }
    }

    
    func startRecordingScale(testData:Bool, onDone:@escaping ()->Void) {
        self.onRecordingDoneCallback = onDone
        guard let requiredAmplitude = self.requiredStartAmplitude else {
            onDone()
            return
        }

        MetronomeModel.shared.startTimer(notified: AudioManager.shared, onDone: {
            if self.speechListenMode {
                sleep(1)
                self.speechManager.speak("Please start your scale")
                sleep(2)
            }
            self.scale.resetMatchedData()
            PianoKeyboardModel.shared.resetScaleMatchState()
            PianoKeyboardModel.shared.resetKeyDownKeyUpState()
            Logger.shared.log(self, "Start recording scale")
            DispatchQueue.main.async {
                //self.recordingAvailable = false
                self.recordingScale = true
            }
            let pitchTapHandler = ScaleTapHandler(requiredStartAmplitude: requiredAmplitude,
                                                  saveTappingToFile: ScalesModel.shared.recordDataMode,
                                                  scale:self.scale)
            if !testData {
                self.audioManager.startRecordingMicrophone(tapHandler: pitchTapHandler, recordAudio: true)
            }
            else {
                self.audioManager.readTestData(tapHandler: ScaleTapHandler(requiredStartAmplitude:
                                                                            self.requiredStartAmplitude ?? 0,
                                                                        saveTappingToFile: false,
                                                                           scale: self.scale))
            }
        })
    }
    
    func stopRecordingScale(_ ctx:String) {
        let duration = self.audioManager.microphoneRecorder?.recordedDuration
        Logger.shared.log(self, "Stop recording scale, duration:\(String(describing: duration)), ctx:\(ctx)")
        audioManager.stopRecording()
        DispatchQueue.main.async {
            //self.recordingAvailable = true
            self.recordingScale = false
        }
        if let onDone = self.onRecordingDoneCallback {
            onDone()
        }
    }
    ///Place either the given or the students scale into the score.
    ///For the student score hilight notes that are not in the scale.
//    func placeScaleInScore(useGiven:Bool = true) {
//        guard let score = self.score else {
//            return
//        }
//        score.clear()
//        if useGiven {
//            setScore()
//            return
//        }
//        
//        let piano = PianoKeyboardModel.shared
//        var noteCount = 0
//        
//        for direction in [0,1] {
//            piano.mapScaleFingersToKeyboard(direction: direction)
//            var start:Int
//            var end:Int
//            if direction == 0 {
//                start = 0
//                end = piano.pianoKeyModel.count - 1
//            }
//            else {
//                start = piano.pianoKeyModel.count - 2
//                end = 0
//            }
//            
//            for i in stride(from: start, through: end, by: direction == 0 ? 1 : -1) {
//                let key = piano.pianoKeyModel[i]
//                if direction == 0 {
//                    if key.keyClickedState.tappedTimeAscending == nil {
//                        continue
//                    }
//                }
//                if direction == 1 {
//                    if key.keyClickedState.tappedTimeDescending == nil {
//                        continue
//                    }
//                }
//                if noteCount > 0 && noteCount % 8 == 0 {
//                    score.addBarLine()
//                }
//                let ts = score.createTimeSlice()
//                let note = Note(timeSlice: ts, num: key.midi, staffNum: 0)
//                note.setValue(value: 0.5)
//                ts.addNote(n: note)
//                if key.scaleNoteState == nil {
//                    ts.setStatusTag(.pitchError)
//                }
//                noteCount += 1
//            }
//        }
//        piano.mapScaleFingersToKeyboard(direction: 0)
//    }
//    
    func forceRepaint() {
        DispatchQueue.main.async {
            self.forcePublish += 1
        }
    }
        
    func setDirection(_ index:Int) {
        DispatchQueue.main.async {
            self.selectedDirection = index
            PianoKeyboardModel.shared.mapScaleFingersToKeyboard(direction: index)
        }
    }
    
    func setTempo(_ index:Int) {
        //DispatchQueue.main.async {
            self.selectedTempoIndex = index
            //PianoKeyboardModel.shared.setFingers(direction: index)
        //}
    }

    func setRecordDataMode(_ way:Bool) {
        self.recordDataMode = way
    }
    
    func setSpeechListenMode(_ way:Bool) {
        DispatchQueue.main.async {
            self.speechListenMode = way
            if way {
                self.speechManager.speak("Hello")
                sleep(2)
                if !self.speechManager.isRunning {
                    self.speechManager.startAudioEngine()
                    self.speechManager.startSpeechRecognition()
                }
            }
            else {
                self.speechManager.stopAudioEngine()
            }
        }
    }
    
    func processSpeech(speech: String) {
        let words = speech.split(separator: " ")
        guard words.count > 0 else {
            return
        }
        speechCommandsReceived += 1
        let m = "Process speech. commandCtr:\(speechCommandsReceived) Words:\(words)"
        logger.log(self, m)
        if words[0].uppercased() == "START" {
            speechManager.stopAudioEngine()
            startRecordingScale(testData: false, onDone: {})
        }
        DispatchQueue.main.async {
            self.speechLastWord = String(words[0])
            self.speechManager.stopAudioEngine()
            self.speechManager.startAudioEngine()
            self.speechManager.startSpeechRecognition()
        }
    }
    
    func doCallibration(type:CallibrationType, amplitudes:[Float]) {
        let n = 4
        guard amplitudes.count >= n else {
            Logger.shared.log(self, "Callibration amplitudes must contain at least \(n) elements.")
            return
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        
        DispatchQueue.main.async {
            if type == .amplitudeFilter {
                self.amplitudeFilter = avgAmplitude
            }
            else {
                self.requiredStartAmplitude = avgAmplitude
            }
            self.saveSetting(type: type, value: avgAmplitude)
        }
    }
        
    func saveSetting(type:CallibrationType, value:Double) {
        let key = type == .startAmplitude ? "requiredStartAmplitude" : "amplitudeFilter"
        UserDefaults.standard.set(value, forKey: key)
    }
}
