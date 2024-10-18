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
        if timerTickerNumber % notesPerClick == 0 {
            metronomeAudioPlayerLow!.play()
            self.tickNum += 1
            metronome.setTimerTickerCountPublished(count: self.tickNum)
        }
    }
    
    func metronomeStop() {
    }
    
}
