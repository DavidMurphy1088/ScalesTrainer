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
    @Published var recordingIsPlaying = false
    @Published var synchedIsPlaying = false

    var scoreHidden = false
    var metronomeTicker:MetronomeTicker? = nil
    
    var recordedTapsFileURL:URL? //File where recorded taps were written
    @Published var recordedTapsFileName:String?
    
    var scaleLeadInCounts:[String] = ["No Clicks", "Two Clicks", "Four Clicks"]
    
    var directionTypes = ["⬆", "⬇"]
    
    var handTypes = ["Right", "Left"]

    var tempoSettings:[String] = []
    @Published var tempoChangePublished = false
    var selectedTempoIndex = 5 //60=2
        
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
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

    @Published private(set) var spinStatePublished:SpinState = .notStarted
    private(set) var spinState:SpinState = .notStarted
    func setSpinState(_ value:SpinState) {
        self.spinState = value
        DispatchQueue.main.async {
            self.spinStatePublished = value
        }
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
            PianoKeyboardModel.sharedRH.redraw()
            PianoKeyboardModel.sharedLH.redraw()
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
    
    //@Published Cant use it. Published needs main thread update but some processes cant wait for tjhe main thread to update it.
    var selectedScaleSegment = 0
    @Published var selectedScaleSegmentPublished = 0
    func setSelectedScaleSegment(_ segment:Int) {
        if segment == self.selectedScaleSegment {
            return
        }
        
        self.selectedScaleSegment = segment
        DispatchQueue.main.async { 
            self.selectedScaleSegmentPublished = segment
        }
        if let combined = PianoKeyboardModel.sharedCombined {
            combined.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, hand: 0)
            combined.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, hand: 1)
            combined.redraw()
        }
        else {
            PianoKeyboardModel.sharedRH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedLH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedRH.clearAllKeyWasPlayedState()
            PianoKeyboardModel.sharedLH.clearAllKeyWasPlayedState()
            
            PianoKeyboardModel.sharedRH.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, hand: 0)
            PianoKeyboardModel.sharedRH.redraw()
            PianoKeyboardModel.sharedLH.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, hand: 1)
            PianoKeyboardModel.sharedLH.redraw()
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
//        if let audioFile = self.recordedAudioFile {
//            let fileURL = audioFile.url
//            let fileManager = FileManager.default
//            do {
//                if fileManager.fileExists(atPath: fileURL.path) {
//                    try fileManager.removeItem(at: fileURL)
//                }
//            } catch {
//                Logger.shared.reportError(self, "Cant delete audio file file: \(error)")
//            }
//        }
        DispatchQueue.main.async {
            self.recordedAudioFile = file
        }
    }
    
    ///Dont make backing a full blown process. This way Its designed to be able to run with a full blown process (but does not yet)
    @Published private(set) var backingOn:Bool = false
    func setBacking(_ way:Bool) {
        let metronome = Metronome.shared
        if way {
            if self.backer == nil {
                self.backer = Backer()
            }
            metronome.addProcessesToNotify(process: self.backer!)
            metronome.setTicking(way: true)
            metronome.start()
        }
        else {
            metronome.stop()
        }
        DispatchQueue.main.async {
            self.backingOn = way
        }
    }
    
    //init(musicBoardGrade:MusicBoardGrade) {
    init() {
        self.scale = Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                          minTempo: 90, dynamicType: .mf, articulationType: .legato)
        self.calibrationTapHandler = nil
        DispatchQueue.main.async {
            //PianoKeyboardModel.shared1.configureKeyboardForScale(scale: self.scale, handIndex: self.scale.hands[0])
            //PianoKeyboardModel.sharedLeftHand.configureKeyboardForScale(scale: self.scale, handIndex: 1)
        }
    }
    
    func setRunningProcess(_ setProcess: RunningProcess, amplitudeFilter:Double? = nil) {
        if setProcess == self.runningProcess {
            return
        }
        Logger.shared.log(self, "Setting process from:\(self.runningProcess) to:\(setProcess.description)")
        if setProcess == .none {
            self.audioManager.stopRecording()
            if self.runningProcess == .syncRecording {
                DispatchQueue.main.async {
                    self.synchedIsPlaying = false
                }
            }
            
            PianoKeyboardModel.sharedLH.hilightNotesOutsideScale = true
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = true
            if self.tapHandlers.count > 0 {
                self.setTapEventSet(self.tapHandlers[0].stopTappingProcess(), publish: true)
            }
            //self.tapHandlers = [] //Dont remove them here. Processes may want them before next process
        }
        else {
            self.tapHandlers = []
            setUserMessage(heading: nil, msg: nil)
            BadgeBank.shared.setShow(false)
            self.setSelectedScaleSegment(0)
        }
        Metronome.shared.stop()
        self.setBacking(false)
        self.runningProcess = setProcess
        DispatchQueue.main.async {
            self.runningProcessPublished = self.runningProcess
        }

        ///For some unknown reason the 1st call does not silence some residue sound from the sampler. The 2nd does appear to.
        self.audioManager.resetAudioKit()
        self.audioManager.resetAudioKit()

        self.setShowKeyboard(true)
        self.setShowLegend(true)
        self.setSelectedScaleSegment(0)
        self.setProcessInstructions(nil)
        if resultInternal != nil {
            self.setShowStaff(true)
        }
        
        PianoKeyboardModel.sharedRH.clearAllFollowingKeyHilights(except: nil)
        PianoKeyboardModel.sharedRH.redraw()
        PianoKeyboardModel.sharedLH.clearAllFollowingKeyHilights(except: nil)
        PianoKeyboardModel.sharedLH.redraw()
        
        let metronome = Metronome.shared
        
        if [.followingScale].contains(setProcess)  {
            self.setResultInternal(nil, "setRunningProcess::nil for follow/practice")
            self.tapHandlers.append(RealTimeTapHandler(bufferSize: 4096, scale:self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            BadgeBank.shared.setTotalCorrect(0)
            setShowKeyboard(true)
            ///Play first note to start then wait some time.
            ///Wait for note to die down otherwise it triggers the first note detection
            if self.scale.scaleNoteState.count > 0 {
                if let sampler = self.audioManager.keyboardMidiSampler {
                    BadgeBank.shared.setShow(true)
                    
                    let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                    for hand in scale.hands {
                        let midi = self.scale.scaleNoteState[hand][0].midi
                        if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi, segment: 0) {
                            let key = keyboard.pianoKeyModel[keyIndex]
                            //key.hilightCallback = {
                            //sampler.play(noteNumber: UInt8(midi), velocity: 64, channel: 0)
                            //}
                            key.hilightKeyToFollow = PianoKeyHilightType.followThisNote
                            keyboard.redraw1()
                        }
                        sampler.play(noteNumber: UInt8(midi), velocity: 64, channel: 0)
                    }
                    ///Need delay to avoid the first note being 'heard' from this sampler playing note
                    usleep(1000000 * UInt32(1.0))
                }
                self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: false)
                self.followScaleProcess(hands: scale.hands, onDone: {cancelled in
                    self.setRunningProcess(.none)
                })
            }
        }
        
        if [.leadingTheScale].contains(setProcess) {
            BadgeBank.shared.setShow(true)
            BadgeBank.shared.setTotalCorrect(0)
            BadgeBank.shared.setTotalIncorrect(0)
            let leadProcess = LeadScaleProcess(scalesModel: self, metronome: metronome)
            self.tapHandlers.append(RealTimeTapHandler(bufferSize: 4096, scale:self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
            leadProcess.start()
            if true {
                self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: false)
            }
            else {
                leadProcess.playDemo()
            }
        }
        
        if [.playingAlongWithScale].contains(setProcess) {
            metronome.addProcessesToNotify(process: HearScalePlayer(hands: scale.hands))
            metronome.setTicking(way: true)
            metronome.start()
        }

        if [RunningProcess.recordingScale].contains(setProcess) {
            self.audioManager.startRecordingMicToRecord()
            metronome.setTicking(way: true)
            metronome.start()
            //metronome.addProcessesToNotify(process: RecordScaleProcess())
        }
        
        if [RunningProcess.recordingScaleForAssessment, RunningProcess.recordScaleWithFileData].contains(setProcess)  {
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
            self.scale.resetMatchedData()
            self.setShowKeyboard(false)
            self.setShowStaff(false)
            //self.setShowParameters(false)
            self.setShowLegend(false)
            self.setResultInternal(nil, "setRunningProcess::start record")
            setUserMessage(heading: nil, msg: nil)
            self.setProcessedEventSet(nil, publish: true)
            PianoKeyboardModel.sharedRH.redraw()
            PianoKeyboardModel.sharedLH.redraw()
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
    
//    func isMetronomeTicking() -> Bool {
//        return self.metronomeTicker != nil
//    }
    
    ///Allow user to follow notes hilighted on the keyboard.
    ///Wait till user hits correct key before moving to and highlighting the next note
    func followScaleProcess(hands:[Int], onDone:((_ cancelled:Bool)->Void)?) {
        
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
            if scale.hands.count == 1 {
                let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: keyboard, semaphore: DispatchSemaphore(value: 0)))
            }
            else {
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedRH, semaphore: DispatchSemaphore(value: 0)))
                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedLH, semaphore: DispatchSemaphore(value: 0)))
            }
            
            var cancelled = false
            
            ///Listen for cancelled state. If cancelled make sure all semaphores are signalled so the the process thread can exit
            ///appmode is None at start since its set (for publish)  in main thread
            DispatchQueue.global(qos: .background).async {
                while true {
                    sleep(1)
                    if self.runningProcess != .followingScale {
                        cancelled = true
                        for keyboardSemaphore in keyboardSemaphores {
                            keyboardSemaphore.semaphore.signal()
                            keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: nil)
                        }
                        break
                    }
                }
            }
            
            var scaleIndex = 0
            var inScaleCount = 0
            
            while true {
                if scaleIndex >= self.scale.scaleNoteState[0].count {
                    break
                }
                ///Add a semaphore to detect when the expected keyboard key is played
                for keyboardSemaphore in keyboardSemaphores {
                    let note = self.scale.scaleNoteState[keyboardSemaphore.keyboard.keyboardNumber - 1][scaleIndex]
                    guard let keyIndex = keyboardSemaphore.keyboard.getKeyIndexForMidi(midi:note.midi, segment:note.segments[0]) else {
                        scaleIndex += 1
                        continue
                    }
                    //currentMidis.append(note.midi)
                    let pianoKey = keyboardSemaphore.keyboard.pianoKeyModel[keyIndex]
                    keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: keyIndex)
                    pianoKey.hilightKeyToFollow = .followThisNote
                    keyboardSemaphore.keyboard.redraw()
                    ///Listen for piano key pressed
                    pianoKey.wasPlayedCallback = {
                        keyboardSemaphore.semaphore.signal()
                        inScaleCount += 1
                        keyboardSemaphore.keyboard.redraw()
                        pianoKey.wasPlayedCallback = nil
                    }
                }

                ///Wait for the right key to be played and signalled on every keyboard

                for keyboardSemaphore in keyboardSemaphores {
                    if !cancelled && self.runningProcess == .followingScale {
                        keyboardSemaphore.semaphore.wait()
                    }
                }
                
                if !cancelled {
                    BadgeBank.shared.setTotalCorrect(BadgeBank.shared.totalCorrect + 1)
                }
                if cancelled || self.runningProcess != .followingScale || scaleIndex >= self.scale.scaleNoteState[0].count - 1 {
                    //self.setSelectedScaleSegment(0)
                    break
                }
                else {
                    scaleIndex += 1
                    let nextNote = self.scale.scaleNoteState[0][scaleIndex]
                    self.setSelectedScaleSegment(nextNote.segments[0])
                }
            }
            self.audioManager.stopRecording()
            self.setSelectedScaleSegment(0)

            if inScaleCount > 2 {
                var msg = "😊 Good job following the scale"
                msg += "\nYou played \(inScaleCount) notes in the scale"
                //msg += "\nYou played \(xxx) notes out of the scale"
                ScalesModel.shared.setUserMessage(heading: "Following the Scale", msg:msg)
            }

            if let onDone = onDone {
                onDone(true)
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
        let isBrokenChord = [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType)
        
        staffType = hand == 0 ? .treble : .bass
        let staffKeyType:StaffKey.StaffKeyType = [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh, .chromatic, .brokenChordMajor].contains(scale.scaleType) ? .major : .minor
        let keySignature:KeySignature
        if [.chromatic].contains(scale.scaleType) {
            keySignature = KeySignature(keyName: "C", keyType: .major)
        }
        else {
            keySignature = KeySignature(keyName: scale.scaleRoot.name, keyType: staffKeyType)
        }
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)

        let timeSigVisible = false //isBrokenChord ? false : true
        let timeSig = scale.timeSignature
        let score = Score(scale: scale, key: staffKey, timeSignature: TimeSignature(top: timeSig.top, bottom: timeSig.bottom, visible: timeSigVisible), linesPerStaff: 5)

        let staff = Staff(score: score, type: staffType, staffNum: 0, linesInStaff: 5)
        score.addStaff(num: 0, staff: staff)
        var totalBarValue = 0.0
        let mult = timeSig.bottom == 8 ? StaffNote.VALUE_TRIPLET : StaffNote.VALUE_QUARTER
        let maxBarValue:Double = Double(timeSig.top) * mult
        
        for i in 0..<scale.scaleNoteState[hand].count {
            if totalBarValue >= maxBarValue {
                ///Bar line is required to calculate presence or not of accidentals in chromatic scales. It can also provide visible note spacing when required.
                ///The bar line not currenlty visible but it might be added to add space around notes
                ///13Oct24 Update - presence of the bar line causes melodic minor scale accidentals to differ from Trinity which appears to assume that all scale notes in in one bar only.
                if false {
                    score.addBarLine(visibleOnStaff: false, forStaffSpacing: isBrokenChord)
                    totalBarValue = 0.0
                }
            }
            let noteState = scale.scaleNoteState[hand][i]
            let ts = score.createTimeSlice()
            let value:Double
            let note = StaffNote(timeSlice: ts, midi: noteState.midi, value: noteState.value, segments: noteState.segments, staffNum: 0)
            note.setValue(value: noteState.value)
            ts.addNote(n: note)
            totalBarValue += noteState.value
        }
        
