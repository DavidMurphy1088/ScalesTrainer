import Foundation

public enum ScaleType {
    case major
    case naturalMinor
    case harmonicMinor
    case melodicMinor
    case arpeggio
    case chromatic
}

public class ScaleNoteState { 
    let id = UUID()
    let sequence:Int
    var midi:Int
    var finger:Int = 0
    var fingerSequenceBreak = false
    var matchedTime:Date? = nil
    var unmatchedTime:Date? = nil ///The time the note was flagged as missed in the scale playing
    var matchedAmplitude:Double? = nil

    init(sequence: Int, midi:Int) {
        self.sequence = sequence
        self.midi = midi
    }
}

public class Scale { 
    let id = UUID()
    private(set) var key:Key
    private(set) var scaleNoteState:[ScaleNoteState]
    private var metronomeAscending = true
    let octaves:Int
    let scaleType:ScaleType

    public init(key:Key, scaleType:ScaleType, octaves:Int) {
        self.key = key
        self.octaves = octaves
        self.scaleType = scaleType
        scaleNoteState = []
        
        ///https://musescore.com/user/27091525/scores/6509601
        ///B, B♭, A, A♭ drop below Middle C for one and two octaves
        ///G drops below Middle C only for 2 octaves
        ///The start of the scale for one octave -
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
                case 5:
                    nextMidi = 59 //B
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
                case 3:
                    nextMidi = 63 //E♭
                case 4:
                    nextMidi = 56 //A♭
                case 5:
                    nextMidi = 61 //D♭
                default:
                    nextMidi = 60
                }
            }
        }
        else {
            if key.sharps > 0 {
                switch key.sharps {
                case 1:
                    nextMidi = 64  //G -> E
                case 2:
                    nextMidi = 59  //D -> B
                case 3:
                    nextMidi = 66  //A -> F#
                case 4:
                    nextMidi = 61  //E -> C#
                case 5:
                    nextMidi = 56  //B -> Ab
                default:
                    nextMidi = 56
                }
            }
            else {
                switch key.flats {
                case 1:
                    nextMidi = 62 //F -> D
                case 2:
                    nextMidi = 67 //B flat -> G
                case 3:
                    nextMidi = 60 //E flat -> C
                case 4:
                    nextMidi = 65 //A flat -> F
                case 5:
                    nextMidi = 58 //D flat -> B flat
                default:
                    nextMidi = 58
                }
            }
        }
        
        ///Some keys just below C drop their first note for 1 octaves
        if octaves > 1 {
            if key.keyType == .major {
                if [1].contains(key.sharps) {
                    nextMidi -= 12
                }
                if [6].contains(key.flats) {
                    nextMidi -= 12
                }
            }
            else {
                if key.flats == 0 && key.sharps == 0 {
                    nextMidi -= 12
                }
                else {
                    if [2,3,5,7].contains(key.sharps) {
                        nextMidi -= 12
                    }
                    if [2,5,7].contains(key.flats) {
                        nextMidi -= 12
                    }
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
                    scaleNoteState.append(ScaleNoteState(sequence: sequence, midi: nextMidi))
                    nextMidi += scaleOffsets[i]
                }
                else {
                    scaleNoteState.append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[i % 8].midi + (oct * 12)))
                }
                sequence += 1
            }
            if oct == octaves - 1 {
                scaleNoteState.append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[0].midi + (octaves) * 12))
                sequence += 1
            }
        }
        
        ///Write the downwards direction
        let up = Array(scaleNoteState)
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
            scaleNoteState.append(ScaleNoteState(sequence: sequence, midi: downMidi))
            sequence += 1
        }
        setFingers()
        setFingerBreaks()
        debug("Constructor")
    }
    
    func debug(_ msg:String) {
        print("==========scale \(msg)", key.name, key.keyType, self.id)
        for state in self.scaleNoteState {
            print("Midi:", state.midi,  "finger", state.finger, "break", state.fingerSequenceBreak, "matched", state.matchedTime != nil)
        }
    }
    
    func resetMatchedData() {
        for state in self.scaleNoteState {
            state.matchedAmplitude = nil
            state.matchedTime = nil
            state.unmatchedTime = nil
        }
    }
    
    ///Return the next expected note in a scale playing
    func getNextExpectedNote() -> ScaleNoteState? {
        for i in 0..<self.scaleNoteState.count {
            if self.scaleNoteState[i].matchedTime == nil &&
                self.scaleNoteState[i].unmatchedTime == nil {
                return self.scaleNoteState[i]
            }
        }
        return nil
    }
    
    func getStateForMidi(midi:Int, direction:Int) -> ScaleNoteState? {
        let start = direction == 0 ? 0 : self.scaleNoteState.count / 2
        let end = direction == 0 ? self.scaleNoteState.count / 2 : self.scaleNoteState.count - 1
        for i in start...end {
            if self.scaleNoteState[i].midi == midi {
                return self.scaleNoteState[i]
            }
        }
        return nil
    }

    ///Calculate finger sequence breaks
    ///Set descending as key one below ascending break key
    func setFingerBreaks() {
        for note in self.scaleNoteState {
            note.fingerSequenceBreak = false
        }
        var lastFinger = self.scaleNoteState[0].finger
        for i in 1..<self.scaleNoteState.count/2 {
            let finger = self.scaleNoteState[i].finger
            let diff = abs(finger - lastFinger)
            if diff > 1 {
                self.scaleNoteState[i].fingerSequenceBreak = true
                self.scaleNoteState[self.scaleNoteState.count - i].fingerSequenceBreak = true
            }
            lastFinger = self.scaleNoteState[i].finger
        }
    }
    
    func getMinMax() -> (Int, Int) {
        let mid = self.scaleNoteState.count / 2
        return (self.scaleNoteState[0].midi, self.scaleNoteState[mid].midi)
    }
    
    func setFingers() {
        var currentFinger = 1

        if ["D♭"].contains(key.name) {
            currentFinger = 2
        }
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
        case "D♭":
            sequenceBreaks = [2, 6]
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
        let halfway = scaleNoteState.count / 2
        var f = 0
        for i in 0..<halfway {
            scaleNoteState[i].finger = fingerPattern[f % fingerPattern.count]
            f += 1
        }
        f -= 1
        scaleNoteState[halfway].finger = fingerPattern[fingerPattern.count-1] + 1
        for i in (halfway+1..<scaleNoteState.count) {
            scaleNoteState[i].finger = fingerPattern[f % fingerPattern.count]
            if f == 0 {
                f = 7
            }
            else {
                f -= 1
            }
        }
    }
    
    static func getTypeName(type:ScaleType) -> String {
        var name = ""
        switch type {
        case ScaleType.naturalMinor:
            name = "Minor"
        case ScaleType.harmonicMinor:
            name = "Harmonic Minor"
        case .melodicMinor:
            name = "Melodic Minor"
        case .arpeggio:
            name = "Arpeggio"
        case .chromatic:
            name = "Chromatic"
        default:
            name += "Major"
        }
        return name
    }
}
