import Foundation

enum ScaleShape {
    case none
    case scale
    case arpgeggio
    case arpgeggio4Note
    case brokenChord
}

public enum ScaleType: CaseIterable, Comparable {
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
    
    case brokenChordMajor
    case brokenChordMinor

    case chromatic
    
    func isMajor() -> Bool {
        return self == .major || self == .arpeggioMajor || self == .arpeggioDominantSeventh || self == .arpeggioMajorSeventh 
        || self == .chromatic || self == .brokenChordMajor
    }
    
    var description: String {
        switch self {
        case .major:
            return "Major"
        case .naturalMinor:
            return "Natural Minor"
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
        case .brokenChordMajor:
            return "Broken Chord Major"
        case .brokenChordMinor:
            return "Broken Chord Minor"
        }
    }
}
///In terms of arpeggios: major, minor, dominant 7ths and diminished 7ths.

public class ScaleNoteState {
    let id = UUID()
    let sequence:Int
    var midi:Int
    let value:Double
    var finger:Int = 0
    var fingerSequenceBreak = false
    var matchedTime:Date? = nil
    ///The time the note was flagged as missed in the scale playing
    var unmatchedTime:Date? = nil
    var matchedAmplitude:Double? = nil
    ///The tempo adjusted normalized duration (value) of the note
    var valueNormalized:Double? = nil
    
    init(sequence: Int, midi:Int, value:Double) {
        self.sequence = sequence
        self.midi = midi
        self.value = value
    }
}

public class Scale { 
    let id = UUID()
    private(set) var scaleRoot:ScaleRoot
    private(set) var scaleNoteState:[ScaleNoteState]
    private var metronomeAscending = true
    var octaves:Int
    let hand:Int
    var scaleType:ScaleType
    var scaleShapeForFingering:ScaleShape

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
        
        if octaves > 3 {
            nextMidi -= 12
        }

        ///All are low and some drop off 88-key keyboard
        if hand == 1 {
            //nextMidi -= 12
            nextMidi -= 12 * octaves
        }
        
        ///Set midi values in scale
        self.scaleShapeForFingering = .none
        let scaleOffsets:[Int] = getScaleOffsets(scaleType: scaleType)

        var sequence = 0
        for oct in 0..<octaves {
            for i in 0..<scaleOffsets.count {
                var noteValue = Settings.shared.getSettingsNoteValueFactor()
                if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                    noteValue *= 3
                }
                if oct == 0 {
                    scaleNoteState.append(ScaleNoteState(sequence: sequence, midi: nextMidi, value: noteValue))
                    nextMidi += scaleOffsets[i]
                }
                else {
                    scaleNoteState.append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[i % 8].midi + (oct * 12), value: noteValue))
                }
                sequence += 1
            }
            if oct == octaves - 1 {
                var noteValue = Settings.shared.getSettingsNoteValueFactor()
                if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                    noteValue *= 3
                }
                scaleNoteState.append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[0].midi + (octaves) * 12, value: noteValue))
                sequence += 1
            }
        }

        if [.major, .naturalMinor, .harmonicMinor, .melodicMinor].contains(self.scaleType) {
            self.scaleShapeForFingering = .scale
        }
        else {
            if [.arpeggioMajor, .arpeggioMinor, .arpeggioDiminished].contains(self.scaleType) {
                self.scaleShapeForFingering = .arpgeggio
            }
            else {
                if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
                    
                }
                else {
                    self.scaleShapeForFingering = .arpgeggio4Note
                }
            }
        }
        
        ///Add notes with midis for the downwards direction
        
        let up = Array(scaleNoteState)
        var ctr = 0
        var lastMidi = 0
        for i in stride(from: up.count - 2, through: 0, by: -1) {
            var downMidi = up[i].midi
            var downValue = up[i].value
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
            let descendingNote = ScaleNoteState(sequence: sequence, midi: downMidi, value: downValue)
            scaleNoteState.append(descendingNote)
            lastMidi = downMidi
            ctr += 1
            sequence += 1
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
            let lastNote = ScaleNoteState(sequence: sequence, midi: lastMidi + 7, value: Settings.shared.getSettingsNoteValueFactor() * 3)
            scaleNoteState.append(lastNote)
        }

        setFingers(hand: hand)
        setFingerBreaks(hand: hand)
        self.debug1("Scale Constructor key:\(scaleRoot.name) hand:\(hand)")
        //debug111()
    }
    
