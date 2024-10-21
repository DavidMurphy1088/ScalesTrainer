import Foundation
import AudioKit
import Foundation
import AVFoundation
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeats = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    var nextNoteIndex = 0
    var beatCount = 0
    var leadInShown = false
    let scale = ScalesModel.shared.scale
    var backingWasOn = false
    var backingChords:BackingChords? = nil
    
    ///Backing
    var nextChordIndex = 0
    var lastChord:BackingChords.BackingChord? = nil
    var remainingSoundValue:Double? = nil
    
    init(hands:[Int]) {
    }
    
    func getKeyboard(hand:Int) -> PianoKeyboardModel {
        if let combined = PianoKeyboardModel.sharedCombined {
            return combined
        }
        else {
            return hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
        }
    }
    
    func metronomeStart() {
        beatCount = 0
        nextNoteIndex = 0
        backingWasOn = scalesModel.backingOn
        if let combined = PianoKeyboardModel.sharedCombined {
            combined.hilightNotesOutsideScale = false
        }
        else {
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            PianoKeyboardModel.sharedLH.hilightNotesOutsideScale = false
        }
        
        self.backingChords = scale.getBackingChords()
    }
    
    func playBacking() {
        guard let sampler = audioManager.backingMidiSampler else {
            return
        }
        guard let backingChords = backingChords else {
            return
        }
        let tickDuration = Metronome.shared.getNoteValueDuration()
        if self.remainingSoundValue == nil || self.remainingSoundValue == 0 {
            let backingChord = backingChords.chords[nextChordIndex]
            if let lastChord = lastChord {
                for pitch in lastChord.pitches {
                    sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
                }
            }
            sampler.volume = 1.0 //0.9 if its running with another operation like play the scale
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
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) {
        if leadingIn {
            return
        }
        if waitBeats > 0 {
            waitBeats -= 1
            return
        }
        let sampler = audioManager.keyboardMidiSampler
        for hand in scale.hands {
            let note = scale.scaleNoteState[hand][nextNoteIndex]
            let keyboard = getKeyboard(hand: hand)
            let keyIndex = keyboard.getKeyIndexForMidi(midi: note.midi, segment:note.segments[0])
            if let keyIndex = keyIndex {
                let key=keyboard.pianoKeyModel[keyIndex]
                key.setKeyPlaying(hilight: true)
                //let velocity:UInt8 = key.keyboardModel == .sharedLH ? 48 : 64
                let velocity:UInt8 = 64
                //if true {
                    self.playBacking()
                //}
                //else {
                    //sampler?.play(noteNumber: UInt8(key.midi), velocity: velocity, channel: 0)
                //}
                if false {
                    ///stop note sounding to drop the sampler's reverb
                    let secsPerCrotchet = 60.0 / Double(ScalesModel.shared.getTempo())
                    let secsBetweenTicks = secsPerCrotchet / Double(scale.timeSignature.top == 3 ? 3 : 2)
                    var secsToWait = secsBetweenTicks * 2.5
                    secsToWait *= note.value
                    DispatchQueue.main.asyncAfter(deadline: .now() + secsToWait) {
                        ///stop() should stop all notes but doies not appear to stop the sound
                        //sampler?.stop()
                        sampler?.stop(noteNumber: UInt8(key.midi), channel: 0)
                    }
                }
            }
        }
        let scaleNoteState = scale.scaleNoteState[0][nextNoteIndex]
        let notesPerBeat = scalesModel.scale.timeSignature.top % 3 == 0 ? 3.0 : 2.0
        waitBeats = Int(scaleNoteState.value * notesPerBeat) - 1

        if nextNoteIndex < self.scalesModel.scale.scaleNoteState[0].count - 1 {
            self.nextNoteIndex += 1
            let nextNote = scale.scaleNoteState[0][nextNoteIndex]
            scalesModel.setSelectedScaleSegment(nextNote.segments[0])
        }
        else {
            scalesModel.setSelectedScaleSegment(0)
            self.nextNoteIndex = 0
            self.remainingSoundValue = nil
        }
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedScaleSegment(0)
    }
}
