import Foundation
import AVFoundation
import Combine
import SwiftUI

class LeadScaleProcess : MetronomeTimerNotificationProtocol {
    let scalesModel:ScalesModel
    var cancelled = false
    var nextExpectedScaleIndex:Int
    let badges = BadgeBank.shared
    var lastMidi:Int? = nil
    var notifyCount = 0
    var leadInShowing = false
    let metronome:Metronome
    
    init(scalesModel:ScalesModel, metronome:Metronome) {
        self.scalesModel = scalesModel
        nextExpectedScaleIndex = 0
        self.metronome = metronome
        //scalesModel.scale.debug11("LeadScaleProcess")
        //scalesModel.scores[0]?.debug1("LeadScaleProcess", withBeam: false, toleranceLevel: 0)
    }
    
    func metronomeStart() {
        //MetronomeModel.shared.makeSilent = false
    }
    
    func metronomeStop() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool)  {
//        if Settings.shared.getLeadInBeats() > 0 {
//            if timerTickerNumber < Settings.shared.getLeadInBeats() {
//                MetronomeModel.shared.setLeadingIn(way: true)
//                leadInShowing = true
//                return false
//            }
//        }
//        MetronomeModel.shared.makeSilent = true
//        if leadInShowing {
//            MetronomeModel.shared.setLeadingIn(way: false)
//            leadInShowing = false
//        }

    }
    
    func start() {
        badges.clearMatches()
        scalesModel.scale.resetMatchedData()
        if scalesModel.tapHandlers.count > 0 {
            let tapHandler = scalesModel.tapHandlers[0] as! RealTimeTapHandler
            tapHandler.notifyFunction = self.notify
        }
        
        scalesModel.scale.resetMatchedData()
        lastMidi = nil
        notifyCount = 0
    }
    
    func notify(midi:Int, status:TapEventStatus) {
        if leadInShowing {
            return
        }
        if ![.inScale, .outOfScale].contains(status) {
            return
        }
        if let lastCorrectMidi = lastMidi {
            if midi == lastCorrectMidi {
                return
            }
        }
        self.lastMidi = midi
        
        let scale = scalesModel.scale
        let hand = scale.hands[0]
        
        let nextExpected = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
        scalesModel.setSelectedScaleSegment(nextExpected.segments[0])

        if midi == nextExpected.midi {
            if nextExpected.matchedTime == nil {
                badges.setTotalCorrect(badges.totalCorrect + 1)
                badges.addMatch(midi)
                nextExpected.matchedTime = Date()
            }
        }
        else {
            if status == .outOfScale {
                nextExpected.matchedTime = Date()
                badges.setTotalIncorrect(badges.totalIncorrect + 1)
            }
            else {
                ///Look for a matching scale note that has not been played yet
                for i in 0..<scale.scaleNoteState[hand].count {
                    let unplayed = scale.scaleNoteState[hand][i]
                    if unplayed.midi == midi && unplayed.matchedTime == nil {
                        badges.setTotalCorrect(badges.totalCorrect + 1)
                        badges.addMatch(midi)
                        unplayed.matchedTime = Date()
                        nextExpectedScaleIndex = i
                        break
                    }
                }
            }
        }
        
        if self.nextExpectedScaleIndex < scale.scaleNoteState[hand].count - 1 {
            nextExpectedScaleIndex += 1
            ///Set next segment here so the tap handler hilights the correct stave note
            let nextExpected = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
            scalesModel.setSelectedScaleSegment(nextExpected.segments[0])
        }
        else {
            ///🙄a random harmonic may trigger a stop
            //scalesModel.setRunningProcess(.none)
            ///Leave the last segment fingering showing
            scalesModel.setSelectedScaleSegment(scalesModel.scale.getHighestSegment())
        }
        notifyCount += 1
    }
    
    func playDemo() {
        self.start()
       
        DispatchQueue.global(qos: .background).async {
            //BadgeBank.shared.clearMatches()
            sleep(1)
            self.badges.clearMatches()
            self.scalesModel.scale.resetMatchedData()
            var lastSegment:Int? = nil
            //metronome.DontUse_JustForDemo()
            let hand = 0
            let keyboard = hand == 0 ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
            let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] //FMAj RH
            //let midis =   [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38] Dmin Harm
            //let midis =     [67, 71, 74, 71, 74, 79, 74, 79, 83, 79, 83, 79, 74, 79, 74, 71, 74, 71, 67, 74] //G maj broken
            
            let notes = self.scalesModel.scale.getStatesInScale(handIndex: hand)
            PianoKeyboardModel.sharedRH.hilightNotesOutsideScale = false
            
            if let sampler = AudioManager.shared.keyboardMidiSampler {
//                let leadin:UInt32 = ScalesModel.shared.scale.scaleType == .brokenChordMajor ? 3 : 4
//                sleep(leadin)
//                //metronome.makeSilent = true
//                MetronomeModel.shared.setLeadingIn(way: false)
//                sleep(1)
                var ctr = 0
                for midi in midis {
                    
                    if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi, segment: 0) {
                        let key=keyboard.pianoKeyModel[keyIndex]
                        let segment = notes[ctr].segments[0]
                        if let lastSegment = lastSegment {
                            self.scalesModel.setSelectedScaleSegment(segment)
                        }
                        lastSegment = segment
                        key.setKeyPlaying(hilight: true)
                    }

                    sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)

                    self.notify(midi: midi, status: .inScale)
                    
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
