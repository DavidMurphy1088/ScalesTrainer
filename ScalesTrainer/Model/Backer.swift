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
    var chordRoots:[Int] = []
    var lastChord:BackingChords.BackingChord? = nil
    var backingChords:BackingChords? = nil
    var scale:Scale? = nil
    var remainingSoundValue:Double? = nil
    var nextChordIndex = 0
    
    func metronomeStart() {
        self.scale = ScalesModel.shared.scale
        if let scale = self.scale {
            self.backingChords = scale.getBackingChords()
        }
        remainingSoundValue = nil
        nextChordIndex = 0
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
        let tickDuration = MetronomeModel.shared.getNoteValueDuration()
        //print("==============", timerTickerNumber, nextChordIndex, self.remainingSoundValue)
        if self.remainingSoundValue == nil || self.remainingSoundValue == 0 {
            let backingChord = backingChords.chords[nextChordIndex]
            if let lastChord = lastChord {
                for pitch in lastChord.pitches {
                    sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
                }
            }
            sampler.volume = 0.9
            for pitch in backingChord.pitches {
                //print("    ===== ", pitch)
                sampler.play(noteNumber: MIDINoteNumber(pitch), velocity: 60, channel: 0)
            }
            self.remainingSoundValue = backingChord.value - tickDuration
            lastChord = backingChord
            if nextChordIndex >= backingChords.chords.count - 1 {
                nextChordIndex = 0
            }
            else {
                nextChordIndex += 1
            }
        }
        else {
            if self.remainingSoundValue != nil {
                self.remainingSoundValue! -= tickDuration
                self.remainingSoundValue = Double(String(format: "%.4f", self.remainingSoundValue!))!
            }
        }
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
