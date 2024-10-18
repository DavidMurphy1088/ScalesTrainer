
import Foundation
class IdentifyScalePlayer : MetronomeTimerNotificationProtocol {
    func metronomeStart() {
        
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
        //let audioManager = AudioManager.shared
        //let sampler = audioManager.midiSampler

        ///Playing the app's scale
        if timerTickerNumber < ScalesModel.shared.scale.scaleNoteState.count {
            //let scaleNote = ScalesModel.shared.scale.scaleNoteState[timerTickerNumber]

            //sampler.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
            //scalesModel.setPianoKeyPlayed(midi: scaleNote.midi)
            ///Scale turnaround
//            if timerTickerNumber == ScalesModel.shared.scale.scaleNoteState.count / 2 {
//                scalesModel.setDirection(1)
//                //scalesModel.forceRepaint()
//                //setFingers(direction: 1)
//            }
        }
        //return timerTickerNumber >= ScalesModel.shared.scale.scaleNoteState.count - 1
    }
    
    func metronomeStop() {
        
    }
    
    
}
