import Foundation

class MatchType {
    var status:NoteCorrectStatus
    var msg:String?
    
    init(_ status:NoteCorrectStatus, _ message:String?) {
        self.status = status
        self.msg = message
    }
    
    func dispStatus() -> String {
        switch status {
        case .correct:
            return "Correct"
        case .wrongNote:
            return "****** ****** Wrong ****** ******"
        default:
            return "    Ignored"
        }
    }
}

///A note that was played that was not in the scale
public class UnMatchedType: Hashable {
    var notePlayedSequence:Int
    var midi:Int
    
    init(notePlayedSequence:Int, midi:Int) {
        self.notePlayedSequence = notePlayedSequence
        self.midi = midi
    }
    public static func == (lhs: UnMatchedType, rhs: UnMatchedType) -> Bool {
        return lhs.notePlayedSequence == rhs.notePlayedSequence
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.notePlayedSequence)
    }
}

class ScaleMatcher : ObservableObject {
    let scale:Scale
    //var lastMatchTime:Date?
    //var nextMatchIndex = 0
    //var matches:[NoteMatch] = []
    var topMidi:Int = 0
    var lastGoodMidi:Int?
    //var wrongCount = 0
    //var correctCount = 0
    //var firstNoteMatched = false
    //var mismatchCount = 0
    var mismatchesAllowed = 0
    var notePlayedSequence:Int = 0
    
    var unMatchedToScale:[UnMatchedType] = []
    var ascending = true

    init(scale:Scale, mismatchesAllowed:Int) {
        self.scale = scale
        for state in self.scale.scaleNoteStates {
            state.matchedTime = nil
            if state.midi > topMidi {
                topMidi = state.midi
            }
        }
        self.mismatchesAllowed = mismatchesAllowed
    }
    
    func initialise() {
        //firstNoteMatched = false
        lastGoodMidi = nil
        //mismatchCount = 0
        //wrongCount = 0
        //nextMatchIndex = 0
        ascending = true
        notePlayedSequence = 0
    }
    
    func midiToNoteNum(midi: Int) -> Int {
        let nameIndex = (midi + 48 - scale.scaleNoteStates[0].midi) % 12
        return nameIndex
    }
    
    func makeMidiOctavesOld(midi: Int) -> [Int] {
        let res = [midi-36, midi-24, midi-12, midi, midi+12, midi+24]
        return res
    }
    
    func makeMidiOctaves(midi: Int) -> [Int] {
        let res = [midi, midi+12, midi-12]
        return res
    }

    func match(timestamp:Date, midis:[Int]) -> MatchType {
        let inputMidi = midis[0]
        var matchedInScale = false
        var match = MatchType(.dataIgnored, nil)

        for midiOctave in makeMidiOctaves(midi:inputMidi) {
            if let indexInScale = scale.getMidiIndex(midi: midiOctave, direction: ascending ? 0 : 1) {
                print("=====", notePlayedSequence, inputMidi, indexInScale)
//                if !ascending && inputMidi == 60 {
//                    print("=====", notePlayedSequence, inputMidi, indexInScale)
//
//                }
                matchedInScale = true
                let state = scale.scaleNoteStates[indexInScale]
                if state.matchedTime == nil {
                    match.status = .correct
                    state.matchedTime = Date()
                    if let lastMidi = lastGoodMidi {
                        if midiOctave < lastMidi || inputMidi == topMidi {
                            ascending = false
                            print("========== Descending")
                        }
                    }
                    
                    lastGoodMidi = midiOctave
                    if !ascending && inputMidi == scale.scaleNoteStates[0].midi {
                        DispatchQueue.main.async {
                            sleep(1)
                            ScalesModel.shared.stopRecordingScale()
                        }
                    }
                }
                else {
                    match.status = .dataIgnored
                }
                break
            }
        }
        if !matchedInScale {
            //if !unMatchedToScale.contains(inputMidi) {
            unMatchedToScale.append(UnMatchedType(notePlayedSequence: notePlayedSequence, midi: inputMidi))
            //}
            match.status = .wrongNote
        }
        self.notePlayedSequence += 1
        return match
    }
    
//    func matchOld(timestamp:Date, midis:[Int]) -> MatchType {
//        if nextMatchIndex >= scale.scaleNoteStates.count {
//            return MatchType(.dataIgnored, "after_scale")
//        }
////        if !firstNoteMatched {
////            if Double(amplitude) < self.startAmplitude { //TODO
////                return MatchType(.dataIgnored, "before_scale, amp:\(self.startAmplitude)")
////            }
////        }
//        
//        let requiredMidi = scale.scaleNoteStates[nextMatchIndex].midi
//        let requiredNoteNumber = self.midiToNoteNum(midi: requiredMidi)
//
//        for midiIndex in 0..<midis.count {
//            let midi = midis[midiIndex]
//            if let lastGoodMidi = lastGoodMidi {
//                if makeMidiOctaves(midi: lastGoodMidi).contains(midi) {
//                    self.mismatchCount = 0
//                    if midiIndex > midis.count - 1 {
//                        return MatchType(.dataIgnored, "already_matched, looking_for midi:\(requiredMidi)") // noteNum:[\(requiredNoteNumber)]")
//                    }
//                }
//            }
//            
//            let requiredMidisOctave = [requiredMidi-24, requiredMidi-12, requiredMidi, requiredMidi+12, requiredMidi+24]
//            if requiredMidisOctave.contains(midi) {
//                scale.scaleNoteStates[nextMatchIndex].matchedTime = timestamp
//                scale.scaleNoteStates[nextMatchIndex].setPlayingMidi(true)
//                ScalesModel.shared.forceRepaint()
//                nextMatchIndex += 1
//                self.firstNoteMatched = true
//                self.mismatchCount = 0
//                self.lastGoodMidi = midi
//                correctCount += 1
//                if correctCount >= scale.scaleNoteStates.count {
//                    DispatchQueue.main.async {
//                        sleep(1)
//                        ScalesModel.shared.stopRecordingScale()
//                    }
//                }
//                return MatchType(.correct, "required_midi:\(requiredMidi) matched:\(midi) noteNum:[\(requiredNoteNumber)]")
//            }
//            if mismatchCount == self.mismatchesAllowed {
//                if firstNoteMatched {
//                    nextMatchIndex += 1
//                }
//                wrongCount += 1
//                DispatchQueue.main.async {
//                    sleep(1)
//                    //ScalesModel.shared.stopRecordingScale()
//                }
//                return MatchType(.wrongNote, "required_midi:\(requiredMidi) OR_Octaves:\(makeMidiOctaves(midi: requiredMidi)) noteNum:[\(requiredNoteNumber)] wrongCount:\(self.wrongCount)")
//            }
//            else {
//                self.mismatchCount += 1
//            }
//        }
//        return MatchType(.dataIgnored, "looking_for midi:\(requiredMidi) noteNum:[\(requiredNoteNumber)]  mismatchCount:\(mismatchCount)")
//    }

