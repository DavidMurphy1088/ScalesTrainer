import Foundation
import AVFoundation
import Combine
import SwiftUI

///Base class to handle exercises
class ExerciseHandler  {
    var midisWithOneKeyPress: [Int] = []
    let scale:Scale
    let scalesModel:ScalesModel
    var nextExpectedNoteForHandIndex:[HandType:Int]
    var nextExpectedStaffSegment:[HandType:Int]
    let exerciseState:ExerciseState
    let badgeBank:BadgeBank ///The badges earned on a per note basis for the exercise
    let metronome:Metronome
    let practiceChartCell:PracticeChartCell?
    var soundEventCtr = 0
    var currentScoreSegment = 0
    var cancelled = false
    
    init(scalesModel:ScalesModel, practiceChartCell:PracticeChartCell?, metronome:Metronome) {
        self.scalesModel = scalesModel
        self.exerciseState = ExerciseState.shared
        self.badgeBank = BadgeBank.shared
        self.nextExpectedNoteForHandIndex = [:]
        nextExpectedStaffSegment = [:]
        self.metronome = metronome
        self.scale = scalesModel.scale
        self.practiceChartCell = practiceChartCell
    }
    
    func start(soundHandler:SoundEventHandlerProtocol) {
        self.badgeBank.setTotalCorrect(0)
        scalesModel.scale.resetMatchedData()
        exerciseState.setExerciseState(ctx: "ExerciseHandler", .exerciseStarted)
        exerciseState.resetTotalCorrect()
        nextExpectedNoteForHandIndex[.left] = 0
        nextExpectedNoteForHandIndex[.right] = 0
        nextExpectedStaffSegment[.right] = 0
        nextExpectedStaffSegment[.left] = 0
        currentScoreSegment = 0
        let numberToWin = (scalesModel.scale.getScaleNoteCount() * (Settings.shared.isDeveloperMode() ? 1 : 3)) / 4
        exerciseState.setNumberToWin(numberToWin)
        if scale.scaleMotion == .contraryMotion {
            if scale.getScaleNoteState(handType: .left, index: 0).midi == scale.getScaleNoteState(handType: .right, index: 0).midi {
                midisWithOneKeyPress.append(scale.getScaleNoteState(handType: .left, index: 0).midi)
            }
        }
        soundHandler.setFunctionToNotify(functionToNotify: self.notifiedOfSound(midi:))
        cancelled = false
        soundHandler.start()
    }

    ///Called by sound handler on receipt of new sound
    func notifiedOfSound(midi:Int) {
        ///For contrary motion scales with LH and RH starting on the note the student will only play one key. (And the same for the final scale note)
        ///But note based badge matching requires that both LH and RH of the scale are matched, so send the midi again.
        let callCount = midisWithOneKeyPress.contains(midi) ? 2 : 1
        for call in 0..<callCount {
            processSound(midi: midi, callNumber: call)
        }
    }
    
    func notifyPlayedKey(midi:Int, hand:HandType?) {
    }
    
