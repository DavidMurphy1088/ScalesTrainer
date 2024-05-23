import Foundation

public enum StatusTag {
    case noTag
    case rhythmError
    case pitchError
    case missingError
    case afterErrorVisible //e.g. all rhythm after a rhythm error is moot
    case afterErrorInvisible 
    case hilightAsCorrect //hilight the correct note that was expected
}

public class TimeSlice : ScoreEntry {
    @Published public var entries:[TimeSliceEntry]
    //@Published public var tagHigh:TagHigh?
    //@Published public var tagLow:String?
    //@Published var notesLength:Int?
    @Published public var statusTag:StatusTag = .noTag

    var score:Score
    var footnote:String?
    var barLine:Int = 0
    var beatNumber:Double = 0.0 //the beat in the bar that the timeslice is at
    //var pitchReplacedEntry:Note?
    
    //Used when recording a tap sequence into a score
    public var tapSecondsNormalizedToTempo:Double?
    //Used to display tempo slow/fast variation per note based on actual tapped milliseconds
    @Published var tapTempoRatio:Double?
    
    public init(score:Score) {
        self.score = score
        self.entries = []
        //tapSecondsNormalizedToTempo = 0.0
    }
    
    public func setStatusTag(_ tag: StatusTag) {
        DispatchQueue.main.async {
            self.statusTag = tag
        }
    }

    public func getValue() -> Double {
        if entries.count > 0 {
            return entries[0].getValue()
        }
        return 0
    }
    
//    public func removeNote(index:Int) {
//        if self.entries.count > index {
//            DispatchQueue.main.async {
//                self.entries.remove(at: index)
//                self.score.updateStaffs()
//                self.score.addStemAndBeamCharaceteristics()
//            }
//        }
//    }

    public func addNote(n:Note) {
        n.timeSlice = self
        //DispatchQueue.main.async {
            self.entries.append(n)
            
            for i in 0..<self.score.staffs.count {
                n.setNotePlacementAndAccidental(score:self.score, staff: self.score.staffs[i])
            }
            self.score.updateStaffs()
            self.score.addStemAndBeamCharaceteristics()
        //}
    }
    
    public func addRest(rest:Rest) {
        self.entries.append(rest)
        score.updateStaffs()
        score.addStemAndBeamCharaceteristics()
    }

//    public func addChord(c:Chord) {
//        for n in c.getNotes() {
//            self.addNote(n: n)
//        }
//        score.addStemAndBeamCharaceteristics()
//        score.updateStaffs()
//    }
    
//    public func setTags(high:TagHigh, low:String) {
//        //DispatchQueue.main.async {
//            //self.tagHigh = high
//            //self.tagLow = low
//        //}
//    }
    
    static func == (lhs: TimeSlice, rhs: TimeSlice) -> Bool {
        return lhs.id == rhs.id
    }
        
    func addTriadAt(timeSlice:TimeSlice, rootNoteMidi:Int, value: Double, staffNum:Int) {
        if getTimeSliceEntries().count == 0 {
            return
        }
        //if let score = score {
            let triad = score.key.makeTriadAt(timeSlice:timeSlice, rootMidi: rootNoteMidi, value: value, staffNum: staffNum)
            for note in triad {
                addNote(n: note)
            }
        //}
    }
    
    public func anyNotesRotated() -> Bool {
        for n in entries {
            if n is Note {
                let note:Note = n as! Note
                if note.rotated {
                    return true
                }
            }
        }
        return false
    }
    
}
