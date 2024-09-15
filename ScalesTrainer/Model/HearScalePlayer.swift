
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    //var notesAndKeys:[(Int, ScaleNoteState, PianoKeyModel)] = []
    //var notesAndKeys:[(Int, ScaleNoteState)] = []
    var nextNoteIndex = 0
    var beatCount = 0
    var leadInShown = false
    var currentSegment = 0
    let scale = ScalesModel.shared.scale
    
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

        ///Make the list of notes to play along with the correct keyboard key
        ///A two hand scale may be played in 1 or 2 keyboards (depending on the scale type)
//        for scaleHand in [0,1] {
//
//            //if let keyboard = keyboard {
//                for i in 0..<scale.scaleNoteState[scaleHand].count {
//                    let scaleNoteState = ScalesModel.shared.scale.scaleNoteState[scaleHand][i]
//                    //let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNoteState.midi, direction:direction)
//                    //if let keyIndex = keyIndex {
//                        //let key=keyboard.pianoKeyModel[keyIndex]
//                        self.notesAndKeys.append((i, scaleNoteState))
//                    //}
////                    if i == ScalesModel.shared.scale.scaleNoteState[scaleHand].count / 2 {
////                        direction = 1
////                    }
//                }
//            //}
//        }
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if Settings.shared.getLeadInBeats() > 0 {
            if beatCount < Settings.shared.getLeadInBeats() {
                MetronomeModel.shared.setLeadingIn(way: true)
                leadInShown = true
                beatCount += 1
                return false
            }
        }
        if leadInShown {
            MetronomeModel.shared.setLeadingIn(way: false)
        }
        let sampler = audioManager.keyboardMidiSampler
        if waitBeats > 0 {
            waitBeats -= 1
            return false
        }
        for hand in scale.hands {
            let note = scale.scaleNoteState[hand][nextNoteIndex]
            let keyboard = getKeyboard(hand: hand)
            let keyIndex = keyboard.getKeyIndexForMidi(midi: note.midi, segment:note.segment)
            if let keyIndex = keyIndex {
                let key=keyboard.pianoKeyModel[keyIndex]

                key.setKeyPlaying(hilight: true)
                sampler?.play(noteNumber: UInt8(key.midi), velocity: 64, channel: 0)
            }
        }
        let scaleNoteState = scale.scaleNoteState[0][nextNoteIndex]
        waitBeats = Int(scaleNoteState.value) - 1

        if nextNoteIndex < self.scalesModel.scale.scaleNoteState[0].count - 1 {
            self.nextNoteIndex += 1
            let nextNote = scale.scaleNoteState[0][nextNoteIndex]
            if nextNote.segment != self.currentSegment {
                scalesModel.setSelectedScaleSegment(nextNote.segment)
                self.currentSegment = nextNote.segment
            }
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
