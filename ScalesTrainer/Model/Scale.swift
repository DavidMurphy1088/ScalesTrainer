import Foundation

enum ScaleShape {
    case none
    case scale
    case arpgeggio
    case arpgeggio4Note
}


public enum ScaleType: CaseIterable {
    case major
    case naturalMinor
    case harmonicMinor
    case melodicMinor
    case arpeggioMajor
    case arpeggioMinor
    case arpeggioDiminished
    
    case arpeggioDominantSeventh
    case arpeggioMajorSeventh
    case arpeggioMinorSeventh
    case arpeggioDiminishedSeventh
    case arpeggioHalfDiminished
    
    case chromatic
    
    func isMajor() -> Bool {
        return self == .major || self == .arpeggioMajor || self == .arpeggioDominantSeventh || self == .arpeggioMajorSeventh 
        || self == .chromatic
    }
    
    var description: String {
        switch self {
        case .major:
            return "Major"
        case .naturalMinor:
            return "Minor"
        case .harmonicMinor:
            return "Harmonic Minor"
        case .melodicMinor:
            return "Melodic Minor"
        case .arpeggioMajor:
            return "Major Arpeggio"
        case .arpeggioMinor:
            return "Minor Arpeggio"
        case .arpeggioDiminished:
            return "Diminished Arpeggio"
        case .arpeggioDominantSeventh:
            return "Dominant Seventh Arpeggio"
        case .arpeggioMajorSeventh:
            return "Major Seventh Arpeggio"
        case .arpeggioMinorSeventh:
            return "Minor Seventh Arpeggio"
        case .arpeggioDiminishedSeventh:
            return "Diminished Seventh Arpeggio"
        case .arpeggioHalfDiminished:
            return "Half Diminished Arpeggio"
        case .chromatic:
            return "Chromatic"
        }
        //return name
    }
}
///In terms of arpeggios: major, minor, dominant 7ths and diminished 7ths.

public class ScaleNoteState {
    let id = UUID()
    let sequence:Int
    var midi:Int
    var finger:Int = 0
    var fingerSequenceBreak = false
    var matchedTime:Date? = nil
    ///The time the note was flagged as missed in the scale playing
    var unmatchedTime:Date? = nil
    var matchedAmplitude:Double? = nil
    ///The tempo adjusted normalized duration (value) of the note
    var valueNormalized:Double? = nil
    
    init(sequence: Int, midi:Int) {
        self.sequence = sequence
        self.midi = midi
    }
}

public class Scale { 
    let id = UUID()
    private(set) var scaleRoot:ScaleRoot
    private(set) var scaleNoteState:[ScaleNoteState]
    private var metronomeAscending = true
    let octaves:Int
    let hand:Int
    let scaleType:ScaleType
    var scaleShape:ScaleShape

