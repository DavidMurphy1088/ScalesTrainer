import Foundation
import AVFoundation
import Combine
import SwiftUI

///None -> user can see finger numbers and tap virtual keyboard - notes are hilighted if in scale
///Practice -> user can use acoustic piano. keyboard display same as .none
///assessWithScale -> acoustic piano, note played and unplayed in scale are marked. Result is gradable. Result is displayed

enum MicTappingMode {
    case off
    case onWithCallibration
    case onWithPractice
    case onWithRecordingScale
}

enum RunningProcess {
    case none
    case callibrating
    case followingScale
    case practicing
    case recordingScale
    case leadingIn
    case recordingScaleWithData
    //case identifyingScale
    case hearingRecording
    case playingAlongWithScale

    var description: String {
        switch self {
        case .none:
            return "None"
        case .callibrating:
            return "Calibrating"
        case .followingScale:
            return "Following Scale"
        case .practicing:
            return "Practicing"
        case .recordingScale:
            return "Recording Scale"
        case .recordingScaleWithData:
            return "Recording Scale With Data"
//        case .identifyingScale:
//            return "Identifying Scale"
        case .hearingRecording:
            return "Hearing Recording"
        case .playingAlongWithScale:
            return "Playing Along With Scale"
        case .leadingIn:
            return "Leading In"
        }
    }
}

public class ScalesModel : ObservableObject {
    static public var shared = ScalesModel()
    var scale:Scale
    
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    @Published var selectedDirection = 0
    
    @Published var score:Score?
    
    var scoreHidden = false
    var recordedTapEvents:TapEvents? = nil
    var recordedTapsFileURL:URL? //File where recorded taps were written
    
//    let scaleRootValues = ["C", "G", "D", "A", "E", "B", "", "F", "B♭", "E♭", "A♭", "D♭"]
//    var selectedScaleRootIndex = 0

//    var scaleTypeNames:[String] //= ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Major Arpeggio", "Minor Arpeggio", "Dominant Seventh Arpeggio", "Major Arpeggio""Chromatic"]
//    var selectedScaleTypeNameIndex = 0
    
    var scaleLeadInCounts:[String] = ["None", "One Bar", "Two Bars", "Four Bars"]
    
    var directionTypes = ["⬆", "⬇"]
    var selectedHandIndex = 0
    
    var handTypes = ["Right", "Left"]

    var tempoSettings = ["♩=40", "♩=50", "♩=60", "♩=70", "♩=80", "♩=90", "♩=100", "♩=110", "♩=120", "♩=130", "♩=140", "♩=150", "♩=160"]
    var selectedTempoIndex = 5 //60=2
        
    ///More than two cannot fit comforatably on screen. Keys are too narrow and score has too many ledger lines
    let octaveNumberValues = [1,2,3,4]
    var selectedOctavesIndex = 0
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler:ScaleTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    var helpTopic:String? = nil
    var onRecordingDoneCallback:(()->Void)?
    
    ///Speech
    @Published var speechListenMode = false
    @Published var speechLastWord = ""

    @Published private(set) var result:Result?
    func setResult(_ result:Result?) {
        DispatchQueue.main.async {
            self.result = result
        }
    }

    @Published private(set) var processInstructions:String? = nil
    func setProcessInstructions(_ msg:String?) {
        DispatchQueue.main.async {
            self.processInstructions = msg
        }
    }
    
