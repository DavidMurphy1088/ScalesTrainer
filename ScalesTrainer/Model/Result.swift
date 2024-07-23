import Foundation
import SwiftUI

class Result : Equatable {
    let id = UUID()
    let fromProcess:RunningProcess
    let scale:Scale
    let amplitudeFilter:Double
    var eventsID:UUID? = nil ///The events set the result was  built from
    let score:Score?
    
    let userMessage:String
    static func == (lhs: Result, rhs: Result) -> Bool {
        return lhs.id == rhs.id
    }
    
    var missedFromScaleCountAsc = 0
    var missedFromScaleCountDesc = 0
    var playedAndWrongCountAsc = 0
    var playedAndWrongCountDesc = 0
    var correctNotes = 0
    let keyboard:PianoKeyboardModel
    
    init(scale:Scale, keyboard:PianoKeyboardModel, fromProcess:RunningProcess, amplitudeFilter:Double, userMessage:String, score:Score?) {
        self.scale = scale
        self.score = score
        self.fromProcess = fromProcess
        self.userMessage = userMessage
        self.amplitudeFilter = amplitudeFilter
        self.keyboard = keyboard
    }
    
    func noErrors() -> Bool {
        return missedFromScaleCountAsc == 0 && missedFromScaleCountDesc == 0 && playedAndWrongCountAsc == 0 && playedAndWrongCountDesc == 0
    }
    
    func isBetter(compare:Result) -> Bool {
        if compare.getTotalErrors() < self.getTotalErrors() {
            return true
        }
        if compare.correctNotes < self.correctNotes {
            return false
        }
        return true
    }
    
    func getTotalErrors() -> Int {
        return missedFromScaleCountAsc + missedFromScaleCountDesc + playedAndWrongCountAsc + playedAndWrongCountDesc
    }
    
    func getInfo() -> String {
        var str = "Result:"
        str += " scale: \(scale.getMinMax())"
        str += " missed: \(missedFromScaleCountAsc + missedFromScaleCountDesc)"
        str += " correct:\(correctNotes)"
        return str
    }
    
    func getResultsString() -> String {
        var str = "Result Errors:\(self.getTotalErrors()) WrongKeys:[\(self.playedAndWrongCountAsc),\(self.playedAndWrongCountDesc)]"
        str += ", MissingInScale:[\(self.missedFromScaleCountAsc),\(missedFromScaleCountDesc)]"
        str += ", Correct:[\(self.correctNotes)]"
        return str
    }
    
    ///Build the result from the timestamps on the keyboard. These track ascending and descending times when each key was played.
    ///Set the assocated notes in the scale with their played time
    func buildResult(score:Score?, offset:Int) {
        self.missedFromScaleCountAsc = 0
        self.missedFromScaleCountDesc = 0
        self.playedAndWrongCountAsc = 0
        self.playedAndWrongCountDesc = 0
        self.correctNotes = 0
        let topIndex = scale.scaleNoteState.count/2
        
//        if true {
//            print("======== ResultCalc...")
//            for key in self.keyboard.pianoKeyModel {
//                print("   ---->", key.midi,
//                      "playedAsc:", key.keyWasPlayedState.tappedTimeAscending ?? "_" ,
//                      "playedDesc:", key.keyWasPlayedState.tappedTimeDescending ?? "_" ,
//                      "\tscaleNote", key.scaleNoteState?.midi ?? "  ", key.scaleNoteState?.matchedTime ?? "None")
//            }
//        }
        scale.resetMatchedData()
        let scaleMinMax = scale.getMinMax()
        
        ///For each key played check its its midi is in the scale. If not, its a wrongly played key
        for direction in [0,1] {
            for key in self.keyboard.pianoKeyModel {
                if let matchedTime = direction == 0 ? key.keyWasPlayedState.tappedTimeAscending : key.keyWasPlayedState.tappedTimeDescending {
                    if let scaleNote = scale.getStateForMidi(midi: key.midi, direction: direction) {
                        self.correctNotes += 1
                        if direction == 0 {
                            scaleNote.matchedTime = key.keyWasPlayedState.tappedTimeAscending
                        }
                        else {
                            scaleNote.matchedTime = key.keyWasPlayedState.tappedTimeDescending
                        }
                        if let score = score {
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, occurence: direction == 0 ? 0 : 1) {
                                timeSlice.setStatusTag(.correct)
                            }
                        }
                    }
                    else {
                        if direction == 0 {
                            self.playedAndWrongCountAsc += 1
                        }
                        else {
                            self.playedAndWrongCountDesc += 1
                        }
                    }
                }
            }
        }
        
