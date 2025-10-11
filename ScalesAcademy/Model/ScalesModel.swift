import Foundation
import AVFoundation
import Combine
import SwiftUI
import AudioKit

///None -> user can see finger numbers and tap virtual keyboard - notes are hilighted if in scale
///Practice -> user can use acoustic piano. keyboard display same as .none
///assessWithScale -> acoustic piano, note played and unplayed in scale are marked. Result is gradable. Result is displayed

enum MicTappingMode {
    case off
    case onWithCalibration
    case onWithPractice
    case onWithRecordingScale
}

public enum UnitTestMode {
    case none
    case save
    case test
}

enum RunningProcess {
    case none
    case followingScale
    case leadingTheScale
    case recordingScale
    case playingAlong
    case backingOn

    var description: String {
        switch self {
        case .none:
            return "None"
        case .followingScale:
            return "Following Scale"
        case .leadingTheScale:
            return "Leading Scale"
        case .recordingScale:
            return "Recording Scale"
        case .playingAlong:
            return "Playing Along With Scale"
        case .backingOn:
            return "Backing On"
        }
    }
}

public class ScalesModel : ObservableObject {
    static public var shared = ScalesModel("static init")
    private let id:UUID
    private(set) var scale:Scale
    
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard
    @Published var isPracticing = false
    
    @Published private var score1:Score? = nil
    func getScore() -> Score? {
        return self.score1
    }
    @Published var recordingIsPlaying = false

    private let setProcessLock = NSLock()
    
    var scoreHidden = false
    var metronomeTicker:MetronomeTicker? = nil
    
    var recordedTapsFileURL:URL? //File where recorded taps were written
    @Published var recordedTapsFileName:String?
    
    var scaleLeadInCounts:[String] = ["No Clicks", "Two Clicks", "Four Clicks"]
    
    var directionTypes = ["⬆", "⬇"]
    
    var handTypes = ["Right", "Left"]

    //public var tempoSettings:[String]
    public var tempoSettings:[Int]

    @Published var tempoChangePublished = false
    private var selectedTempoIndex = 0 //5 //60=2

    var exerciseBadge:ExerciseBadge?
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    //let calibrationTapHandler:RealTimeTapHandler? //(requiredStartAmplitude: 0, recordData: false, scale: nil)
    let audioManager = AudioManager.shared
    let logger = AppLogger.shared
    var helpTopic:String? = nil
    var onRecordingDoneCallback:(()->Void)?
    var soundEventHandlers:[SoundEventHandlerProtocol] = []
    
    ///Just used for receiving MIDI messages locally generated for testing
    var midiTestHander:MIDISoundEventHandler?
        
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

    ///Speech
    @Published var speechListenMode = false
    @Published var speechLastWord = ""

    ///Result cannot be published since it needs to be updated on the main thread. e.g. for rapid callibration analyses
    ///ResultDisplay is the published version
//    private(set) var resultInternal:Result?
//    func setResultInternal(_ result:Result?, _ ctx:String) {
//        //let noErrors = result == nil ? true : result!.noErrors()
//        self.resultInternal = result
//        DispatchQueue.main.async {
//            self.resultPublished = result
//            PianoKeyboardModel.sharedRH.redraw()
//            PianoKeyboardModel.sharedLH.redraw()
//        }
//    }
//    @Published private(set) var resultPublished:Result?

    enum DirectionOfPlay {
        case upwards
        case downwards
    }
    @Published private(set) var directionOfPlayPublished:DirectionOfPlay? = nil // = DirectionOfPlay.upwards
    func setInitialDirectionOfPlay(scale:Scale) {
        DispatchQueue.main.async {
            let reverse = self.scale.hands.count == 1 && self.scale.hands[0] == 1 && self.scale.scaleMotion == .contraryMotion
            self.directionOfPlayPublished = reverse ? .downwards : .upwards
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
    
    //@Published Cant use it. Published needs main thread update but some processes cant wait for the main thread to update it.
    var selectedScaleSegment = 0
    @Published var selectedScaleSegmentPublished = 0
    func setSelectedScaleSegment(_ segment:Int) {
        if segment == self.selectedScaleSegment {
//            if self.directionOfPlayPublished != nil {
//                return
//            }
        }
        
        self.selectedScaleSegment = segment
        DispatchQueue.main.async { 
            self.selectedScaleSegmentPublished = segment
            let scaleSegments = self.scale.getMinMaxSegments()
            let reverse = self.scale.hands.count == 1 && self.scale.hands[0] == 1 && self.scale.scaleMotion == .contraryMotion
            if scaleSegments.0 == segment {
                self.directionOfPlayPublished = reverse ? DirectionOfPlay.downwards : DirectionOfPlay.upwards
            }
            else {
                self.directionOfPlayPublished = reverse ? DirectionOfPlay.upwards : DirectionOfPlay.downwards
            }
        }
        if let combined = PianoKeyboardModel.sharedCombined {
            combined.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, handType: .right, scaleDirection: segment)
            combined.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, handType: .left, scaleDirection: segment)
            combined.redraw()
        }
        else {
            PianoKeyboardModel.sharedRH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedLH.resetLinkScaleFingersToKeyboardKeys()
            PianoKeyboardModel.sharedRH.clearAllKeyWasPlayedState()
            PianoKeyboardModel.sharedLH.clearAllKeyWasPlayedState()
            
            PianoKeyboardModel.sharedRH.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, handType: .right, scaleDirection: segment)
            PianoKeyboardModel.sharedRH.redraw()
            PianoKeyboardModel.sharedLH.linkScaleFingersToKeyboardKeys(scale: self.scale, scaleSegment: segment, handType: .left,
                                                                       scaleDirection: segment)
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
        DispatchQueue.main.async {
            self.recordedAudioFile = file
        }
    }
    