    func noteNumToName(num:Int) -> String {
        var ret = ""
        switch num {
        case 0:
            ret = "C"
        case 2:
            ret = "D"
        case 4:
            ret = "E"
        case 5:
            ret = "F"
        case 7:
            ret = "G"
        case 9:
            ret = "A"
        case 11:
            ret = "B"
        default:
            ret = String(num)
        }
        return ret
    }
    
    func stats() -> String {
        var missing = 0
        var correctCount = 0
        for state in self.scale.scaleNoteStates {
            if state.matchedTime == nil {
                missing += 1
            }
            else {
                correctCount += 1
            }
        }

        var lastMatchTime:Date?
        var ctr = 0
        var total = 0.0
        //get tempo
        for match in self.scale.scaleNoteStates {
            if match.matchedTime == nil {
                break
            }
            if let lastMatchTime = lastMatchTime {
                let delta = match.matchedTime!.timeIntervalSince1970 - lastMatchTime.timeIntervalSince1970
                total += delta
                ctr += 1
            }
            lastMatchTime = match.matchedTime
        }
        let avgDuration = total / Double(ctr)
        let tempo = avgDuration > 0 ? Int(60.0 / avgDuration) : 0
        let missingSymbol = missing > 0 ? "❓❓" : ""
        var stats = "ScaleMatcher, \(missingSymbol) Missing:\(missing)  Correct:\(correctCount)  Tempo:♩=\(tempo) (\(tempo/4))  MismatchesAllowed:\(self.mismatchesAllowed)"
        ScalesModel.shared.result = Result(scale: scale, notInScale: self.unMatchedToScale)
        return stats
    }
    
//    func matchNew1(timestamp:Date, frequency:Float, asc:Bool) -> MatchType {
////        if nextMatchIndex >= matches.count  {
////            return MatchType(.seen)
////        }
//        let midi = frequencyToMIDI(frequency: frequency)
//
//        var c = 0
//        let midPoint = self.matches.count / 2
//        var matched1:Set<Int> = []
//
//        if ascending {
//            for i in 0...midPoint {
//                let match = self.matches[i]
//                if midi == match.midi {
//                    if match.matchedTime == nil {
//                        match.matchedTime = timestamp
//                        if midi == topMidi {
//                            ascending = false
//                            matched1 = []
//                        }
//                        return MatchType(.correct)
//                    }
//                    matched1.insert(midi)
//                }
//                if midi > match.midi {
//                    if match.matchedTime == nil {
////                        if !match.missNoted {
////                            match.missNoted = true
////                            let status = MatchType(.wrongNote)
////                            status.missedMidis = [match.midi]
////                            return status
////                        }
//                    }
//                }
//                if midi < match.midi {
//                    if match.matchedTime == nil {
//                        return MatchType(matched1.contains(midi) ? .dataIgnored : .wrongNote)
//                    }
//                }
//            }
//        }
//        else {
//            for i in midPoint..<self.matches.count {
//                let match = self.matches[i]
//                if midi == match.midi {
//                    if match.matchedTime == nil {
//                        match.matchedTime = timestamp
//                        return MatchType(.correct)
//                    }
//                    matched1.insert(midi)
//                }
//                if midi > match.midi {
//                    if match.matchedTime == nil {
//                        return MatchType(matched1.contains(midi) ? .dataIgnored : .wrongNote)
//                    }
//                }
//            }
//        }
//        return MatchType(.dataIgnored)
//    }
}
