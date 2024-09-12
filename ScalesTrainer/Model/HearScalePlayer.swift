
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    var notesAndKeys:[(Int, ScaleNoteState, PianoKeyModel, Int)] = []
    var nextNote = 0
    var beatCount = 0
    var leadInShown = false
    
    init(hands:[Int]) {
    }
    
    func metronomeStart() {
        beatCount = 0
        let scale = ScalesModel.shared.scale

        ///Make the list of notes to play along with the correct keyboard key
        ///A two hand scale may be played in 1 or 2 keyboards (depending on the scale type)
        for scaleHand in [0,1] {
            //let scaleHand = scale.hands[scaleHandIndex]
            var direction = 0
            var keyboard:PianoKeyboardModel? = nil
            if scaleHand == 0 {
                if scale.hands.contains(scaleHand) {
                    keyboard = PianoKeyboardModel.sharedRH
                }
            }
            else {
                if scale.hands.contains(scaleHand) {
                    keyboard = PianoKeyboardModel.sharedLH //scale.needsTwoKeyboards() ? PianoKeyboardModel.shared2 : PianoKeyboardModel.shared1
                }
            }
            if let keyboard = keyboard {
                for i in 0..<scale.scaleNoteState[scaleHand].count {
                    let scaleNoteState = ScalesModel.shared.scale.scaleNoteState[scaleHand][i]
                    let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNoteState.midi, direction:direction)
                    if let keyIndex = keyIndex {
                        let key=keyboard.pianoKeyModel[keyIndex]
                        self.notesAndKeys.append((i, scaleNoteState, key, direction))
                    }
                    if i == ScalesModel.shared.scale.scaleNoteState[scaleHand].count / 2 {
                        direction = 1
                    }
                }
            }
        }
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
        
        for note in self.notesAndKeys {
            let (sequence, scaleNoteState, key, direction) = note
            if sequence == self.nextNote {
                key.setKeyPlaying(ascending: direction, hilight: true)
                sampler?.play(noteNumber: UInt8(scaleNoteState.midi), velocity: 64, channel: 0)
                waitBeats = Int(scaleNoteState.value) - 1
            }
        }

        if nextNote < self.scalesModel.scale.scaleNoteState[0].count - 1 {
            self.nextNote += 1
        }
        else {
            self.nextNote = 0
        }
        return false
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedDirection(0)
    }
}
