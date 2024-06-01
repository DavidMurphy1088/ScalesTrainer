import Foundation
import SwiftUI

class Result : Equatable {
    let id = UUID()
    let runningProcess:RunningProcess
    
    let userMessage:String
    static func == (lhs: Result, rhs: Result) -> Bool {
        return lhs.id == rhs.id
    }
    
    var missedCountAsc = 0
    var missedCountDesc = 0
    var wrongCountAsc = 0
    var wrongCountDesc = 0
    var recordedTempo:Int = 0
    
    init(runningProcess:RunningProcess, userMessage:String) {
        self.userMessage = userMessage
        self.runningProcess = runningProcess
    }
    
    func buildResult() {
        let keyboardModel = PianoKeyboardModel.shared
        PianoKeyboardModel.shared.debug("build result")
        guard let score = ScalesModel.shared.score else {
            return
        }
        
        ///the mapping of keys to scale notes can be different ascending vs. descending. e.g. melodic minor
        for direction in [0,1] {
            keyboardModel.mapScaleFingersToKeyboard(direction: direction)
            for i in 0..<keyboardModel.pianoKeyModel.count {
                let key = keyboardModel.pianoKeyModel[i]
                if key.scaleNoteState != nil {
                    if direction == 0 {
                        if key.keyClickedState.tappedTimeAscending == nil {
                            missedCountAsc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                    }
                    if direction == 1 {
                        if key.keyClickedState.tappedTimeDescending == nil {
                            missedCountDesc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                    }
                }
                else {
                    if direction == 0 {
                        if key.keyClickedState.tappedTimeAscending != nil {
                            wrongCountAsc += 1
                        }
                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                            timeSlice.setStatusTag(.pitchError)
                        }
                    }
                    if direction == 1 {
                        if key.keyClickedState.tappedTimeDescending != nil {
                            wrongCountDesc += 1
                        }
                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                            timeSlice.setStatusTag(.pitchError)
                        }
                    }
                }
            }
        }
    }
}

