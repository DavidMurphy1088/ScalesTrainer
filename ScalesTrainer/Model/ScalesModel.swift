import Foundation
import AVFoundation
import Combine
import SwiftUI

///None -> user can see finger numbers and tap virtual keyboard - notes are hilighted if in scale
///Practice -> user can use acoustic piano. keyboard display same as .none
///assessWithScale -> acoustic piano, note played and unplayed in scale are marked. Result is gradable. Result is displayed

enum MicTappingMode {
    case off
    case onWithCalibration
    case onWithPractice
    case onWithRecordingScale
}

enum RunningProcess {
    case none
    case followingScale
    case leadingTheScale
    case recordingScale
    case recordingScaleForAssessment
    //case metronomeOn
    case recordScaleWithFileData
    case syncRecording
    case playingAlongWithScale

    var description: String {
        switch self {
        case .none:
            return "None"

        case .followingScale:
            return "Following Scale"
        case .leadingTheScale:
            return "Practicing"
        case .recordingScale:
            return "Recording Scale"
       case .recordingScaleForAssessment:
            return "Recording Scale"
        case .recordScaleWithFileData:
            return "Recording Scale With File Data"
//        case .recordScaleWithTapData:
//            return "Recording Scale With Tap Data"
//        case .identifyingScale:
//            return "Identifying Scale"
        case .syncRecording:
            return "Synchronize Recording"
        case .playingAlongWithScale:
            return "Playing Along With Scale"
//        case .metronomeOn:
//            return "Metronome On"
        }
    }
}

enum SpinState {
    case notStarted
    case selectedBet
    case spinning
    case spunAndStopped
}

public class ScalesModel : ObservableObject {
    
    static public var shared = ScalesModel() //musicBoardGrade:
                                            //MusicBoardGrade(board: MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: "")))
    private(set) var scale:Scale
    
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    @Published var scores:[Score?] = [nil, nil]
    @Published var recordingIsPlaying1 = false
    @Published var synchedIsPlaying = false

    var scoreHidden = false
    
    var recordedTapsFileURL:URL? //File where recorded taps were written
    @Published var recordedTapsFileName:String?
    
    var scaleLeadInCounts:[String] = ["No Clicks", "Two Clicks", "Four Clicks"]
    
    var directionTypes = ["⬆", "⬇"]
    
    var handTypes = ["Right", "Left"]

    var tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120", "130", "140", "150", "160"]
    var selectedTempoIndex = 5 //60=2
        
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    //let calibrationTapHandler:ScaleTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let calibrationTapHandler:RealTimeTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    var helpTopic:String? = nil
    var onRecordingDoneCallback:(()->Void)?
    var tapHandlers:[TapHandlerProtocol] = []
    var backer:Backer?
    
    private(set) var processedEventSet:TapStatusRecordSet? = nil
    @Published var processedEventSetPublished = false
    func setProcessedEventSet(_ value:TapStatusRecordSet?, publish:Bool) {
        self.processedEventSet = value
        if publish {
            DispatchQueue.main.async {
                self.processedEventSetPublished = value != nil
            }
        }
    }
    
    private(set) var tapEventSet:TapEventSet? = nil
    func setTapEventSet(_ value:TapEventSet?, publish:Bool) {
        self.tapEventSet = value
    }

    //@Published
    private(set) var spinState:SpinState = .notStarted
    func setSpinState1(_ value:SpinState) {
        //DispatchQueue.main.async {
            self.spinState = value
        //}
    }

    ///Speech
    @Published var speechListenMode = false
    @Published var speechLastWord = ""

    ///Result cannot be published since it needs to be updated on the main thread. e.g. for rapid callibration analyses
    ///ResultDisplay is the published version
    private(set) var resultInternal:Result?
    func setResultInternal(_ result:Result?, _ ctx:String) {
        let noErrors = result == nil ? true : result!.noErrors()
        self.resultInternal = result
        DispatchQueue.main.async {
            self.resultPublished = result
            PianoKeyboardModel.sharedRightHand.redraw()
        }
    }
    @Published private(set) var resultPublished:Result?

