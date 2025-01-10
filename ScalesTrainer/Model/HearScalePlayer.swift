import Foundation
import AudioKit
import Foundation
import AVFoundation
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    let process:RunningProcess
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeatsForScale = 0
    var waitBeatsForBacking = 0
    let audioManager = AudioManager.shared
    
    let scalesModel = ScalesModel.shared
    var nextNoteIndex = 0
    var beatCount = 0
    var leadInShown = false
    let scale = ScalesModel.shared.scale
    var backingChords:BackingChords? = nil
    let tickDuration:Double
    ///Backing
    var nextChordIndex = 0
    var backingChord:BackingChords.BackingChord? = nil
    
    init(hands:[Int], process:RunningProcess) {
        self.process = process
        self.tickDuration = Metronome.shared.getNoteValueDuration()
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
        if let combined = PianoKeyboardModel.sharedCombined {
            combined.hilightNotesOutsideScale = false
        }
        else {
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            PianoKeyboardModel.sharedLH.hilightNotesOutsideScale = false
        }
        
        self.backingChords = scale.getBackingChords()
    }
    
    private func playBacking() {
        guard let sampler = audioManager.getSamplerForBacking() else {
            return
        }
        guard let backingChords = backingChords else {
            return
        }
        
        if let lastChord = self.backingChord {
            for pitch in lastChord.pitches {
                sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
            }
        }

        self.backingChord = backingChords.chords[nextChordIndex]
        guard let backingChord = self.backingChord else {
            return
        }
        sampler.volume = 1.0 //0.9 if its running with another operation like play the scale
        for pitch in backingChord.pitches {
            sampler.play(noteNumber: MIDINoteNumber(pitch), velocity: 60, channel: 0)
        }
        
        //lastChord = backingChord
        if nextChordIndex >= backingChords.chords.count - 1 {
            nextChordIndex = 0
        }
        else {
            nextChordIndex += 1
        }
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) {
        if leadingIn {
            return
        }

        let samplerForKeyboard = audioManager.getSamplerForKeyboard()

        for hand in scale.hands {
            let note = scale.getScaleNoteState(handType: hand==0 ? .right : .left, index: nextNoteIndex)

            let keyboard = getKeyboard(hand: hand)
            let keyIndex = keyboard.getKeyIndexForMidi(midi: note.midi)
            
            if let keyIndex = keyIndex {
                
                if self.waitBeatsForScale == 0 {
                    let key=keyboard.pianoKeyModel[keyIndex]
                    ///Hilight the keyboard key and score note for the note.
                    key.setKeyPlaying()
                    //let velocity:UInt8 = key.keyboardModel == .sharedLH ? 48 : 64
                    let velocity:UInt8 = 64
                    if process == .playingAlongWithScale {
                        samplerForKeyboard?.play(noteNumber: UInt8(key.midi), velocity: velocity, channel: 0)
                        let wait = note.value >= 1 ? 0.7 : 0.3
                        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                            samplerForKeyboard?.stop(noteNumber: UInt8(key.midi), channel: 0)
                            //print("Executed after 0.5 seconds on the main queue.")
                        }
                    }
                    if let score = scalesModel.getScore() {
                        score.hilightStaffNote(segment: note.segments[0], midi: note.midi, handType: hand == 0 ? .right : .left)
                    }
                }
                
                if scale.hands.count == 1 || hand == 0 {
                    if self.waitBeatsForBacking == 0 {
                        if process == .backingOn {
                            self.playBacking()
                        }
                    }
                }

//                if false {
//                    ///stop note sounding to drop the sampler's reverb
//                    let secsPerCrotchet = 60.0 / Double(ScalesModel.shared.getTempo())
//                    let secsBetweenTicks = secsPerCrotchet / Double(scale.timeSignature.top == 3 ? 3 : 2)
//                    var secsToWait = secsBetweenTicks * 2.5
//                    secsToWait *= note.value
//                    let key=keyboard.pianoKeyModel[keyIndex]
//                    DispatchQueue.main.asyncAfter(deadline: .now() + secsToWait) {
//                        ///stop() should stop all notes but doies not appear to stop the sound
//                        //sampler?.stop()
//                        samplerForKeyboard?.stop(noteNumber: UInt8(key.midi), channel: 0)
//                    }
//                }
            }
        }

        ///Calculate any required note delay
        if waitBeatsForScale == 0 {
            let scaleNoteState = scale.getScaleNoteState(handType: .right, index: nextNoteIndex)
            let notesPerBeat = scalesModel.scale.timeSignature.top % 3 == 0 ? 3.0 : 2.0
            waitBeatsForScale = Int(scaleNoteState.value * notesPerBeat) - 1
            if nextNoteIndex < self.scalesModel.scale.getScaleNoteCount() - 1 {
                self.nextNoteIndex += 1
                let nextNote = scale.getScaleNoteState(handType: .right, index: nextNoteIndex)
                scalesModel.setSelectedScaleSegment(nextNote.segments[0])
            }
            else {
                if let score = scalesModel.getScore() {
                    waitBeatsForScale += scale.getRemainingBeatsInLastBar(timeSignature: score.timeSignature) * Int(notesPerBeat)
                }
                scalesModel.setSelectedScaleSegment(0)
                self.nextNoteIndex = 0
            }
        }
        else {
            waitBeatsForScale -= 1
        }
        
        if waitBeatsForBacking == 0 {
            if let backingChord = self.backingChord {
                waitBeatsForBacking = Int(backingChord.value/self.tickDuration) - 1
            }
        }
        else {
            waitBeatsForBacking -= 1
        }
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedScaleSegment(0)
    }
}