    @Published private(set) var showStaff = false
    func setShowStaff(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showStaff = newValue
        }
    }
    
    @Published private(set) var showFingers = true
    func setShowFingers(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showFingers = newValue
        }
    }    
    
    @Published private(set) var userMessage:String? = nil
    func setUserMessage(_ newValue: String?) {
        DispatchQueue.main.async {
            self.userMessage = newValue
        }
    }
    
    @Published private(set) var showKeyboard:Bool = true
    func setShowKeyboard(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showKeyboard = newValue
        }
    }
    
    @Published private(set) var showParameters:Bool = true
    func setShowParameters(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showParameters = newValue
        }
    }
    
    @Published private(set) var showLegend:Bool = true
    func setShowLegend(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showLegend = newValue
        }
    }
    
    @Published private(set) var runningProcess:RunningProcess = .none
    
    @Published private(set) var recordedAudioFile:AVAudioFile?
    func setRecordedAudioFile(_ file: AVAudioFile?) {
        DispatchQueue.main.async {
            self.recordedAudioFile = file
        }
    }
    
    @Published private(set) var backingOn:Bool = false
    func setBacking(_ way:Bool) {
        let metronome = MetronomeModel.shared
        if way {
            metronome.startTimer(notified: Backer(), countAtQuaverRate: false, onDone: {
            })
        }
        else {
            metronome.stop()
        }
        DispatchQueue.main.async {
            self.backingOn = way
        }
    }
    
    func setRunningProcess(_ setProcess: RunningProcess) {
        Logger.shared.log(self, "Setting process ---> \(setProcess.description)")
        DispatchQueue.main.async {
            self.runningProcess = setProcess
        }
        self.audioManager.stopRecording()
        self.audioManager.resetAudioKitToMIDISampler()
        
        self.setShowKeyboard(true)
        self.setShowParameters(true)
        self.setShowLegend(true)
        self.setDirection(0)
        self.setProcessInstructions(nil)
        if result != nil {
            self.setShowStaff(true)
        }
        MetronomeModel.shared.isTiming = false
        
        Logger.shared.clearLog()
        
        let keyboard = PianoKeyboardModel.shared
        keyboard.clearAllFollowingKeyHilights(except: nil)
        PianoKeyboardModel.shared.redraw()
        
        if [.followingScale, .practicing, .callibrating].contains(setProcess)  {
            self.setResult(nil)
            let tapHandler = PracticeTapHandler(amplitudeFilter: setProcess == .callibrating ? 0 : Settings.shared.amplitudeFilter, hilightPlayingNotes: true)
            if setProcess == .followingScale {
                setShowKeyboard(true)
                ///Play first note only. Tried play all notes in scale but the app then listens to itself via the mic and responds to its own sounds
                ///Wait for note to die down otherwise it triggers the first note detection
                //DispatchQueue.main.async {
                    if self.scale.scaleNoteState.count > 0 {
                        if let sampler = self.audioManager.midiSampler {
                            let midi = UInt8(self.scale.scaleNoteState[0].midi)
                            sampler.play(noteNumber: midi, velocity: 64, channel: 0)
                            ///Without delay here the fist note wont hilight - no idea why
                            sleep(2)
                        }
                    }
                //}
            }
            self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: false)
            if setProcess == .followingScale {
                self.followScaleProcess(onDone: {cancelled in
                    self.setRunningProcess(.none)
                })
            }
        }
        
        if [RunningProcess.playingAlongWithScale].contains(setProcess)  {
            let metronome = MetronomeModel.shared
            metronome.isTiming = true
            DispatchQueue.main.async {
                self.runningProcess = .leadingIn
            }
            doLeadIn(instruction: "Play along with the scale", leadInDone: {
                DispatchQueue.main.async {
                    self.runningProcess = .playingAlongWithScale
                }
                metronome.startTimer(notified: HearScalePlayer(), countAtQuaverRate: false, onDone: {
                })
            })
        }
        
        if [RunningProcess.hearingRecording].contains(setProcess)  {
            let metronome = MetronomeModel.shared
            metronome.startTimer(notified: HearUserScale(), countAtQuaverRate: false, onDone: {
                self.setRunningProcess(.none)
            })
        }

        if [RunningProcess.recordingScale, RunningProcess.recordingScaleWithData].contains(setProcess)  {
            keyboard.resetKeysWerePlayedState()
            self.scale.resetMatchedData()
            self.setShowKeyboard(false)
            self.setShowStaff(false)
            self.setShowParameters(false)
            self.setShowLegend(false)
            self.setResult(nil)
            self.setUserMessage(nil)
            //self.setShowFingers(false)
            keyboard.redraw()
            let tapHandler = ScaleTapHandler(amplitudeFilter: Settings.shared.amplitudeFilter, hilightPlayingNotes: false)
            if setProcess == .recordingScaleWithData {
                self.audioManager.readTestData(tapHandler: tapHandler)
            }
            else {
                DispatchQueue.main.async {
                    self.runningProcess = .leadingIn
                }
                doLeadIn(instruction: "Record your scale", leadInDone: {
                    //😡😡😡😡😡😡 cannot record and tap concurrenlty
                    //self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: true)
                    DispatchQueue.main.async {
                        self.runningProcess = RunningProcess.recordingScale
                    }
                    self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: false)
                })
            }
        }

        //PianoKeyboardModel.shared.debug("END Setting process ---> \(setProcess.description)")
    }

    func doLeadIn(instruction:String, leadInDone:@escaping ()->Void) {
        let scaleLeadIn = ScaleLeadIn()
        if Settings.shared.scaleLeadInBarCount > 0 {
            ///Dont let the metronome ticks fire erroneous frequencies during the lead-in.
            audioManager.blockTaps = true
            self.setProcessInstructions(scaleLeadIn.getInstructions())
            MetronomeModel.shared.startTimer(notified: scaleLeadIn, countAtQuaverRate: false, onDone: {                self.setProcessInstructions(instruction)
                self.audioManager.blockTaps = false
                leadInDone()
            })
        }
        else {
            leadInDone()
            self.setProcessInstructions("Start recording your scale")
        }
        
    }
    
    init() {
        //scaleTypeNames = ["Major", "Minor", "Harmonic Minor", "Melodic Minor"]
        //scaleTypeNames.append(["Major Arpeggio", "Minor Arpeggio", "Dominant Seventh Arpeggio", "Major Arpeggio", "Chromatic"])
        //scaleTypeNames.append(contentsOf: ["Major Arpeggio", "Minor Arpeggio", "Diminished Arpeggio"])
        //scaleTypeNames.append(contentsOf: ["Dominant Seventh Arpeggio", "Major Seventh Arpeggio", "Minor Seventh Arpeggio", "Diminished Seventh Arpeggio", "Half Diminished Arpeggio"])
        //scaleTypeNames.append(contentsOf: ["Chromatic"])

        scale = Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, octaves: 1, hand: 0)
        DispatchQueue.main.async {
            PianoKeyboardModel.shared.configureKeyboardSize()
        }

        self.callibrationTapHandler = nil
    }
    
    ///Return the color a keyboard note should display its status as. Clear -> dont show anything
    func getKeyStatusColor(_ keyModel:PianoKeyModel) -> Color {
        guard let result = self.result else {
            return Color.clear
        }
        guard result.runningProcess != .followingScale else {
            return Color.clear
        }
        var color:Color
        let fullOpacity = 0.4
        let halfOpacity = 0.4
        if keyModel.scaleNoteState != nil {
            ///Key is in the scale
            if selectedDirection == 0 {
                color = keyModel.keyWasPlayedState.tappedTimeAscending == nil ? Color.yellow.opacity(fullOpacity) :  Color.green.opacity(halfOpacity)
            }
            else {
                color = keyModel.keyWasPlayedState.tappedTimeDescending == nil ? Color.yellow.opacity(halfOpacity) :  Color.green.opacity(halfOpacity)
            }
        }
        else {
            ///Key was not in the scale
            if selectedDirection == 0 {
                color = keyModel.keyWasPlayedState.tappedTimeAscending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
            }
            else {
                color = keyModel.keyWasPlayedState.tappedTimeDescending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
            }
        }
        return color
    }
    
