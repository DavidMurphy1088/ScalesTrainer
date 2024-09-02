import Foundation
import AVFoundation
import Combine
import SwiftUI

class LeadScaleProcess {
    let scalesModel:ScalesModel
    var cancelled = false
    var nextExpectedScaleIndex:Int
    let badges = BadgeBank.shared
    var lastMidi:Int? = nil
    
    init(scalesModel:ScalesModel) {
        self.scalesModel = scalesModel
        nextExpectedScaleIndex = 0
    }
    
    func start() {
        badges.setTotalCorrect(0)
        badges.setTotalIncorrect(0)
        scalesModel.scale.resetMatchedData()
        let x = scalesModel.tapHandlers[0] as! RealTimeTapHandler
        x.notifyFunction = self.notify
        scalesModel.scale.resetMatchedData()
        lastMidi = nil
    }
    
    func notify(midi:Int, status:TapEventStatus) {
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
        let hand = scalesModel.scale.hand
        
        let nextExpected = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]

        if midi == nextExpected.midi {
            if nextExpected.matchedTime == nil {
                badges.setTotalCorrect(badges.totalCorrect + 1)
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
            scalesModel.setRunningProcess(.none)
        }

        if [.inScale, .outOfScale].contains(status) {
            let nextExpected = scale.scaleNoteState[hand][self.nextExpectedScaleIndex]
            //print("============ Notified", midi, "correct:", badges.totalCorrect, "wrong:", badges.totalIncorrect, "nextExpected:\(nextExpected.midi)")
        }
    }
}
