
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var direction = 0
    
    func metronomeStart() {
        let audioManager = AudioManager.shared
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        let audioManager = AudioManager.shared
        let sampler = audioManager.midiSampler
        let keyboard = PianoKeyboardModel.shared
        let scalesModel = ScalesModel.shared
        ///Playing the app's scale
        if timerTickerNumber < ScalesModel.shared.scale.scaleNoteState.count {
            let scaleNote = ScalesModel.shared.scale.scaleNoteState[timerTickerNumber]
            let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNote.midi, direction:direction)
            if let keyIndex = keyIndex {
                let key=keyboard.pianoKeyModel[keyIndex]
                key.setKeyPlaying(ascending: direction, hilight: true)
            }
            sampler?.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
            
            ///Scale turnaround
            if timerTickerNumber == ScalesModel.shared.scale.scaleNoteState.count / 2 {
                scalesModel.setDirection(1)
                direction = 1
                //scalesModel.forceRepaint()
                //setFingers(direction: 1)
            }
        }
        return timerTickerNumber >= ScalesModel.shared.scale.scaleNoteState.count - 1
    }
    
    func metronomeStop() {
        ScalesModel.shared.setDirection(0)
    }
    
}
