
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var direction = 0
    var noteToPlay:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    let metronome:MetronomeModel
    let ticker:MetronomeTicker
    let handIndexes:[Int]
    
    init(handIndex:Int, metronome:MetronomeModel) {
        self.metronome = metronome
        self.ticker = MetronomeTicker(metronome: metronome)
        self.handIndexes = handIndex == 2 ? [0,1] : [handIndex]
        
    }
    
    func metronomeStart() {
        ticker.metronomeStart()
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        ///Wait for lead in if specified
        if Settings.shared.metronomeOn {
            let _ = ticker.metronomeTicked(timerTickerNumber: timerTickerNumber)
            if Settings.shared.scaleLeadInBarCount > 0 {
                let bar = timerTickerNumber / 4
                if bar < Settings.shared.scaleLeadInBarCount {
                    return false
                }
            }
        }
        
        let sampler = audioManager.keyboardMidiSampler

        ///Playing the app's scale
        
        for handIndex in self.handIndexes {
            let keyboard = handIndex == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
            if lastNoteValue == nil || lastNoteValue == 0 {
                if noteToPlay[handIndex] >= ScalesModel.shared.scale.scaleNoteState[handIndex].count {
                    noteToPlay[handIndex] = 0
                }
                let scaleNoteState = ScalesModel.shared.scale.scaleNoteState[handIndex][noteToPlay[handIndex]]
                let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNoteState.midi, direction:direction)
                if let keyIndex = keyIndex {
                    let key=keyboard.pianoKeyModel[keyIndex]
                    key.setKeyPlaying(ascending: direction, hilight: true)
                }
                sampler?.play(noteNumber: UInt8(scaleNoteState.midi), velocity: 64, channel: 0)
                
                ///Scale turnaround
                if noteToPlay[handIndex] == ScalesModel.shared.scale.scaleNoteState.count / 2 {
                    scalesModel.setSelectedDirection(1)
                    direction = 1
                    
                }
                noteToPlay[handIndex] += 1
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