    public init(scaleRoot:ScaleRoot, scaleType:ScaleType, octaves:Int, hand:Int) {
        self.scaleRoot = scaleRoot
        self.octaves = octaves
        self.scaleType = scaleType
        scaleNoteState = []
        self.hand = hand
        
        ///https://musescore.com/user/27091525/scores/6509601
        ///B, B♭, A, A♭ drop below Middle C for one and two octaves
        ///G drops below Middle C only for 2 octaves
        ///The start of the scale for one octave -
        var nextMidi = 0
        switch scaleRoot.name {
        case "C":
            nextMidi = 60
        case "C#":
            nextMidi = 61
        case "D♭":
            nextMidi = 61
        case "D":
            nextMidi = 62
        case "D#":
            nextMidi = 63
        case "E♭":
            nextMidi = 63
        case "E":
            nextMidi = 64
        case "F":
            nextMidi = 65
        case "F#":
            nextMidi = 66
        case "G♭":
            nextMidi = 66
        case "G":
            nextMidi = 67 - 12
        case "G#":
            nextMidi = 68 - 12
        case "A♭":
            nextMidi = 68 - 12
        case "A":
            nextMidi = 69 - 12
        case "A#":
            nextMidi = 70 - 12
        case "B♭":
            nextMidi = 70 - 12
        case "B":
            nextMidi = 71 - 12
        default:
            nextMidi = 60
        }
        
        ///For a 3 octave scale start one octave lower
        let dropForThreeOcataves = false
        
        if octaves > 2 {
            if dropForThreeOcataves {
                nextMidi -= 12
            }
            else {
                if octaves > 3 {
                    nextMidi -= 12
                }
            }
        }

        ///All are low and some drop off 88-key keyboard
        if hand == 1 {
            nextMidi -= 12
        }
        
        ///Set midi values in scale
        self.scaleShape = .none
        let scaleOffsets:[Int] = getScaleOffsets(scaleType: scaleType)

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
        
//        if (scaleNoteState.count - 1) % 7 == 0 {
//            self.scaleShape = .scale
//        }
//        else {
//            if (scaleNoteState.count - 1) % 3 == 0 {
//                self.scaleShape = .arpgeggio
//            }
//            else {
//                self.scaleShape = .arpgeggio4Note
//            }
//        }
        if [.major, .naturalMinor, .harmonicMinor, .melodicMinor].contains(self.scaleType) {
            self.scaleShape = .scale
        }
        else {
            if [.arpeggioMajor, .arpeggioMinor, .arpeggioDiminished].contains(self.scaleType) {
                self.scaleShape = .arpgeggio
            }
            else {
                self.scaleShape = .arpgeggio4Note
            }
        }
        
        ///Add notes with midis for the downwards direction
        let up = Array(scaleNoteState)
        var ctr = 0
        for i in stride(from: up.count - 2, through: 0, by: -1) {
            var downMidi = up[i].midi
            if scaleType == .melodicMinor {
                if i > 0 {
                    if ctr % 7 == 0 {
                        downMidi = downMidi - 1
                    }
                    if ctr % 7 == 1 {
                        downMidi = downMidi - 1
                    }
                }
            }
            let descendingNote = ScaleNoteState(sequence: sequence, midi: downMidi)
            scaleNoteState.append(descendingNote )
            ctr += 1
            sequence += 1
        }

        setFingers(hand: hand)
        setFingerBreaks(hand: hand)
        //debug111("Scale Constructor key:\(scaleRoot.name) hand:\(hand)")
    }
    
    func getScaleOffsets(scaleType : ScaleType) -> [Int] {
        var scaleOffsets:[Int] = []
        switch scaleType {
        case .major:
            scaleOffsets = [2,2,1,2,2,2,2]
        case .naturalMinor:
            scaleOffsets = [2,1,2,2,1,2,2]
        case .harmonicMinor:
            scaleOffsets = [2,1,2,2,1,3,1]
        case .melodicMinor:
            scaleOffsets = [2,1,2,2,2,2,1]
        case .arpeggioMajor:
            scaleOffsets = [4,3,4]
        case .arpeggioMinor:
            scaleOffsets = [3,4,4]
        case .arpeggioDiminished:
            scaleOffsets = [3,3,6]
            
        case .arpeggioDominantSeventh:
            scaleOffsets = [4,3,3,2]
        case .arpeggioMajorSeventh:
            scaleOffsets = [4,3,4,1]
        case .arpeggioMinorSeventh:
            scaleOffsets = [3,4,3,2]

        case .arpeggioHalfDiminished:
            scaleOffsets = [3,3,4,2]
        case .arpeggioDiminishedSeventh:
            scaleOffsets = [3,3,3,3]
        case .chromatic:
            scaleOffsets = [1,1,1,1,1,1,1,1,1,1,1,1]

        }

        return scaleOffsets
    }
    
    func debug1(_ msg:String)  {
        print("==========scale \(msg)", scaleRoot.name, scaleType, self.id)
        
        func getValue(_ value:Double?) -> String {
            if value == nil {
                return "None"
            }
            else {
                return String(format: "%.2f", value!)
            }
        }
        for state in self.scaleNoteState {
            print("Midi:", state.midi,  "finger:", state.finger, "break:", state.fingerSequenceBreak, "matched:", state.matchedTime != nil, "time:", state.matchedTime ?? "",
                  "valueNormalized:", getValue(state.valueNormalized))
        }
    }
    
