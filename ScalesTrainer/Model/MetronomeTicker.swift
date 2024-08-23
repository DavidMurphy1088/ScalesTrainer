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
    var beatCount = 0
    var metronome:MetronomeModel
    
    init(metronome:MetronomeModel) {
        self.metronome = metronome
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        beatCount = 0
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        if Settings.shared.metronomeOn {
            if beatCount % 4 == 0 {
                metronomeAudioPlayerHigh!.play()
            }
            else {
                metronomeAudioPlayerLow!.play()
            }
        }
        beatCount += 1
        return false
    }
    
    func metronomeStop() {
    }
    
}
