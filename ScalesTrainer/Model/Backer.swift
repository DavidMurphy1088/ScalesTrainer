import SwiftUI
import Foundation
import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX
import Speech

class Backer :MetronomeTimerNotificationProtocol{
    let audioManager = AudioManager.shared
    var callNum = 0
    var chordRoots:[Int] = []
    
    func metronomeStart() {
        let scale = ScalesModel.shared.scale
        let key = scale.key
        var root = scale.scaleNoteState[0].midi
        root -= 12
        if key.keyType == .major {
            chordRoots.append(root)
            chordRoots.append(root - 3) //ii minoir
            chordRoots.append(root - 7) //IV
            chordRoots.append(root - 5) //V
        }
        else {
            chordRoots.append(root) // i
            chordRoots.append(root - 7) //iv
            chordRoots.append(root - 5) //V
            chordRoots.append(root) //i
        }
    }
    
    func metronomeStop() {
    }
    
    func getMidi(bar:Int, beat:Int) -> Int {
        let scale = ScalesModel.shared.scale
        let root = chordRoots[bar % 4]
        var midi = 0
        ///Make Alberti pattern
        if scale.key.keyType == .major {
            switch beat {
            case 0:
                midi = root
            case 1:
                midi = root + 7
            case 2:
                midi = bar % 4 == 1 ? root + 3 : root + 4
                //midi = root + 4
            case 3:
                midi = root + 7
            default:
                midi = root
            }
        }
        else {
            switch beat {
            case 0:
                midi = root
            case 1:
                midi = root + 7
            case 2:
                midi = [0,1,3].contains(bar % 4) ? root + 3 : root + 4
                //midi = root + 4
            case 3:
                midi = root + 7
            default:
                midi = root
            }
        }
        return midi
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        //let keyPlayingSeconds = 1.0 //How long the key stays hilighed when played
        let beat = callNum % 4
        var midi = 0
        let bar = callNum / 4
        midi = getMidi(bar: bar, beat: beat)
        audioManager.midiSampler.play(noteNumber: MIDINoteNumber(midi), velocity: 60, channel: 0)
        callNum += 1
        return false
    }
}
