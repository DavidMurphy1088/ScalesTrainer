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

public class ScaleNoteState :ObservableObject, Hashable {
    let id = UUID()
    let sequence:Int
    //@Published The UI Canvas used to pain the piano key does not get updated with published  changes. It draws direct.
    private(set) var isPlayingMidi = true
    @Published private(set) var correctState = NoteCorrectStatus.dataIgnored
    var midi:Int
    var finger:Int = 0
    var fingerSequenceBreak = false
    var matchedTime:Date? = nil
    
    init(sequence: Int, midi:Int) {
        self.sequence = sequence
        self.midi = midi
        isPlayingMidi = false
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    public static func == (lhs: ScaleNoteState, rhs: ScaleNoteState) -> Bool {
        return rhs.id == lhs.id
    }
    
    public func setPlayingMidi(_ way:Bool) {
        //DispatchQueue.main.async {
            //print("====>>> setPlayMidi", self.midi, way)
            self.isPlayingMidi = way
        //}
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
        if key.keyType == .major {
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
        }
        else {
            if key.sharps > 0 {
                switch key.sharps {
                case 1:
                    nextMidi = 64
                case 2:
                    nextMidi = 59
                case 3:
                    nextMidi = 66  //F#
                case 4:
                    nextMidi = 61
                default:
                    nextMidi = 57
                }
            }
            else {
                switch key.flats {
                case 1:
                    nextMidi = 62 //D
                case 2:
                    nextMidi = 67 //G
                case 3:
                    nextMidi = 60 //C
                case 4:
                    nextMidi = 65 //F
                default:
                    nextMidi = 60
                }
            }
        }
        
        ///Set midi values in scale
        var scaleOffsets:[Int] = []
        if scaleType == .major {
            scaleOffsets = [2,2,1,2,2,2,2]
        }
        if scaleType == .naturalMinor {
            scaleOffsets = [2,1,2,2,1,2,2]
        }
        if scaleType == .harmonicMinor {
            scaleOffsets = [2,1,2,2,1,3,1]
        }
        if scaleType == .melodicMinor {
            scaleOffsets = [2,1,2,2,2,2,1]
        }
        
        var sequence = 0
        for oct in 0..<octaves {
            for i in 0..<7 {
                if oct == 0 {
                    scaleNoteStates.append(ScaleNoteState(sequence: sequence, midi: nextMidi))
                    nextMidi += scaleOffsets[i]
                }
                else {
                    scaleNoteStates.append(ScaleNoteState(sequence: sequence, midi: scaleNoteStates[i % 8].midi + (oct * 12)))
                }
                sequence += 1
            }
            if oct == octaves - 1 {
                scaleNoteStates.append(ScaleNoteState(sequence: sequence, midi: scaleNoteStates[0].midi + (octaves) * 12))
                sequence += 1
            }
        }
        
        ///Downwards
        let up = Array(scaleNoteStates)
        for i in stride(from: up.count - 2, through: 0, by: -1) {
            var downMidi = up[i].midi
            if scaleType == .melodicMinor {
                if i > 0 {
                    if i % 6 == 0 {
                        downMidi = downMidi - 1
                    }
                    if i % 5 == 0 {
                        downMidi = downMidi - 1
                    }
                }
            }
            scaleNoteStates.append(ScaleNoteState(sequence: sequence, midi: downMidi))
            sequence += 1
        }

        setFingers()
        
        setFingerBreaks(direction: 0)

        print("==========scale", key.name, key.keyType)
        for state in self.scaleNoteStates {
            print("Midis", state.midi,  "finger", state.finger, "break", state.fingerSequenceBreak)
        }
    }
    
    func resetPlayMidiStatus() {
        for state in self.scaleNoteStates {
            state.setPlayingMidi(false)
        }
    }
    
    func resetMatches() {
        for i in 0..<self.scaleNoteStates.count {
            self.scaleNoteStates[i].matchedTime = nil
        }
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
    
    ///Get the offset in the scale for the given midi
    ///The search is direction specific since melodic minors have different notes in the descending direction
    func getMidiIndex(midi:Int, direction:Int) -> Int? {
        var endIndex:Int
        var startIndex:Int
        
        if direction == 0 {
            startIndex = 0
            endIndex = (self.scaleNoteStates.count / 2) + 1
        }
        else {
            startIndex = (self.scaleNoteStates.count / 2) + 1
            endIndex = self.scaleNoteStates.count 
        }
        
        for i in startIndex..<endIndex {
            if scaleNoteStates[i].midi == midi {
                return i
            }
        }
        return nil
    }
}