    @Published private(set) var processInstructions:String? = nil
    func setProcessInstructions(_ msg:String?) {
        DispatchQueue.main.async {
            self.processInstructions = msg
        }
    }
    
    @Published private(set) var showStaff = true
    func setShowStaff(_ newValue: Bool) {
        DispatchQueue.main.async {
//            PianoKeyboardModel.shared.configureKeyboardSize()
//            self.setDirection(0)
//            PianoKeyboardModel.shared.redraw()
            self.showStaff = newValue
        }
    }
    
    @Published private(set) var showFingers = true
    func setShowFingers(_ newValue: Bool) {
        DispatchQueue.main.async {
            self.showFingers = newValue
        }
    }
    
    @Published var selectedDirection = 0
    func setSelectedDirection(_ index:Int) {
        DispatchQueue.main.async {
            self.selectedDirection = index
            PianoKeyboardModel.sharedRightHand.linkScaleFingersToKeyboardKeys(scale: self.scale, handIndex: 0, direction: index)
            PianoKeyboardModel.sharedRightHand.redraw()
            PianoKeyboardModel.sharedLeftHand.linkScaleFingersToKeyboardKeys(scale: self.scale, handIndex: 1, direction: index)
            PianoKeyboardModel.sharedLeftHand.redraw()
        }
    }
    
    @Published private(set) var userMessage:String? = nil
    @Published var showUserMessage: Bool = false
    @Published var userMessageHeading: String? = nil
    func setUserMessage(heading: String?, msg: String?) {
        DispatchQueue.main.async {
            self.userMessageHeading = heading
            self.userMessage = msg
            self.showUserMessage = msg != nil
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
    
    private(set) var runningProcess:RunningProcess = .none
    @Published private(set) var runningProcessPublished:RunningProcess = .none

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
            if self.backer == nil {
                self.backer = Backer()
            }
            metronome.addProcessesToNotify(process: self.backer!)
//            metronome.startTimer(notified: Backer(), onDone: {
//            })
        }
        else {
            //metronome.stop()
            if let backer = self.backer {
                metronome.removeProcessesToNotify(process: backer)
            }
        }
        DispatchQueue.main.async {
            self.backingOn = way
        }
    }
    
