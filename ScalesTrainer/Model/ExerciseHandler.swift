import Foundation
import AVFoundation
import Combine
import SwiftUI

protocol ExerciseHandlerProtocol: AnyObject {
    func applySerialLock() -> Bool
}

class RequiredNote {
    let sequenceNum: Int
    let midi:Int
    let handType:HandType
    var matched = false
    init(sequenceNum: Int, midi:Int, handType:HandType) {
        self.sequenceNum = sequenceNum
        self.midi = midi
        self.handType = handType
    }
}
///Base class to handle exercises
class ExerciseHandler : ExerciseHandlerProtocol  {
    let exerciseType:RunningProcess
    
    var midisWithOneKeyPress: [Int] = []
    let scale:Scale
    let scalesModel:ScalesModel
    var nextExpectedNoteForHandIndex:[HandType:Int]
    var nextExpectedStaffSegment:[HandType:Int]
    let exerciseState:ExerciseState
    let exerciseBadgesList:ExerciseBadgesList ///The badges earned on a per note basis for the exercise
    let metronome:Metronome
    let practiceChart:PracticeChart?
    let practiceChartCell:PracticeChartCell?
    var currentScoreSegment = 0
    var cancelled = false
    let accessQueue = DispatchQueue(label: "ExerciseHandlerQueue")
    var lastMatchedMidi:Int? = nil
    var lastKeyHilighted:PianoKeyModel? = nil
    let scaleMinxMaxMidis:(Int, Int)
    var noteNotificationNumber = 0
    
    init(exerciseType:RunningProcess, scalesModel:ScalesModel, practiceChart:PracticeChart?, practiceChartCell:PracticeChartCell?, metronome:Metronome) {
        self.exerciseType = exerciseType
        self.scalesModel = scalesModel
        self.exerciseState = ExerciseState.shared
        self.exerciseBadgesList = ExerciseBadgesList.shared
        self.nextExpectedNoteForHandIndex = [:]
        nextExpectedStaffSegment = [:]
        self.metronome = metronome
        self.scale = scalesModel.scale
        self.practiceChart = practiceChart
        self.practiceChartCell = practiceChartCell
        self.scaleMinxMaxMidis = scale.getMinMaxMidis()
    }
    
    func start(soundHandler:SoundEventHandlerProtocol) {
        self.exerciseBadgesList.setTotalBadges(0)
        scale.resetMatchedData()
        exerciseState.resetTotalCorrect()
        nextExpectedNoteForHandIndex[.left] = 0
        nextExpectedNoteForHandIndex[.right] = 0
        nextExpectedStaffSegment[.right] = 0
        nextExpectedStaffSegment[.left] = 0
        currentScoreSegment = 0
        let numberToWin = scale.getScaleNoteCount()
        exerciseState.setNumberToWin(numberToWin)
        if scale.scaleMotion == .contraryMotion {
            if scale.getScaleNoteState(handType: .left, index: 0)!.midi == scale.getScaleNoteState(handType: .right, index: 0)!.midi {
                midisWithOneKeyPress.append(scale.getScaleNoteState(handType: .left, index: 0)!.midi)
            }
        }
        soundHandler.setFunctionToNotify(functionToNotify: self.notifiedOfSound(midi:))
        cancelled = false
        soundHandler.start()
        lastKeyHilighted = nil
        noteNotificationNumber = 0
        if self.exerciseType == .followingScale {
            hilightKey(scaleIndex: 0)
        }
        if MIDIManager.shared.testMidiNotes != nil {
            MIDIManager.shared.playTestMidiNotes(soundHandler: soundHandler)
        }
    }
    
    func applySerialLock() -> Bool {
        return false
    }
    
    func hilightKey(scaleIndex:Int) {
        if let lastKeyHilighted = self.lastKeyHilighted {
            lastKeyHilighted.hilightType = .none
        }
        var keyToHilight:PianoKeyModel? = nil
        let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
        let handIndex = keyboard.keyboardNumber == 1 ? 0 : 1
        let scaleMidis = scale.getMidisInScale(handIndex: handIndex)
        if (scaleIndex >= 0 && scaleIndex < scaleMidis.count) {
            let hilightMidi = scaleMidis[scaleIndex]
            if let index = keyboard.getKeyIndexForMidi(midi: hilightMidi) {
                keyToHilight = keyboard.pianoKeyModel[index]
                if let key = keyToHilight {
                    key.hilightType = .followThisNote
                    self.lastKeyHilighted = key
                }
            }
        }
    }
    