    //init(musicBoardGrade:MusicBoardGrade) {
    init(_ ctx:String) {
        self.scale = Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                          minTempo: 90, dynamicTypes: [.mf], articulationTypes: [.legato])
//        if scale.timeSignature.top == 3 {
//            self.tempoSettings = ["42", "44", "46", "48", "50", "52", "54", "56", "58", "60"]
//        }
//        else {
//            self.tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120", "130"]
//        }
        self.id = UUID()
        self.tempoSettings = []
    }
    
    func setTempos(scale:Scale) {
        if scale.timeSignature.top == 3 {
            self.tempoSettings = [42, 44, 46, 48, 50, 52, 54, 56, 58, 60]
        }
        else {
            self.tempoSettings = [40, 50, 60, 70, 80, 90, 100, 110, 120, 130]
        }
        if !self.tempoSettings.contains(scale.minTempo) {
            self.tempoSettings.append(scale.minTempo)
            tempoSettings.sort()
        }
    }
    
    func exerciseCompletedNotify() {
        if soundEventHandlers.count > 0 {
            let soundHandler = soundEventHandlers[0]
            soundHandler.setFunctionToNotify(functionToNotify: nil)
        }
    }
    
//    ///Show the key hilights for the Follow task
//    func showFollowKeyHilights(sampler:MIDISampler) {
//        for hand in scale.hands {
//            if let noteState = self.scale.getScaleNoteState(handType: hand == 0 ? .right : .left, index: 0) {
//                let midi = noteState.midi
//                let keyboard:PianoKeyboardModel
//                if let combined = PianoKeyboardModel.sharedCombined {
//                    keyboard = combined
//                }
//                else {
//                    keyboard = hand == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
//                }
//                
//                if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
//                    let key = keyboard.pianoKeyModel[keyIndex]
//                    //key.hilightCallback = {
//                    //sampler.play(noteNumber: UInt8(midi), velocity: 64, channel: 0)
//                    //}
//                    key.hilightKeyToFollow = PianoKeyHilightType.followThisNote
//                    keyboard.redraw1()
//                }
//                sampler.play(noteNumber: UInt8(midi), velocity: 64, channel: 0)
//            }
//        }
//    }
    
    func setRunningProcess(_ setProcess: RunningProcess, amplitudeFilter:Double? = nil) {
        let metronome = Metronome.shared
        let user = Settings.shared.getCurrentUser("Scales model, set Run process")
        if setProcess == .leadingTheScale {
            
        }
        if setProcess == self.runningProcess {
            return
        }
        setProcessLock.lock()
        defer {
            setProcessLock.unlock()
        }
        AppLogger.shared.log(self, "Setting process from:\(self.runningProcess) to:\(setProcess.description)")
        if setProcess == .none {
            self.audioManager.stopListening()
//            if self.runningProcess == .syncRecording {
//                DispatchQueue.main.async {
//                    self.synchedIsPlaying = false
//                }
//            }
            
            PianoKeyboardModel.sharedLH.hilightNotesOutsideScale = true
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = true
            if self.soundEventHandlers.count > 0 {
                //self.setTapEventSet(self.tapHandlers[0].stopTappingProcess(), publish: true)
                //self.setTapEventSet(self.soundEventHandlers[0].stop(), publish: true)
                self.soundEventHandlers[0].stop()
            }
            //self.tapHandlers = [] //Dont remove them here. Processes may want them before next process
        }
        else {
            self.soundEventHandlers = []
            setUserMessage(heading: nil, msg: nil)
            self.setSelectedScaleSegment(0)
        }
        
        //metronome.stop("ScalesModel 1 Process:\(setProcess)")

        self.runningProcess = setProcess
        DispatchQueue.main.async {
            self.runningProcessPublished = self.runningProcess
        }

        ///For some unknown reason the 1st call does not silence some residue sound from the sampler. The 2nd does appear to.
        //self.audioManager.resetAudioKit()
        //self.audioManager.resetAudioKit()

        self.setShowKeyboard(true)
        self.setShowLegend(true)
        self.setSelectedScaleSegment(0)
        
        PianoKeyboardModel.sharedRH.clearAllFollowingKeyHilights(except: nil)
        PianoKeyboardModel.sharedRH.redraw()
        PianoKeyboardModel.sharedLH.clearAllFollowingKeyHilights(except: nil)
        PianoKeyboardModel.sharedLH.redraw()
        
        if [.followingScale, .leadingTheScale].contains(setProcess) {
            let soundHandler:SoundEventHandlerProtocol
            if user.settings.useMidiSources {
                soundHandler = MIDISoundEventHandler(scale: scale)
                self.midiTestHander = soundHandler as? MIDISoundEventHandler
            }
            else {
                soundHandler = AcousticSoundEventHandler(scale: scale)
            }
            self.soundEventHandlers.append(soundHandler)
            self.exerciseBadge = ExerciseBadge.getRandomExerciseBadge()
            let exerciseProcess = ExerciseHandler(exerciseType: setProcess, scalesModel: self, metronome: metronome)
            exerciseProcess.start(soundHandler: soundHandler)
            if !user.settings.useMidiSources {
                self.audioManager.configureAudio(withMic: true, recordAudio: false, soundEventHandlers: self.soundEventHandlers)
            }
        }
        
        if [.playingAlong].contains(setProcess) {
            //self.audioManager.configureAudio(withMic: false, recordAudio: false)
            //metronome.stop("ScalesModel PlayAlong")
            //metronome.addProcessesToNotify(process: HearScalePlayer(hands: scale.hands, process: .playingAlong))
            //metronome.start("ScalesModel PlayAlong", doLeadIn: true, scale: self.scale)
        }
        
        if [.backingOn].contains(setProcess) {
//            self.audioManager.configureAudio(withMic: false, recordAudio: false)
//            metronome.stop("ScalesModel Backing")
//            //metronome.addProcessesToNotify(process: HearScalePlayer(hands: scale.hands, process: .backingOn, endCallback: <#() -> Void#>))
//            metronome.start("ScalesModel Backing", doLeadIn: true, scale: self.scale)
        }

        if [RunningProcess.recordingScale].contains(setProcess) {
//            self.audioManager.configureAudio(withMic: true, recordAudio: true, soundEventHandlers: self.soundEventHandlers)
//            metronome.stop("ScalesModel Record")
//            metronome.start("ScalesModel Record", doLeadIn: true, scale: self.scale)
        }
        
//        if [RunningProcess.recordingScaleForAssessment, RunningProcess.recordScaleWithFileData].contains(setProcess)  {
//            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
//            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
//            self.scale.resetMatchedData()
//            self.setShowKeyboard(false)
//            self.setShowStaff(false)
//            self.setShowLegend(false)
//            self.setResultInternal(nil, "setRunningProcess::start record")
//            setUserMessage(heading: nil, msg: nil)
//            self.setProcessedEventSet(nil, publish: true)
//            PianoKeyboardModel.sharedRH.redraw()
//            PianoKeyboardModel.sharedLH.redraw()
//            ///4096 has extra params to figure out automatic scale play end
//            ///WARING - adding too many seems to have a penalty on accuracy of the standard sizes like 4096. i.e. 4096 gets more taps on its own than when >2 others are also installed.
////            self.tapHandlers.append(ScaleTapHandler(bufferSize: 4096, scale: self.scale, amplitudeFilter: Settings.shared.amplitudeFilter))
////            self.tapHandlers.append(ScaleTapHandler(bufferSize: 2048, scale: self.scale, amplitudeFilter: nil))
////            self.tapHandlers.append(ScaleTapHandler(bufferSize: 8192 * 2, scale: self.scale, amplitudeFilter: nil))
//
//            //self.tapHandlers.append(ScaleTapHandler(bufferSize: 2 * 8192, scale: nil, amplitudeFilter: nil))
//            self.recordedTapsFileURL = nil
//            if setProcess == .recordScaleWithFileData {
//                ///For plaback of an emailed file
//                let tapEventSets = self.audioManager.readTestDataFile()
//                //self.audioManager.playbackTapEvents(tapEventSets: tapEventSets, tapHandlers: self.tapHandlers)
//            }
//
//            if setProcess == .recordingScaleForAssessment {
//                DispatchQueue.main.async {
//                    //self.runningProcess = .leadingIn
//                }
////                doLeadIn(instruction: "Record your scale", leadInDone: {
////                    //😡😡 cannot record and tap concurrenlty
////                    //self.audioManager.startRecordingMicWithTapHandler(tapHandler: tapHandler, recordAudio: true)
////                    DispatchQueue.main.async {
////                        self.runningProcess = RunningProcess.recordingScaleForAssessment
////                    }
////                    self.audioManager.startRecordingMicWithTapHandlers(tapHandlers: self.tapHandlers, recordAudio: true)
////                })
//            }
//        }
    }
    
    ///Allow user to follow notes hilighted on the keyboard.
    ///Wait till user hits correct key before moving to and highlighting the next note