//    ///Allow the user to play along with the scale
//    func playAlongWithScaleProcess(onDone:((_ cancelled:Bool)->Void)?) {
//        HearScalePlayer()
//    }
    
    ///Allow user to follow notes hilighted on the keyboard
    ///Wait till user hits correct key before moving to and highlighting the next note
    func followScaleProcess(onDone:((_ cancelled:Bool)->Void)?) {
        DispatchQueue.global(qos: .background).async { [self] in
            let semaphore = DispatchSemaphore(value: 0)
            let keyboard = PianoKeyboardModel.shared
            var scaleIndex = 0
            var cancelled = false
            
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
                keyboard.clearAllFollowingKeyHilights(except: keyIndex)
                pianoKey.hilightFollowingKey = true
                keyboard.redraw()

                ///Listen for piano key pressed
                
                pianoKey.wasPlayedCallback = {
                    semaphore.signal()
                    keyboard.redraw()
                    pianoKey.wasPlayedCallback = nil
                }

                ///Listen for cancel activity
                DispatchQueue.global(qos: .background).async {
                    ///appmode is None at start since its set (for publish)  in main thread
                    while true {
                        sleep(1)
                        if self.runningProcess != .followingScale {
                            cancelled = true
                            break
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                if self.runningProcess != .followingScale {
                    break
                }
                
                ///Change direction
                let highest = self.scale.getMinMax().1
                if pianoKey.midi == highest {
                    self.setDirection(1)
                }
                if scaleIndex > self.scale.scaleNoteState.count - 1 {
                    break
                }
                scaleIndex += 1
            }
            self.audioManager.stopRecording()
            if !cancelled {
//                let result = Result(runningProcess: .followingScale, userMessage: cancelled ? "Cancelled" : "😊 Good job 😊")
//                ///Follow mode should not make a right/wrong result. It has
//                //result.buildResult()
//                self.setResult(result)
                ScalesModel.shared.setUserMessage("😊 Good job following the scale 😊")
            }

            if let onDone = onDone {
                onDone(cancelled)
            }
        }
    }
    
    ///Get tempo for 1/4 note
    func getTempo() -> Int {
        var selected = self.tempoSettings[self.selectedTempoIndex]
        selected = String(selected.dropFirst(2))
        return Int(selected) ?? 60
    }
    
    func createScore(scale:Scale) -> Score {
        let staffType:StaffType = self.selectedHandIndex == 0 ? .treble : .bass
        let staffKeyType:StaffKey.StaffKeyType = [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh, .chromatic].contains(scale.scaleType) ? .major : .minor
        let keySignature = KeySignature(keyName: scale.scaleRoot.name, keyType: staffKeyType)
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)
        let score = Score(key: staffKey, timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)

        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
        var inBarCount = 0
        var lastNote:StaffNote?
        
        for i in 0..<scale.scaleNoteState.count {
            if i % 4 == 0 && i > 0 {
                score.addBarLine()
                inBarCount = 0
            }
            let noteState = scale.scaleNoteState[i]
            let ts = score.createTimeSlice()
            let note = StaffNote(timeSlice: ts, num: noteState.midi, value: StaffNote.VALUE_QUARTER, staffNum: 0)
//            if showTempoVariation {
//                note.valueNormalized = noteState.valueNormalized
//            }
//            else {
//                note.valueNormalized = nil
//            }
            //note.setValue(value: 0.5)
            note.setValue(value: 1.0)
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
        //score.debugScore11("END CREATE SCORE", withBeam: false, toleranceLevel: 0)
        return score
    }
    
    func setKeyAndScale(scaleRoot: ScaleRoot, scaleType:ScaleType, octaves:Int, hand:Int) {
        let name = scaleRoot.name //self.scaleRootValues[self.selectedScaleRootIndex]
        let scaleTypeName = scaleType.description //self.scaleTypeNames[self.selectedScaleTypeNameIndex]
        self.scale = Scale(scaleRoot: ScaleRoot(name: name),
                           scaleType: Scale.getScaleType(name: scaleTypeName),
                           octaves: octaves, //self.octaveNumberValues[self.selectedOctavesIndex],
                           hand: hand) //self.selectedHandIndex)
        //self.scale.debug111("========== ScalesModel")
        
        PianoKeyboardModel.shared.configureKeyboardSize()
        setDirection(0)

        PianoKeyboardModel.shared.redraw()
        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.score = self.createScore(scale: self.scale)
                //self.score?.debugScore111("======END ScalesModel.setKeyAndScale type:\(scaleType) HAND:\(hand)", withBeam: false, toleranceLevel: 0)
            }
        }
    }

