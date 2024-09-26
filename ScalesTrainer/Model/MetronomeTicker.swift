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
    let scale:Scale
    
    init(scale:Scale) {
        self.scale = scale
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerLow?.volume = 0.1
        metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        metronomeAudioPlayerHigh?.volume = 0.2
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if !Settings.shared.metronomeSilent {
            if timerTickerNumber % self.scale.timeSignature.top == 0 {
                metronomeAudioPlayerHigh!.play()
            }
            else {
                metronomeAudioPlayerLow!.play()
            }
        }
        return false
    }
    
    func metronomeStop() {
    }
    
}
