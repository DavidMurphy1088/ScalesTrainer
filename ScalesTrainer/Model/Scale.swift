
import Foundation

class NoteMatch {
    let noteNumber:Int
    let midi:Int
    var matchedTime:Date?
    //var missNoted = false
    init(noteNumber:Int, midi:Int) {
        self.noteNumber = noteNumber
        self.midi = midi
    }
}

class MatchType {
    enum Status {
        case correct
        case wrongNote
        case dataIgnored
    }
    var status:Status
    var msg:String?
    
    init(_ status:Status, _ message:String?) {
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

class Scale {
    var notes:[Int]
    public var display = ""
    
    init(start:Int, major:Bool, octaves:Int) {
        notes = []
        var next = start
        for oct in 0..<octaves {
            for i in 0..<7 {
                notes.append(next)
                var delta = 2
                if major {
                    if [2, 6].contains(i) {
                        delta = 1
                    }
                }
                else {
                    if [1, 4,6].contains(i) {
                        delta = 1
                    }
                    if [5].contains(i) {
                        delta = 3
                    }
                }
                next += delta
            }
            if oct == octaves - 1 {
                notes.append(next)
            }
        }
        var m = ""
        for n in notes {
            m += "  \(n)"
        }
        display = m
    }
}