    //init(musicBoardGrade:MusicBoardGrade) {
    init() {
        self.scale = Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .parallelMotion, octaves: 1, hand: 0,
                           minTempo: 90, dynamicType: .mf, articulationType: .legato)
        self.calibrationTapHandler = nil
        DispatchQueue.main.async {
            PianoKeyboardModel.sharedRightHand.configureKeyboardForScale(scale: self.scale, handIndex: 0)
            PianoKeyboardModel.sharedLeftHand.configureKeyboardForScale(scale: self.scale, handIndex: 1)
        }
    }
    
    func setRunningProcess(_ setProcess: RunningProcess, amplitudeFilter:Double? = nil) {
        
        Logger.shared.log(self, "Setting process from:\(self.runningProcess) to:\(setProcess.description)")
        if setProcess == .none {
            self.audioManager.stopRecording()
            if self.runningProcess == .syncRecording {
                DispatchQueue.main.async {
                    self.synchedIsPlaying = false
                }
            }
            MetronomeModel.shared.removeAllProcesses()
            if self.tapHandlers.count > 0 {
                self.setTapEventSet(self.tapHandlers[0].stopTappingProcess(), publish: true)
            }
            //self.tapHandlers = [] //Dont remove them here. Processes may want them before next process
        }
        else {
            self.tapHandlers = []
            setUserMessage(heading: nil, msg: nil)
            BadgeBank.shared.setShow(false)
        }
        self.runningProcess = setProcess
        DispatchQueue.main.async {
            self.runningProcessPublished = self.runningProcess
        }

        ///For some unknwon reason the 1st call does not silence some residue sound from the sampler. The 2nd does appear to.
        self.audioManager.resetAudioKit()
        self.audioManager.resetAudioKit()

        self.setShowKeyboard(true)
        self.setShowParameters(true)
        self.setShowLegend(true)
        self.setSelectedDirection(0)
        self.setProcessInstructions(nil)
        if resultInternal != nil {
            self.setShowStaff(true)
        }
        MetronomeModel.shared.isTiming = false
        
        let keyboard = scale.hand == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
        keyboard.clearAllFollowingKeyHilights(except: nil)
        keyboard.redraw()
        let metronome = MetronomeModel.shared
        
        if [.followingScale].contains(setProcess)  {
            self.setResultInternal(nil, "setRunningProcess::nil for follow/practice")
            self.tapHandlers.append(RealTimeTapHandler(bufferSize: 4096, scale:self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            BadgeBank.shared.setTotalCorrect(0)
            
            if setProcess == .followingScale {
                setShowKeyboard(true)
                ///Play first note to start then wait some time.
                ///Wait for note to die down otherwise it triggers the first note detection
                if self.scale.scaleNoteState.count > 0 {
                    if let sampler = self.audioManager.keyboardMidiSampler {
                        var hands:[Int] = []
                        if scale.hand < 2 {
                            hands.append(scale.hand)
                        }
                        else {
                            hands.append(0)
                            hands.append(1)
                        }
                        for hand in hands {
                            let midi = UInt8(self.scale.scaleNoteState[hand][0].midi)
                            sampler.play(noteNumber: midi, velocity: 64, channel: 0)
                        }
                        ///Need delay to avoid the first note being 'heard' from this sampler playing note
                        usleep(1000000 * UInt32(2.0))
                    }
                }
            }
            
            self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: false)
            if setProcess == .followingScale {
                BadgeBank.shared.setShow(true)
                self.followScaleProcess(handIndex: scale.hand, onDone: {cancelled in
                    self.setRunningProcess(.none)
                })
            }
        }
        
        if [.leadingTheScale].contains(setProcess) {
            BadgeBank.shared.setShow(true)
            BadgeBank.shared.setTotalCorrect(0)
            BadgeBank.shared.setTotalIncorrect(0)
            metronome.isTiming = true
            let leadProcess = LeadScaleProcess(scalesModel: self, metronome: metronome)
            self.tapHandlers.append(RealTimeTapHandler(bufferSize: 4096, scale:self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            leadProcess.start()
            metronome.addProcessesToNotify(process: leadProcess)
            self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: false)
        }
        
        if [.playingAlongWithScale].contains(setProcess) {
            metronome.isTiming = true
            metronome.addProcessesToNotify(process: HearScalePlayer(handIndex: scale.hand))
        }

        if [RunningProcess.recordingScale].contains(setProcess) {
            self.audioManager.startRecordingMicToRecord()
            let metronome = MetronomeModel.shared
            metronome.isTiming = true
            let process = RecordScaleProcess()
            metronome.addProcessesToNotify(process: process)
        }
        
        if [RunningProcess.recordingScaleForAssessment, RunningProcess.recordScaleWithFileData].contains(setProcess)  {
            keyboard.resetKeysWerePlayedState()
            self.scale.resetMatchedData()
            self.setShowKeyboard(false)
            self.setShowStaff(false)
            self.setShowParameters(false)
            self.setShowLegend(false)
            self.setResultInternal(nil, "setRunningProcess::start record")
            setUserMessage(heading: nil, msg: nil)
            self.setProcessedEventSet(nil, publish: true)
            keyboard.redraw()
            ///4096 has extra params to figure out automatic scale play end
            ///WARING - adding too many seems to have a penalty on accuracy of the standard sizes like 4096. i.e. 4096 gets more taps on its own than when >2 others are also installed.
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 4096, scale: self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 2048, scale: self.scale, amplitudeFilter: nil))
//            self.tapHandlers.append(ScaleTapHandler(bufferSize: 1024, scale: nil, amplitudeFilter: nil))
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 8192 * 2, scale: self.scale, amplitudeFilter: nil))

            //self.tapHandlers.append(ScaleTapHandler(bufferSize: 2 * 8192, scale: nil, amplitudeFilter: nil))
            self.recordedTapsFileURL = nil
            if setProcess == .recordScaleWithFileData {
                ///For plaback of an emailed file
                let tapEventSets = self.audioManager.readTestDataFile()
                self.audioManager.playbackTapEvents(tapEventSets: tapEventSets, tapHandlers: self.tapHandlers)
            }

            if setProcess == .recordingScaleForAssessment {
                DispatchQueue.main.async {
                    //self.runningProcess = .leadingIn
                }
//                doLeadIn(instruction: "Record your scale", leadInDone: {
//                    //😡😡 cannot record and tap concurrenlty
//                    //self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: true)
//                    DispatchQueue.main.async {
//                        self.runningProcess = RunningProcess.recordingScaleForAssessment
//                    }
//                    self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: true)
//                })
            }
        }
    }
    
    ///Allow user to follow notes hilighted on the keyboard.
    ///Wait till user hits correct key before moving to and highlighting the next note
    func followScaleProcess(handIndex:Int, onDone:((_ cancelled:Bool)->Void)?) {
        DispatchQueue.global(qos: .background).async { [self] in
            class KeyboardSemaphore {
                let keyboard:PianoKeyboardModel
                let semaphore:DispatchSemaphore
                init(keyboard:PianoKeyboardModel, semaphore:DispatchSemaphore) {
                    self.keyboard = keyboard
                    self.semaphore = semaphore
                }
            }
            var keyboardSemaphores:[KeyboardSemaphore] = []
            if handIndex == 0 {
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedRightHand, semaphore: DispatchSemaphore(value: 0)))
            }
            if handIndex == 1 {
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedLeftHand, semaphore: DispatchSemaphore(value: 0)))
            }
            if handIndex == 2 {
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedRightHand, semaphore: DispatchSemaphore(value: 0)))
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedLeftHand, semaphore: DispatchSemaphore(value: 0)))
            }

            var scaleIndex = 0
            var cancelled = false
            var inScaleCount = 0
            
            while true {
                if scaleIndex >= self.scale.scaleNoteState[0].count {
                    break
                }
                
                var currentMidis:[Int] = []
                
                ///Add a semaphore to detect when the expected keyboard key is played
                for keyboardSemaphore in keyboardSemaphores {
                    let note = self.scale.scaleNoteState[keyboardSemaphore.keyboard.hand][scaleIndex]
                    guard let keyIndex = keyboardSemaphore.keyboard.getKeyIndexForMidi(midi:note.midi, direction:0) else {
                        scaleIndex += 1
                        continue
                    }
                    currentMidis.append(note.midi)
                    let pianoKey = keyboardSemaphore.keyboard.pianoKeyModel[keyIndex]
                    keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: keyIndex)
                    pianoKey.hilightFollowingKey = true
                    keyboardSemaphore.keyboard.redraw()
                    //print("============added semaphore for hand", keyboardSemaphore.keyboard.hand, note.midi)
                    ///Listen for piano key pressed
                    pianoKey.wasPlayedCallback = {
                        keyboardSemaphore.semaphore.signal()
                        inScaleCount += 1
                        keyboardSemaphore.keyboard.redraw()
                        pianoKey.wasPlayedCallback = nil
                    }
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
                    for keyboardSemaphore in keyboardSemaphores {
                        keyboardSemaphore.semaphore.signal()
                        keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: nil)
                    }
                }
                
                ///Wait for the right key to be played on every keyboard
                for keyboardSemaphore in keyboardSemaphores {
                    if self.runningProcess != .followingScale {
                        break
                    }
                    keyboardSemaphore.semaphore.wait()
                }
                
                BadgeBank.shared.setTotalCorrect(BadgeBank.shared.totalCorrect + 1)
                
                ///Change direction to descending
                let highest = self.scale.getMinMax(handIndex: keyboardSemaphores[0].keyboard.hand).1
                if currentMidis[0] == highest {
                    self.setSelectedDirection(1)
                }
                if scaleIndex >= self.scale.scaleNoteState[0].count - 1 {
                    break
                }
                scaleIndex += 1
            }
            self.audioManager.stopRecording()

            if inScaleCount > 2 {
                if let eventSet = self.self.tapEventSet {
                    let xx = eventSet.eventsOutOfScale()
                    var msg = "😊 Good job following the scale"
                    msg += "\nYou played \(inScaleCount) notes in the scale"
                    //msg += "\nYou played \(xxx) notes out of the scale"
                    ScalesModel.shared.setUserMessage(heading: "Following the Scale", msg:msg)
                }
            }

            if let onDone = onDone {
                onDone(cancelled)
            }
        }
    }
    
    ///Get tempo for 1/4 note
    func getTempo() -> Int {
        var selected = self.tempoSettings[self.selectedTempoIndex]
        //selected = String(selected.dropFirst(2))
        selected = String(selected)
        return Int(selected) ?? 60
    }
    
    func createScore(scale:Scale, hand:Int) -> Score {
        let staffType:StaffType
        
//        if scale.scaleNoteState.count > 0 {
//            ///52 = Max is E below middle C which requires 3 ledger in treble clef
//            //staffType = scale.scaleNoteState[handIndex][0].midi >= 52 ? .treble : .bass
//            if scale.hand == 2 {
//                staffType = .treble
//            }
//            else {
//                staffType = scale.hand == 0 ? .treble : .basscreateScore
//        }
//        else {
//            staffType = .treble
//        }
        staffType = hand == 0 ? .treble : .bass
        let staffKeyType:StaffKey.StaffKeyType = [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh, .chromatic, .brokenChordMajor].contains(scale.scaleType) ? .major : .minor
        let keySignature = KeySignature(keyName: scale.scaleRoot.name, keyType: staffKeyType)
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)
        let top = [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType) ? 3 : 4
        let score = Score(key: staffKey, timeSignature: TimeSignature(top: top, bottom: 4), linesPerStaff: 5)

        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
        var inBarTotalValue = 0.0
        //let handIndex = scale.hand == 1 ? 1 : 0
        //var lastNote:StaffNote?
        
        for i in 0..<scale.scaleNoteState[hand].count {
            if Int(inBarTotalValue) >= top {
                score.addBarLine()
                inBarTotalValue = 0.0
            }

            let noteState = scale.scaleNoteState[hand][i]
            let ts = score.createTimeSlice()
            
            let note = StaffNote(timeSlice: ts, num: noteState.midi, value: noteState.value, staffNum: 0)
            note.setValue(value: noteState.value)
            ts.addNote(n: note)
            inBarTotalValue += noteState.value
            //lastNote = note
        }
