
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    var nextNoteIndex = 0
    var beatCount = 0
    var leadInShown = false
    let scale = ScalesModel.shared.scale
    var backingWasOn = false
    
    init(hands:[Int]) {
    }
    
    func getKeyboard(hand:Int) -> PianoKeyboardModel {
        if let combined = PianoKeyboardModel.sharedCombined {
            return combined
        }
        else {
            return hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
        }
    }
    
    func metronomeStart() {
        beatCount = 0
        nextNoteIndex = 0
        backingWasOn = scalesModel.backingOn
        if let combined = PianoKeyboardModel.sharedCombined {
            combined.hilightNotesOutsideScale = false
        }
        else {
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            PianoKeyboardModel.sharedLH.hilightNotesOutsideScale = false
        }
        //scalesModel.setBacking(false)
        self.scalesModel.scale.debug2("HearScale")
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
//        if Settings.shared.getLeadInBeats() > 0 {
////            if backingWasOn {
////                scalesModel.setBacking(false)
////            }
//            if beatCount < Settings.shared.getLeadInBeats() {
//                MetronomeModel.shared.setLeadingIn(way: true)
//                leadInShown = true
//                beatCount += 1
//                return false
//            }
//        }
//        if leadInShown {
//            MetronomeModel.shared.setLeadingIn(way: false)
//        }
//        if timerTickerNumber == 0 {
//            if backingWasOn {
//                scalesModel.backer?.callNum = 0
//            }
//        }
//
        if waitBeats > 0 {
            waitBeats -= 1
            return false
        }
        let sampler = audioManager.keyboardMidiSampler
        for hand in scale.hands {
            let note = scale.scaleNoteState[hand][nextNoteIndex]
            let keyboard = getKeyboard(hand: hand)
            let keyIndex = keyboard.getKeyIndexForMidi(midi: note.midi, segment:note.segments[0])
            if let keyIndex = keyIndex {
                let key=keyboard.pianoKeyModel[keyIndex]
                key.setKeyPlaying(hilight: true)
                let velocity:UInt8 = key.keyboardModel == .sharedLH ? 48 : 64
                sampler?.play(noteNumber: UInt8(key.midi), velocity: velocity, channel: 0)
            }
        }
        let scaleNoteState = scale.scaleNoteState[0][nextNoteIndex]
        let notesPerBeat = scalesModel.scale.timeSignature.top % 3 == 0 ? 3.0 : 2.0
        waitBeats = Int(scaleNoteState.value * notesPerBeat) - 1
        //print("=========", scaleNoteState.midi, waitBeats)

        if nextNoteIndex < self.scalesModel.scale.scaleNoteState[0].count - 1 {
            self.nextNoteIndex += 1
            let nextNote = scale.scaleNoteState[0][nextNoteIndex]
            scalesModel.setSelectedScaleSegment(nextNote.segments[0])
        }
        else {
            scalesModel.setSelectedScaleSegment(0)
            self.nextNoteIndex = 0
        }

        return false
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedScaleSegment(0)
    }
}
