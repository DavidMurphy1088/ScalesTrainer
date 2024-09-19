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
    let metronome:MetronomeModel
    
    init(scalesModel:ScalesModel, metronome:MetronomeModel) {
        self.scalesModel = scalesModel
        nextExpectedScaleIndex = 0
        self.metronome = metronome
    }
    
    func metronomeStart() {
        MetronomeModel.shared.makeSilent = false
    }
    
    func metronomeStop() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if Settings.shared.getLeadInBeats() > 0 {
            if timerTickerNumber < Settings.shared.getLeadInBeats() {
                MetronomeModel.shared.setLeadingIn(way: true)
                leadInShowing = true
                return false
            }
        }
        MetronomeModel.shared.makeSilent = true
        if leadInShowing {
            MetronomeModel.shared.setLeadingIn(way: false)
            leadInShowing = false
        }

        return false
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
        //DispatchQueue.main.async {
//        DispatchQueue.global(qos: .background).async {
//            if let sampler = AudioManager.shared.keyboardMidiSampler {
//                sleep(1)
//                sampler.play(noteNumber: UInt8(65), velocity: 65, channel: 0)
//                sleep(1)
//                sampler.play(noteNumber: UInt8(67), velocity: 67, channel: 0)
//                sleep(1)
//                sampler.play(noteNumber: UInt8(67), velocity: 69, channel: 0)
//
//            }
//        }
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
                //let key = 
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
            let nextNote = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
            scalesModel.setSelectedScaleSegment(nextNote.segment)
        }
        else {
            ///🙄a random harmonic may trigger a stop
            //scalesModel.setRunningProcess(.none)
            scalesModel.setSelectedScaleSegment(0)
        }
//        if let lastSegment = lastSegment {
//            if nextExpected.segment != lastSegment {
//                
//            }
//        }
//        lastSegment = nextExpected.segment
        notifyCount += 1
    }
    
    func playDemo() {
        DispatchQueue.global(qos: .background).async {
            let metronome = MetronomeModel.shared
            metronome.DontUse()
            let rh = false
            let keyboard = rh ? PianoKeyboardModel.sharedRH : PianoKeyboardModel.sharedLH
            //let midis =   [65, 67, 69, 70, 72, 74, 76, 77, 76, 74, 72, 70, 69, 67, 65] FMAj RH
            let midis =     [38, 40, 41, 43, 45, 46, 49, 50, 49, 46, 45, 43, 41, 40, 38]
            if let sampler = AudioManager.shared.keyboardMidiSampler {
                sleep(4)
                metronome.makeSilent = true
                MetronomeModel.shared.setLeadingIn(way: false)
                sleep(1)
                for midi in midis {
                    if let keyIndex = keyboard.getKeyIndexForMidi(midi: midi, segment: 0) {
                        let key=keyboard.pianoKeyModel[keyIndex]
                        key.setKeyPlaying(hilight: true)
                    }
                    sampler.play(noteNumber: UInt8(midi), velocity: 65, channel: 0)
                    self.notify(midi: midi, status: .inScale)
                    let tempo = 70
                    let sleep = 1000000 * 1.0 * (Double(60)/Double(tempo))
                    usleep(UInt32(sleep))
                }
                ScalesModel.shared.setRunningProcess(.none)
            }
        }
    }

}
