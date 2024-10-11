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
    ///Oct2024 Changed to one tone for metronome
    //var metronomeAudioPlayerHigh:AVAudioPlayer?
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
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        //print("    Ticker ========", "TickNum", tickNum , tickNum % ScalesModel.shared.scale.timeSignature.top, ScalesModel.shared.scale.timeSignature.top)
        if !Settings.shared.metronomeSilent {
//            if tickNum % ScalesModel.shared.scale.timeSignature.top == 0 {
//                metronomeAudioPlayerHigh!.play()
//            }
//            else {
//                metronomeAudioPlayerLow!.play()
//            }
            
            metronomeAudioPlayerLow!.play()
        }
        self.tickNum += 1
        return false
    }
    
    func metronomeStop() {
    }
    
}
