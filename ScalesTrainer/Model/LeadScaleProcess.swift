import Foundation
import AVFoundation
import Combine
import SwiftUI

class LeadScaleProcess : ExerciseHandler, MetronomeTimerNotificationProtocol {
    
    class RequiredNote {
        let midi:Int
        let hand:HandType
        var matched = false
        init(midi:Int, hand:HandType) {
            self.midi = midi
            self.hand = hand
        }
    }
    var requiredNotes:[RequiredNote] = []
    
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
//        lastMidi = nil
//        lastMidiScaleIndex = nil
//        notifyCount = 0
//        noteStack=[]

    }
    
    override func notifyPlayedKey(midi: Int, hand:HandType?) {
        if self.requiredNotes.count == 0 {
            for h in scale.hands {
                let hand = h==0 ? HandType.right : .left
                if let expectedOffset = self.nextExpectedNoteForHandIndex[hand] {
                    let expectedMidi = scale.getScaleNoteState(handType: hand, index: expectedOffset).midi
                    self.requiredNotes.append(RequiredNote(midi: expectedMidi, hand: hand))
                }
            }
        }
        var matchedCount = 0
        for requiredNote in requiredNotes {
            if requiredNote.midi == midi && requiredNote.hand == hand {
                requiredNote.matched = true
            }
            if requiredNote.matched {
                matchedCount += 1
            }
        }
        if matchedCount == scale.hands.count {
            badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
            for requiredNote in requiredNotes {
                self.nextExpectedNoteForHandIndex[requiredNote.hand]! += 1
            }
            self.requiredNotes = []
            let index = nextExpectedNoteForHandIndex[hand!]!
            if index < scale.getScaleNoteCount() {
                let scaleNote = scale.getScaleNoteState(handType: hand!, index: index)
                scalesModel.setSelectedScaleSegment(scaleNote.segments[0])
            }
            awardChartBadge()
            _ = testForEndOfExercise()
        }
    }
    
//    func listenForKeys() {
//        
//        for hand in [HandType.left, HandType.right] {
//            if let expectedIndex = self.nextExpectedNoteForHandIndex[hand] {
//                var expectedNote = scale.getScaleNoteState(handType: hand, index: expectedIndex)
//                if let keybord = PianoKeyboardModel.sharedCombined { ///contrary motion
//                    if let keyboardIndex = keybord.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                        let key=keybord.pianoKeyModel[keyboardIndex]
//                        key.setKeyPlaying()
//                    }
//                }
//                else {
//                    if let keyboardIndex = keyboard[handForNote]?.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                        let key=keyboard[handForNote]!.pianoKeyModel[keyboardIndex]
//                        key.setKeyPlaying()
//                    }
//                }
//
//            }
//        }
//    }
    
//    func processSound1(midi:Int, callNumber:Int) {

