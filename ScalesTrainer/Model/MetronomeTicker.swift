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
    var metronomeAudioPlayerHigh:AVAudioPlayer?
    
    init() {
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerLow?.volume = 0.1
        metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        metronomeAudioPlayerHigh?.volume = 0.2
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if !Settings.shared.metronomeSilent {
            if timerTickerNumber % 4 == 0 {
                metronomeAudioPlayerHigh!.play()
            }
            else {
                metronomeAudioPlayerLow!.play()
            }
        }
        MetronomeModel.shared.setTimerTickerCountPublished(count: timerTickerNumber / MetronomeModel.shared.notesPerClick)
        return false
    }
    
    func metronomeStop() {
    }
    
}
