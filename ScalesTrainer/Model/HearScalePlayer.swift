
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var direction = 0
    var noteToPlay = 0
    var lastNoteValue:Double? = nil
    let audioManager = AudioManager.shared
    let keyboard = PianoKeyboardModel.sharedSingle
    let scalesModel = ScalesModel.shared
    let metronome:MetronomeModel
    let ticker:MetronomeTicker
    
    init(metronome:MetronomeModel) {
        self.metronome = metronome
        self.ticker = MetronomeTicker(metronome: metronome)
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
        
        if lastNoteValue == nil || lastNoteValue == 0 {
            if noteToPlay >= ScalesModel.shared.scale.scaleNoteState.count {
                noteToPlay = 0
            }
            let scaleNote = ScalesModel.shared.scale.scaleNoteState[noteToPlay]
            let keyIndex = keyboard.getKeyIndexForMidi(midi: scaleNote.midi, direction:direction)
            if let keyIndex = keyIndex {
                let key=keyboard.pianoKeyModel[keyIndex]
                key.setKeyPlaying(ascending: direction, hilight: true)
            }
            sampler?.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
            
            ///Scale turnaround
            if noteToPlay == ScalesModel.shared.scale.scaleNoteState.count / 2 {
                scalesModel.setSelectedDirection(1)
                direction = 1
                //scalesModel.forceRepaint()
                //setFingers(direction: 1)
            }
//            if noteToPlay >= ScalesModel.shared.scale.scaleNoteState.count - 1 {
//                scalesModel.setSelectedDirection(0)
//                ///Dont repeat the scale root on replays
//                noteToPlay = 1
//            }
//            else {
                noteToPlay += 1
//            }
            lastNoteValue = scaleNote.value
        }
        if lastNoteValue != nil {
            lastNoteValue! -= 1.0
        }
        return false
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedDirection(0)
    }
    
}