    ///Determine the keyboard (LH or RH) the sound was played from (required for scales with both hands).
    ///Then set the key on that keyboard playing. Also hilight the associated staff note.
    ///The specific exercise sets the callback on the key to have its code executed once the key is set playing.
    ///
    public func processSound(midi:Int, callNumber:Int) {
        ///Does the received midi match with the expected note in any hand?
        var handMatchingExpectedScaleNote:HandType?
        var handsToSearch:[HandType] = []
        if scale.hands.count == 1 {
            handsToSearch.append(scale.hands[0] == 0 ? .right : .left)
        }
        else {
            handsToSearch.append(.left)
            handsToSearch.append(.right)
        }
        ///Determine which hand the next expected note was played if possible.
        ///If the note played matches exactly the note expected for a given hand assume that hand played it.
        for hand in handsToSearch {
            if let nextExpectedIndex = self.nextExpectedNoteForHandIndex[hand] {
                if nextExpectedIndex < scale.getScaleNoteCount() {
                    let nextExpected = scale.getScaleNoteState(handType: hand, index: nextExpectedIndex)
                    if midi == nextExpected.midi {
                        handMatchingExpectedScaleNote = hand
                        break
                    }
                }
            }
        }

        ///Make the list of possible keyboards
        
        var keyToPlay:PianoKeyModel? = nil
        var keyboards: [KeyboardType: PianoKeyboardModel] = [:]
        
        if let combined = PianoKeyboardModel.sharedCombined {
            keyboards[.combined] = combined
        }
        else {
            ///Only consider keyboards that are visible for this scale.
            if scale.hands.contains(0) {
                keyboards[.right] = PianoKeyboardModel.sharedRH
            }
            if scale.hands.contains(1) {
                keyboards[.left] = PianoKeyboardModel.sharedLH
            }
        }

        ///Determine which keyboard to press the key on
        
        if let handForNote = handMatchingExpectedScaleNote {
            ///Midi was in the scale for this hand. Set the note in the scale for that hand to matched.
            let keyboard:PianoKeyboardModel
            if PianoKeyboardModel.sharedCombined != nil {
                ///contrary motion
                keyboard = keyboards[.combined]!
            }
            else {
                keyboard = (handForNote == .right ? keyboards[.right] : keyboards[.left])!
            }
            if let keyboardIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                keyToPlay=keyboard.pianoKeyModel[keyboardIndex]
                if let noteState = keyToPlay?.scaleNoteState {
                    self.currentScoreSegment = noteState.segments[0]
                }
            }
        }
        else {
            for keyboardType in keyboards.keys {
                if let keyboard:PianoKeyboardModel = keyboards[keyboardType] {
                    if let index = keyboard.getKeyIndexForMidi(midi: midi) {
                        keyToPlay=keyboard.pianoKeyModel[index]
                    }
                }
            }
        }
        
        ///Play the keyboard key and determine which staff to hilight the key on.
        
        if let keyToPlay = keyToPlay {
            keyToPlay.setKeyPlaying()
            if let score = scalesModel.getScore() {
                let keyboard = keyToPlay.keyboardModel
                ///NB - The combined keyboard has no hand type
                score.hilightStaffNote(segment: self.currentScoreSegment, midi: midi, handType: keyboard.getKeyboardHandType())
            }
        }
        

        print("======== ExerciseHandler, processSound ctr:\(self.soundEventCtr) ", "midi", midi,
              "keyboard", keyToPlay?.keyboardModel.keyboardNumber ?? "NoKeyboard")
        let hand:HandType?
        if callNumber == 1 {
            hand = .right
        }
        else {
            hand = handMatchingExpectedScaleNote
        }
        notifyPlayedKey(midi: midi, hand: hand)
        self.soundEventCtr += 1
    }
    
    func awardChartBadge() {
        if Settings.shared.practiceChartGamificationOn {
            let wonStateOld = exerciseState.totalCorrect >= exerciseState.numberToWin
            exerciseState.bumpTotalCorrect()
            let wonStateNew = exerciseState.totalCorrect >= exerciseState.numberToWin
            if !wonStateOld && wonStateNew {
                if let exerciseBadge = scalesModel.exerciseBadge {
                    if let practiceChartCell = practiceChartCell {
                        practiceChartCell.addBadge(badge: exerciseBadge)
                    }
                }
            }
        }
    }
    
    func testForEndOfExercise() -> Bool {
        let atEnd:Bool
        if scale.hands.count == 1 {
            atEnd = self.nextExpectedNoteForHandIndex[.left]! >= scale.getScaleNoteCount() ||
            self.nextExpectedNoteForHandIndex[.right]! >= scale.getScaleNoteCount()
        }
        else {
            atEnd = self.nextExpectedNoteForHandIndex[.left]! >= scale.getScaleNoteCount() &&
                    self.nextExpectedNoteForHandIndex[.right]! >= scale.getScaleNoteCount()
        }
        if atEnd {
            scalesModel.clearFunctionToNotify()
            scalesModel.setRunningProcess(.none)
            exerciseState.setExerciseState(ctx: "ExerciseHandler - ExerciseEnded", exerciseState.getState() == .won ? .wonAndFinished : .lost)
            return true
        }
        else {
            return false
        }
    }
}

///Prompt the use for the key to play and wait for them to do that
///
class FollowScaleProcess : ExerciseHandler, MetronomeTimerNotificationProtocol  {
    class KeyboardSemaphore {
        let id:Int
        let keyboard:PianoKeyboardModel
        let semaphore:DispatchSemaphore
        init(id:Int, keyboard:PianoKeyboardModel, semaphore:DispatchSemaphore) {
            self.keyboard = keyboard
            self.semaphore = semaphore
            self.id = id
        }
    }
    var keyboardSemaphores:[KeyboardSemaphore] = []

