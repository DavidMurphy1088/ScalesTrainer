
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var direction = 0
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    let handIndexes:[Int]
    
    init(handIndex:Int) {
        self.handIndexes = handIndex == 2 ? [0,1] : [handIndex]
    }
    
    func metronomeStart() {
    }
    
    func soundMetronomeTick(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        let sampler = audioManager.keyboardMidiSampler
        if waitBeats > 0 {
            waitBeats -= 1
            return false
        }

        ///Playing the app's scale
        for handIndex in self.handIndexes {
            let keyboard = handIndex == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
            if lastNoteValue == nil || lastNoteValue == 0 {
                if noteToPlayIndex[handIndex] >= ScalesModel.shared.scale.scaleNoteState[handIndex].count {
                    noteToPlayIndex[handIndex] = 0
                    scalesModel.setSelectedDirection(0)
                    direction = 0
                }
                let scaleNoteState = ScalesModel.shared.scale.scaleNoteState[handIndex][noteToPlayIndex[handIndex]]
                let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNoteState.midi, direction:direction)
                if let keyIndex = keyIndex {
                    let key=keyboard.pianoKeyModel[keyIndex]
                    key.setKeyPlaying(ascending: direction, hilight: true)
                }
                sampler?.play(noteNumber: UInt8(scaleNoteState.midi), velocity: 64, channel: 0)
                waitBeats = Int(scaleNoteState.value) - 1

                ///Scale turnaround
                if noteToPlayIndex[handIndex] == ScalesModel.shared.scale.scaleNoteState[handIndex].count / 2 {
                    scalesModel.setSelectedDirection(1)
                    direction = 1
                }
                noteToPlayIndex[handIndex] += 1
                lastNoteValue = scaleNoteState.value
            }
            if lastNoteValue != nil {
                lastNoteValue! -= 1.0
            }
        }
        return false
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedDirection(0)
    }
}
