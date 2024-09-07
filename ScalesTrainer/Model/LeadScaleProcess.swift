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
    var beatCount = 0
    var leadInShowing = false
    let metronome:MetronomeModel
    
    init(scalesModel:ScalesModel, metronome:MetronomeModel) {
        self.scalesModel = scalesModel
        nextExpectedScaleIndex = 0
        self.metronome = metronome
    }
    
    func metronomeStart() {
    }
    
    func metronomeStop() {
    }
    
    func metronomeTickNotification(timerTickerNumber: Int, leadingIn:Bool) -> Bool {
        if Settings.shared.scaleLeadInBarCount > 0 {
            if beatCount / 4 < Settings.shared.scaleLeadInBarCount {
                MetronomeModel.shared.setLeadingIn(way: true)
                leadInShowing = true
                beatCount += 1
                return false
            }
        }
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
        let hand = scalesModel.scale.hand == 2 ? 0 : scalesModel.scale.hand
        
        let nextExpected = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
        //print("\n=====================IN ", "Cnt", notifyCount, status, "Next", self.nextExpectedScaleIndex, "MIDI", nextExpected.midi, "total", scale.scaleNoteState[hand].count)
        //print("\n=====================IN ", "MIDI", midi, "Cnt", notifyCount, status, "Next", nextExpected.midi, "Correct", badges.totalCorrect)


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
        }
        else {
            //print("========>>>>>>>>>>>>>>>>", "Cnt", notifyCount, self.nextExpectedScaleIndex, scale.scaleNoteState[hand].count)
            //if self.nextExpectedScaleIndex >= scale.scaleNoteState[hand].count  {
                scalesModel.setRunningProcess(.none)
            //}
        }

        //print("=====================OUT", "Cnt", notifyCount, status, "Next", self.nextExpectedScaleIndex, "total", scale.scaleNoteState[hand].count)
        notifyCount += 1
    }
}
