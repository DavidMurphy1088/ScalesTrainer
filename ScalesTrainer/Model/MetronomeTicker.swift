import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class MetronomeTicker : MetronomeTimerNotificationProtocol {
    let audioManager = AudioManager.shared
    var callNum = 0
    var metronomeAudioPlayerLow:AVAudioPlayer?
    var tickNum = 0
    
    init() {
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerLow?.volume = 0.1
        //metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        //metronomeAudioPlayerHigh?.volume = 0.2
        tickNum = 0
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
        let metronome = Metronome.shared
        let notesPerClick = metronome.getNotesPerClick()
        ///1.0.20 play the tick on every note but make the offbeat zero volume.
        ///This fixes the limp when some notes were played with a metronome tick and some played with it. In that case the 2nd note played was about 10% more duration than the first.
        if true || timerTickerNumber % notesPerClick == 0 {
            if let player = metronomeAudioPlayerLow {
                player.volume = timerTickerNumber % notesPerClick == 0 ? 0.1 : 0.0
                player.play()
            }
            self.tickNum += 1
            metronome.setTimerTickerCountPublished(count: self.tickNum)
        }
    }
    
    func metronomeStop() {
    }
    
}
