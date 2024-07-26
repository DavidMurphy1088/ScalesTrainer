import Foundation
import SwiftUI

class Result : Equatable {
    let id = UUID()
    let fromProcess:RunningProcess
    let scale:Scale
    //let offset:Int
    let amplitudeFilter:Double
    let compressingFactor:Int
    
    var eventsID:UUID? = nil ///The events set the result was  built from
    
    let userMessage:String
    static func == (lhs: Result, rhs: Result) -> Bool {
        return lhs.id == rhs.id
    }
    var missedFromScaleCountAsc = 0
    var missedFromScaleCountDesc = 0
    var playedAndWrongCountAsc = 0
    var playedAndWrongCountDesc = 0
    var correctNotes = 0
    
   // let score:Score
    let keyboard:PianoKeyboardModel
    
    init(scale:Scale, keyboard:PianoKeyboardModel, fromProcess:RunningProcess, amplitudeFilter:Double, compressingFactor:Int, userMessage:String) {
        self.scale = scale
        self.fromProcess = fromProcess
        self.userMessage = userMessage
        self.amplitudeFilter = amplitudeFilter
        self.keyboard = keyboard
        //self.score = score
        self.compressingFactor = compressingFactor
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
        var str = "Result Errors "
        str += ", MissingInScale:[\(self.missedFromScaleCountAsc),\(missedFromScaleCountDesc)]"
        str += ", Correct:[\(self.correctNotes)]"
        str += ", WrongKeys:[Asc:\(self.playedAndWrongCountAsc),Dsc:\(self.playedAndWrongCountDesc)],  **TotalErrors:\(self.getTotalErrors()) "
        return str
    }
    
    ///Build the result from the timestamps on the keyboard. These track ascending and descending times when each key was played.
    ///Set the assocated notes in the scale with their played time
    func buildResult(offset:Int) {
        self.missedFromScaleCountAsc = 0
        self.missedFromScaleCountDesc = 0
        self.playedAndWrongCountAsc = 0
        self.playedAndWrongCountDesc = 0
        self.correctNotes = 0
        
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
//                        if let score = score {
//                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, occurence: direction == 0 ? 0 : 1) {
//                                timeSlice.setStatusTag(.correct)
//                            }
//                        }
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
//                if let score = score {
//                    if let timeSlice = score.getTimeSliceForMidi(midi: scaleNote.midi, occurence: direction == 0 ? 0 : 1) {
//                        timeSlice.setStatusTag(.missingError)
//                    }
//                }
            }
            if scaleNote.midi == topNoteMidi {
                direction = 1
            }
        }
        
        if noErrors() {
            let _ = scale.setNoteNormalizedValues()
//            if let score = score {
//                score.setNormalizedValues(scale: scale)
//            }
        }
        //Logger.shared.log(self, "Built result. scaleStart:\(scale.scaleNoteState[0].midi) Errors:\(self.getErrorString()) Ampl Filter:\(self.amplitudeFilter)")
    }
    
}