//        if let lastNote = lastNote {
//            let valueInLastBar = inBarTotalValue - lastNote.getValue()
//            lastNote.setValue(value: 4 - valueInLastBar)
//        }
        Logger.shared.log(self, "Created score type:\(staffType) octaves:\(scale.scaleNoteState[hand].count/12)")
        return score
    }
    
    func setScale(scale:Scale) {
        let name = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false) 
        Logger.shared.log(self, "setScale to:\(name)")
        let scoreRH = self.createScore(scale: scale, hand: 0)
        let scoreLH = self.createScore(scale: scale, hand: 1)
        self.setScaleAndScore(scale: scale, scores: [scoreRH, scoreLH], ctx: "setScale")
    }

    func setScaleByRootAndType(scaleRoot: ScaleRoot, scaleType:ScaleType, scaleMotion:ScaleMotion, octaves:Int, hand:Int, ctx:String) {
        let name = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
        Logger.shared.log(self, "setScaleByRootAndType to:root:\(name)")
                          //ctx:\(ctx) from:\(self.scale.getScaleName(handFull: false, octaves: false))")
        let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoot.name),
                          scaleType: scaleType, scaleMotion: scaleMotion,
                           octaves: octaves,
                           hand: hand,
                          minTempo: 90, dynamicType: .mf, articulationType: .legato)
        setScale(scale: scale)
