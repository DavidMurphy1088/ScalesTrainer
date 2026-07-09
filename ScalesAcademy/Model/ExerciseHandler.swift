import Foundation
import AVFoundation
import Combine
import SwiftUI

///A note required next in the scale
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
class ExerciseHandler  {
    let exerciseType:RunningProcess
    var midisWithOneKeyPress: [Int] = []
    let scale:Scale
    let scalesModel:ScalesModel
    var nextExpectedNoteIndexForHand:[HandType:Int]
    var nextExpectedStaffSegment:[HandType:Int]
    let exerciseState:ExerciseState
    let exerciseBadgesList:ExerciseBadgesList ///The badges earned on a per note basis for the exercise
    let metronome:Metronome
    //let practiceChart:PracticeChart?
    //let practiceChartCell:PracticeChartCell?
    var currentScoreSegment = 0
    var cancelled = false
    let accessQueue = DispatchQueue(label: "ExerciseHandlerQueue")
    var lastMatchedMidi:Int? = nil
    var lastKeyHilighted:PianoKeyModel? = nil
    let scaleMinxMaxMidis:(Int, Int)
    let user:User
    var noteNotificationNumber = 0
    
    //init(exerciseType:RunningProcess, scalesModel:ScalesModel, practiceChart:PracticeChart?, practiceChartCell:PracticeChartCell?,
    init(exerciseType:RunningProcess, scalesModel:ScalesModel, metronome:Metronome) {
        self.exerciseType = exerciseType
        self.scalesModel = scalesModel
        self.exerciseState = ExerciseState.shared
        self.exerciseBadgesList = ExerciseBadgesList.shared
        self.nextExpectedNoteIndexForHand = [:]
        nextExpectedStaffSegment = [:]
        self.metronome = metronome
        self.scale = scalesModel.scale
        //self.practiceChart = practiceChart
        //self.practiceChartCell = practiceChartCell
        self.scaleMinxMaxMidis = scale.getMinMaxMidis()
        self.user = Settings.shared.getCurrentUser("Exercise Handler init")
    }
    
