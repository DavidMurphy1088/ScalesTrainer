import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class ScaleLeadIn : MetronomeTimerNotificationProtocol{
    let audioManager = AudioManager.shared
    var callNum = 0
    var chordRoots:[Int] = []
    var metronomeAudioPlayerLow:AVAudioPlayer?
    var metronomeAudioPlayerHigh:AVAudioPlayer?
    var beatCount = 0
    let barCount = Settings.shared.scaleLeadInBarCount
    
    func useMajor(_ scale:Scale) -> Bool {
        return [.major, .arpeggioMajor, .arpeggioDominantSeventh, .arpeggioMajorSeventh].contains(scale.scaleType)
    }
    
    func metronomeStart() {
        metronomeAudioPlayerLow = audioManager.loadAudioPlayer(name: "metronome_mechanical_low")
        metronomeAudioPlayerHigh = audioManager.loadAudioPlayer(name: "metronome_mechanical_high")
        beatCount = 0
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        if beatCount % 4 == 0 {
            metronomeAudioPlayerHigh!.play()
        }
        else {
            metronomeAudioPlayerLow!.play()
        }
        beatCount += 1
        return beatCount >= barCount * 4
    }
    
    func metronomeStop() {
    }

    func getInstructions() -> String {
        var str = "Start your scale after "
        switch barCount {
        case 1:
            str += "one bar"
        case 2:
            str += "two bars"
        case 3:
            str += "four bars"

        default:
            str += "."
        }
        return str
    }
    
}