//        let score = self.createScore(scale: scale)
//        self.setScaleAndScore(scale: scale, score: score, ctx: "setKeyAndScale")
//        self.setResultInternal(nil, "setScaleByRootAndType")
//        PianoKeyboardModel.sharedRightHand.redraw()
    }
    
    func setScaleAndScore(scale:Scale, scores:[Score], ctx:String) {
        let name = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
        Logger.shared.log(self, "setScaleAndScore to:\(name) ctx:\(ctx)")
        self.scale = scale
        PianoKeyboardModel.sharedRightHand.configureKeyboardForScale(scale: scale, handIndex: 0)
        PianoKeyboardModel.sharedLeftHand.configureKeyboardForScale(scale: scale, handIndex: 1)

        self.setSelectedDirection(0)
        PianoKeyboardModel.sharedRightHand.redraw()
        PianoKeyboardModel.sharedLeftHand.redraw()

        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.scores = scores
            }
        }
    }
    
    func setKeyboard() {
        let name = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
        Logger.shared.log(self, "setScaleAndScore to:\(name))")
        let scale = self.scale
        scale.octaves = 4
        //scale.scaleType = .major
        self.scale = scale
        PianoKeyboardModel.sharedRightHand.configureKeyboardForScale(scale: scale, handIndex: 0)
        self.setSelectedDirection(0)
        PianoKeyboardModel.sharedRightHand.unmapScaleFingersToKeyboard()
        PianoKeyboardModel.sharedRightHand.redraw()
        
        PianoKeyboardModel.sharedLeftHand.configureKeyboardForScale(scale: scale, handIndex: 1)
        //self.setSelectedDirection(0)
        PianoKeyboardModel.sharedLeftHand.unmapScaleFingersToKeyboard()
        PianoKeyboardModel.sharedLeftHand.redraw()

        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.scores = self.scores
            }
        }
    }
    
