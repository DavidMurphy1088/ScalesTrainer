import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class MetronomeTicker : MetronomeTimerNotificationProtocol {
    let audioManager = AudioManager.shared
    var metronomeAudioPlayerLow:AVAudioPlayer?
    
    init() {
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerLow?.volume = 0.1
        //_tickNum = 0
    }
    
    func metronomeTickNotification(timerTickerNumber: Int)  {
        let metronome = Metronome.shared
        let notesPerClick = metronome.getNotesPerClick()
        ///1.0.20 play the tick on every note but make the offbeat zero volume.
        ///This fixes the limp when some notes were played with a metronome tick and some played with it. In that case the 2nd note played was about 10% more duration than the first.
        if true || timerTickerNumber % notesPerClick == 0 {
            if let player = metronomeAudioPlayerLow {
                player.volume = timerTickerNumber % notesPerClick == 0 ? 0.1 : 0.0
                //print("        ============= metronomeTickNotification 🔔 Tick\(timerTickerNumber)")
                player.play()
            }
        }
    }
    
    func metronomeStop() {
    }
    
}