//    func stopRecordingScale(_ ctx:String) {
//        let duration = self.audioManager.microphoneRecorder?.recordedDuration
//        Logger.shared.log(self, "Stop recording scale, duration:\(String(describing: duration)), ctx:\(ctx)")
//        audioManager.stopRecording()
//        DispatchQueue.main.async { [self] in
//            //self.recordingAvailable = true
//            setRunningProcess(.none)
//        }
//        if let onDone = self.onRecordingDoneCallback {
//            onDone()
//        }
//    }
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
            PianoKeyboardModel.shared.linkScaleFingersToKeyboardKeys(direction: index)
        }
    }
    
    func setTempo(_ index:Int) {
        //DispatchQueue.main.async {
            self.selectedTempoIndex = index
            //PianoKeyboardModel.shared.setFingers(direction: index)
        //}
    }
    
//    func setSpeechListenMode(_ way:Bool) {
//        DispatchQueue.main.async {
//            self.speechListenMode = way
//            if way {
//                self.speechManager.speak("Hello")
//                sleep(2)
//                if !self.speechManager.isRunning {
//                    self.speechManager.startAudioEngine()
//                    self.speechManager.startSpeechRecognition()
//                }
//            }
//            else {
//                self.speechManager.stopAudioEngine()
//            }
//        }
//    }
    
//    func processSpeech(speech: String) {
//        let words = speech.split(separator: " ")
//        guard words.count > 0 else {
//            return
//        }
//        speechCommandsReceived += 1
//        let m = "Process speech. commandCtr:\(speechCommandsReceived) Words:\(words)"
//        logger.log(self, m)
//        if words[0].uppercased() == "START" {
//            speechManager.stopAudioEngine()
//        }
//        DispatchQueue.main.async {
//            self.speechLastWord = String(words[0])
//            self.speechManager.stopAudioEngine()
//            self.speechManager.startAudioEngine()
//            self.speechManager.startSpeechRecognition()
//        }
//    }
    
    func calculateCallibration() {
        guard let events = self.recordedTapEvents else {
            Logger.shared.reportError(self, "No events")
            return
        }
        var amplitudes:[Float] = []
        for event in events.events {
            let amplitude = Float(event.amplitude)
            amplitudes.append(amplitude)
        }
        let n = 8
        guard amplitudes.count >= n else {
            Logger.shared.reportError(self, "Callibration amplitudes must contain at least \(n) elements.")
            return
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        Settings.shared.amplitudeFilter = avgAmplitude
        Settings.shared.save()
    }

}
