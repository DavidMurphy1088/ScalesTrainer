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
        let tapHandler = scalesModel.tapHandlers[0] as! RealTimeTapHandler
        tapHandler.notifyFunction = self.notify
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
}
