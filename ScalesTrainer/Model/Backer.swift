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
        var root = scale.scaleNoteState[0].midi
        root -= 12
        chordRoots.append(root)
        chordRoots.append(root - 3)
        chordRoots.append(root - 7)
        chordRoots.append(root - 5)
    }
    
    func metronomeStop() {
    }
    
    func getMidi(bar:Int, beat:Int) -> Int {
        //let key = chords[bar % 4]
        let root = chordRoots[bar % 4]
        var midi = 0
        switch beat {
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
        return midi
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        //let keyPlayingSeconds = 1.0 //How long the key stays hilighed when played
        let beat = callNum % 4
        var midi = 0
        let bar = callNum / 4
        midi = getMidi(bar: bar, beat: beat)
        audioManager.midiSampler.play(noteNumber: MIDINoteNumber(midi), velocity: 32, channel: 0)
        callNum += 1
        return false
    }
}
