import Foundation
import AVFoundation
import Combine
import SwiftUI

class LeadScaleProcess : ExerciseHandler, MetronomeTimerNotificationProtocol {
    
    class RequiredNote {
        let midi:Int
        let hand:HandType
        var matched = false
        init(midi:Int, hand:HandType) {
            self.midi = midi
            self.hand = hand
        }
    }
    var requiredNotes:[RequiredNote] = []
    
    override init(scalesModel:ScalesModel, practiceChart:PracticeChart?, practiceChartCell:PracticeChartCell?, metronome:Metronome) {
        super.init(scalesModel: scalesModel, practiceChart: practiceChart, practiceChartCell: practiceChartCell, metronome: metronome)
    }
    
    func metronomeStart() {
    }
    
    func metronomeStop() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
    }
    
    override func start(soundHandler:SoundEventHandlerProtocol) {
        super.start(soundHandler: soundHandler)
    }
    
    override func notifyPlayedKey(midi: Int, hand:HandType?) {
        if self.requiredNotes.count == 0 {
            for h in scale.hands {
                let hand = h==0 ? HandType.right : .left
                if let expectedOffset = self.nextExpectedNoteForHandIndex[hand] {
                    let expectedMidi = scale.getScaleNoteState(handType: hand, index: expectedOffset).midi
                    self.requiredNotes.append(RequiredNote(midi: expectedMidi, hand: hand))
                }
            }
        }
        var matchedCount = 0
        for requiredNote in requiredNotes {
            if requiredNote.midi == midi && requiredNote.hand == hand {
                requiredNote.matched = true
            }
            if requiredNote.matched {
                matchedCount += 1
            }
        }
        if matchedCount == scale.hands.count {
            badgeBank.setTotalCorrect(badgeBank.totalCorrect + 1)
            for requiredNote in requiredNotes {
                self.nextExpectedNoteForHandIndex[requiredNote.hand]! += 1
            }
            self.requiredNotes = []
            let index = nextExpectedNoteForHandIndex[hand!]!
            if index < scale.getScaleNoteCount() {
                let scaleNote = scale.getScaleNoteState(handType: hand!, index: index)
                scalesModel.setSelectedScaleSegment(scaleNote.segments[0])
            }
            awardChartBadge()
            _ = testForEndOfExercise()
        }
    }
    
    func playDemo() {
        //self.start()
       
        DispatchQueue.global(qos: .background).async {
            sleep(1)
            //self.badgeBank.clearMatches()
            self.scalesModel.scale.resetMatchedData()
            var lastSegment:Int? = nil
            let hand = 0
            let keyboard = hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
            let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] //FMAj RH
            //let midis =   [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38] Dmin Harm
            //let midis =     [67, 71, 74, 71, 74, 79, 74, 79, 83, 79, 83, 79, 74, 79, 74, 71, 74, 71, 67, 74] //G maj broken
            
            let notes = self.scalesModel.scale.getStatesInScale(handIndex: hand)
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            
            if let sampler = AudioManager.shared.getSamplerForKeyboard() {
//                let leadin:UInt32 = ScalesModel.shared.scale.scaleType == .brokenChordMajor ? 3 : 4
//                sleep(leadin)
//                //metronome.makeSilent = true
//                MetronomeModel.shared.setLeadingIn(way: false)
//                sleep(1)
                var ctr = 0
                for midi in midis {
                    
                    if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi) {
                        let key=keyboard.pianoKeyModel[keyIndex]
                        let segment = notes[ctr].segments[0]
                        if let lastSegment = lastSegment {
                            self.scalesModel.setSelectedScaleSegment(segment)
                        }
                        lastSegment = segment
                        key.setKeyPlaying()
                    }

                    sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)

                    self.notifiedOfSound(midi: midi)
                    
                    //var tempo:Double = [9, 19].contains(ctr) ? 70/3 : 70 //Broken Chords
                    let tempo:Double =  70 //50 = Broken
                    //let notesPerBeatBeat = [9, 19].contains(ctr) ? 1.0 : 3.0 //Broken
                    let notesPerBeatBeat = [14].contains(ctr) ? 0.75 : 2.0
                    var sleep = (1000000 * 1.0 * (Double(60)/tempo)) / notesPerBeatBeat
                    sleep = sleep * 0.95
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0/notesPerBeatBeat) {
//                        //sampler.stop(noteNumber: UInt8(midi), channel: 0)
//                    }
                    usleep(UInt32(sleep))
                    ctr += 1
                }
                ScalesModel.shared.setRunningProcess(.none)
            }
        }
    }

}

