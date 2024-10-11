import SwiftUI
import Foundation
import AudioKit
import SoundpipeAudioKit
import Foundation
import AVFoundation
import Foundation
import AudioKitEX

class Backer :MetronomeTimerNotificationProtocol {
    let audioManager = AudioManager.shared
    var callNum = 0
    var chordRoots:[Int] = []
    var lastChord:BackingChords.BackingChord? = nil
    var backingChords:BackingChords? = nil
    var scale:Scale? = nil
    
    func metronomeStart() {
        self.scale = ScalesModel.shared.scale
        if let scale = self.scale {
            self.backingChords = scale.getBackingChords()
        }
//        let scaleRoot = scale.scaleNoteState[0][0].midi % 12
//        var root = scaleRoot + 60 - 12
//        if root >= 55 {
//            root -= 12
//        }
//        chordRoots = []
//        if useMajor(scale) {
//            chordRoots.append(root)
//            chordRoots.append(root - 3) //ii minor
//            chordRoots.append(root - 7) //IV
//            chordRoots.append(root - 5) //V
//        }
//        else {
//            chordRoots.append(root) // i
//            chordRoots.append(root - 7) //iv
//            chordRoots.append(root - 5) //V
//            chordRoots.append(root) //i
//        }
        callNum = 0
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        guard let sampler = audioManager.backingMidiSampler else {
            return false
        }
        guard let backingChords = backingChords else {
            return false
        }
        guard let scale = scale else {
            return false
        }
        //        let bar = (callNum / beatsInCycle) % 4
        //        midi = getMidi(bar: bar, beat: beat)

        let beatsInCycle = ScalesModel.shared.scale.timeSignature.top
        //let beat = callNum % beatsInCycle
        let backingChord = backingChords.chords[callNum % backingChords.chords.count]
        if let lastChord = lastChord {
            for pitch in lastChord.pitches {
                sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
            }
        }

        for pitch in backingChord.pitches {
            sampler.play(noteNumber: MIDINoteNumber(pitch), velocity: 60, channel: 0)
        }
        lastChord = backingChord
        callNum += 1
        return false
    }
    
    func metronomeStop() {
        if let sampler = audioManager.backingMidiSampler {
            if let lastChord = lastChord {
                for pitch in lastChord.pitches {
                    sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
                }
            }
        }
    }
    
//    func getMidi(bar:Int, beat:Int) -> Int {
//        let scale = ScalesModel.shared.scale
//        let root = chordRoots[bar % 4]
//        var midi = 0
//        ///Make Alberti pattern
//        if useMajor(scale) {
//            switch beat {
//            case 0:
//                midi = root
//            case 1:
//                midi = root + 7
//            case 2:
//                //midi = bar % 4 == 1 ? root + 3 : root + 4
//                //midi = bar % 4 == 1 ? root + 3 : root + 4
//                midi = [1].contains(bar) ? root + 3 : root + 4
//            case 3:
//                midi = root + 7
//            default:
//                midi = root
//            }
//        }
//        else {
//            switch beat {
//            case 0:
//                midi = root
//            case 1:
//                midi = root + 7
//            case 2:
//                ///Raise the leading note for the dominant in bar #3
//                midi = [0,1,3].contains(bar) ? root + 3 : root + 4
//                //midi = [0,1,3].contains(bar % beatsInCycle) ? root + 4 : root + 4
//                //midi = root + 3
//            case 3:
//                midi = root + 7
//            default:
//                midi = root
//            }
//        }
//        return midi
//    }
    
//    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
//        let beatsInCycle = ScalesModel.shared.scale.timeSignature.top
//        let beat = callNum % beatsInCycle
//        var midi = 0
//        let bar = (callNum / beatsInCycle) % 4
//        midi = getMidi(bar: bar, beat: beat)
//
//        if let sampler = audioManager.backingMidiSampler {
//            if let lastMidi = lastMidi {
//                sampler.stop(noteNumber: MIDINoteNumber(lastMidi), channel: 0)
//            }
//            sampler.play(noteNumber: MIDINoteNumber(midi), velocity: 60, channel: 0)
//        }
//        lastMidi = midi
//        callNum += 1
//        return false
//    }
}
