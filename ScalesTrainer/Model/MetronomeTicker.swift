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
    //var beatCount = 0
    //var metronome:MetronomeModel
    
    init() {
        //self.metronome = metronome
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerLow?.volume = 0.2
        metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        metronomeAudioPlayerHigh?.volume = 0.5
    }
    
    func soundMetronomeTick(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if Settings.shared.metronomeOn {
            if timerTickerNumber % 4 == 0 {
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
