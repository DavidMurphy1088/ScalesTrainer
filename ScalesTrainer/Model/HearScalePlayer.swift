
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
    //var currentSegment = 0
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
        //scalesModel.scale.debug1("Hear")
        PianoKeyboardModel.sharedCombined?.debug22("Hear")
        nextNoteIndex = 0
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
            //keyboard.debug1("Hear")
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
            scalesModel.setSelectedScaleSegment(nextNote.segment)
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