    ///Set note durations normalized to the tempo and return an average tempo
    public func setNoteNormalizedValues() -> Int? {
        for note in self.scaleNoteState {
            note.valueNormalized = nil
        }
        guard self.scaleNoteState.count > 4 else {
            return nil
        }
        guard self.scaleNoteState[0].matchedTime != nil else {
            return nil
        }
        var timeIntervals:[Double] = []
        
        ///Calculate the the note durations
        var lastMatch:Date? = self.scaleNoteState[0].matchedTime
        var sum:Double = 0
        var timedNotesCount = 0

        for note in self.scaleNoteState {
            if let matched = note.matchedTime {
                if lastMatch == nil {
                    lastMatch = matched
                    timeIntervals.append(0)
                    continue
                }
                let delta = matched.timeIntervalSince1970 - lastMatch!.timeIntervalSince1970 //{
                    timeIntervals.append(delta)
                sum += delta
                timedNotesCount += 1
                lastMatch = matched
            }
        }
        
        ///Calculate the average and apply the deltas to each note
        if sum > 0 {
            let average = Double(sum) / Double(timedNotesCount)
            let tempo = 60.0 * 1.0 / average
            for n in 0..<self.scaleNoteState.count - 1 {
                if n+1 < timeIntervals.count {
                    if timeIntervals[n+1] > 0 {
                        let note = scaleNoteState[n]
                        let normalized = timeIntervals[n+1] / average
                        note.valueNormalized = normalized
                    }
                }
            }
            return Int(tempo)
        }
        else {
            return 0
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
        guard self.scaleShape == .scale else {
            return
        }
        let halfway = self.scaleNoteState.count/2-1
        if hand == 0 {
            var lastFinger = self.scaleNoteState[0].finger
            for i in 1...halfway {
                let finger = self.scaleNoteState[i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteState[i].fingerSequenceBreak = true
                    self.scaleNoteState[self.scaleNoteState.count - i].fingerSequenceBreak = true
                }
                lastFinger = self.scaleNoteState[i].finger
            }
        }
        else {
            var lastFinger = self.scaleNoteState[halfway].finger
            for i in stride(from: halfway-1, to: 0, by: -1) {
                let finger = self.scaleNoteState[i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteState[i+1].fingerSequenceBreak = true
                    let mirror = halfway + (halfway - i) + 2
                    if mirror < self.scaleNoteState.count - 1 {
                        self.scaleNoteState[mirror].fingerSequenceBreak = true
                    }
                }
                lastFinger = self.scaleNoteState[i].finger
            }
        }
    }
    
    func getMinMax() -> (Int, Int) {
        let mid = self.scaleNoteState.count / 2
        return (self.scaleNoteState[0].midi, self.scaleNoteState[mid].midi)
    }
    
    func stringIndexToInt(index:Int, fingers:String) -> Int {
        let index = index % fingers.count
        let charIndex = fingers.index(fingers.startIndex, offsetBy: index)
        let character = fingers[charIndex]
        let characterAsString = String(character)
        if let intValue = Int(characterAsString) {
            return intValue
        }
        else {
            return 0
        }
    }
    
    ///Alfreds page 88. RH read left to right, LH read right to left. Use numbers in paren e.g. (3) instead of 3
    func setFingers(hand:Int) {
        var fingers = ""
        var leftHandLastFingerJump = 1 ///For LH - what finger jump between scale note 0 and 1. in Alberts arpeggio LH difference between leftmost two finger numbers.
        
        ///Regular scale
        
        if scaleShape == .scale {
            ///Note theat for LH finer pattern goes from high to low notes (reversed)
            switch self.scaleRoot.name {
            case "B":
                fingers = hand == 0 ? "1231234" : "1234123"
            case "F":
                fingers = hand == 0 ? "1234123" : "1231234"
            case "F#":
                if scaleType == .major {
                    fingers = hand == 0 ? "2341231" : "4123123"
                }
                else {
                    fingers = hand == 0 ? "2312341" : "4123123"
                }
            case "B♭":
                if scaleType == .major {
                    fingers = hand == 0 ? "4123123" : "3123412"
                }
                else {
                    fingers = hand == 0 ? "4123123" : "2341231"
                }
            case "E♭":
                if scaleType == .major {
                    fingers = hand == 0 ? "3123412" : "3123412"
                }
                else {
                    fingers = hand == 0 ? "3123412" : "2312341"
                }
            case "A♭":
                fingers = hand == 0 ? "3412312" : "3123412" ///probably need different for minor vs. harmonic minor

            case "C#","D♭":
                if scaleType == .major {
                    fingers = hand == 0 ? "2312341" : "3123412"
                }
                else {
                    fingers = hand == 0 ? "2312341" : "3123412"
                }
            default:
                fingers = "1231234"
            }
        }
                
        ///Three note arpeggio
        
        if scaleShape == .arpgeggio {
            switch self.scaleRoot.name {
            case "C", "G":
                fingers = hand == 0 ? "123" : "124"
            case "D":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    leftHandLastFingerJump = 2
                    fingers = hand == 0 ? "123" : "123"
                }
                else {
                    fingers = hand == 0 ? "123" : "124"
                }
            case "A":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    leftHandLastFingerJump = 2
                    fingers = hand == 0 ? "123" : "123"
                }
                else {
                    fingers = hand == 0 ? "123" : "124"
                }
            case "E":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    leftHandLastFingerJump = 2
                    fingers = hand == 0 ? "123" : "123"
                }
                else {
                    fingers = hand == 0 ? "123" : "124"
                }
            case "B":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    leftHandLastFingerJump = 2
                    fingers = hand == 0 ? "123" : "123"
                }
                else {
                    fingers = hand == 0 ? "123" : "124"
                }
            case "F":
                fingers = hand == 0 ? "123" : "124"
            case "B♭":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    fingers = hand == 0 ? "412" : "312"
                }
                else {
                    fingers = hand == 0 ? "321" : "312"
                }
            case "E♭":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    fingers = hand == 0 ? "412" : "241"
                }
                else {
                    fingers = hand == 0 ? "123" : "124"
                }
            case "A♭":
                fingers = hand == 0 ? "412" : "241"
            case "D♭":
                fingers = hand == 0 ? "412" : "241"
            default:
                fingers = hand == 0 ? "123" : "123"
            }
        }
        
        ///Four note arpeggio
        
        if scaleShape == .arpgeggio4Note {
            switch self.scaleRoot.name {
            case "B♭":
                fingers = hand == 0 ? "4123" : "2312"
            case "E♭":
                fingers = hand == 0 ? "4124" : (self.scaleType == .arpeggioMajorSeventh ? "4123" : "2341")
            case "A♭":
                fingers = hand == 0 ? "4124" : "2341"
            case "D♭":
                fingers = hand == 0 ? "4123" : "2341"
            default:
                fingers = hand == 0 ? "1234" : "1234"
            }
        }
        
        let halfway = scaleNoteState.count / 2
        if hand == 0 {
            var f = 0
            for i in 0..<halfway {
                scaleNoteState[i].finger = stringIndexToInt(index: i, fingers: fingers)
                f += 1
            }
            f -= 1
            var highNoteFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers) + 1
            if scaleShape == .arpgeggio {
                if highNoteFinger < 5 {
                    highNoteFinger += 1
                }
            }
            scaleNoteState[halfway].finger = highNoteFinger
            for i in (halfway+1..<scaleNoteState.count) {
                scaleNoteState[i].finger = stringIndexToInt(index: f, fingers: fingers)
                f -= 1
            }
        }
        else {
            var f = 0
            ///For LH - start halfway in scale, count forwards through fingers and backwards onto scale
            for i in stride(from: halfway, through: 0, by: -1) {
            //for i in stride(from: halfway, to: 0, by: -1) {
                scaleNoteState[i].finger = stringIndexToInt(index: f, fingers: fingers)
                scaleNoteState[i + 2*f].finger = stringIndexToInt(index: f, fingers: fingers)
                f += 1
            }
            if leftHandLastFingerJump > 0  {
                let nextToLastFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers)
                //var edgeFinger = stringIndexToInt(index: 1, fingers: fingers) + 1
//                if edgeFinger < 5 {
//                    let midiDiff = abs(scaleNoteState[0].midi - scaleNoteState[1].midi)
//                    if midiDiff > 2 {
//                        edgeFinger += 1
//                    }
//                }
                scaleNoteState[0].finger = nextToLastFinger + leftHandLastFingerJump
            }
            //scaleNoteState[scaleNoteState.count-1].finger = edgeFinger
        }
        //debug11("================ INIT")
    }
    
    func setFingersRightHandOld() {
        var currentFinger = 1

        if ["D♭"].contains(scaleRoot.name) {
            currentFinger = 2
        }
        if ["B♭"].contains(scaleRoot.name) {
            currentFinger = 4
        }
        if ["A♭", "E♭"].contains(scaleRoot.name) {
            currentFinger = 3
        }

        var sequenceBreaks:[Int] = [] //Offsets where the fingering sequence breaks
        var fingerPattern:[Int] = []
        
        ///the offsets in the scale where the finger is not one up from the last
        if [ScaleType.major, ScaleType.naturalMinor, ScaleType.melodicMinor, ScaleType.harmonicMinor].contains(self.scaleType) {
            fingerPattern = Array(repeating: 0, count: 7)
            switch scaleRoot.name {
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
        }
        if [ScaleType.arpeggioMajor, ScaleType.arpeggioMinor, ScaleType.arpeggioDiminished].contains(self.scaleType) {
            fingerPattern = Array(repeating: 0, count: 3)
            sequenceBreaks = [3]
        }
        if [ScaleType.arpeggioDominantSeventh, ScaleType.arpeggioMajorSeventh, ScaleType.arpeggioMinorSeventh, ScaleType.arpeggioHalfDiminished, ScaleType.arpeggioDiminishedSeventh].contains(self.scaleType) {
            fingerPattern = Array(repeating: 0, count: 4)
            sequenceBreaks = [4]
        }
        
        for i in 0..<fingerPattern.count {
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
        var highNoteFinger = fingerPattern[fingerPattern.count-1] + 1
        if [ScaleType.arpeggioMajor, ScaleType.arpeggioMinor, ScaleType.arpeggioDiminished].contains(self.scaleType) {
            highNoteFinger += 1
        }
        scaleNoteState[halfway].finger = highNoteFinger
        
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

        if ["B♭"].contains(scaleRoot.name) {
            currentFinger = 3
        }
        if ["A♭"].contains(scaleRoot.name) {
            currentFinger = 3
        }
        if ["E♭"].contains(scaleRoot.name) {
            currentFinger = 2
        }
        if ["D♭"].contains(scaleRoot.name) {
            currentFinger = 3
        }

        var sequenceBreaks:[Int] = [] //Offsets where the fingering sequence breaks
        ///the offsets in the scale where the finger is not one up from the last
        switch scaleRoot.name {
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

    func getScaleName() -> String {
        var name = scaleRoot.name + " " + scaleType.description
        name += self.hand == 0 ? ", Right Hand" : ", Left Hand"
        name += ", \(self.octaves) \(self.octaves > 1 ? "Octaves" : "Octave")"

        //if includeHandName {
        //name += self.hand == 0 ? ", Right Hand" : ", Left Hand"
        //}
        return name
    }
    
//    static func getTypeName(type:ScaleType) -> String {
//        var name = ""
//        switch type {
//        case ScaleType.major:
//            name = "Major"
//        case ScaleType.naturalMinor:
//            name = "Minor"
//        case ScaleType.harmonicMinor:
//            name = "Harmonic Minor"
//        case .melodicMinor:
//            name = "Melodic Minor"
//        case .arpeggioMajor:
//            name = "Major Arpeggio"
//        case .arpeggioMinor:
//            name = "Minor Arpeggio"
//        case .arpeggioDiminished:
//            name = "Diminished Arpeggio"
//        case .arpeggioMajorSeventh:
//            name = "Major Seventh Arpeggio"
//        case .arpeggioDominantSeventh:
//            name = "Dominant Seventh Arpeggio"
//        case .arpeggioDiminishedSeventh:
//            name = "Diminished Seventh Arpeggio"
//        case .arpeggioMinorSeventh:
//            name = "Minor Seventh Arpeggio"
//        case .arpeggioHalfDiminished:
//            name = "Half Diminished Arpeggio"
////        case .chromatic:
////            name = "Chromatic"
//        }
//        return name
//    }
    
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
        case "Major Arpeggio":
            return ScaleType.arpeggioMajor
        case "Minor Arpeggio":
            return ScaleType.arpeggioMinor
            
        case "Dominant Seventh Arpeggio":
            return ScaleType.arpeggioDominantSeventh
        case "Major Seventh Arpeggio":
            return ScaleType.arpeggioMajorSeventh
        case "Minor Seventh Arpeggio":
            return ScaleType.arpeggioMinorSeventh
        case "Diminished Arpeggio":
            return ScaleType.arpeggioDiminished
        case "Diminished Seventh Arpeggio":
            return ScaleType.arpeggioDiminishedSeventh
        case "Half Diminished Arpeggio":
            return ScaleType.arpeggioHalfDiminished
        default:
            return ScaleType.major
        }
    }
    
}
