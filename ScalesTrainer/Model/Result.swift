import Foundation
import SwiftUI

class Result : Equatable {
    let id = UUID()
    let fromProcess:RunningProcess
    let scale:Scale
    let amplitudeFilter:Double
    var eventsID:UUID? = nil ///The events set the result was  built from
    var keysTapped:Int = 0
    
    let userMessage:String
    static func == (lhs: Result, rhs: Result) -> Bool {
        return lhs.id == rhs.id
    }
    
    var missedCountAsc = 0
    var missedCountDesc = 0
    var wrongCountAsc = 0
    var wrongCountDesc = 0
    var correctNotes = 0
    
    init(scale:Scale, fromProcess:RunningProcess, amplitudeFilter:Double, userMessage:String) {
        self.scale = scale
        //self.score = score
        self.fromProcess = fromProcess
        self.userMessage = userMessage
        self.amplitudeFilter = amplitudeFilter
    }
    
    func noErrors() -> Bool {
        return missedCountAsc == 0 && missedCountDesc == 0 && wrongCountAsc == 0 && wrongCountDesc == 0
    }
    
    func isBetter(compare:Result) -> Bool {
        if compare.totalErrors() < self.totalErrors() {
            return true
        }
        if compare.correctNotes < self.correctNotes {
            return false
        }
        return true
    }
    
    func totalErrors() -> Int {
        return missedCountAsc + missedCountDesc + wrongCountAsc + wrongCountDesc
    }
    
    func getInfo() -> String {
        var str = "Result:"
        str += " scale: \(scale.getMinMax())"
        str += " missed: \(missedCountAsc + missedCountDesc)"
        str += " correct:\(correctNotes)"
        return str
    }

    func buildResult(score:Score?) {
        self.missedCountAsc = 0
        self.missedCountDesc = 0
        self.wrongCountAsc = 0
        self.wrongCountDesc = 0
        self.correctNotes = 0
        let topIndex = scale.scaleNoteState.count/2
        for i in 0..<scale.scaleNoteState.count {
            let note = scale.scaleNoteState[i]
            if i <= topIndex {
                if note.matchedTime == nil {
                    self.missedCountAsc += 1
                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 0) {
                        timeSlice.setStatusTag(.missingError)
                    }
                }
                else {
                    self.correctNotes += 1
                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 0) {
                        timeSlice.setStatusTag(.correct)
                    }
                }
            }
            else {
                if note.matchedTime == nil {
                    self.missedCountDesc += 1
                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 1) {
                        timeSlice.setStatusTag(.missingError)
                    }
                }
                else {
                    self.correctNotes += 1
                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 1) {
                        timeSlice.setStatusTag(.correct)
                    }
                }
            }
        }
    }
    
    ///Build the result from the the keyboard taps.
    ///Apply to the score.
    func buildResultOld() {
        let keyboardModel = PianoKeyboardModel.shared
        guard let score = ScalesModel.shared.score else {
            return
        }
        //let score = ScalesModel.shared.createScore(scale: self.scale)
        //keyboardModel.debug11("BuildRes")
        ///Set result  status for keyboard keys, score notes.
        ///The mapping of keys to scale notes can be different ascending vs. descending. e.g. melodic minor
        for direction in [0,1] {
            keyboardModel.linkScaleFingersToKeyboardKeys(scale: self.scale, direction: direction)
            for i in 0..<keyboardModel.pianoKeyModel.count {
                let key = keyboardModel.pianoKeyModel[i]
                if key.scaleNoteState != nil {
                    ///The key is in the scale
                    if direction == 0 {
                        if key.keyWasPlayedState.tappedTimeAscending == nil {
                            self.missedCountAsc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                        else {
                            self.correctNotes += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.correct)
                            }
                        }
                    }
                    if direction == 1 {
                        if key.keyWasPlayedState.tappedTimeDescending == nil {
                            self.missedCountDesc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                        else {
                            self.correctNotes += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.correct)
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
                    }
                    if direction == 1 {
                        if key.keyWasPlayedState.tappedTimeDescending != nil {
                            wrongCountDesc += 1
                        }
                    }
                }
            }
        }
        if noErrors() {
            //let scale = ScalesModel.shared.scale
            let _ = scale.setNoteNormalizedValues()
            score.setNormalizedValues(scale: scale)
        }
        Logger.shared.log(self, "Built result. scaleStart:\(scale.scaleNoteState[0].midi) Total errors:\(self.totalErrors()) Ampl Filter:\(self.amplitudeFilter)")
    }
}