//        if isBrokenChord {
//            value = noteState.value == StaffNote.VALUE_TRIPLET ? noteState.value : StaffNote.VALUE_QUARTER + StaffNote.VALUE_QUAVER
//        }
//        else {
//            value = noteState.value
//        }

        //score.debugScore2("Broken", withBeam: true, toleranceLevel: 0)
        //Logger.shared.log(self, "Created score type:\(staffType)")
        return score
    }
    
    func setScale(scale:Scale) {
        ///Deep copy to ensure reset of the scale segments
        self.setScaleByRootAndType(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType, scaleMotion: scale.scaleMotion,
                                   minTempo: scale.minTempo, octaves: scale.octaves, hands: scale.hands, ctx: "ScalesModel")
    }

    func setScaleByRootAndType(scaleRoot: ScaleRoot, scaleType:ScaleType, scaleMotion:ScaleMotion, minTempo:Int, octaves:Int, hands:[Int], ctx:String) {
        let name = scale.getScaleName(handFull: true, octaves: true)
        Logger.shared.log(self, "setScaleByRootAndType to:root:\(name)")
                          //ctx:\(ctx) from:\(self.scale.getScaleName(handFull: false, octaves: false))")
        let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoot.name),
                          scaleType: scaleType, scaleMotion: scaleMotion,
                           octaves: octaves,
                           hands: hands,
                          minTempo: minTempo, dynamicType: .mf, articulationType: .legato)
        setScaleKeyboardAndScore(scale: scale)
    }

    private func setScaleKeyboardAndScore(scale:Scale) {
        ///This assumes a new scale as input. This method does not re-initialize the scale segments. i.e. cannot be used for a scale that was already used
        let name = scale.getScaleName(handFull: true, octaves: true)
        Logger.shared.log(self, "setScale to:\(name)")
        
        let scoreRH = self.createScore(scale: scale, hand: 0)
        let scoreLH = self.createScore(scale: scale, hand: 1)
        if scale.timeSignature.top == 3 {
            self.tempoSettings = ["42", "44", "46", "48", "50", "52", "54", "56", "58", "60"]
        }
        else {
            self.tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120", "130"]
        }

        self.configureKeyboards(scale: scale, ctx: "setScale")
        DispatchQueue.main.async {
            ///Scores are @Published so set them here
            DispatchQueue.main.async {
                self.tempoChangePublished = !self.tempoChangePublished
                self.scores = [scoreRH, scoreLH]
            }
        }
    }
    
    func configureKeyboards(scale:Scale, ctx:String) {
        let name1 = scale.getScaleName(handFull: true, octaves: true)
        Logger.shared.log(self, "setScaleAndScore to:\(name1) ctx:\(ctx)")
        self.scale = scale
        
        if let combinedKeyboard = PianoKeyboardModel.sharedCombined {
            combinedKeyboard.resetLinkScaleFingersToKeyboardKeys()
            combinedKeyboard.configureKeyboardForScale(scale: scale, hand: 0)
            self.setSelectedScaleSegment(0)
            let middleKey = combinedKeyboard.pianoKeyModel.count / 2
            combinedKeyboard.pianoKeyModel[middleKey].setKeyPlaying(hilight: true)
            combinedKeyboard.redraw()
        }
        else {
            ///Set the single RH and RH keyboard
            PianoKeyboardModel.sharedRH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedLH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedRH.configureKeyboardForScale(scale: scale, hand: 0)
            PianoKeyboardModel.sharedLH.configureKeyboardForScale(scale: scale, hand: 1)
            self.setSelectedScaleSegment(0)
            PianoKeyboardModel.sharedRH.redraw()
            PianoKeyboardModel.sharedLH.redraw()
        }
    }

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
        var keyName = scale.getScaleName(handFull: true)
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