        ///Look for notes in scale that were not played
        let topNoteMidi = scale.getMinMax().1
        var direction = 0
        for scaleNote in scale.scaleNoteState {
            if scaleNote.matchedTime == nil {
                if direction == 0 {
                    self.missedFromScaleCountAsc += 1
                } else {
                    self.missedFromScaleCountDesc += 1
                }
                if let score = score {
                    if let timeSlice = score.getTimeSliceForMidi(midi: scaleNote.midi, occurence: direction == 0 ? 0 : 1) {
                        timeSlice.setStatusTag(.missingError)
                    }
                }
            }
            if scaleNote.midi == topNoteMidi {
                direction = 1
            }
        }
        
        if noErrors() {
            let _ = scale.setNoteNormalizedValues()
            if let score = score {
                score.setNormalizedValues(scale: scale)
            }
        }
        //Logger.shared.log(self, "Built result. scaleStart:\(scale.scaleNoteState[0].midi) Errors:\(self.getErrorString()) Ampl Filter:\(self.amplitudeFilter)")
    }
    
//    func buildResultOld(score:Score?) {
//        self.missedFromScaleCountAsc = 0
//        self.missedFromScaleCountDesc = 0
//        self.playedAndWrongCountAsc = 0
//        self.playedAndWrongCountDesc = 0
//        self.correctNotes = 0
//        let topIndex = scale.scaleNoteState.count/2
//        
//        for i in 0..<scale.scaleNoteState.count {
//            let note = scale.scaleNoteState[i]
//            if i <= topIndex {
//                if note.matchedTime == nil {
//                    self.missedFromScaleCountAsc += 1
//                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 0) {
//                        timeSlice.setStatusTag(.missingError)
//                    }
//                }
//                else {
//                    self.correctNotes += 1
//                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 0) {
//                        timeSlice.setStatusTag(.correct)
//                    }
//                }
//            }
//            else {
//                if note.matchedTime == nil {
//                    self.missedFromScaleCountDesc += 1
//                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 1) {
//                        timeSlice.setStatusTag(.missingError)
//                    }
//                }
//                else {
//                    self.correctNotes += 1
//                    if let timeSlice = score?.getTimeSliceForMidi(midi: note.midi, count: 1) {
//                        timeSlice.setStatusTag(.correct)
//                    }
//                }
//            }
//        }
//        if noErrors() {
//            //let scale = ScalesModel.shared.scale
//            let _ = scale.setNoteNormalizedValues()
//            if let score = score {
//                score.setNormalizedValues(scale: scale)
//            }
//        }
//    }
//    
//    ///Build the result from the the keyboard taps.
//    ///Apply to the score.
//    func buildResultOld1() {
//        let keyboardModel = PianoKeyboardModel.shared
//        guard let score = ScalesModel.shared.score else {
//            return
//        }
//        //let score = ScalesModel.shared.createScore(scale: self.scale)
//        //keyboardModel.debug11("BuildRes")
//        ///Set result  status for keyboard keys, score notes.
//        ///The mapping of keys to scale notes can be different ascending vs. descending. e.g. melodic minor
//        for direction in [0,1] {
//            keyboardModel.linkScaleFingersToKeyboardKeys(scale: self.scale, direction: direction)
//            for i in 0..<keyboardModel.pianoKeyModel.count {
//                let key = keyboardModel.pianoKeyModel[i]
//                if key.scaleNoteState != nil {
//                    ///The key is in the scale
//                    if direction == 0 {
//                        if key.keyWasPlayedState.tappedTimeAscending == nil {
//                            self.missedFromScaleCountAsc += 1
//                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                                timeSlice.setStatusTag(.missingError)
//                            }
//                        }
//                        else {
//                            self.correctNotes += 1
//                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                                timeSlice.setStatusTag(.correct)
//                            }
//                        }
//                    }
//                    if direction == 1 {
//                        if key.keyWasPlayedState.tappedTimeDescending == nil {
//                            self.missedFromScaleCountDesc += 1
//                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                                timeSlice.setStatusTag(.missingError)
//                            }
//                        }
//                        else {
//                            self.correctNotes += 1
//                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
//                                timeSlice.setStatusTag(.correct)
//                            }
//                        }
//                    }
//                }
//                ///The key is not in the scale
//                else {
//                    if direction == 0 {
//                        if key.keyWasPlayedState.tappedTimeAscending != nil {
//                            playedAndWrongCountAsc += 1
//                        }
//                    }
//                    if direction == 1 {
//                        if key.keyWasPlayedState.tappedTimeDescending != nil {
//                            playedAndWrongCountDesc += 1
//                        }
//                    }
//                }
//            }
//        }
//        if noErrors() {
//            //let scale = ScalesModel.shared.scale
//            let _ = scale.setNoteNormalizedValues()
//            score.setNormalizedValues(scale: scale)
//        }
//        Logger.shared.log(self, "Built result. scaleStart:\(scale.scaleNoteState[0].midi) Errors:\(self.getErrorString()) Ampl Filter:\(self.amplitudeFilter)")
//    }
}

