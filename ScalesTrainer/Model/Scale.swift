import Foundation

public enum NoteCorrectStatus {
    case correct
    case wrongNote
    case dataIgnored
}

public enum ScaleType {
    case major
    case naturalMinor
    case harmonicMinor
    case melodicMinor
    case arpeggio
}

public class ScaleNoteState :ObservableObject {
    @Published private(set) var isPlayingMidi = true
    @Published private(set) var correctState = NoteCorrectStatus.dataIgnored
    var midi:Int
    var finger:Int = 0
    var fingerSequenceBreak = false
    
    init(midi:Int) {
        self.midi = midi
        isPlayingMidi = false
    }
    
    public func setPlayingMidi(_ way:Bool) {
        DispatchQueue.main.async {
            self.isPlayingMidi = way
        }
    }
    public func setCorrectState(_ way:NoteCorrectStatus) {
        DispatchQueue.main.async {
            self.correctState = way
        }
    }
}

public class Scale {
    private(set) var key:Key
    private(set) var scaleNoteStates:[ScaleNoteState]

    public init(key:Key, scaleType:ScaleType, octaves:Int) {
        self.key = key
        scaleNoteStates = []
        var nextMidi = 0
        if key.sharps > 0 {
            switch key.sharps {
            case 1:
                nextMidi = 67
            case 2:
                nextMidi = 62
            case 3:
                nextMidi = 57  //A
            case 4:
                nextMidi = 64
            default:
                nextMidi = 60
            }
        }
        else {
            switch key.flats {
            case 1:
                nextMidi = 65 //F
            case 2:
                nextMidi = 58 //B♭
                //next = 70 //B♭
            case 3:
                nextMidi = 63 //E♭
            case 4:
                nextMidi = 56 //A♭
            default:
                nextMidi = 60
            }

        }
        
        ///Set midi values in scale
        for oct in 0..<octaves {
            for i in 0..<7 {
                scaleNoteStates.append(ScaleNoteState(midi: nextMidi))
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

                nextMidi += delta
            }
            if oct == octaves - 1 {
                scaleNoteStates.append(ScaleNoteState(midi: nextMidi))
            }
        }
        
        ///Downwards
        let up = Array(scaleNoteStates)
        for i in stride(from: up.count - 2, through: 0, by: -1) {
            scaleNoteStates.append(up[i])
        }

        setFingers()
        
        setFingerBreaks(direction: 0)

//        print("==========scale", key.name)
//        for state in self.scaleNoteStates {
//            print("Midis", state.midi,  "finger", state.finger, "break", state.fingerSequenceBreak)
//        }
    }
    
    ///Calculate finger sequence breaks
    ///Only calculated for ascending. Descending view assumes break is on key one below ascending break key
    func setFingerBreaks(direction:Int) {
        if direction == 0 {
            var lastFinger = self.scaleNoteStates[0].finger
            for i in 1..<self.scaleNoteStates.count/2 {
                let finger = self.scaleNoteStates[i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteStates[i].fingerSequenceBreak = true
                }
                else {
                    self.scaleNoteStates[i].fingerSequenceBreak = false
                }
                lastFinger = self.scaleNoteStates[i].finger
            }
        }
    }
    
    func setFingers() {
        var currentFinger = 1

        if ["B♭"].contains(key.name) {
            currentFinger = 4
        }
        if ["A♭", "E♭"].contains(key.name) {
            currentFinger = 3
        }

        var sequenceBreaks:[Int] = [] //Offsets where the fingering sequence breaks
        ///the offsets in the scale where the finger is not one up from the last
        switch key.name {
        case "F":
            sequenceBreaks = [4, 7]
        case "B♭":
            sequenceBreaks = [1, 4]
        case "E♭":
            sequenceBreaks = [1, 5]
        case "A♭":
            sequenceBreaks = [2, 5]
        default:
            sequenceBreaks = [3, 7]
        }
        var fingerPattern:[Int] = Array(repeating: 0, count: 7)
        
        for i in 0..<7 {
            fingerPattern[i] = currentFinger
            let index = i+1
            if sequenceBreaks.contains(index) {
                //breaks.removeFirst()
                currentFinger = 1
            }
            else {
                currentFinger += 1
            }
        }
        let halfway = scaleNoteStates.count / 2
        var f = 0
        for i in 0..<halfway {
            scaleNoteStates[i].finger = fingerPattern[f % fingerPattern.count]
            f += 1
        }
        f -= 1
        scaleNoteStates[halfway].finger = fingerPattern[fingerPattern.count-1] + 1
        for i in (halfway+1..<scaleNoteStates.count) {
            scaleNoteStates[i].finger = fingerPattern[f % fingerPattern.count]
            if f == 0 {
                f = 7
            }
            else {
                f -= 1
            }
        }
    }
    
    func getMidiIndex(midi:Int) -> Int? {
        for i in 0..<self.scaleNoteStates.count {
            if scaleNoteStates[i].midi == midi {
                return i
            }
        }
        return nil
    }
}