//    func followScaleProcessOLD(hands:[Int], onDone:((_ cancelled:Bool)->Void)?) {
//        
//        DispatchQueue.global(qos: .background).async { [self] in
//            class KeyboardSemaphore {
//                let keyboard:PianoKeyboardModel
//                let semaphore:DispatchSemaphore
//                init(keyboard:PianoKeyboardModel, semaphore:DispatchSemaphore) {
//                    self.keyboard = keyboard
//                    self.semaphore = semaphore
//                }
//            }
//            var keyboardSemaphores:[KeyboardSemaphore] = []
//            if scale.hands.count == 1 {
//                let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
//                keyboardSemaphores.append(KeyboardSemaphore(keyboard: keyboard, semaphore: DispatchSemaphore(value: 0)))
//            }
//            else {
//                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedRH, semaphore: DispatchSemaphore(value: 0)))
//                keyboardSemaphores.append(KeyboardSemaphore(keyboard: PianoKeyboardModel.sharedLH, semaphore: DispatchSemaphore(value: 0)))
//            }
//            
//            var cancelled = false
//            
//            ///Listen for cancelled state. If cancelled make sure all semaphores are signalled so the the process thread can exit
//            ///appmode is None at start since its set (for publish)  in main thread
//            DispatchQueue.global(qos: .background).async {
//                while true {
//                    sleep(1)
//                    if self.runningProcess != .followingScale {
//                        cancelled = true
//                        for keyboardSemaphore in keyboardSemaphores {
//                            keyboardSemaphore.semaphore.signal()
//                            keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: nil)
//                        }
//                        break
//                    }
//                }
//            }
//            
//            var scaleIndex = 0
//            var inScaleCount = 0
//            
//            while true {
//                if scaleIndex >= self.scale.getScaleNoteCount() {
//                    break
//                }
//                ///Add a semaphore to detect when the expected keyboard key is played
//                for keyboardSemaphore in keyboardSemaphores {
//                    let keyboardNumber = keyboardSemaphore.keyboard.keyboardNumber - 1
//                    let note = self.scale.getScaleNoteState(handType: keyboardNumber == 0 ? .right : .left, index: scaleIndex)
//                    guard let keyIndex = keyboardSemaphore.keyboard.getKeyIndexForMidi(midi:note.midi, segment:note.segments[0]) else {
//                        scaleIndex += 1
//                        continue
//                    }
//                    //currentMidis.append(note.midi)
//                    let pianoKey = keyboardSemaphore.keyboard.pianoKeyModel[keyIndex]
//                    keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: keyIndex)
//                    pianoKey.hilightKeyToFollow = .followThisNote
//                    keyboardSemaphore.keyboard.redraw()
//                    ///Listen for piano key pressed
//                    pianoKey.wasPlayedCallback = {
//                        keyboardSemaphore.semaphore.signal()
//                        inScaleCount += 1
//                        keyboardSemaphore.keyboard.redraw()
//                        pianoKey.wasPlayedCallback = nil
//                    }
//                }
//
//                ///Wait for the right key to be played and signalled on every keyboard
//
//                for keyboardSemaphore in keyboardSemaphores {
//                    if !cancelled && self.runningProcess == .followingScale {
//                        keyboardSemaphore.semaphore.wait()
//                    }
//                }
//                
//                if !cancelled {
//                    badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
//                }
//                if cancelled || self.runningProcess != .followingScale || scaleIndex >= self.scale.getScaleNoteCount() - 1 {
//                    //self.setSelectedScaleSegment(0)
//                    break
//                }
//                else {
//                    scaleIndex += 1
//                    let nextNote = self.scale.getScaleNoteState(handType: .right, index: scaleIndex)
//                    self.setSelectedScaleSegment(nextNote.segments[0])
//                }
//            }
//            self.audioManager.stopRecording()
//            self.setSelectedScaleSegment(0)
//
//            if inScaleCount > 2 {
//                var msg = "😊 Good job following the scale"
//                msg += "\nYou played \(inScaleCount) notes in the scale"
//                //msg += "\nYou played \(xxx) notes out of the scale"
//                ScalesModel.shared.setUserMessage(heading: "Following the Scale", msg:msg)
//            }
//
//            if let onDone = onDone {
//                onDone(true)
//            }
//        }
//    }
    
    func idStringDebug() -> String {
        let uuidString = self.id.uuidString
        return "🟢" + String(uuidString.suffix(6))
    }
    
    ///Get tempo for 1/4 note
