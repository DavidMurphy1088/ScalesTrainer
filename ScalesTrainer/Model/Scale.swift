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

    public init(key:Key, scaleType:ScaleType, octaves:Int, hand:Int) {
        self.key = key
        self.octaves = octaves
        self.scaleType = scaleType
        scaleNoteState = []
        
        ///https://musescore.com/user/27091525/scores/6509601
        ///B, B♭, A, A♭ drop below Middle C for one and two octaves
        ///G drops below Middle C only for 2 octaves
        ///The start of the scale for one octave -
        var nextMidi = 0
        switch key.name {
        case "C":
            nextMidi = 60
        case "D♭":
            nextMidi = 61
        case "D":
            nextMidi = 62
        case "E♭":
            nextMidi = 63
        case "E":
            nextMidi = 64
        case "F":
            nextMidi = 65
        case "G":
            nextMidi = 67
        case "A♭":
            nextMidi = 68 - 12
        case "A":
            nextMidi = 69 - 12
        case "B♭":
            nextMidi = 70 - 12
        case "B":
            nextMidi = 71 - 12
        default:
            nextMidi = 60
        }
        
        ///Some keys just below C drop their first note for 1 octaves
        if octaves > 1 {
            if ["G"].contains(key.name) {
                nextMidi -= 12
            }
        }
        
        if hand == 1 {
            nextMidi -= 12
            if octaves > 1 {
                nextMidi -= 12
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
        if scaleType == .chromatic {
            scaleOffsets = [1,1,1,1,1,1,1,1,1,1,1,1]
        }

        var sequence = 0
        for oct in 0..<octaves {
            for i in 0..<scaleOffsets.count {
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
        
        ///Add notes with midis for the downwards direction
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
            let descendingNote = ScaleNoteState(sequence: sequence, midi: downMidi)
            scaleNoteState.append(descendingNote )
            sequence += 1
        }
        if hand == 0 {
            setFingersRightHand()
        }
        else {
            setFingersLeftHand()
        }
        setFingerBreaks(hand: hand)
        //debug11("Scale Constructor key:\(key.name) hand:\(hand)")
    }
    
    func debug111(_ msg:String) {
        print("==========scale \(msg)", key.name, key.keyType, self.id)
        for state in self.scaleNoteState {
            print("Midi:", state.midi,  "finger", state.finger, "break", state.fingerSequenceBreak, "matched", state.matchedTime != nil)
        }
    }
    
    public func getTempo() -> Int? {
        guard self.scaleNoteState.count > 4 else {
            return nil
        }
        guard self.scaleNoteState[0].matchedTime != nil else {
            return nil
        }
        var timeIntervals:[Double] = []
        
        var lastMatch:Date? = self.scaleNoteState[0].matchedTime
        for note in self.scaleNoteState {
            if let matched = note.matchedTime {
                if lastMatch == nil {
                    lastMatch = matched
                    continue
                }
                let delta = matched.timeIntervalSince1970 - lastMatch!.timeIntervalSince1970
                timeIntervals.append(delta)
                lastMatch = matched
            }
        }
        let sum = timeIntervals.reduce(0, +)
        let average = Double(sum) / Double(timeIntervals.count)
        let tempo = 60.0 * 1.0 / average
        return Int(tempo)
    }
    
    func resetMatchedData() {
        for state in self.scaleNoteState {
            state.matchedAmplitude = nil
            state.matchedTime = nil
            state.unmatchedTime = nil
        }
    }
    
    ///Return the next expected note in a scale playing
    func getNextExpectedNotes(count:Int) -> [ScaleNoteState] {
        var result:[ScaleNoteState] = []
        for i in 0..<self.scaleNoteState.count {
            if self.scaleNoteState[i].matchedTime == nil &&
                self.scaleNoteState[i].unmatchedTime == nil {
                result.append(scaleNoteState[i])
                if result.count >= count {
                    break
                }
            }
        }
        return result
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
    private func setFingerBreaks(hand:Int) {
        for note in self.scaleNoteState {
            note.fingerSequenceBreak = false
        }
        var range = self.scaleNoteState.count/2-1
        if hand == 1 {
            range += 1
        }
        var lastFinger = self.scaleNoteState[0].finger
        for i in 1...range {
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
    
    func setFingersRightHand() {
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
                ///Force a break
                f = 7
            }
            else {
                f -= 1
            }
        }
    }
    
    func setFingersLeftHand() {
        ///Set the fingering from highest to lowest first then mirror image it to the ascending section of the scale
        ///i.e. the currentFinger initialises as the finger used by the LH to play the scales highest note
        var currentFinger = 1

        if ["B♭"].contains(key.name) {
            currentFinger = 3
        }
        if ["A♭"].contains(key.name) {
            currentFinger = 3
        }
        if ["E♭"].contains(key.name) {
            currentFinger = 2
        }
        if ["D♭"].contains(key.name) {
            currentFinger = 3
        }

        var sequenceBreaks:[Int] = [] //Offsets where the fingering sequence breaks
        ///the offsets in the scale where the finger is not one up from the last
        switch key.name {
        case "F":
            sequenceBreaks = [3, 7]
        case "B♭":
            sequenceBreaks = [1, 5]
        case "B":
            sequenceBreaks = [4, 7]
        case "E♭":
            sequenceBreaks = [2, 6]
        case "A♭":
            sequenceBreaks = [1, 5]
        case "D♭":
            sequenceBreaks = [1, 5]

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
        for i in stride(from: halfway, through: scaleNoteState.count-1, by: 1) {
            let finger = fingerPattern[i % fingerPattern.count]
            scaleNoteState[i].finger = finger
            scaleNoteState[halfway - f].finger = finger
            f += 1
        }

        scaleNoteState[0].finger = fingerPattern[fingerPattern.count-1] + 1
        scaleNoteState[scaleNoteState.count-1].finger = fingerPattern[fingerPattern.count-1] + 1
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
    
    static func getScaleType(name:String) -> ScaleType {
        switch name {
        case "Minor":
            return ScaleType.naturalMinor
        case "Major":
            return ScaleType.major
        case "Harmonic Minor":
            return ScaleType.harmonicMinor
        case "Melodic Minor":
            return ScaleType.melodicMinor
        case "Chromatic":
            return ScaleType.chromatic
        case "Arpeggio":
            return ScaleType.arpeggio
        default:
            return ScaleType.major
        }
    }
}
