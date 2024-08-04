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
    case practicing
    case recordingScale
    case leadingIn
    case recordScaleWithFileData
    case syncRecording
    case playingAlongWithScale

    var description: String {
        switch self {
        case .none:
            return "None"

        case .followingScale:
            return "Following Scale"
        case .practicing:
            return "Practicing"
        case .recordingScale:
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
        case .leadingIn:
            return "Leading In"
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
    
    static public var shared = ScalesModel(musicBoardGrade: MusicBoardGrade(board: MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: ""), gradeName: "Grade1"))
    
    private(set) var scale:Scale
    
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    @Published var score:Score?
    @Published var recordingIsPlaying1 = false
    @Published var synchedIsPlaying = false

    var scoreHidden = false
    
    var recordedTapsFileURL:URL? //File where recorded taps were written
    @Published var recordedTapsFileName:String?
    
    //let calibrationResults = CalibrationResults()
    
    var scaleLeadInCounts:[String] = ["None", "One Bar", "Two Bars", "Four Bars"]
    
    var directionTypes = ["⬆", "⬇"]
    var selectedHandIndex = 0
    
    var handTypes = ["Right", "Left"]

    var tempoSettings = ["♩=40", "♩=50", "♩=60", "♩=70", "♩=80", "♩=90", "♩=100", "♩=110", "♩=120", "♩=130", "♩=140", "♩=150", "♩=160"]
    var selectedTempoIndex = 5 //60=2
        
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let calibrationTapHandler:ScaleTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    var helpTopic:String? = nil
    var onRecordingDoneCallback:(()->Void)?
    var tapHandlers:[TapHandlerProtocol] = []
    
    private(set) var tapHandlerEventSet:TapStatusRecordSet? = nil
    @Published var tapHandlerEventSetPublished = false
    func setTapHandlerEventSet(_ value:TapStatusRecordSet?, publish:Bool) {
        self.tapHandlerEventSet = value
        if publish {
            DispatchQueue.main.async {
                self.tapHandlerEventSetPublished = value != nil
            }
        }
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
            PianoKeyboardModel.shared.redraw()
        }
        let coinBank = CoinBank.shared
        if result != nil {
            coinBank.adjustAfterResult(noErrors: noErrors)
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
            PianoKeyboardModel.shared.linkScaleFingersToKeyboardKeys(scale: self.scale, direction: index)
            PianoKeyboardModel.shared.redraw()
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
            metronome.startTimer(notified: Backer(), onDone: {
            })
        }
        else {
            metronome.stop()
        }
        DispatchQueue.main.async {
            self.backingOn = way
        }
    }
    
    init(musicBoardGrade:MusicBoardGrade) {
        self.scale = Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, octaves: Settings.shared.defaultOctaves, hand: 0)
        self.calibrationTapHandler = nil
        DispatchQueue.main.async {
            PianoKeyboardModel.shared.configureKeyboardForScale(scale: self.scale)
        }
    }
    
    func processTapEvents(fromProcess: RunningProcess, saveTapEventsToFile:Bool) -> TapStatusRecordSet? {
        var tapEventSets:[TapEventSet] = []
        for tapHandler in self.tapHandlers {
            tapEventSets.append(tapHandler.stopTappingProcess())
        }
        
        let analyser = TapsEventsAnalyser(scale: self.scale,
                                          recordedTapEventSets: tapEventSets,
                                          keyboard: PianoKeyboardModel.shared,
                                          fromProcess: self.runningProcess)
        let (bestResult, bestEvents) = analyser.getBestResult()
        
        ///Save the taps to a file
        if saveTapEventsToFile {
            if let bestResult = bestResult {
                var tapEventSets:[TapEventSet] = []
                for tapHandler in self.tapHandlers {
                    tapEventSets.append(tapHandler.stopTappingProcess())
                }
                self.saveTapsToFile(tapSets: tapEventSets, result: bestResult)
            }
        }
                
        ///Replay the best fit scale to set the app's display state
        ///If there are too many errors just display the scale at the octaves it was shown as
        let bestScale:Scale = self.scale
//            if bestResult == nil || bestResult!.getTotalErrors() > 3 {
//                bestScale = self.scale.makeNewScale(offset: 0)
//            }
//            else {
//                bestScale = self.scale.makeNewScale(offset: bestConfiguration.scaleOffset)
//            }
        
        let scalesModel = ScalesModel.shared
        ///Score note status is updated during result build, keyboard key status is updated by tap processing
        let score = scalesModel.createScore(scale: bestScale)
        scalesModel.setScaleAndScore(scale: bestScale, score: score, ctx: "ScaleTapHandler:bestOffset")
            
        ///Ensure keyboard visible key statuses are updated during events apply
        var finalEventStatusSet:TapStatusRecordSet? = nil
        
        let keyboard = PianoKeyboardModel.shared
        if let result = bestResult {
            if let eventSet = bestEvents {
                
                let (finalResult, finalSet) = analyser.applyEvents(ctx: "useBest",
                                                    bufferSize: result.bufferSize,
                                                    recordedTapEvents: result.tappedEventsSet.events,
                                                    offset: 0, scale: bestScale,
                                                    keyboard: keyboard, 
                                                    amplitudeFilter:result.amplitudeFilter,
                                                    compressingFactor: result.compressingFactor,
                                                    octaveLenient: true,
                                                    score: score,
                                                    updateKeyboard: true)
                keyboard.redraw()
                Logger.shared.log(self, "=======> Applied best events. Offset:\(0) Result:\(result.getInfo())")
                scalesModel.setResultInternal(finalResult, "stop Tapping")
                finalEventStatusSet = finalSet
            }
        }
        self.tapHandlers = []
        return finalEventStatusSet
    }
    
    func setRunningProcess(_ setProcess: RunningProcess, amplitudeFilter:Double? = nil) {
        //let coinBank = CoinBank.shared
        Logger.shared.log(self, "Setting process from:\(self.runningProcess) to:\(setProcess.description)")
        if setProcess == .none {
            self.audioManager.stopRecording()
            if [.recordingScale, .recordScaleWithFileData].contains(self.runningProcess) {
                if let statsSet = processTapEvents(fromProcess: self.runningProcess, saveTapEventsToFile: self.runningProcess == .recordingScale) {
                    setTapHandlerEventSet(statsSet, publish: true)
                }
            }
            if self.runningProcess == .syncRecording {
                DispatchQueue.main.async {
                    self.synchedIsPlaying = false
                }
            }
        }
        self.runningProcess = setProcess
        DispatchQueue.main.async {
            self.runningProcessPublished = self.runningProcess
        }

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
        
        let keyboard = PianoKeyboardModel.shared
        keyboard.clearAllFollowingKeyHilights(except: nil)
        keyboard.redraw()
        
        if [.followingScale, .practicing].contains(setProcess)  {
            self.setResultInternal(nil, "setRunningProcess::nil for follow/practice")
            self.tapHandlers.append(RealTimeTapHandler(bufferSize: 4096, amplitudeFilter: Settings.shared.amplitudeFilter))
            if setProcess == .followingScale {
                setShowKeyboard(true)
                ///Play first note only. Tried play all notes in scale but the app then listens to itself via the mic and responds to its own sounds
                ///Wait for note to die down otherwise it triggers the first note detection
                //DispatchQueue.main.async {
                    if self.scale.scaleNoteState.count > 0 {
                        if let sampler = self.audioManager.keyboardMidiSampler {
                            let midi = UInt8(self.scale.scaleNoteState[0].midi)
                            sampler.play(noteNumber: midi, velocity: 64, channel: 0)
                            ///Without delay here the fist note wont hilight - no idea why
                            sleep(2)
                        }
                    }
                //}
            }
            self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: false)
            if setProcess == .followingScale {
                self.followScaleProcess(onDone: {cancelled in
                    self.setRunningProcess(.none) //, tapBufferSize: Settings.shared.tapBufferSize)
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
                metronome.startTimer(notified: HearScalePlayer(), onDone: {
                })
            })
        }
        
        if [RunningProcess.syncRecording].contains(setProcess)  {
            let metronome = MetronomeModel.shared
            DispatchQueue.main.async {
                self.synchedIsPlaying = true
            }
            metronome.startTimer(notified: HearUserScale(), onDone: {
                self.setRunningProcess(.none) //, tapBufferSize: Settings.shared.tapBufferSize)
            })
        }

        if [RunningProcess.recordingScale, RunningProcess.recordScaleWithFileData].contains(setProcess)  {
            keyboard.resetKeysWerePlayedState()
            self.scale.resetMatchedData()
            self.setShowKeyboard(false)
            self.setShowStaff(false)
            self.setShowParameters(false)
            self.setShowLegend(false)
            self.setResultInternal(nil, "setRunningProcess::start record")
            self.setUserMessage(nil)
            self.setTapHandlerEventSet(nil, publish: true)
            keyboard.redraw()
            ///4096 has extra params to figure out automatic scale play end
            ///WARING - adding too many seems to have a penalty on accuracy of the standard sizes like 4096. i.e. 4096 gets more taps on its own than when >2 others are also installed.
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 4096, scale: self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 2048, scale: nil, amplitudeFilter: nil))
//            self.tapHandlers.append(ScaleTapHandler(bufferSize: 1024, scale: nil, amplitudeFilter: nil))
            self.tapHandlers.append(ScaleTapHandler(bufferSize: 8192 * 2, scale: nil, amplitudeFilter: nil))

            //self.tapHandlers.append(ScaleTapHandler(bufferSize: 2 * 8192, scale: nil, amplitudeFilter: nil))
            self.recordedTapsFileURL = nil
            if setProcess == .recordScaleWithFileData {
                ///For plaback of an emailed file
                let tapEventSets = self.audioManager.readTestDataFile()
                self.audioManager.playbackTapEvents(tapEventSets: tapEventSets, tapHandlers: self.tapHandlers)
            }

            if setProcess == .recordingScale {
                DispatchQueue.main.async {
                    self.runningProcess = .leadingIn
                }
                doLeadIn(instruction: "Record your scale", leadInDone: {
                    //😡😡 cannot record and tap concurrenlty
                    //self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: true)
                    DispatchQueue.main.async {
                        self.runningProcess = RunningProcess.recordingScale
                    }
                    self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: true)
                })
            }
        }
    }

    func doLeadIn(instruction:String, leadInDone:@escaping ()->Void) {
        let scaleLeadIn = ScaleLeadIn()
        if Settings.shared.scaleLeadInBarCount > 0 {
            ///Dont let the metronome ticks fire erroneous frequencies during the lead-in.
            audioManager.blockTaps = true
            self.setProcessInstructions(scaleLeadIn.getInstructions())
            MetronomeModel.shared.startTimer(notified: scaleLeadIn, onDone: {                
                self.setProcessInstructions(instruction)
                self.audioManager.blockTaps = false
                leadInDone()
            })
        }
        else {
            leadInDone()
            self.setProcessInstructions("Start recording your scale")
        }
        
    }

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
                    self.setSelectedDirection(1)
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
        //let staffType:StaffType = self.selectedHandIndex == 0 ? .treble : .bass
        let staffType:StaffType
        if scale.scaleNoteState.count > 0 {
            //staffType = scale.scaleNoteState[0].midi >= 60 ? .treble : .bass
            ///52 = Max is E below middle C which requires 3 ledger in treble clef
            staffType = scale.scaleNoteState[0].midi >= 52 ? .treble : .bass
        }
        else {
            staffType = .treble
        }
        let staffKeyType:StaffKey.StaffKeyType = [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh, .chromatic, .brokenChordMajor].contains(scale.scaleType) ? .major : .minor
        let keySignature = KeySignature(keyName: scale.scaleRoot.name, keyType: staffKeyType)
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)
        let top = [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType) ? 3 : 4
        let score = Score(key: staffKey, timeSignature: TimeSignature(top: top, bottom: 4), linesPerStaff: 5)

        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
        var inBarTotalValue = 0.0
        //var lastNote:StaffNote?
        //let noteValue = Settings.shared.getSettingsNoteValueFactor()
        
        for i in 0..<scale.scaleNoteState.count {
            if Int(inBarTotalValue) >= top {
                score.addBarLine()
                inBarTotalValue = 0.0
            }

            let noteState = scale.scaleNoteState[i]
            let ts = score.createTimeSlice()
            
            let note = StaffNote(timeSlice: ts, num: noteState.midi, value: noteState.value, staffNum: 0)
            ts.addNote(n: note)
            inBarTotalValue += noteState.value
            //lastNote = note
        }
