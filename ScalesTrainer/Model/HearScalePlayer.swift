
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    var notesAndKeys:[[(ScaleNoteState, PianoKeyModel, Int)]] = []
    var nextNote = 0
    var handsToPlay:[Int] = []
    var beatCount = 0
    var leadInShown = false
    
    init(handIndex:Int) {
    }
    
    func metronomeStart() {
        beatCount = 0
        let scale = ScalesModel.shared.scale
        for handIndex in [0,1] {
            notesAndKeys.append([])
            var direction = 0
            let keyboard = handIndex == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
            for i in 0..<scale.scaleNoteState[handIndex].count {
                let scaleNoteState = ScalesModel.shared.scale.scaleNoteState[handIndex][i]
                let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNoteState.midi, direction:direction)
                if let keyIndex = keyIndex {
                    let key=keyboard.pianoKeyModel[keyIndex]
                    self.notesAndKeys[handIndex].append((scaleNoteState, key, direction))
                }
                if i == ScalesModel.shared.scale.scaleNoteState[handIndex].count / 2 {
                    direction = 1
                }
            }
        }
        if scale.hand == 2 {
            handsToPlay = [0,1]
        }
        else {
            handsToPlay = [scale.hand]
        }
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if Settings.shared.scaleLeadInBarCount > 0 {
            if beatCount / 4 < Settings.shared.scaleLeadInBarCount {
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
        
        for hand in handsToPlay {
            let (scaleNoteState,key, direction) = self.notesAndKeys[hand][self.nextNote]
            key.setKeyPlaying(ascending: direction, hilight: true)
            sampler?.play(noteNumber: UInt8(scaleNoteState.midi), velocity: 64, channel: 0)
            waitBeats = Int(scaleNoteState.value) - 1
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