//        ///Determine which keyboard to press the key on
//        var keyboard: [KeyboardType: PianoKeyboardModel] = [:]
//        keyboard[.right] = PianoKeyboardModel.sharedRH
//        keyboard[.left] = PianoKeyboardModel.sharedLH
//
//        if let handForNote = handForNote {
//            ///Midi was in the scale for this hand. Set the note in the scale for that hand to matched.
//            if let keybord = PianoKeyboardModel.sharedCombined { ///contrary motion
//                if let keyboardIndex = keybord.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                    let key=keybord.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                }
//            }
//            else {
//                if let keyboardIndex = keyboard[handForNote]?.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                    let key=keyboard[handForNote]!.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                }
//            }
//
//            let matchedIndex = self.nextExpectedNoteInScaleIndex[handForNote]!
//            var noteState = scale.getScaleNoteState(handType: handForNote, index: matchedIndex)
//            noteState.matchedTime = Date()
//
//            ///Decide if a badge was earned. For both hand scales both the LH and RH must be matched
//            var correctNotePlayed = false
//            if scale.hands.count == 1 {
//                correctNotePlayed = true
//            }
//            else {
//                if handForNote == .left {
//                    correctNotePlayed = scale.getScaleNoteState(handType: .right, index: matchedIndex).matchedTime != nil
//                }
//                else {
//                    correctNotePlayed = scale.getScaleNoteState(handType: .left, index: matchedIndex).matchedTime != nil
//                }
//            }
//            if correctNotePlayed {
//                badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
//                let wonStateOld = exerciseState.totalCorrect >= exerciseState.numberToWin
//                exerciseState.setTotalCorrect(exerciseState.totalCorrect + 1)
//                let wonStateNew = exerciseState.totalCorrect >= exerciseState.numberToWin
//                if !wonStateOld && wonStateNew {
//                    if let exerciseBadge = scalesModel.exerciseBadge {
//                        if let practiceChartCell = practiceChartCell {
//                            practiceChartCell.addBadge(badge: exerciseBadge)
//                        }
//                    }
//                }
//            }
//        }
//        else {
//            ///Midi not in scale - Press the keyboard key in whicher keyboard found first
//            for hand in [KeyboardType.right, .left] {
//                if let keyboardIndex = keyboard[hand]?.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[hand]) {
//                    let key=keyboard[hand]!.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                    break
//                }
//            }
//        }
//
//        ///If the midi played was in the scale hilight the note on the score in the correct hand. If the scale is finished exit the process.
//        if let handForNote = handForNote {
//            let index = self.nextExpectedNoteInScaleIndex[handForNote]!
//            if let score = score {
//                let noteScaleState = scale.getScaleNoteState(handType: handForNote, index: index)
//                score.hilightStaffNote(segment: noteScaleState.segments[0], midi: midi, handType: handForNote)
//            }
//
//            ///Advance the hand that played a scale note
//            if index < scale.getScaleNoteCount()  {
//                self.nextExpectedNoteInScaleIndex[handForNote]! += 1
//            }
//
//            ///Test for the end of the process - i.e. all notes matched.
//            let atEnd:Bool
//            if scale.hands.count == 1 {
//                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() ||
//                self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
//            }
//            else {
//                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() &&
//                        self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
//            }
//            if atEnd {
//                scalesModel.clearFunctionToNotify()
//                scalesModel.setRunningProcess(.none)
//                exerciseState.setExerciseState("LeadScale-Ended", exerciseState.state == .won ? .wonAndFinished : .lost)
//            }
//        }
//    }
     
    //func listenForKeyPresses() {
        //        if let handForNote = handForNote {
        //            let index = self.nextExpectedNoteInScaleIndex[handForNote]!
        //            if let score = score {
        //                let noteScaleState = scale.getScaleNoteState(handType: handForNote, index: index)
        //                score.hilightStaffNote(segment: noteScaleState.segments[0], midi: midi, handType: handForNote)
        //            }
        //
        //            ///Advance the hand that played a scale note
        //            if index < scale.getScaleNoteCount()  {
        //                self.nextExpectedNoteInScaleIndex[handForNote]! += 1
        //            }
        //
        //            ///Test for the end of the process - i.e. all notes matched.
        //            let atEnd:Bool
        //            if scale.hands.count == 1 {
        //                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() ||
        //                self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
        //            }
        //            else {
        //                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() &&
        //                        self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
        //            }
        //            if atEnd {
        //                scalesModel.clearFunctionToNotify()
        //                scalesModel.setRunningProcess(.none)
        //                exerciseState.setExerciseState("LeadScale-Ended", exerciseState.state == .won ? .wonAndFinished : .lost)
        //            }
        //        }

    //}
    
    //override
