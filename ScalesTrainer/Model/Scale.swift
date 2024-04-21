
import Foundation

class NoteMatch {
    let noteNumber:Int
    let midi:Int
    var matchedTime:Date?
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

public enum ScaleType {
    case major
    case naturalMinor
    case harmonicMinor
    case melodicMinor
    case arpeggio
}

//fingers and note screwed for f and othe rflat keys
public class Scale {
    let key:Key
    var notes:[Int]
    var fingers:[Int]
    public var display = ""
    
    public init(key:Key, scaleType:ScaleType, octaves:Int) {
        self.key = key
        notes = []
        fingers = []
        var next = 0
        if key.sharps > 0 {
            switch key.sharps {
            case 1:
                next = 67
            case 2:
                next = 62
            case 3:
                next = 69
            case 4:
                next = 64
            default:
                next = 60
            }
        }
        else {
            switch key.flats {
            case 1:
                next = 65
            case 2:
                next = 58
            case 3:
                next = 64
            case 4:
                next = 68
            default:
                next = 60
            }

        }
        ///upwards
        for oct in 0..<octaves {
            for i in 0..<7 {
                notes.append(next)
                var delta = 2
                if scaleType == .major {
                    if [2, 6].contains(i) {
                        delta = 1
                    }
                }
                if [ScaleType.naturalMinor, ScaleType.harmonicMinor].contains(scaleType) {
                    if [1, 4,6].contains(i) {
                        delta = 1
                    }
                    if scaleType == .harmonicMinor {
                        if [5].contains(i) {
                            delta = 3
                        }
                    }
                }

                next += delta
            }
            if oct == octaves - 1 {
                notes.append(next)
            }
        }
        ///downwards
        let up = Array(notes)
        for i in stride(from: up.count - 2, through: 0, by: -1) {
            notes.append(up[i])
        }
        var m = ""
        for n in notes {
            m += "  \(n)"
        }
        display = m
        setFingers()
    }
    
    func setFingers() {
        self.fingers = Array(repeating: 0, count: notes.count)
        var currentFinger = 1
        if ["B♭", "E♭", "A♭"].contains(key.name) {
            currentFinger = 2
        }
        var breaks:[Int] = []
        switch key.name {
        default:
            breaks = [3, 7]
        }
        var lastMidi = 0
        var fingerPattern:[Int] = Array(repeating: 0, count: 7)
        
        for i in 0..<7 {
            fingerPattern[i] = currentFinger
            let index = i+1
            if breaks.contains(index) {
                breaks.removeFirst()
                currentFinger = 1
            }
            else {
                currentFinger += 1
            }
        }
        let halfway = notes.count / 2
        var f = 0
        for i in 0..<halfway {
            fingers[i] = fingerPattern[f % fingerPattern.count]
            f += 1
        }
        f -= 1
        fingers[halfway] = 5
        for i in (halfway+1..<fingers.count) {
            fingers[i] = fingerPattern[f % fingerPattern.count]
            if f == 0 {
                f = 7
            }
            else {
                f -= 1
            }
        }
       //print(key.name, fingerPattern, fingers)
    }
    
    func containsMidi(midi:Int) -> Bool {
        return self.notes.contains(midi)
    }
}