//    func getTempo(_ ctx: String) -> Int {
//        var selected = self.tempoSettings[self.selectedTempoIndex]
//        //selected = String(selected)
//        //return Int(selected) ?? 60
//        return selected
//    }
    
    ///Add the required scales notes to the score as timeslices.
    func createScore(scale:Scale) -> Score {
        
        func addFinalRests(timeSig:TimeSignature, barValue:Double) {
            ///Add rests as required to fill the last bar
            var values:[Double] = []
            if timeSig.top == 4 {
                if barValue == 1 {
                    values = [1.0, 2.0]
                }
                if barValue == 2 {
                    values = [2.0]
                }
                if barValue == 3 {
                    values = [1.0]
                }
                
            }
            for v in values {
                let ts = score.createTimeSlice()
                for handType in handTypes {
                    let rest = Rest(timeSlice: ts, value: v, segments: [])
                    ts.addRest(rest: rest)
                }
            }
        }
        
        let isBrokenChord = [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType)
        
        let staffKeyType:StaffKey.StaffKeyType = [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh, .chromatic, .brokenChordMajor, .trinityBrokenTriad].contains(scale.scaleType) ? .major : .minor
        let keySignature:KeySignature
        if [.chromatic, .arpeggioDiminishedSeventh].contains(scale.scaleType) {
            keySignature = KeySignature(keyName: "C", keyType: .major)
        }
        else {
            keySignature = KeySignature(keyName: scale.scaleRoot.name, keyType: staffKeyType)
        }
        let staffKey = StaffKey(type: staffKeyType, keySig: keySignature)
        let timeSigVisible = false //isBrokenChord ? false : true
        let timeSig = scale.timeSignature
        let score = Score(scale: scale, key: staffKey,
                          timeSignature: TimeSignature(top: timeSig.top, bottom: timeSig.bottom, visible: timeSigVisible),
                          linesPerStaff: 5, debugOn: scale.debugOn)
        
        ///Add the required number of staves to the score depending on the number of hands
        var totalBarValue  = 0.0
        let mult = timeSig.bottom == 8 ? StaffNote.VALUE_TRIPLET : StaffNote.VALUE_QUARTER
        let maxBarValue:Double = Double(timeSig.top) * mult
        let handTypes:[HandType] = scale.hands.count > 1 ? [HandType.right,HandType.left] : [scale.hands[0] == 0 ? .right : .left]
        
        ///Add LH and RH notes played at the same time to the same TimeSlice and add bar lines.
        for i in 0..<scale.getScaleNoteCount() {
            if totalBarValue >= maxBarValue {
                ///Bar line is required to calculate presence or not of accidentals in chromatic scales. It can also provide visible note spacing when required.
                ///The bar line is not currenlty visible but it might be added to add space around notes
                ///13Oct24 Update - presence of the bar line causes melodic minor scale accidentals to differ from Trinity which appears to assume that all scale notes in in one bar only.
                ///29Oct24 Update - better to have harmonic minor match for Grade 1 Trinity. Trinity harmonic minor appears to imply invisible bar lines when setting accidentals.
                ///But their melodic minor does not imply invisible bar lines - nightmare 🥵 ....
                ///04Jan2025 -
                ///Trin Grade 1, D Min Harmonic assumes there is a barline - see the 2nd C#
                ///Trin Grade 1, D Min Melodic assumes there is not a barline - see the C natural
                ///This diff my require change in custom scale properties to add or not bar LinearGradient
                ///10Jan2025 - Both agree now to use bar lines even though Trinity dont.
                score.addBarLine(visibleOnStaff: true, forStaffSpacing: isBrokenChord)
                totalBarValue = 0.0
            }
            
            let ts = score.createTimeSlice()
            var maxValue:Double?
            
            ///The note for each hand is added to the one single TimeSlice
            for handType in handTypes {
                let noteState = scale.getScaleNoteState(handType: handType, index: i)
                if let noteState = noteState {
                    let note = StaffNote(timeSlice: ts, midi: noteState.midi, value: noteState.value, handType:handType, segments: noteState.segments)
                    note.setValue(value: noteState.value)
                    ts.addNote(n: note)
                    if maxValue == nil || noteState.value > maxBarValue {
                        maxValue = noteState.value
                    }
                }
            }
            if let maxValue = maxValue {
                totalBarValue += maxValue
            }
        }
        
        addFinalRests(timeSig: timeSig, barValue: totalBarValue)
        score.setTimesliceStartAtValues()
        
        ///===== Clef inserts ====
        
        ///Insert clefs into the score as ScoreEntries (not Timeslices) where necessary to reduce too many ledger lines.
        ///Clefs are inserted prior to a quaver group of notes if any note in that group requires too many ledger lines using the staff's current clef
        ///Clefs are inserted at the location of the first note in group's value offset within the scale
        ///The clef is inserted into both staves. e.g. if a (UI invisible) treble clef is insert into the LH staff a clef is also insert into the RH staff so the staffs still line up in the UI.
        ///Each note's vertical offset from the staff center is checked to see if it exceeds either the highest or lowest offset allowed before a clef switch must occur
        ///When each note in the scale is subsequently analysed for its position that analyis is conducated from the staff's current clef, not the staff's default clef (LH = bass clef etc)
        let timeSlices = score.getAllTimeSlices()
        let handIndex = 1
        var currentClefType = handIndex == 1 ? ClefType.bass : ClefType.treble
        var lastGroupStart = 0.0
        var offsetsInGroup:[Int] = []
        let offsetsAboveLimit = 8
        let offsetsBelowLimit = -7
        
        for tsIndex in 0..<timeSlices.count {
            ///Determine if a clef switch is required based on the notes in the group. If yes, insert the Clef in the score to 1) display and 2) set the right clef for subsequent note layout
            ///Consider a clef change only at a bar start
            var clefSwitchEnabled = true
            if let customisation = scale.scaleCustomisation {
                if let clefSwitch = customisation.clefSwitch {
                    clefSwitchEnabled = clefSwitch
                }
            }
            if clefSwitchEnabled {
                ///Clef switching currenlty only occurs in the LH stave. Only if it occurs there must an invisible clef be inserted into the RH stave to keep the two staves aligned.
                ///i.e. if the stave is the LH stave or its the LH and RH staves showing together.
                if scale.hands.contains(1) {
                    if timeSlices[tsIndex].valuePointInBar == 0 {
                        let highest = offsetsInGroup.max()
                        let lowest = offsetsInGroup.min()
                        if highest != nil && lowest != nil {
                            if (highest! > offsetsAboveLimit && currentClefType == .bass) || (lowest! < offsetsBelowLimit && currentClefType == .treble) {
                                let newClefType:ClefType = currentClefType == .bass ? .treble : .bass
                                score.addStaffClef(clefType: newClefType, handType: .left, atValuePosition: lastGroupStart)
                                currentClefType = newClefType
                            }
                        }
                        offsetsInGroup = []
                        lastGroupStart = timeSlices[tsIndex].valuePoint
                    }
                }
            }
            let timeSlice = timeSlices[tsIndex]
            let entries = timeSlice.getTimeSliceEntries(notesOnly: true)
            let noteIndex = scale.hands.count > 1 ? scale.hands[handIndex] : 0
            if entries.count <= noteIndex {
                continue
            }
            
            let staffNote = entries[noteIndex] as! StaffNote
            ///Analyse the note's placement in the current clef layout
            let clef = StaffClef(scale: scale, score: score, clefType: currentClefType)
            let placement = clef.getNoteViewPlacement(note: staffNote)
            offsetsInGroup.append(placement.offsetFromStaffMidline)
        }
        
        ///------------------------------------------------------------------------------------------------
        ///Create the required display staffs (one for the each hand) and position the required notes in them.
        ///Group all notes within a clef and then set their stem characteristics according to the clef just before them. i.e. obey clef switching
        ///------------------------------------------------------------------------------------------------

        ///Adjust this note's accidental to counter a previous note in the bar's accidental if the note was at the same staff offset but a different MIDI.
        ///If the MIDI is the same as the previous note at the staff offset, set this note's accidental to nil since it's accidental conveys from the previous note.
        ///If the note has an accidental but the key signature includes the accidental dont show the accidental on the note.
        func adjustNoteAccidentalGivenPreceedingBarNotes(clef:StaffClef, note:StaffNote, barNotes:[StaffNote]) {
            let notePlacement = note.noteStaffPlacement
            var matchedAccidental = false
            
            ///Counter any previous accidental based on the note's offset on the staff
            for prevNote in barNotes.reversed() {
                if prevNote.noteStaffPlacement.offsetFromStaffMidline == notePlacement.offsetFromStaffMidline {
                    if let lastAccidental = prevNote.noteStaffPlacement.accidental {
                        if prevNote.midi > note.midi {
                            notePlacement.accidental = lastAccidental - 1
                            matchedAccidental = true
                            break
                        }
                        if prevNote.midi < note.midi {
                            notePlacement.accidental = lastAccidental + 1
                            matchedAccidental = true
                            break
                        }
                        if prevNote.midi == note.midi {
                            notePlacement.accidental = nil
                            matchedAccidental = true
                            break
                        }
                    }
                    else {
                        ///Dont break - keep going since the absense of an accidental on this note does not mean there will be an earlier one whose accidental needs overriding
                       //break
                    }
                }
            }
            if matchedAccidental {
                return
            }
            if !notePlacement.placementCanBeSetByKeySignature {
                return
            }
            
            ///If not already matched, adjust the note's accidental based on the key signature
            
            ///Use no accidental since the key signature has it
            if clef.score.key.hasKeySignatureNote(note: note.midi) {
                notePlacement.accidental = nil
                matchedAccidental = true
            }
            ///Use the natural accidental to differentiate note from the key signature
            if clef.score.key.keySig.flats.count > 0 {
                if clef.score.key.hasKeySignatureNote(note: note.midi-1) {
                    //if notePlacement.placementCanBeSetByKeySignature {
                        notePlacement.accidental = 0
                        matchedAccidental = true
                    //}
                }
            }
            if clef.score.key.keySig.sharps.count > 0 {
                if clef.score.key.hasKeySignatureNote(note: note.midi+1) {
                    //if notePlacement.placementCanBeSetByKeySignature {
                        notePlacement.accidental = 0
                        matchedAccidental = true
                    //}
                }
            }
        }
        
        ///Rule for chromatics is you must use at least one of every line and space but no more than two. All chromatics are notated in key sig "C".
        ///You should use the --perfect 4th and perfect 5th -- above the base when you get to those pitches.
        ///This requires that the accidentals used for each note should match the accidental required for the first note.
        ///E.g. in D chromatic there must be a G (perfect 4th above) and an A (perfect 5th above)."
        ///These adjustments are made after the the note's default placements have been made on the staff.
        ///Use the first accidental found to apply to subsequent notes that need accidentals
        func adjustNotePlacementForChromatic(staffNote:StaffNote, firstAccidental:Int?) {
            //return
            let placement = staffNote.noteStaffPlacement
            if placement.accidental != nil && placement.accidental != firstAccidental {
                if placement.accidental == -1 {
                    placement.offsetFromStaffMidline -= 1
                    placement.accidental = 1
                    staffNote.noteStaffPlacement = placement
                    placement.placementCanBeSetByKeySignature = false
                    //lastAccidentalOffset = placement.offsetFromStaffMidline
                }
                else {
                    if placement.accidental == 1 {
                        placement.offsetFromStaffMidline += 1
                        placement.accidental = -1
                        staffNote.noteStaffPlacement = placement
                        placement.placementCanBeSetByKeySignature = false
                        //lastAccidentalOffset = placement.offsetFromStaffMidline
                    }
                }
            }
        }
        
        ///For a scale there must a a note for every note letter in the scale. A note letter must not repeat for consecutive notes
        ///This is required to ensure that scales like E♭harmonic minor show a C flat, not B natural for MIDI 71. MIDI 70 already shows the B flat.
        func adjustNotePlacementForScale(note:StaffNote, previousNote:StaffNote?, staffClef:StaffClef) {
            guard let previousNote = previousNote else {
                return
            }

            //Todo for say offset 1 to 2 its going up two semitones, not 1.
            if note.midi >= previousNote.midi {
                let delta = note.noteStaffPlacement.offsetFromStaffMidline - previousNote.noteStaffPlacement.offsetFromStaffMidline
                if delta == 1 {
                    return
                }
                if delta == 0 {
                    ///e.g. E♭ harmonic minor note=B
                    note.noteStaffPlacement.offsetFromStaffMidline += 1
                    note.noteStaffPlacement.accidental = -1
                }
                if delta == 2 {
                    ///e.g. F# major D# to F♮should be D# to E#
                    note.noteStaffPlacement.offsetFromStaffMidline -= 1
                    note.noteStaffPlacement.accidental = 1
                }
            }
            else {
                ///Descending
                let delta = previousNote.noteStaffPlacement.offsetFromStaffMidline - note.noteStaffPlacement.offsetFromStaffMidline
                if delta == 1 {
                    return
                }
                if delta == 0 {
                    note.noteStaffPlacement.offsetFromStaffMidline -= 1
                    note.noteStaffPlacement.accidental = 1
                }
                if delta == 2 {
                    note.noteStaffPlacement.offsetFromStaffMidline += 1
                    note.noteStaffPlacement.accidental = -1
                }
            }
            ///Dont let anything change the accidental since we've deliberately moved it to its own offset on the staff
            note.noteStaffPlacement.placementCanBeSetByKeySignature = false
        }
        
        var accidentalToUse:Int? = nil ///Use same accidental for both staffs. e,g, chromatic LH start E, RH start C
        
        /// Process all hands
        for handType in handTypes {
            var startStemCharacteristicsIndex = 0
            let staff = Staff(score: score, handType: handType, linesInStaff: 5)
            score.addStaff(staff: staff)
            var clefForPositioning = handType == .right ? StaffClef(scale: scale, score: score, clefType: .treble) : StaffClef(scale: scale, score: score, clefType: .bass)
            var notesInBar:[StaffNote] = []
            var previousScaleNote:StaffNote? = nil
            var clefSwitch = false
            
            /// Process all score entries - timeslices and bar line
            for scoreEntryIndex in 0..<score.scoreEntries.count {
                let scoreEntry = score.scoreEntries[scoreEntryIndex]
                if let staffClef = scoreEntry as? StaffClef {
                    ///Set stem characteristics for all the notes in the previous clef
                    if staff.handType == .left {
                        score.addStemCharacteristics(handType: handType, clef: clefForPositioning, startEntryIndex: startStemCharacteristicsIndex, endEntryIndex: scoreEntryIndex)
                        startStemCharacteristicsIndex = scoreEntryIndex
                        clefSwitch = clefForPositioning.clefType != staffClef.clefType
                        clefForPositioning = staffClef //Staff(score: score, type: staffClef.staffType, linesInStaff: 5)
                    }
                }
                if scoreEntry is BarLine {
                    notesInBar = []
                }
                
                ///Determine the placement and accidentals for each note in the score.
                if let timeSlice = scoreEntry as? TimeSlice {
                    
                    for staffNote in timeSlice.getTimeSliceNotes(handType: handType) {

                        staffNote.noteStaffPlacement = clefForPositioning.getNoteViewPlacement(note: staffNote)
                        if accidentalToUse == nil {
                            if staffNote.noteStaffPlacement.accidental != nil {
                                accidentalToUse = staffNote.noteStaffPlacement.accidental
                            }
                        }
                        if scale.scaleType == .chromatic {
                            adjustNotePlacementForChromatic(staffNote: staffNote, firstAccidental: accidentalToUse)
                        }
                        if [ScaleType.major, .naturalMinor, .harmonicMinor, .melodicMinor].contains(scale.scaleType) {
                            if !clefSwitch {
                                adjustNotePlacementForScale(note: staffNote, previousNote: previousScaleNote, staffClef: clefForPositioning)
                            }
                            previousScaleNote = staffNote
                            clefSwitch = false
                        }
                        adjustNoteAccidentalGivenPreceedingBarNotes(clef: clefForPositioning, note: staffNote, barNotes: notesInBar)
                        notesInBar.append(staffNote)
                    }
                }
            }
            //score.debug2(ctx: "ScalesModel.createScore \(handType) DONE OFFSETS", handType: nil)

            ///Do stem characteristics for the last remaining group of notes
            score.addStemCharacteristics(handType: handType, clef: clefForPositioning,
                                         startEntryIndex: startStemCharacteristicsIndex, endEntryIndex: score.scoreEntries.count - 1)
            //if score.debugOn {
                //score.debug2(ctx: "ScalesModel.createScore \(handType) END", handType: nil)
            //}
        }
        return score
    }
    
    func setScale(scale:Scale) {
        ///Deep copy to ensure reset of the scale segments
        _ = self.setScaleByRootAndType(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType, scaleMotion: scale.scaleMotion,
                                   minTempo: scale.minTempo, octaves: scale.octaves, hands: scale.hands, 
                                   dynamicTypes: scale.dynamicTypes,
                                   articulationTypes: scale.articulationTypes,
                                   ctx: "ScalesModel")
    }

    func setScaleByRootAndType(scaleRoot: ScaleRoot, scaleType:ScaleType, scaleMotion:ScaleMotion, minTempo:Int, octaves:Int, hands:[Int],
                               dynamicTypes:[DynamicType], articulationTypes:[ArticulationType], ctx:String="",
                               scaleCustomisation:ScaleCustomisation? = nil, 
                               debugOn:Bool = false, callback: ((Scale, Score) -> Void)? = nil) -> Scale {
        //let name = scale.getScaleName(handFull: true, octaves: true)

        let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoot.name),
                          scaleType: scaleType, scaleMotion: scaleMotion,
                          octaves: octaves,
                          hands: hands,
                          minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                          scaleCustomisation: scaleCustomisation,
                          debugOn: debugOn)
        setKeyboardAndScore(scale: scale, callback:callback)
        return scale
    }

    public func setKeyboardAndScore(scale:Scale, callback: ((Scale, Score) -> Void)?) {
        ///This assumes a new scale as input. This method does not re-initialize the scale segments. i.e. cannot be used for a scale that was already used
        //let name = scale.getScaleName(handFull: true, octaves: true)
        //Logger.shared.log(self, "setScale to:\(name)")
        
        let score = self.createScore(scale: scale)
        if let callback = callback {
            callback(scale, score)
        }
        
//        if scale.timeSignature.top == 3 {
//            self.tempoSettings = ["42", "44", "46", "48", "50", "52", "54", "56", "58", "60"]
//        }
//        else {
//            self.tempoSettings = ["40", "50", "60", "70", "80", "90", "100", "110", "120", "130"]
//        }
        
        ///10Jan2025 - changed to ensure keyboard key view has score to be able to set its note names
        //self.configureKeyboards(scale: scale, ctx: "setScale")
        //DispatchQueue.main.async {
            ///Scores are @Published so set them here
            //DispatchQueue.main.async {
                self.tempoChangePublished = !self.tempoChangePublished
                self.score1 = score
            //}
        //}
        self.configureKeyboards(scale: scale, ctx: "setScale")
    }
    
    func configureKeyboards(scale:Scale, ctx:String) {
        //let name = scale.getScaleName(handFull: true, octaves: true)
        self.scale = scale
        if let score = self.getScore() {
            if let combinedKeyboard = PianoKeyboardModel.sharedCombined {
                combinedKeyboard.resetLinkScaleFingersToKeyboardKeys()
                combinedKeyboard.configureKeyboardForScale(scale: scale, score: score, handType: .right)
                self.setSelectedScaleSegment(0)
                let middleKey = combinedKeyboard.pianoKeyModel.count / 2
                combinedKeyboard.pianoKeyModel[middleKey].setKeyPlaying()
                combinedKeyboard.redraw()
            }
            else {
                ///Set the single RH and RH keyboard
                PianoKeyboardModel.sharedRH.resetLinkScaleFingersToKeyboardKeys()
                PianoKeyboardModel.sharedLH.resetLinkScaleFingersToKeyboardKeys()
                PianoKeyboardModel.sharedRH.configureKeyboardForScale(scale: scale, score: score, handType: .right)
                PianoKeyboardModel.sharedLH.configureKeyboardForScale(scale: scale, score: score, handType: .left)
                self.setSelectedScaleSegment(0)
                PianoKeyboardModel.sharedRH.redraw()
                PianoKeyboardModel.sharedLH.redraw()
            }
        }
    }

    func forceRepaint() {
        DispatchQueue.main.async {
            self.forcePublish += 1
        }
    }
        
    func setTempo(_ ctx:String, _ index:Int) {
        self.selectedTempoIndex = index
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
        var keyName = scale.getScaleIdentificationKey()
        keyName = keyName.replacingOccurrences(of: " ", with: "")
        var fileName = String(format: "%02d", month)+"_"+String(format: "%02d", day)+"_"+String(format: "%02d", hour)+"_"+String(format: "%02d", minute)
//        fileName += "_"+keyName + "_"+String(scale.octaves) + "_" + String(scale.getScaleNoteState(handType: .right, index: 0).midi) + "_" + modelName
        fileName += "_"+keyName + "_"+String(scale.octaves)  + "_" + modelName
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
            AppLogger.shared.log(self, "Wrote \(tapSets.count) tapSets to \(url)")
        } catch {
            AppLogger.shared.reportError(self, "Error writing to file: \(error)")
        }
        DispatchQueue.main.async {
            ScalesModel.shared.recordedTapsFileName = fileName
        }
    }
}