//    func getMatchCount(matched:Bool) -> Int {
//        var cnt = 0
//        for note in self.scaleNoteState {
//            if matched {
//                if note.matchedTime != nil {
//                    cnt += 1
//                }
//            }
//            else {
//                if note.matchedTime == nil {
//                    cnt += 1
//                }
//            }
//        }
//        return cnt
//    }
    
    func makeNewScale(offset:Int) -> Scale {
        let scale = Scale(scaleRoot: self.scaleRoot, scaleType: self.scaleType, octaves: self.octaves, hand: self.hand)
        for note in scale.scaleNoteState {
            note.midi += offset
        }
        return scale
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
            
        case .brokenChordMajor:
            scaleOffsets = [4, 3, -3,   3, 5, -5,   5, 4, -4 ]
        case .brokenChordMinor:
            scaleOffsets = [3, 4, -4   ]
        }
        
        return scaleOffsets
    }
    
    func debug1(_ msg:String)  {
        print("==========Scale  Debug \(msg)", scaleRoot.name, scaleType, self.id)
        func getValue(_ value:Double?) -> String {
            if value == nil {
                return "None"
            }
            else {
                return String(format: "%.2f", value!)
            }
        }
        for state in self.scaleNoteState {
            print("Midi:", state.midi,  "value:", state.value, "finger:", state.finger, "break:", state.fingerSequenceBreak,
                  "matched:", state.matchedTime != nil, "time:", state.matchedTime ?? "",
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
        
        ///Calculate the the note durations for all notes except the first (from the previous note time)
        var lastMatch:Date? = nil //self.scaleNoteState[0].matchedTime
        var sumOfDurations:Double = 0
        var timedNotesCount = 0
        
        for note in self.scaleNoteState {
            if let matched = note.matchedTime {
                if lastMatch == nil {
                    lastMatch = matched
                    //timeIntervals.append(0)
                    continue
                }
                let delta = matched.timeIntervalSince1970 - lastMatch!.timeIntervalSince1970
                timeIntervals.append(delta)
                sumOfDurations += delta
                timedNotesCount += 1
                lastMatch = matched
            }
        }
        
        ///Calculate the average and apply the deltas to each note
        if sumOfDurations > 0 {
            let averageDuration = Double(sumOfDurations) / Double(timedNotesCount)
            for n in 0..<self.scaleNoteState.count {
                let note = scaleNoteState[n]
                if n == self.scaleNoteState.count - 1 {
                    ///Cant know duration for last note
                    note.valueNormalized = 1.0
                }
                else {
                    let normalized = timeIntervals[n] / averageDuration
                    note.valueNormalized = normalized
                }
            }
        }
        guard timedNotesCount > 0 else {
            return 0
        }
        let tempo = 60.0 / (sumOfDurations / Double(timedNotesCount))
        if tempo.isFinite && !tempo.isNaN {
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
//    func getNextExpectedNotes(count:Int) -> [ScaleNoteState] {
//        var result:[ScaleNoteState] = []
//        for i in 0..<self.scaleNoteState.count {
//            if self.scaleNoteState[i].matchedTime == nil &&
//                self.scaleNoteState[i].unmatchedTime == nil {
//                result.append(scaleNoteState[i])
//                if result.count >= count {
//                    break
//                }
//            }
//        }
//        return result
//    }
    
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
        guard self.scaleShapeForFingering == .scale else {
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
    
    func getMidisInScale() -> [Int] {
        var notes:[Int] = []
        for note in self.scaleNoteState {
            notes.append(note.midi)
        }
        return notes
    }
    
    func stringIndexToInt(index:Int, fingers:String) -> Int {
        if fingers.count == 0 {
            return 0
        }
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
        
        if scaleShapeForFingering == .scale {
            ///Note that for LH finger the given pattern goes from high to low notes (reversed)
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
            case "G♭":
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
        
        if scaleShapeForFingering == .arpgeggio {
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
        
        if scaleShapeForFingering == .arpgeggio4Note {
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
        
        ///Apply the finger patterns for ascending and descending
        
        let halfway = scaleNoteState.count / 2
        if hand == 0 {
            var f = 0
            for i in 0..<halfway {
                scaleNoteState[i].finger = stringIndexToInt(index: i, fingers: fingers)
                f += 1
            }
            f -= 1
            var highNoteFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers) + 1
            if scaleShapeForFingering == .arpgeggio {
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
    }

    func getScaleName(short:Bool = false) -> String {
        var name = scaleRoot.name + " " + scaleType.description
        if !short {
            name += self.hand == 0 ? ", Right Hand" : ", Left Hand"
            name += ", \(self.octaves) \(self.octaves > 1 ? "Octaves" : "Octave")"
        }

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
        case "Natural Minor":
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
            
        case "Broken Chord Major":
            return ScaleType.brokenChordMajor
        case "Broken Chord Minor":
            return ScaleType.brokenChordMinor

        default:
            return ScaleType.major
        }
    }
    
}