//        if let lastNote = lastNote {
//            let valueInLastBar = inBarTotalValue - lastNote.getValue()
//            lastNote.setValue(value: 4 - valueInLastBar)
//        }
        Logger.shared.log(self, "Created score type:\(staffType) octaves:\(scale.scaleNoteState.count/12) range:\(scale.getMinMax()) noteValue:\(Settings.shared.getSettingsNoteValueFactor())")
        return score
    }
    
    func setScale(scale:Scale) {
        Logger.shared.log(self, "setScale to:\(scale.getScaleName()) from:\(self.scale.getScaleName())")
        let score = self.createScore(scale: scale)
        self.setScaleAndScore(scale: scale, score: score, ctx: "setScale")
    }

    func setScaleByRootAndType(scaleRoot: ScaleRoot, scaleType:ScaleType, octaves:Int, hand:Int, ctx:String) {
        Logger.shared.log(self, "setScaleByRootAndType to:root:\(scaleRoot.name) type:\(scaleType.description)  ctx:\(ctx) from:\(self.scale.getScaleName())")
        let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoot.name),
                          //scaleType: Scale.getScaleType(name: scaleType.description),
                          scaleType: scaleType,
                           octaves: octaves,
                           hand: hand)
        let score = self.createScore(scale: scale)
        self.setScaleAndScore(scale: scale, score: score, ctx: "setKeyAndScale")
        self.setResultInternal(nil, "setScaleByRootAndType")
        PianoKeyboardModel.shared.redraw()
    }
    
    func setScaleAndScore(scale:Scale, score:Score, ctx:String) {
        Logger.shared.log(self, "setScaleAndScore to:\(scale.getScaleName()) ctx:\(ctx)")
        self.scale = scale
        PianoKeyboardModel.shared.configureKeyboardForScale(scale: scale)
        self.setSelectedDirection(0)
        PianoKeyboardModel.shared.redraw()

        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.score = score
            }
        }
    }
    
    func setKeyboard() {
        Logger.shared.log(self, "setScaleAndScore to:\(scale.getScaleName())")
        var scale = self.scale
        scale.octaves = 4
        //scale.scaleType = .major
        self.scale = scale
        PianoKeyboardModel.shared.configureKeyboardForScale(scale: scale)
        self.setSelectedDirection(0)
        PianoKeyboardModel.shared.unmapScaleFingersToKeyboard()
        PianoKeyboardModel.shared.redraw()

        DispatchQueue.main.async {
            ///Absolutely no idea why but if not here the score wont display 😡
            DispatchQueue.main.async {
                self.score = self.score
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
        
    func setTempo(_ index:Int) {
        //DispatchQueue.main.async {
            self.selectedTempoIndex = index
            //PianoKeyboardModel.shared.setFingers(direction: index)
        //}
    }

    func saveTapsToFile(tapSets:[TapEventSet], result:Result) {
        let scale = self.scale
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let day = calendar.component(.day, from: Date())
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let device = UIDevice.current
        let modelName = device.model
        var keyName = scale.getScaleName()
        keyName = keyName.replacingOccurrences(of: " ", with: "")
        var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"+String(format: "%02d", hour)+"_"+String(format: "%02d", minute)
        fileName += "_"+keyName + "_"+String(scale.octaves) + "_" + String(scale.scaleNoteState[0].midi) + "_" + modelName
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