//    func processSound1(midi:Int, callNumber:Int) {
//        //print("\n========== LEAD processMIDI call:", callNumber, midi, "Indexes:", self.nextExpectedNoteInScaleIndex[.left], self.nextExpectedNoteInScaleIndex[.right])
//        
//        ///Does the received midi match with the expected note in any hand?
//        var handForNote:HandType?
//        var handsToSearch:[HandType] = []
//        if scale.hands.count == 1 {
//            handsToSearch.append(scale.hands[0] == 0 ? .right : .left)
//        }
//        else {
//            handsToSearch.append(.left)
//            handsToSearch.append(.right)
//        }
//        for hand in handsToSearch {
//            if let nextExpectedIndex = self.nextExpectedNoteInScaleIndex[hand] {
//                if nextExpectedIndex < scale.getScaleNoteCount() {
//                    let nextExpected = scale.getScaleNoteState(handType: hand, index: nextExpectedIndex)
//                    if midi == nextExpected.midi {
//                        handForNote = hand
//                        break
//                    }
//                }
//            }
//        }
//
//        ///Determine which keyboard to press the key on
//        var keyboard: [KeyboardType: PianoKeyboardModel] = [:]
//        keyboard[.right] = PianoKeyboardModel.sharedRH
//        keyboard[.left] = PianoKeyboardModel.sharedLH
//
//        if let handForNote = handForNote {
//            ///Midi was in the scale for this hand. Set the note in the scale for that hand to matched.
//            if let keybord = PianoKeyboardModel.sharedCombined { ///contrary motion
//                if let keyboardIndex = keybord.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                    let key=keybord.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                }
//            }
//            else {
//                if let keyboardIndex = keyboard[handForNote]?.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[handForNote]) {
//                    let key=keyboard[handForNote]!.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                }
//            }
//
//            let matchedIndex = self.nextExpectedNoteInScaleIndex[handForNote]!
//            var noteState = scale.getScaleNoteState(handType: handForNote, index: matchedIndex)
//            noteState.matchedTime = Date()
//            
//            ///Decide if a badge was earned. For both hand scales both the LH and RH must be matched
//            var correctNotePlayed = false
//            if scale.hands.count == 1 {
//                correctNotePlayed = true
//            }
//            else {
//                if handForNote == .left {
//                    correctNotePlayed = scale.getScaleNoteState(handType: .right, index: matchedIndex).matchedTime != nil
//                }
//                else {
//                    correctNotePlayed = scale.getScaleNoteState(handType: .left, index: matchedIndex).matchedTime != nil
//                }
//            }
//            if correctNotePlayed {
//                badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
//                let wonStateOld = exerciseState.totalCorrect >= exerciseState.numberToWin
//                exerciseState.setTotalCorrect(exerciseState.totalCorrect + 1)
//                let wonStateNew = exerciseState.totalCorrect >= exerciseState.numberToWin
//                if !wonStateOld && wonStateNew {
//                    if let exerciseBadge = scalesModel.exerciseBadge {
//                        if let practiceChartCell = practiceChartCell {
//                            practiceChartCell.addBadge(badge: exerciseBadge)
//                        }
//                    }
//                }
//            }
//        }
//        else {
//            ///Midi not in scale - Press the keyboard key in whicher keyboard found first
//            for hand in [KeyboardType.right, .left] {
//                if let keyboardIndex = keyboard[hand]?.getKeyIndexForMidi(midi: midi, segment: self.nextExpectedScaleSegment[hand]) {
//                    let key=keyboard[hand]!.pianoKeyModel[keyboardIndex]
//                    key.setKeyPlaying()
//                    break
//                }
//            }
//        }
//        
//        ///If the midi played was in the scale hilight the note on the score in the correct hand. If the scale is finished exit the process.
//        if let handForNote = handForNote {
//            let index = self.nextExpectedNoteInScaleIndex[handForNote]!
//            if let score = score {
//                let noteScaleState = scale.getScaleNoteState(handType: handForNote, index: index)
//                score.hilightStaffNote(segment: noteScaleState.segments[0], midi: midi, handType: handForNote)
//            }
//            
//            ///Advance the hand that played a scale note
//            if index < scale.getScaleNoteCount()  {
//                self.nextExpectedNoteInScaleIndex[handForNote]! += 1
//            }
//            
//            ///Test for the end of the process - i.e. all notes matched.
//            let atEnd:Bool
//            if scale.hands.count == 1 {
//                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() ||
//                self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
//            }
//            else {
//                atEnd = self.nextExpectedNoteInScaleIndex[.left]! >= scale.getScaleNoteCount() &&
//                        self.nextExpectedNoteInScaleIndex[.right]! >= scale.getScaleNoteCount()
//            }
//            if atEnd {
//                scalesModel.clearFunctionToNotify()
//                scalesModel.setRunningProcess(.none)
//                exerciseState.setExerciseState("LeadScale-Ended", exerciseState.state == .won ? .wonAndFinished : .lost)
//            }
//        }
//    }
    
    func playDemo() {
        //self.start()
       
        DispatchQueue.global(qos: .background).async {
            sleep(1)
            //self.badgeBank.clearMatches()
            self.scalesModel.scale.resetMatchedData()
            var lastSegment:Int? = nil
            let hand = 0
            let keyboard = hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
            let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] //FMAj RH
            //let midis =   [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38] Dmin Harm
            //let midis =     [67, 71, 74, 71, 74, 79, 74, 79, 83, 79, 83, 79, 74, 79, 74, 71, 74, 71, 67, 74] //G maj broken
            
            let notes = self.scalesModel.scale.getStatesInScale(handIndex: hand)
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
                            self.scalesModel.setSelectedScaleSegment(segment)
                        }
                        lastSegment = segment
                        key.setKeyPlaying()
                    }

                    sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)

                    self.notifiedOfSound(midi: midi)
                    
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

}

