import Foundation
import Speech
import Combine

enum AppMode {
    case practiceMode
    case resultMode
}

public class ScalesModel : ObservableObject {
    static public var shared = ScalesModel()
    var scale:Scale
    
    @Published var appMode:AppMode
    @Published var requiredStartAmplitude:Double? = nil
    @Published var amplitudeFilter:Double = 0.0
    @Published var recordingAvailable = false
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    @Published var recordingScale = false
    @Published var selectedDirection = 0
    var selectedTempoIndex = 4
    
    @Published var score:Score?
    var scoreHidden = false
    var recordedEvents:TapEvents? = nil
    var notesHidden = false
    
    //let pianoKeyboardModel = PianoKeyboardModel.shared
    
    let keyValues = ["C", "G", "D", "A", "E", "B", "", "F", "B♭", "E♭", "A♭", "D♭"]
    var selectedKey = Key(name: "C", keyType: .major) {
        didSet {
            stopAudioTasks()
        }
    }
    
    let scaleTypes = ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Arpeggio", "Chromatic"]
    
    var selectedScaleType = 0 {
        didSet {
            stopAudioTasks()
        }
    }
    var directionTypes = ["⬆", "⬇"]
    
    var handTypes = ["Right", "Left"]

    var tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120", "130", "140", "150", "160"]
    
    ///More than two cannot fit comforatably on screen. Keys are too narrow and score has too many ledger lines
    let octaveNumberValues = [1,2]
    var selectedOctavesIndex = 0 {
        didSet {stopAudioTasks()}
    }
    var selectedHandIndex = 0 

    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler:PitchTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
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
    
    var result:Result?
    
    init() {
        appMode = .practiceMode
        scale = Scale(key: Key(name: "C", keyType: .major), scaleType: .major, octaves: 1)
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
    
    func getTempo() -> Int {
        let selected = self.tempoSettings[self.selectedTempoIndex]
        return Int(selected) ?? 60
    }
    
    func setScore() {
        let keySig = self.selectedKey.keySignature
        let staffType:StaffType = self.selectedHandIndex == 0 ? .treble : .bass
        score = Score(key: StaffKey(type: .major,
                                    keySig: keySig),
                                    timeSignature: TimeSignature(top: 4, bottom: 4),
                                    linesPerStaff: 5)
        guard let score = score else {
            return
        }
        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
       
        for i in 0..<scale.scaleNoteState.count {
            if i % 4 == 0 && i > 0 {
                score.addBarLine()
            }
            let note = scale.scaleNoteState[i]
            let ts = score.createTimeSlice()
            ts.addNote(n: Note(timeSlice: ts, num: note.midi, value: Note.VALUE_QUARTER, staffNum: 0))
        }

    }
    
    func setAppMode(_ mode:AppMode, resetRecorded:Bool) {
        if mode == .practiceMode {
            self.startPracticeHandler()
        }
        else {
            self.stopPracticeHandler()
        }
        DispatchQueue.main.async {
            self.appMode = mode
        }
        if resetRecorded {
            self.recordedEvents = nil
            PianoKeyboardModel.shared.resetDisplayState()
        }
    }
        
    func forceRepaint() {
        DispatchQueue.main.async {
            self.forcePublish += 1
        }
    }
    
    private func stopAudioTasks() {
        if self.isPracticing {
            stopPracticeHandler()
        }
        if self.recordingScale {
            stopRecordingScale("Reset")
        }
        MetronomeModel.shared.stop()
        //audioManager.stopPlaySampleFile()
    }
    
    func setKey(index:Int) {
        let name = keyValues[index]
        self.selectedKey = Key(name: name, keyType: .major)
        setScore()
    }
    
    func setDirection(_ index:Int) {
        DispatchQueue.main.async {
            self.selectedDirection = index
            PianoKeyboardModel.shared.setFingers(direction: index)
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
    
    func setScale() {
        var scaleType:ScaleType = .major
        switch self.selectedScaleType {
        case 1:
            scaleType = .naturalMinor
        case 2:
            scaleType = .harmonicMinor
        case 3:
            scaleType = .melodicMinor
        default:
            scaleType = .major
        }
        self.scale = Scale(key: self.selectedKey,
                           scaleType: scaleType,
                           octaves: self.octaveNumberValues[self.selectedOctavesIndex])
        PianoKeyboardModel.shared.configureKeyboardSize()
        setScore()
    }

    func startPracticeHandler() {
        DispatchQueue.main.async {
            self.isPracticing = true
            self.scale.resetMatchedData()
//            PianoKeyboardModel.shared.resetDisplayState()
//            PianoKeyboardModel.shared.resetScaleMatchState()
        }
        let practiceTapHandler = PracticeTapHandler()
        self.audioManager.startRecordingMicrophone(tapHandler: practiceTapHandler, recordAudio: false)
    }

    func stopPracticeHandler() {
        Logger.shared.log(self, "Stop listening to microphone")
        DispatchQueue.main.async {
            self.isPracticing = false
            PianoKeyboardModel.shared.resetDisplayState()
        }
        audioManager.stopRecording()
    }
    
    func startRecordingScale(testData:Bool, onDone:@escaping ()->Void) {
        self.onRecordingDoneCallback = onDone
        guard let requiredAmplitude = self.requiredStartAmplitude else {
            onDone()
            return
        }
//        let delay = 2 * 1000000
//        usleep(useconds_t(delay))
        //MetronomeModel.shared.startTimer(notified: SpeechManager.shared, userScale: false, onDone: {
        MetronomeModel.shared.startTimer(notified: AudioManager.shared, userScale: false, onDone: {
            if self.speechListenMode {
                sleep(1)
                self.speechManager.speak("Please start your scale")
                sleep(2)
            }
            self.scale.resetMatchedData()
            PianoKeyboardModel.shared.resetScaleMatchState()
            PianoKeyboardModel.shared.resetDisplayState()
            Logger.shared.log(self, "Start recording scale")
            DispatchQueue.main.async {
                self.recordingAvailable = false
                self.recordingScale = true
            }
            let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: requiredAmplitude,
                                                  saveTappingToFile: ScalesModel.shared.recordDataMode,
                                                  scale:self.scale)
            if !testData {
                self.audioManager.startRecordingMicrophone(tapHandler: pitchTapHandler, recordAudio: true)
            }
            else {
                self.audioManager.readTestData(tapHandler: PitchTapHandler(requiredStartAmplitude:
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
//            self.speechManager.startAudioEngine()
//            self.speechManager.startSpeechRecognition()
            self.recordingAvailable = true
            self.recordingScale = false
            //if let file = self.audioManager.recorder?.audioFile {
                //}
                //else {
                    //Logger.shared.reportError(self, "Recorded file is zero length")
                //}
            //}
        }
        if let onDone = self.onRecordingDoneCallback {
            onDone()
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