//    func processTapEvents(fromProcess: RunningProcess, saveTapEventsToFile:Bool) -> TapStatusRecordSet? {
//        var tapEventSets:[TapEventSet] = []
//        for tapHandler in self.tapHandlers {
//            tapEventSets.append(tapHandler.stopTappingProcess())
//        }
//        
//        let analyser = TapsEventsAnalyser(scale: self.scale,
//                                          recordedTapEventSets: tapEventSets,
//                                          keyboard: PianoKeyboardModel.sharedRightHand,
//                                          fromProcess: self.runningProcess)
//        let (bestResult, bestEvents) = analyser.getBestResult()
//        
//        ///Save the taps to a file
//        if saveTapEventsToFile {
//            if let bestResult = bestResult {
//                var tapEventSets:[TapEventSet] = []
//                for tapHandler in self.tapHandlers {
//                    tapEventSets.append(tapHandler.stopTappingProcess())
//                }
//                self.saveTapsToFile(tapSets: tapEventSets, result: bestResult)
//            }
//        }
//                
//        ///Replay the best fit scale to set the app's display state
//        ///If there are too many errors just display the scale at the octaves it was shown as
//        let bestScale:Scale = self.scale
////            if bestResult == nil || bestResult!.getTotalErrors() > 3 {
////                bestScale = self.scale.makeNewScale(offset: 0)
////            }
////            else {
////                bestScale = self.scale.makeNewScale(offset: bestConfiguration.scaleOffset)
////            }
//        
//        let scalesModel = ScalesModel.shared
//        ///Score note status is updated during result build, keyboard key status is updated by tap processing
//        let score = scalesModel.createScore(scale: bestScale)
//        scalesModel.setScaleAndScore(scale: bestScale, score: score, ctx: "ScaleTapHandler:bestOffset")
//            
//        ///Ensure keyboard visible key statuses are updated during events apply
//        var finalEventStatusSet:TapStatusRecordSet? = nil
//        
//        let keyboard = PianoKeyboardModel.sharedRightHand
//        if let result = bestResult {
//            if let eventSet = bestEvents {
//                
//                let (finalResult, finalSet) = analyser.applyEvents(ctx: "useBest",
//                                                    bufferSize: result.bufferSize,
//                                                    recordedTapEvents: result.tappedEventsSet.events,
//                                                    offset: 0, scale: bestScale,
//                                                    keyboard: keyboard,
//                                                    amplitudeFilter:result.amplitudeFilter,
//                                                    compressingFactor: result.compressingFactor,
//                                                    octaveLenient: true,
//                                                    score: score,
//                                                    updateKeyboard: true)
//                keyboard.redraw()
//                Logger.shared.log(self, "=======> Applied best events. Offset:\(0) Result:\(result.getInfo())")
//                scalesModel.setResultInternal(finalResult, "stop Tapping")
//                finalEventStatusSet = finalSet
//            }
//        }
//        self.tapHandlers = []
//        return finalEventStatusSet
//    }

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
        
    func setTempo(_ index:Int) {
        //DispatchQueue.main.async {
            self.selectedTempoIndex = index
            //PianoKeyboardModel.shared.setFingers(direction: index)
        //}
    }

    func saveTapsToFile(tapSets:[TapEventSet], result:Result) {
        let scale = self.scale
        let handIndex = 0
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let day = calendar.component(.day, from: Date())
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let device = UIDevice.current
        let modelName = device.model
        var keyName = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
        keyName = keyName.replacingOccurrences(of: " ", with: "")
        var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"+String(format: "%02d", hour)+"_"+String(format: "%02d", minute)
        fileName += "_"+keyName + "_"+String(scale.octaves) + "_" + String(scale.scaleNoteState[handIndex][0].midi) + "_" + modelName
//        fileName += "_"+String(result.playedAndWrongCountAsc)+","+String(result.playedAndWrongCountDesc)+","+String(result.missedFromScaleCountAsc)+","+String(result.missedFromScaleCountDesc)
        fileName += "_Taps"+String(tapSets.count)
        fileName += "_"+String(AudioManager.shared.recordedFileSequenceNum)
        
        fileName += ".txt"
        AudioManager.shared.recordedFileSequenceNum += 1
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.recordedTapsFileURL = documentDirectoryURL.appendingPathComponent(fileName)
        guard let url = self.recordedTapsFileURL else {
            return
        }
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            }
            let fileHandle = try FileHandle(forWritingTo: url)
            let header = "--FileName "+fileName+"\n"
            if let data = header.data(using: .utf8) {
                fileHandle.write(data)
            }
            for tapSet in tapSets {
                var config = "--TapSet BufferSize \(tapSet.bufferSize)"
                config += "\n"
                //try config.write(to: savedTapsFileURL, atomically: true, encoding: .utf8)
                if let data = config.data(using: .utf8) {
                    fileHandle.write(data)
                }
                for tap in tapSet.events {
                    let timeInterval = tap.timestamp.timeIntervalSince1970
                    let tapData = "time:\(timeInterval)\tfreq:\(tap.frequency)\tampl:\(tap.amplitude)\n"
                    if let data = tapData.data(using: .utf8) {
                        //fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                    }
                }
            }
            //ScalesModel.shared.recordedTapsFileURL = fileURL
            fileHandle.closeFile()
            Logger.shared.log(self, "Wrote \(tapSets.count) tapSets to \(url)")
        } catch {
            Logger.shared.reportError(self, "Error writing to file: \(error)")
        }
        DispatchQueue.main.async {
            ScalesModel.shared.recordedTapsFileName = fileName
        }
    }
}