//func notifiedOfSoundOld(midi:Int) {
//        if leadInShowing {
//            return
//        }
//
//        if let lastCorrectMidi = lastMidi {
//            if midi == lastCorrectMidi {
//                return
//            }
//        }
//        self.lastMidi = midi
//
//        let scale = scalesModel.scale
//        let handType = scale.hands[0] == 0 ? HandType.right : HandType.left
//
//        let nextExpected = scale.getScaleNoteState(handType: handType, index: self.nextExpectedScaleIndex) //scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
//        scalesModel.setSelectedScaleSegment(nextExpected.segments[0])
//        notifyCount += 1
//
//        if midi == nextExpected.midi {
//            if nextExpected.matchedTime == nil {
//                badges.setTotalCorrect(badges.totalCorrect + 1)
//                badges.addMatch(midi)
//                nextExpected.matchedTime = Date()
//            }
//        }
////        else {
////            if status == .outOfScale {
////                nextExpected.matchedTime = Date()
////                badges.setTotalIncorrect(badges.totalIncorrect + 1)
////            }
////            else {
////                ///Look for a matching scale note that has not been played yet
////                for i in 0..<scale.scaleNoteState[hand].count {
////                    let unplayed = scale.scaleNoteState[hand][i]
////                    if unplayed.midi == midi && unplayed.matchedTime == nil {
////                        badges.setTotalCorrect(badges.totalCorrect + 1)
////                        badges.addMatch(midi)
////                        unplayed.matchedTime = Date()
////                        nextExpectedScaleIndex = i
////                        break
////                    }
////                }
////            }
////        }
//        if midi == nextExpected.midi {
//            if self.nextExpectedScaleIndex < scale.getScaleNoteStates(handType: handType).count - 1 {
//                nextExpectedScaleIndex += 1
//                ///Set next segment here so the tap handler hilights the correct stave note
//                let nextExpected = scale.getScaleNoteState(handType: handType, index: self.nextExpectedScaleIndex) ///scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
//                scalesModel.setSelectedScaleSegment(nextExpected.segments[0])
//            }
//        }
////        else {
////            ///🙄a random harmonic may trigger a stop
////            //scalesModel.setRunningProcess(.none)
////            ///Leave the last segment fingering showing
////            scalesModel.setSelectedScaleSegment(scalesModel.scale.getHighestSegment())
////        }
//}
