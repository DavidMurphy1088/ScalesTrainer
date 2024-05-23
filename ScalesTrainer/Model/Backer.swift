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
    var chords:[Key] = []
    
    func metronomeStart() {
        chords.append(Key(name:"C", keyType: .major))
        chords.append(Key(name:"A", keyType: .minor))
        chords.append(Key(name:"F", keyType: .major))
        chords.append(Key(name:"G", keyType: .major))
    }
    
    func metronomeStop() {
    }
    
    func getMidi(bar:Int, beat:Int) -> Int {
        let key = chords[bar % 4]
        let root = key.getRootMidi()
        var midi = 0
        switch beat {
        case 1:
            midi = root + 7
        case 2:
            midi = key.keyType == .minor ? root + 3 : root + 4
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
        audioManager.midiSampler.play(noteNumber: MIDINoteNumber(midi), velocity: 64, channel: 0)
        callNum += 1
        return false
    }
}