    func start(soundHandler:SoundEventHandlerProtocol) {
        self.exerciseBadgesList.setTotalBadges(0)
        scale.resetMatchedData()
        exerciseState.resetTotalCorrect()
        nextExpectedNoteIndexForHand[.left] = 0
        nextExpectedNoteIndexForHand[.right] = 0
        nextExpectedStaffSegment[.right] = 0
        nextExpectedStaffSegment[.left] = 0
        currentScoreSegment = 0
        if Parameters.midiEnabled { MIDIManager.shared.matchedNotes.start(hands: scale.getHandTypes()) }
        let numberToWin = scale.getScaleNoteCount()
        exerciseState.setNumberToWin(numberToWin)
        if scale.scaleMotion == .contraryMotion {
            if scale.getScaleNoteState(handType: .left, index: 0)!.midi == scale.getScaleNoteState(handType: .right, index: 0)!.midi {
                midisWithOneKeyPress.append(scale.getScaleNoteState(handType: .left, index: 0)!.midi)
            }
        }
        soundHandler.setFunctionToNotify(functionToNotify: self.notifiedOfSound(midiMsg:))
        cancelled = false
        soundHandler.start()
        lastKeyHilighted = nil
        noteNotificationNumber = 0
        if self.exerciseType == .followingScale {
            hilightKey(scaleIndex: 0)
        }
        if Parameters.midiEnabled {
            let user = Settings.shared.getCurrentUser("ExerciseHandler - start")
            if user.settings.useMidiSources {
                if MIDIManager.shared.testMidiNotes != nil {
                    MIDIManager.shared.playTestMidiNotes(soundHandler: soundHandler)
                }
            }
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
    func notifiedOfSound(midiMsg:MIDIMessage) {
//        if midiMsg.messageType == MIDIMessage.MIDIStatus.noteOff {
//            if Parameters.midiEnabled { MIDIManager.shared.matchedNotes.processNoteOff(midi: midiMsg.midi) }
//            return
//        }
        ///For contrary motion scales with LH and RH starting on the note the student will only play one key. (And the same for the final scale note)
        ///But note based badge matching requires that both LH and RH of the scale are matched, so send the midi again.
        let midi = midiMsg.midi
        ///Filter out harmonics and overtones that cause wrong note notification.
        if !user.settings.useMidiSources {
            let margin = 3
            if midi < self.scaleMinxMaxMidis.0 - margin {
                return
            }
            if midi > self.scaleMinxMaxMidis.1 + margin {
                return
            }
        }
        ///A contrary motion scale with LH and RH starting on the same note needs to generate a call for each hand
        let callCount = midisWithOneKeyPress.contains(midi) ? 2 : 1
        for call in 0..<callCount {
//            if self.applySerialLock() {
//                accessQueue.sync {
//                    processSound(callNumber: call, midi: midi, velocity: midiMsg.velocity)
//                }
//            }
//            else {
                pressKeyboard(callNumber: call, midi: midi, velocity: midiMsg.velocity)
//            }
        }
        self.noteNotificationNumber += 1
    }
    
    ///Determine the keyboard (LH or RH) the sound was played from (required for scales with both hands).
    ///Then set the key on that keyboard playing. Also hilight the associated staff note.
    ///The specific exercise sets the callback on the key to have its code executed once the key is set playing.
    ///
    public func pressKeyboard(callNumber:Int, midi:Int, velocity:Float) {
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
            var nextExpectedNotes:[Int] = []
            for hand in handsToSearch {
                if let nextExpectedIndex = self.nextExpectedNoteIndexForHand[hand] {
                    if nextExpectedIndex < scale.getScaleNoteCount() {
                        if let nextExpected = scale.getScaleNoteState(handType: hand, index: nextExpectedIndex) {
                            if midi == nextExpected.midi {
                                handThatPlayedNote = hand
                                break
                            }
                            else {
                                nextExpectedNotes.append(nextExpected.midi)
                            }
                        }
                    }
                }
            }
            ///If the note was not in the scale for either hand decide which was the most likley hand given the note's distance to the hand's expected note.
            if handThatPlayedNote == nil && nextExpectedNotes.count >= 2 {
                if abs(midi - nextExpectedNotes[0]) < abs(midi - nextExpectedNotes[1]) {
                    handThatPlayedNote = HandType.left
                }
                else {
                    handThatPlayedNote = HandType.right
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

        if let handType = handThatPlayedNote, let keyboard = keyboardThatPlayedNote {
            notifyPlayedKey(Keyboard: keyboard, midi: midi, handType: handType, velocity: velocity)
        }
    }
    
    ///16Mar2025 - sometimes get wrong octave of note played so allow it
    ///allowHarmonics - also accept the fifth above (+7) and fifth below (-5), the other common pitch-detection harmonic error
    func harmonicsTolerantMidis(_ midi:Int, allowHarmonics: Bool = false) -> [Int] {
        var allowed:[Int]
        if allowHarmonics {
            allowed = [midi-24, midi-12, midi, midi+12, midi+24, midi+7, midi-5]
        }
        else {
            allowed = [midi-24, midi-12, midi, midi+12, midi+24]
        }
        return allowed
    }

    func notifyPlayedKey(Keyboard:PianoKeyboardModel, midi:Int, handType:HandType, velocity:Float) {
        var expectedNotes:[RequiredNote] = []
                
        ///Gather the expected next midi(s) in each hand. We look ahead usualy 2 notes for a match.
        ///Thats because at faster tempos there may be failure to get notified of correct notes the student plays.
        ///1 Jul 2026 make lookahead default 2. 1 => Wrongly played notes could be ignored.
        ///Counter - 2 => correct notes faster tempos or staccato articulation may give wrong note. i.e. the note was played but didn't get this far. TBD to decide
        ///2Jul 2026 no more than 2 lookahead should be needed for the tempos in the Grade 1->5 syllabus tempos
        if expectedNotes.count == 0 {
            for h in scale.hands {
                let handType = h==0 ? HandType.right : .left
                if let expectedOffset = self.nextExpectedNoteIndexForHand[handType] {
                    ///A trailing pitch from ascending might match itself going back down if looking ahead > 1
                    let atScaleMiddle = expectedOffset == self.scale.getScaleNoteCount()/2
                    let lookahead:Int
                    if user.settings.useMidiSources {
                        lookahead = 1
                    }
                    else if Parameters.shared.debugMode {
                        lookahead = atScaleMiddle ? 1 : Parameters.shared.lookaheadGate
                    }
                    else {
                        lookahead = atScaleMiddle ? 1 : 2
                    }
                    for i in 0..<lookahead {
                        if let nextExpectedNote = scale.getScaleNoteState(handType: handType, index: expectedOffset + i) {
                            let expectedMidi = nextExpectedNote.midi
                            expectedNotes.append(RequiredNote(sequenceNum: i, midi: expectedMidi, handType: handType))
                        }
                    }
                }
            }
        }
        
        ///Match all the notes covered by the new arriving note
        for expectedNote in expectedNotes {
            ///16Mar2025 - sometimes get wrong octave of note played so allow it
            let allowed:[Int]
            if user.settings.useMidiSources {
                allowed = [expectedNote.midi]
            }
            else {
                allowed = harmonicsTolerantMidis(expectedNote.midi, allowHarmonics: Parameters.shared.allowHarmonics)
            }
            if allowed.contains(midi) && expectedNote.handType == handType {
                expectedNote.matched = true
                for previousNote in expectedNotes {
                    if previousNote.sequenceNum < expectedNote.sequenceNum {
                        previousNote.matched = true
                    }
                }
                break
            }
        }
        
        ///Advance the nextExpectedNoteIndex and set the scale segment
        var matchedCount = 0
        for expectedNote in expectedNotes {
            if expectedNote.matched {
                matchedCount += 1
                self.lastMatchedMidi = expectedNote.midi
                if self.nextExpectedNoteIndexForHand.keys.contains(handType) {
                    nextExpectedNoteIndexForHand[expectedNote.handType]! += 1
                }
                if let index = nextExpectedNoteIndexForHand[handType] {
                    if index < scale.getScaleNoteCount() {
                        if let scaleNote = scale.getScaleNoteState(handType: handType, index: index) {
                            scalesModel.setSelectedScaleSegment(scaleNote.segments[0])
                        }
                    }
                    if self.exerciseType == .followingScale {
                        hilightKey(scaleIndex: index)
                    }
                }
            }
        }
        
        if matchedCount == 0 {
            if Parameters.shared.debugMode {
                let expectedStr = expectedNotes.map { "\(StaffNote.getNoteName(midiNum: $0.midi))(\($0.midi))" }.joined(separator: ",")
                let handIndex = handType == .right ? 0 : 1
                let scaleMidis = scale.getMidisInScale(handIndex: handIndex)
                let notInScale = !scaleMidis.contains(midi)
                let suffix = notInScale ? "  WRONG NOTE" : ""
                let totalMatched = nextExpectedNoteIndexForHand[handType] ?? 0
                let line = String(format: "==notifyPlayedKey MIDI:%d (%@) vol:%.3f  expected:[%@]  matched:0  badge:n/a  total:%d/%d%@", midi, StaffNote.getNoteName(midiNum: midi), velocity, expectedStr, totalMatched, scale.getScaleNoteCount(), suffix)
                ProcessLog.shared.log(line)
            }
            ///The note pitches may ring on and cause > 1 note notification
            if let lastMatchedMidi = self.lastMatchedMidi {
                if (midi % 12) != (lastMatchedMidi % 12) {
                    testForFailExercise(midi: midi, velocity: velocity, requiredNotes: expectedNotes, keyboard: Keyboard)
                }
            }
        }
        else {
            var awardBadge = false
            if scale.hands.count == 1 {
                awardBadge = true
            }
            else {
                if nextExpectedNoteIndexForHand[HandType.right] == nextExpectedNoteIndexForHand[HandType.left] {
                    awardBadge = true
                }
            }
            if Parameters.shared.debugMode {
                let expectedStr = expectedNotes.map { "\(StaffNote.getNoteName(midiNum: $0.midi))(\($0.midi))" }.joined(separator: ",")
                let totalMatched = nextExpectedNoteIndexForHand[handType] ?? 0
                let matchFlag = matchedCount > 1 ? " 🔴" : " 🟢"
                let line = String(format: "==notifyPlayedKey MIDI:%d (%@) vol:%.3f  expected:[%@]  matched:%d  badge:%@  total:%d/%d", midi, StaffNote.getNoteName(midiNum: midi), velocity, expectedStr, matchedCount, awardBadge ? "yes" : "no", totalMatched, scale.getScaleNoteCount()) + matchFlag
                ProcessLog.shared.log(line)
            }
            if awardBadge {
                for _ in 0..<matchedCount {
                    exerciseBadgesList.setTotalBadges(exerciseBadgesList.totalBadges + 1)
                    exerciseState.bumpTotalCorrect()
                }
                if Parameters.shared.debugMode {
                    let line = "==awardBadge matchedCount:\(matchedCount)  totalCorrect:\(exerciseState.totalCorrect)  numberToWin:\(exerciseState.numberToWin)  exerciseState:\(exerciseState.getState())"
                    ProcessLog.shared.log(line)
                }
            }
            testForEndOfExercise()
        }
    }
    
    func testForFailExercise(midi:Int, velocity:Float, requiredNotes: [RequiredNote], keyboard:PianoKeyboardModel) {
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
        
        ///If the note was close to (but not the same as) an expected note, the note played was wrong
        ///16Mar2025 - sometimes get wrong octave of octave played
        for requiredNote in requiredNotes {
            let allowed = harmonicsTolerantMidis(requiredNote.midi, allowHarmonics: Parameters.shared.allowHarmonics)
            if !allowed.contains(midi) {
                if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                    let key = keyboard.pianoKeyModel[keyIndex]
                    key.hilightType = .wasWrongNote
                }
                let segment = currentScoreSegment == 0 ? "ascending" : "descending"
                let useFlats = (scalesModel.getScore()?.key.keySig.flats.count ?? 0) > 0
                let msg = Parameters.shared.debugMode
                    ? "Wrong Note — \(segment), played: \(midi) \(StaffNote.getNoteName(midiNum: midi, useFlats: useFlats))  expected: \(requiredNote.midi) \(StaffNote.getNoteName(midiNum: requiredNote.midi, useFlats: useFlats))"
                    : "Wrong Note — \(segment), played: \(StaffNote.getNoteName(midiNum: midi, useFlats: useFlats))  expected: \(StaffNote.getNoteName(midiNum: requiredNote.midi, useFlats: useFlats))"
                if Parameters.shared.debugMode {
                    let line = String(format: "==EXERCISE ENDED wrong note played:%d (%@) expected:%d (%@) %@ vol:%.3f 😡", midi, StaffNote.getNoteName(midiNum: midi, useFlats: useFlats), requiredNote.midi, StaffNote.getNoteName(midiNum: requiredNote.midi, useFlats: useFlats), segment, velocity)
                    ProcessLog.shared.log(line)
                }
                exerciseState.setExerciseState("Wrong note midi:\(midi) required:\(requiredNote.midi)", .exerciseLost, msg)
                scalesModel.exerciseCompletedNotify()
                if Parameters.midiEnabled { MIDIManager.shared.testMidiNotesStopPlaying = true }
                break
            }
        }
    }
    
    func testForEndOfExercise()  {
        func wrapUp() {
            scalesModel.exerciseCompletedNotify()
            self.scalesModel.setRunningProcess(.none)
            if exerciseState.getState() == .exerciseStarted {
                exerciseState.setExerciseState("Follow, EndOfExercise", .exerciseLost, "Notes Not Complete")
            }
        }
        
        let atEnd:Bool
        if scale.hands.count == 1 {
            atEnd = self.nextExpectedNoteIndexForHand[.left]! >= scale.getScaleNoteCount() ||
            self.nextExpectedNoteIndexForHand[.right]! >= scale.getScaleNoteCount()
        }
        else {
            atEnd = self.nextExpectedNoteIndexForHand[.left]! >= scale.getScaleNoteCount() &&
                    self.nextExpectedNoteIndexForHand[.right]! >= scale.getScaleNoteCount()
        }
        if atEnd {
            wrapUp()
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