    ///Called by sound handler on receipt of new sound
    func notifiedOfSound(midi:Int) {
        ///For contrary motion scales with LH and RH starting on the note the student will only play one key. (And the same for the final scale note)
        ///But note based badge matching requires that both LH and RH of the scale are matched, so send the midi again.
        
        ///Filter out harmonics and overtones that cause wrong note notification.
        let margin = 3
        //let margin = 12 + 2
        if midi < self.scaleMinxMaxMidis.0 - margin {
            return
        }
        if midi > self.scaleMinxMaxMidis.1 + margin {
            return
        }

        let callCount = midisWithOneKeyPress.contains(midi) ? 2 : 1
        for call in 0..<callCount {
            if self.applySerialLock() {
                accessQueue.sync {
                    processSound(midi: midi, callNumber: call)
                }
            }
            else {
                processSound(midi: midi, callNumber: call)
            }
        }
        self.noteNotificationNumber += 1
    }
    
    ///Determine the keyboard (LH or RH) the sound was played from (required for scales with both hands).
    ///Then set the key on that keyboard playing. Also hilight the associated staff note.
    ///The specific exercise sets the callback on the key to have its code executed once the key is set playing.
    ///
    public func processSound(midi:Int, callNumber:Int) {
        ///Determine which hand the next expected note was played with if possible.
        var handThatPlayedNote:HandType?
        var handsToSearch:[HandType] = []

        if scale.hands.count == 1 {
            let hand = scale.hands[0] == 0 ? HandType.right : .left
            handThatPlayedNote = hand
        }
        else {
            ///Does the received midi match with the expected note in any hand?
            ///If the note played matches exactly the note expected for a given hand assume that hand played it.
            ///Otherwise we can't know the correct hand for sure.
            handsToSearch.append(.left)
            handsToSearch.append(.right)
            for hand in handsToSearch {
                if let nextExpectedIndex = self.nextExpectedNoteForHandIndex[hand] {
                    if nextExpectedIndex < scale.getScaleNoteCount() {
                        if let nextExpected = scale.getScaleNoteState(handType: hand, index: nextExpectedIndex) {
                            if midi == nextExpected.midi {
                                handThatPlayedNote = hand
                                break
                            }
                        }
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
        
        var keyboardThatPlayedNote:PianoKeyboardModel? = nil
        
        if let handThatPlayedNote = handThatPlayedNote {
            ///Midi was in the scale for this hand. Set the note in the scale for that hand to matched.
            //let keyboard:PianoKeyboardModel
            if PianoKeyboardModel.sharedCombined != nil {
                ///contrary motion
                keyboardThatPlayedNote = keyboards[.combined]!
            }
            else {
                keyboardThatPlayedNote = (handThatPlayedNote == .right ? keyboards[.right] : keyboards[.left])!
            }
            if let keyboard = keyboardThatPlayedNote {
                if let keyboardIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                    keyToPlay=keyboard.pianoKeyModel[keyboardIndex]
                    if let noteState = keyToPlay?.scaleNoteState {
                        self.currentScoreSegment = noteState.segments[0]
                    }
                }
            }
        }
        else {
            for keyboardType in keyboards.keys {
                if let keyboard:PianoKeyboardModel = keyboards[keyboardType] {
                    if let index = keyboard.getKeyIndexForMidi(midi: midi) {
                        keyToPlay=keyboard.pianoKeyModel[index]
                        keyboardThatPlayedNote = keyboard
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

        let handType:HandType?
//        if callNumber == 1 { ???? 🥵
//            hand = .right
//        }
//        else {
            handType = handThatPlayedNote
//        }
        if let handType = handType, let keyboard = keyboardThatPlayedNote {
            notifyPlayedKey(Keyboard: keyboard, midi: midi, handType: handType)
        }
    }
    
    func notifyPlayedKey(Keyboard:PianoKeyboardModel, midi:Int, handType:HandType) {
        ///Gather the expected next midi(s) in each hand. We look ahead usualy 2 notes for a match.
        ///Thats because at faster tempos there may be failure to get notified of correct notes the student plays.
        var requiredNotes:[RequiredNote] = []
        
        if requiredNotes.count == 0 {
            for h in scale.hands {
                let handType = h==0 ? HandType.right : .left
                if let expectedOffset = self.nextExpectedNoteForHandIndex[handType] {
                    ///A trailing pitch from ascending might match itself going back down if looking ahead > 1
                    let atScaleMiddle = expectedOffset == self.scale.getScaleNoteCount()/2
                    let lookahead = atScaleMiddle ? 1 : 2
                    for i in 0..<lookahead {
                        if let nextExpectedNote = scale.getScaleNoteState(handType: handType, index: expectedOffset + i) {
                            let expectedMidi = nextExpectedNote.midi
                            requiredNotes.append(RequiredNote(sequenceNum: i, midi: expectedMidi, handType: handType))
                        }
                    }
                }
            }
        }

        for requiredNote in requiredNotes {
            ///16Mar2025 - sometimes get wrong octave of note played so allow it
            let allowed = [requiredNote.midi-24, requiredNote.midi-12, requiredNote.midi, requiredNote.midi+12, requiredNote.midi+24]
            //if requiredNote.midi == midi && requiredNote.handType == handType {
            if allowed.contains(midi) && requiredNote.handType == handType {
                requiredNote.matched = true
                for previousNote in requiredNotes {
                    if previousNote.sequenceNum < requiredNote.sequenceNum {
                        previousNote.matched = true
                    }
                }
                break
            }
        }
        
        var matchedCount = 0
        for requiredNote in requiredNotes {
            if requiredNote.matched {
                matchedCount += 1

                exerciseBadgesList.setTotalBadges(exerciseBadgesList.totalBadges + 1)
                self.lastMatchedMidi = requiredNote.midi
                //for requiredNote in requiredNotes {
                //if let hand = handType {
                if self.nextExpectedNoteForHandIndex.keys.contains(handType) {
                    nextExpectedNoteForHandIndex[requiredNote.handType]! += 1
                }
                //}
                //}
                if let index = nextExpectedNoteForHandIndex[handType] {
                    if index < scale.getScaleNoteCount() {
                        if let scaleNote = scale.getScaleNoteState(handType: handType, index: index) {
                            scalesModel.setSelectedScaleSegment(scaleNote.segments[0])
                        }
                    }
                    if self.exerciseType == .followingScale {
                        hilightKey(scaleIndex: index)
                    }
                    awardChartBadge()
                    _ = testForEndOfExercise()
                }
            }
        }
        
        //requiredNotes.removeAll { $0.matched }
        
        if matchedCount == 0 {
            testForFailExercise(midi: midi, requiredNotes: requiredNotes, keyboard: Keyboard)
        }
        
        ///Check notes in both hands are matched before moving on, otherwise wait for the other hand
//        if matchedCount == scale.hands.count {
//            exerciseBadgesList.setTotalBadges(exerciseBadgesList.totalBadges + 1)
//            self.lastMatchedMidi = midi
//            for requiredNote in requiredNotes {
//                self.nextExpectedNoteForHandIndex[requiredNote.hand]! += 1
//            }
//            self.requiredNotes = []
//            let index = nextExpectedNoteForHandIndex[hand!]!
//            if index < scale.getScaleNoteCount() {
//                if let scaleNote = scale.getScaleNoteState(handType: hand!, index: index) {
//                    scalesModel.setSelectedScaleSegment(scaleNote.segments[0])
//                }
//            }
//            if self.exerciseType == .followingScale {
//                hilightKeys(scaleIndex: index)
//            }
//            awardChartBadge()
//            _ = testForEndOfExercise()
//        }
//        else {
//            if midi != lastMatchedMidi {
//                testForFailExercise(midi: midi, requiredNotes: self.requiredNotes)
//            }
//        }
    }
        
    func awardChartBadge() {
        let user = Settings.shared.getCurrentUser()
        if user.settings.practiceChartGamificationOn {
            let wonStateOld = exerciseState.totalCorrect >= exerciseState.numberToWin
            exerciseState.bumpTotalCorrect()
            let wonStateNew = exerciseState.totalCorrect >= exerciseState.numberToWin
            if !wonStateOld && wonStateNew {
                if let exerciseBadge = scalesModel.exerciseBadge {
                    if let practiceChartCell = practiceChartCell {
                        practiceChartCell.addBadge(badge: exerciseBadge, callback: {
                            self.practiceChart?.savePracticeChartToFile()
                        })
                    }
                }
            }
        }
    }
    
    func testForFailExercise(midi:Int, requiredNotes: [RequiredNote], keyboard:PianoKeyboardModel) {
        ///The note pitches may ring on and cause > 1 note notification
        guard let lastMatchedMidi = self.lastMatchedMidi else {
            return
        }
        let lastMatchedMidis = [lastMatchedMidi-24, lastMatchedMidi-12, lastMatchedMidi, lastMatchedMidi+12, lastMatchedMidi+24]
        if lastMatchedMidis.contains(midi) {
            return
        }
        if self.lastMatchedMidi == nil {
            ///Student may be finding correct start octave
            var scaleStartMidis = requiredNotes.map { $0.midi }
            if let min = scaleStartMidis.min() {
                for delta in stride(from: -24, through: 24, by: 12) {
                    scaleStartMidis.append(min + delta)
                }
                if scaleStartMidis.contains(midi) {
                    return
                }
            }
        }
        ///If the note was close to (but not the same as) an expected note, the note played was wrong
        //////16Mar2025 - sometimes get wrong octave of octave played
        for requiredNote in requiredNotes {
            let allowed = [requiredNote.midi-24, requiredNote.midi-12, requiredNote.midi, requiredNote.midi+12, requiredNote.midi+24]
            //let midiDiff = abs(midi - requiredNote.midi)
            if !allowed.contains(midi) {
                if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                    let key = keyboard.pianoKeyModel[keyIndex]
                    key.hilightType = .wasWrongNote
                }
                exerciseState.setExerciseState("Wrong note midi:\(midi) required:\(requiredNote.midi)", .exerciseLost, "Wrong Note")
                scalesModel.exerciseCompletedNotify()
                MIDIManager.shared.testMidiNotesStopPlaying = true
                break
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
            scalesModel.exerciseCompletedNotify()
            scalesModel.setRunningProcess(.none)
            if exerciseState.getState() == .exerciseStarted {
                exerciseState.setExerciseState("Follow, EndOfExercise", .exerciseLost, "Notes Not Complete")
            }
            if let practiceChart {
                practiceChart.savePracticeChartToFile()
            }
            return true
        }
        else {
            return false
        }
    }

}


//func playDemo() {
//    //self.start()
//    let scalesModel = ScalesModel.shared
//    DispatchQueue.global(qos: .background).async {
//        sleep(1)
//        //self.badgeBank.clearMatches()
//        scale.resetMatchedData()
//        var lastSegment:Int? = nil
//        let hand = 0
//        let keyboard = hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
//        let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] //FMAj RH
//        //let midis =   [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38] Dmin Harm
//        //let midis =     [67, 71, 74, 71, 74, 79, 74, 79, 83, 79, 83, 79, 74, 79, 74, 71, 74, 71, 67, 74] //G maj broken
//        
//        let notes = scale.getStatesInScale(handIndex: hand)
//        PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
//        
//        if let sampler = AudioManager.shared.getSamplerForKeyboard() {
////                let leadin:UInt32 = ScalesModel.shared.scale.scaleType == .brokenChordMajor ? 3 : 4
////                sleep(leadin)
////                //metronome.makeSilent = true
////                MetronomeModel.shared.setLeadingIn(way: false)
////                sleep(1)
//            var ctr = 0
//            for midi in midis {
//                
//                if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
//                    let key=keyboard.pianoKeyModel[keyIndex]
//                    let segment = notes[ctr].segments[0]
//                    if let lastSegment = lastSegment {
//                        scalesModel.setSelectedScaleSegment(segment)
//                    }
//                    lastSegment = segment
//                    key.setKeyPlaying()
//                }
//
//                sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)
//
//                //notifiedOfSound(midi: midi)
//                
//                //var tempo:Double = [9, 19].contains(ctr) ? 70/3 : 70 //Broken Chords
//                let tempo:Double =  70 //50 = Broken
//                //let notesPerBeatBeat = [9, 19].contains(ctr) ? 1.0 : 3.0 //Broken
//                let notesPerBeatBeat = [14].contains(ctr) ? 0.75 : 2.0
//                var sleep = (1000000 * 1.0 * (Double(60)/tempo)) / notesPerBeatBeat
//                sleep = sleep * 0.95
//
//                usleep(UInt32(sleep))
//                ctr += 1
//            }
//            ScalesModel.shared.setRunningProcess(.none)
//        }
//    }
//}


