import Foundation
import AudioKit
import Foundation
import AVFoundation
import Foundation

class HearScalePlayer : MetronomeTimerNotificationProtocol {
    let process:RunningProcess
    let endCallback:()->Void
    var noteToPlayIndex:[Int] = [0, 0]
    var lastNoteValue:Double? = nil
    var waitBeatsForScale = 0
    var waitBeatsForBacking = 0
    let audioManager = AudioManager.shared
    let metronome = Metronome.shared
    
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
    
    init(hands:[Int], process:RunningProcess, endCallback:@escaping ()->Void) {
        self.process = process
        self.tickDuration = Metronome.shared.getNoteValueDuration()
        self.endCallback = endCallback
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
    
    private func stopLastSampledSounds() {
        guard let sampler = audioManager.getSamplerForBacking() else {
            return
        }
        if let lastChord = self.backingChord {
            for pitch in lastChord.pitches {
                sampler.stop(noteNumber: MIDINoteNumber(pitch), channel: 0)
            }
        }
    }
    
    private func playBacking() {
        guard let sampler = audioManager.getSamplerForBacking() else {
            return
        }
        guard let backingChords = backingChords else {
            return
        }
        //return 
        self.stopLastSampledSounds()
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
    
    func metronomeTickNotification(timerTickerNumber: Int) {
        let samplerForKeyboard = audioManager.getSamplerForKeyboard()
        
        for hand in scale.hands {
            let noteState:ScaleNoteState? = scale.getScaleNoteState(handType: hand==0 ? .right : .left, index: nextNoteIndex)
            var backingPlayed = false
            guard let note = noteState else {
                return
            }

            let keyboard = getKeyboard(hand: hand)
            let keyboardKeyIndex = keyboard.getKeyIndexForMidi(midi: note.midi)
            
            if let keyboardKeyIndex = keyboardKeyIndex {
            
                ///Hilight the keyboard key, sound the note and highlight the score note.
                if self.waitBeatsForScale == 0 {
                    let key=keyboard.pianoKeyModel[keyboardKeyIndex]
                    key.setKeyPlaying()
                    //let velocity:UInt8 = key.keyboardModel == .sharedLH ? 48 : 64
                    let velocity:UInt8 = 64
                    if [.playingAlong, .recordingScale].contains(process) {
                        samplerForKeyboard?.play(noteNumber: UInt8(key.midi), velocity: velocity, channel: 0)
                        ///Stop the note soon to avoid the reverb, extended sounding effect of leaving it running
                        if let noteValue = key.scaleNoteState?.value {
                            let tempo = Double(metronome.currentTempo)
                            let wait = noteValue * (60.0 / tempo) * 1.0
                            ///Dont silence the last note since the same note will be repeated as the first note of the next play iteration (which then wont sound)
                            if nextNoteIndex < self.scale.getScaleNoteCount() - 1 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                                    samplerForKeyboard?.stop(noteNumber: UInt8(key.midi), channel: 0)
                                }
                            }
                        }
                    }
                    if [.backingOn].contains(process) {
                        if !backingPlayed {
                            if self.waitBeatsForBacking == 0 {
                                if process == .backingOn {
                                    self.playBacking()
                                    backingPlayed = true
                                }
                            }
                        }
                    }
                    if let score = scalesModel.getScore() {
                        score.hilightStaffNote(segment: note.segments[0], midi: note.midi, handType: hand == 0 ? .right : .left)
                    }
                }
            }
        }

//        print("        ============ HearScalePlayer 🧛 metronomeTickNotification, tick:\(timerTickerNumber) ,index:\(nextNoteIndex) ,process:\(self.process)")

        ///Select the next scale segment and advance the scale's note to play index. Stop the exercise if required.
        if waitBeatsForScale == 0 {
            let scaleNoteState = scale.getScaleNoteState(handType: .right, index: nextNoteIndex)
            if let scaleNoteState = scaleNoteState {
                let notesPerBeat = scalesModel.scale.timeSignature.top % 3 == 0 ? 3.0 : 2.0
                waitBeatsForScale = Int(scaleNoteState.value * notesPerBeat) - 1
                if nextNoteIndex < self.scalesModel.scale.getScaleNoteCount() - 1 {
                    self.nextNoteIndex += 1
                    if let nextNote = scale.getScaleNoteState(handType: .right, index: nextNoteIndex) {
                        scalesModel.setSelectedScaleSegment(nextNote.segments[0])
                    }
                }
                else {
                    if let score = scalesModel.getScore() {
                        waitBeatsForScale += scale.getRemainingBeatsInLastBar(timeSignature: score.timeSignature) * Int(notesPerBeat)
                    }
                    scalesModel.setSelectedScaleSegment(0)
                    self.nextNoteIndex = 0
                    if [.playingAlong, .backingOn].contains(self.process) {
                        self.endCallback()
                    }
                }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            ///Dont stop too early for a nice sound
            self.stopLastSampledSounds()
        }
    }
}