    override init(scalesModel:ScalesModel, practiceChartCell:PracticeChartCell?, metronome:Metronome) {
        super.init(scalesModel: scalesModel, practiceChartCell: practiceChartCell, metronome: metronome)
    }
    
    func metronomeStart() {
    }
    
    func metronomeStop() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
    }
    
    override func start(soundHandler:SoundEventHandlerProtocol) {
        super.start(soundHandler: soundHandler)

        self.keyboardSemaphores = []

        if scale.hands.count == 1 {
            let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
            self.keyboardSemaphores.append(KeyboardSemaphore(id: 0, keyboard: keyboard, semaphore: DispatchSemaphore(value: 0)))
        }
        else {
            ///For a combined (single) keyboard for two-hands (e.g. chromatic) we still need 2 semaphores to wait for the two notes
            if let combined = PianoKeyboardModel.sharedCombined {
                self.keyboardSemaphores.append(KeyboardSemaphore(id: 0, keyboard: combined, semaphore: DispatchSemaphore(value: 0)))
                self.keyboardSemaphores.append(KeyboardSemaphore(id: 1, keyboard: combined, semaphore: DispatchSemaphore(value: 0)))
            }
            else {
                self.keyboardSemaphores.append(KeyboardSemaphore(id: 0, keyboard: PianoKeyboardModel.sharedRH, semaphore: DispatchSemaphore(value: 0)))
                self.keyboardSemaphores.append(KeyboardSemaphore(id: 1, keyboard: PianoKeyboardModel.sharedLH, semaphore: DispatchSemaphore(value: 0)))
            }
        }
        
        ///Setup to listen for cancelled state. If cancelled make sure all semaphores are signalled so the the process thread can exit
        ///appmode is None at start since its set (for publish)  in main thread
        DispatchQueue.global(qos: .background).async {
            while true {
                sleep(1)
                if self.scalesModel.runningProcess != .followingScale {
                    for keyboardSemaphore in self.keyboardSemaphores {
                        keyboardSemaphore.semaphore.signal()
                        keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except: nil)
                    }
                    self.cancelled = true
                    break
                }
            }
        }
        listenForKeyPresses()
    }
    
    ///Setup DispatchSemaphores on each keyboard to wait for the expected key on that keyboard.
    ///Update badges for the notes played.
    ///
    func listenForKeyPresses() {
        DispatchQueue.global(qos: .background).async { [self] in
            
            var scaleIndex = 0
            var inScaleCount = 0
            
            while true {
                if scaleIndex >= self.scale.getScaleNoteCount() {
                    break
                }
                
                ///Set a semaphore to detect when the expected keyboard key is played.
                ///Hilight on th ekeyboard the next note(s) to be played
                
                var combinedHandCtr = 0
                var hilightedKeys:[Int] = []
                
                for keyboardSemaphore in keyboardSemaphores {
                    let keyboardNumber = keyboardSemaphore.keyboard.keyboardNumber - 1
                    let hand:HandType
                    if let combinedkeyboard = PianoKeyboardModel.sharedCombined {
                        ///Add a semaphore for each hand
                        hand = combinedHandCtr == 0 ? .right : .left
                        combinedHandCtr += 1
                    }
                    else {
                        hand = keyboardNumber == 0 ? .right : .left
                    }
                    let note = self.scale.getScaleNoteState(handType: hand, index: scaleIndex)
                    guard let keyIndex = keyboardSemaphore.keyboard.getKeyIndexForMidi(midi:note.midi) else {
                        scaleIndex += 1
                        continue
                    }
                    //currentMidis.append(note.midi)
                    let pianoKey = keyboardSemaphore.keyboard.pianoKeyModel[keyIndex]
                    hilightedKeys.append(keyIndex)
                    keyboardSemaphore.keyboard.clearAllFollowingKeyHilights(except:hilightedKeys)
                    
                    pianoKey.hilightKeyToFollow = .followThisNote
                    keyboardSemaphore.keyboard.redraw()
                    ///Set the closure called when a piano key is pressed
                    //pianoKey.setCallbackFunction(fn: {
                    //print("============ Adding semaphore callback for key. midi:", pianoKey.midi, "keyboard:", pianoKey.keyboardModel.keyboardNumber)
                    pianoKey.addCallbackFunction(fn: {
                        keyboardSemaphore.semaphore.signal()
                        inScaleCount += 1
                        keyboardSemaphore.keyboard.redraw()
                        //print("=============listenForKeyPresses 😊 KeyCallback called id:\(keyboardSemaphore.id)", "midi", pianoKey.midi)
                        //pianoKey.setCallbackFunction(fn: nil)
                        //pianoKey.setCallbackFunction(fn: nil)
                    })
                }
                
                ///Wait for the right key to be played and signalled on every keyboard
                
                //print("============= Follow waiting ... for:", nextExpectedNoteForHandIndex)
                for keyboardSemaphore in keyboardSemaphores {
                    if !self.cancelled && self.scalesModel.runningProcess == .followingScale {
                        keyboardSemaphore.semaphore.wait()
                        //print("============= ➡️ end wait \(keyboardSemaphore.id)")
                        self.nextExpectedNoteForHandIndex[keyboardSemaphore.keyboard.keyboardNumber==1 ? .right : .left]! += 1
                    }
                }
               //print("============= Follow received all expected notes ...")

                if self.cancelled { //}|| self.scalesModel.runningProcess != .followingScale || scaleIndex >= self.scale.getScaleNoteCount() - 1 {
                   break
                }
                else {
                    scaleIndex += 1
                    if scaleIndex < self.scale.getScaleNoteCount() {
                        let nextNote = self.scale.getScaleNoteState(handType: .right, index: scaleIndex)
                        scalesModel.setSelectedScaleSegment(nextNote.segments[0])
                    }
                    badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
                    awardChartBadge()
                    if testForEndOfExercise() {
                        break
                    }
                }
            }
            scalesModel.setSelectedScaleSegment(0)
            
//            if inScaleCount > 2 {
//                var msg = "😊 Good job following the scale"
//                msg += "\nYou played \(inScaleCount) notes in the scale"
//                //msg += "\nYou played \(xxx) notes out of the scale"
//                ScalesModel.shared.setUserMessage(heading: "Following the Scale", msg:msg)
//            }
            }
        }
    }
    
    func playDemo() {
        //self.start()
        let scalesModel = ScalesModel.shared
        DispatchQueue.global(qos: .background).async {
            sleep(1)
            //self.badgeBank.clearMatches()
            scalesModel.scale.resetMatchedData()
            var lastSegment:Int? = nil
            let hand = 0
            let keyboard = hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
            let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] //FMAj RH
            //let midis =   [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38] Dmin Harm
            //let midis =     [67, 71, 74, 71, 74, 79, 74, 79, 83, 79, 83, 79, 74, 79, 74, 71, 74, 71, 67, 74] //G maj broken
            
            let notes = scalesModel.scale.getStatesInScale(handIndex: hand)
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            
            if let sampler = AudioManager.shared.getSamplerForKeyboard() {
//                let leadin:UInt32 = ScalesModel.shared.scale.scaleType == .brokenChordMajor ? 3 : 4
//                sleep(leadin)
//                //metronome.makeSilent = true
//                MetronomeModel.shared.setLeadingIn(way: false)
//                sleep(1)
                var ctr = 0
                for midi in midis {
                    
                    if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                        let key=keyboard.pianoKeyModel[keyIndex]
                        let segment = notes[ctr].segments[0]
                        if let lastSegment = lastSegment {
                            scalesModel.setSelectedScaleSegment(segment)
                        }
                        lastSegment = segment
                        key.setKeyPlaying()
                    }

                    sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)

                    //notifiedOfSound(midi: midi)
                    
                    //var tempo:Double = [9, 19].contains(ctr) ? 70/3 : 70 //Broken Chords
                    let tempo:Double =  70 //50 = Broken
                    //let notesPerBeatBeat = [9, 19].contains(ctr) ? 1.0 : 3.0 //Broken
                    let notesPerBeatBeat = [14].contains(ctr) ? 0.75 : 2.0
                    var sleep = (1000000 * 1.0 * (Double(60)/tempo)) / notesPerBeatBeat
                    sleep = sleep * 0.95
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0/notesPerBeatBeat) {
//                        //sampler.stop(noteNumber: UInt8(midi), channel: 0)
//                    }
                    usleep(UInt32(sleep))
                    ctr += 1
                }
                ScalesModel.shared.setRunningProcess(.none)
            }
        }
    }


