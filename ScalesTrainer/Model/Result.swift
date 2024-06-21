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
    var correctNotes = 0
    
    init(runningProcess:RunningProcess, userMessage:String) {
        self.userMessage = userMessage
        self.runningProcess = runningProcess
    }
    
    func noErrors() -> Bool {
        return missedCountAsc == 0 && missedCountDesc == 0 && wrongCountAsc == 0 && wrongCountDesc == 0
    }
    
    ///Build the result for the the keyboard and the score
    func buildResult() {
        let keyboardModel = PianoKeyboardModel.shared
        guard let score = ScalesModel.shared.score else {
            return
        }
        
        ///Set result  status for keyboard keys, score notes
        ///the mapping of keys to scale notes can be different ascending vs. descending. e.g. melodic minor

        for direction in [0,1] {
            keyboardModel.linkScaleFingersToKeyboardKeys(direction: direction)
            for i in 0..<keyboardModel.pianoKeyModel.count {
                let key = keyboardModel.pianoKeyModel[i]
                if key.scaleNoteState != nil {
                    if direction == 0 {
                        if key.keyWasPlayedState.tappedTimeAscending == nil {
                            missedCountAsc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                        else {
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.correct)
                                self.correctNotes += 1
                            }
                        }
                    }
                    if direction == 1 {
                        if key.keyWasPlayedState.tappedTimeDescending == nil {
                            missedCountDesc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                        else {
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.correct)
                                self.correctNotes += 1
                            }
                        }
                    }
                }
                ///The key is not in the scale
                else {
                    if direction == 0 {
                        if key.keyWasPlayedState.tappedTimeAscending != nil {
                            wrongCountAsc += 1
                        }
//                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                            ///Not in scale => The note is not in the score
//                            //timeSlice.setStatusTag(.pitchError)
//                        }
                    }
                    if direction == 1 {
                        if key.keyWasPlayedState.tappedTimeDescending != nil {
                            wrongCountDesc += 1
                        }
//                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                            ///Not in scale => The note is not in the score
//                            //timeSlice.setStatusTag(.pitchError)
//                        }
                    }
                }
            }
        }
        if noErrors() {
            let scale = ScalesModel.shared.scale
            let _ = scale.setNoteNormalizedValues()
            //score.calculateTapToValueRatios()
            score.setNormalizedValues(scale: scale)
            score.debugScore111("=== Result", withBeam: false, toleranceLevel: 0)
        }
        
    }
}

