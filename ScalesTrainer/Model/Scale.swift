import Foundation

enum ScaleShape : Codable {
    case none
    case scale
    case arpgeggio
    case arpgeggio4Note
    case brokenChord
}

public enum DynamicType: String, CaseIterable, Comparable, Codable {
    case mf = "mf"
    
    var description: String {
        switch self {
        case .mf:
            return "Mezzo-Forte"
        }
    }

    // Required for Comparable
    public static func < (lhs: DynamicType, rhs: DynamicType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum ArticulationType: CaseIterable, Comparable, Codable {
    case legato
    var description: String {
        switch self {
        case .legato:
            return "Legato"
        }
    }
}

public enum ScaleType: CaseIterable, Comparable, Codable {
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
            return "Major Broken Chord"
        case .brokenChordMinor:
            return "Minor Broken Chord"
        }
    }
}

public enum ScaleMotion: CaseIterable, Comparable, Codable {
    case similarMotion
    case contraryMotion
    var description: String {
        switch self {
        case .similarMotion:
            return "Similar Motion"
        case .contraryMotion:
            return "Contrary Motion"
        }
    }
}

public class ScaleNoteState : Codable{
    var id = UUID()
    let sequence:Int
    var midi:Int
    var value:Double
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
    
    func isWhiteKey() -> Bool {
        let offset = self.midi % 12
        return [0,2,4,5,7,9,11].contains(offset)
    }
}

public class Scale : Codable {
    var id = UUID()
    static var createCount = 0
    private(set) var scaleRoot:ScaleRoot
    private(set) var scaleNoteState:[[ScaleNoteState]]
    private var metronomeAscending = true
    var octaves:Int
    let hands:[Int]
    let minTempo:Int
    let dynamicType:DynamicType
    let articulationType:ArticulationType
    var scaleType:ScaleType
    var scaleMotion:ScaleMotion
    var scaleShapeForFingering:ScaleShape
    
    public init() {
        self.scaleRoot = ScaleRoot(name: "")
        self.scaleNoteState = []
        octaves = 0
        hands = []
        minTempo = 0
        dynamicType = .mf
        articulationType = .legato
        scaleType = .major
        scaleMotion = .similarMotion
        scaleShapeForFingering = .scale
    }

    public init(scaleRoot:ScaleRoot, scaleType:ScaleType, scaleMotion:ScaleMotion,octaves:Int, hands:[Int],
                minTempo:Int, dynamicType:DynamicType, articulationType:ArticulationType) {
        self.scaleRoot = scaleRoot
        self.minTempo = minTempo
        self.dynamicType = dynamicType
        self.articulationType = articulationType
        self.octaves = octaves
        self.scaleType = scaleType
        self.scaleMotion = scaleMotion
        scaleNoteState = []
        self.hands = hands
        print("============= StartScale", self.scaleRoot.name, self.scaleMotion, self.hands)
        ///Determine scale start note
        ///https://musescore.com/user/27091525/scores/6509601
        ///
        ///Amber - One octave Treble Clef:
        ///Lowest start note is B one ledger line below the stave, making highest note A one ledger line above the stave.
        ///One octave Bass Clef:
        ///Lowest start note is E one ledger line below the stave, making the highest note D one ledger line above the stave.
        ///Two octaves Treble Clef:
        ///Lowest start note is F three ledger lines below the stave, making highest note E three ledger lines above the stave.
        ///Two octaves Bass Clef:
        ///Lowest start note is A three ledger lines below the stave, making highest note G three ledger lines above the stave.
        
        ///The start of the scale for one octave -
        var firstMidi = 0
        switch scaleRoot.name {
        case "C":
            firstMidi = 60
        case "C#":
            firstMidi = 61
        case "D♭":
            firstMidi = 61
        case "D":
            firstMidi = 62
        case "D#":
            firstMidi = 63
        case "E♭":
            firstMidi = 63
        case "E":
            firstMidi = 64
        case "F":
            firstMidi = 65
        case "F#":
            firstMidi = 66
        case "G♭":
            firstMidi = 66
        case "G":
            firstMidi = 67 //- 12
        case "G#":
            firstMidi = 68 //- 12
        case "A♭":
            firstMidi = 68 //- 12
        case "A":
            firstMidi = 69 //- 12
        case "A#":
            firstMidi = 70 - 12
        case "B♭":
            firstMidi = 70 - 12
        case "B":
            firstMidi = 71 - 12
        default:
            firstMidi = 60
        }
        
        self.scaleShapeForFingering = .none
        if [.major, .naturalMinor, .harmonicMinor, .melodicMinor].contains(self.scaleType) {
            self.scaleShapeForFingering = .scale
        }
        if [.arpeggioMajor, .arpeggioMinor, .arpeggioDiminished].contains(self.scaleType) {
            self.scaleShapeForFingering = .arpgeggio
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
            self.scaleShapeForFingering = .brokenChord
        }
        if [.arpeggioMajorSeventh, .arpeggioMinorSeventh, .arpeggioDominantSeventh, .arpeggioDiminishedSeventh].contains(self.scaleType) {
            self.scaleShapeForFingering = .arpgeggio4Note
        }
        
        ///Set midi values in scale
        
        let scaleOffsets:[Int] = getScaleOffsets(scaleType: scaleType)
        
        for handIndex in [0,1] {
            var sequence = 0
            var nextMidi = firstMidi
            let scaleOffsetsForHand:[Int]
            scaleOffsetsForHand = scaleOffsets

            if handIndex == 1 {
                nextMidi -= 12
                if self.scaleMotion == .similarMotion {
                    if firstMidi >= 62 {
                        nextMidi -= 12
                    }
                }
            }
            if octaves > 1 {
                if handIndex == 0 {
                    if firstMidi >= 65 {
                        nextMidi -= 12
                    }
                }
                if handIndex == 1 {
                    if firstMidi >= 69 {
                        nextMidi -= 12
                    }
                }
            }
            
            self.scaleNoteState.append([])
            
            for oct in 0..<octaves {
                for i in 0..<scaleOffsetsForHand.count {
                    var noteValue = Settings.shared.getSettingsNoteValueFactor()
                    if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                        noteValue *= 3
                    }
                    if oct == 0 {
                        scaleNoteState[handIndex].append(ScaleNoteState(sequence: sequence, midi: nextMidi, value: noteValue))
                        let deltaDirection = 1 //(scaleType == .contraryMotion && handIndex==1) ? -1 : 1
                        nextMidi += scaleOffsetsForHand[i] * deltaDirection
                    }
                    else {
                        scaleNoteState[handIndex].append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[handIndex][i % 8].midi + (oct * 12), value: noteValue))
                    }
                    sequence += 1
                }
                ///Add top note
                if oct == octaves - 1 {
                    var noteValue = Settings.shared.getSettingsNoteValueFactor()
                    if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                        noteValue *= 3
                    }
                    scaleNoteState[handIndex].append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[handIndex][0].midi + (octaves) * 12, value: noteValue))
                    sequence += 1
                }
            }
        }

        ///Downwards direction - Mirror notes with midis for the downwards direction
        let up = Array(scaleNoteState)
        var ctr = 0
        var lastMidi = 0
        for handIndex in [0,1] {
            var sequence = 0
            for i in stride(from: up[handIndex].count - 2, through: 0, by: -1) {
                var downMidi = up[handIndex][i].midi
                let downValue = up[handIndex][i].value
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
                scaleNoteState[handIndex].append(descendingNote)
                lastMidi = downMidi
                ctr += 1
                sequence += 1
            }
            if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
                let lastNote = ScaleNoteState(sequence: sequence, midi: lastMidi + 7, value: Settings.shared.getSettingsNoteValueFactor() * 3)
                scaleNoteState[handIndex].append(lastNote)
            }
            
            ///Set last note value to fill all of last bar
            
            var totalValue = 0.0
            for note in scaleNoteState[handIndex] {
                totalValue += note.value
            }
            let lastBarValue = Int(totalValue) % 4
            let lastNoteValue = 4 - lastBarValue + 1
            scaleNoteState[handIndex][scaleNoteState[handIndex].count-1].value = Double(lastNoteValue)
        }
        
        if scaleMotion == .contraryMotion {
            ///The left hand start has to be the RH start pitch. The LH is switched from ascending then descending to descending then ascending.
            ///So interchange the two halves of the scale.
            let middleIndex = (scaleNoteState[1].count / 2) + 1
            let firstPart = scaleNoteState[1].prefix(middleIndex)
            let secondPart = scaleNoteState[1].suffix(middleIndex)
            scaleNoteState[1] = []
            var seq = 0
            for state in secondPart {
                ///Need deep copy
                scaleNoteState[1].append(ScaleNoteState(sequence: seq, midi: state.midi, value: state.value))
            }
            seq = 0
            for i in 1..<firstPart.count {
                scaleNoteState[1].append(ScaleNoteState(sequence: seq, midi: firstPart[i].midi, value: firstPart[i].value))
            }
            ///The last note value is now in the middle of the scale ... so exchange it
            let lastNoteValue = scaleNoteState[1][middleIndex - 1].value
            let firstNoteValue = scaleNoteState[1][0].value
            scaleNoteState[1][middleIndex - 1].value = firstNoteValue
            let lastNoteIndex = scaleNoteState[1].count-1

            scaleNoteState[1][lastNoteIndex].value = lastNoteValue
        }
        
        for hand in [0,1] {
            setFingers(hand: hand)
            if self.scaleType == .chromatic {
                ///Chromatic fingering is usually 1,3 whereas finger breaks for other scales are determined by a break in the finger number in the finger sequence.
                setChromaticFingerBreaks(hand: hand)
            }
            else {
                setFingerBreaks(hand: hand)
            }
        }
        debug121("endOfInit")
        Scale.createCount += 1
    }
    
    func setChromaticFingerBreaks(hand:Int) {
        let midway = self.scaleNoteState[hand].count / 2
        for i in 0...midway {
            let scaleNote = self.scaleNoteState[hand][i]
            if hand == 0 {
                if scaleNote.isWhiteKey() {
                    scaleNote.fingerSequenceBreak = [0, 5].contains(scaleNote.midi % 12) ? false : true
                }
            }
            if hand == 1 {
                if scaleMotion == .contraryMotion {
                    if scaleNote.isWhiteKey() {
                        scaleNote.fingerSequenceBreak = [4, 11].contains(scaleNote.midi % 12) ? false : true
                    }
                }
                else {
                    scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
                }
            }
        }
        for i in midway+1..<self.scaleNoteState[hand].count {
            let scaleNote = self.scaleNoteState[hand][i]
            if hand == 0 {
                scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
            }
            if hand == 1 {
                if scaleMotion == .contraryMotion {
                    scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
                }
                else {
                    if scaleNote.isWhiteKey() {
                        scaleNote.fingerSequenceBreak = [4, 11].contains(scaleNote.midi % 12) ? false : true
                    }
                }
            }
        }
    }

//    func setChromaticFingerBreaksOld(hand:Int) {
//        var whiteCount = 0
//        let midway = self.scaleNoteState[hand].count / 2
//        for i in 0..<midway {
//            let scaleNote = self.scaleNoteState[hand][i]
//            if hand == 0 {
//                if i > 0 && scaleNote.isWhiteKey() {
//                    scaleNote.fingerSequenceBreak = whiteCount == 0 ? true : false
//                    whiteCount += 1
//                }
//                else {
//                    whiteCount = 0
//                    scaleNote.fingerSequenceBreak = false
//                }
//            }
//            else {
//                if scaleNote.isWhiteKey() {
//                    scaleNote.fingerSequenceBreak = scaleMotion == .contraryMotion ? true : false
//                    whiteCount += 1
//                }
//                else {
//                    whiteCount = 0
//                    if i > 0 {
//                        ///finger over
//                        scaleNote.fingerSequenceBreak = scaleMotion == .contraryMotion ? false : true
//                    }
//                }
//            }
//        }
//        for i in midway+1..<self.scaleNoteState[hand].count {
//            let scaleNote = self.scaleNoteState[hand][i]
//            if hand == 0 { //}|| scaleMotion == .contraryMotion {
//                if scaleNote.isWhiteKey() {
//                    scaleNote.fingerSequenceBreak = false
//                    whiteCount += 1
//                }
//                else {
//                    whiteCount = 0
//                    scaleNote.fingerSequenceBreak = true
//                }
//            }
//            else {
//                if scaleNote.isWhiteKey() {
//                    scaleNote.fingerSequenceBreak = whiteCount == 0 ? true : false
//                    whiteCount += 1
//                }
//                else {
//                    whiteCount = 0
//                    scaleNote.fingerSequenceBreak = false
//                }
//            }
//        }
//    }
    
    func makeNewScale(offset:Int) -> Scale {
        let scale = Scale(scaleRoot: self.scaleRoot, scaleType: self.scaleType, scaleMotion: self.scaleMotion, octaves: self.octaves, hands: self.hands,
                          minTempo: self.minTempo, dynamicType: self.dynamicType, articulationType: self.articulationType)
        for handIndex in [0,1] {
            for note in scale.scaleNoteState[handIndex] {
                note.midi += offset
            }
        }
        return scale
    }
    
    func getKeyboardCount() -> Int {
        if self.hands.count == 1 {
            return 1
        }
        else {
            return 2 //self.scaleMotion .contraryMotion1 ? 1 : 2
        }
    }
    
    func getScaleOffsets(scaleType : ScaleType) -> [Int] {
        var scaleOffsets:[Int] = []
        switch scaleType {
        case .major:
            scaleOffsets = [2,2,1,2,2,2,1]
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
//        case .contraryMotion:
//            scaleOffsets = [2,2,1,2,2,2,1]
        }
        
        return scaleOffsets
    }
    
    func needsTwoKeyboards() -> Bool {
        return self.hands.count > 1 //&& self.scaleMotion != .contraryMotion1
    }
    
    func debug121(_ msg:String)  {
        print("==========Scale  Debug \(msg)", scaleRoot.name, scaleType, "Hands:", self.hands, "octaves:", self.octaves, "motion:", self.scaleMotion, "id:", self.id)
        func getValue(_ value:Double?) -> String {
            if value == nil {
                return "None"
            }
            else {
                return String(format: "%.2f", value!)
            }
        }
        for handIndex in [0,1]{
            var idx = 0
            for state in self.scaleNoteState[handIndex] {
//                let xxx = state.id.uuidString
//                let stateid = String(xxx.suffix(4))
                print("Hand", handIndex, "idx:", idx, "\tMidi:", state.midi,  "value:", state.value, "finger:", state.finger, "break:", state.fingerSequenceBreak,
                      "matched:", state.matchedTime != nil, "time:", state.matchedTime ?? "",
                      "valueNormalized:", getValue(state.valueNormalized))
                idx += 1
            }
        }
    }
    
    ///Set note durations normalized to the tempo and return an average tempo
    public func setNoteNormalizedValues() -> Int? {
        var tempoSum = 0
        for handIndex in [0,1] {
            for note in self.scaleNoteState[handIndex] {
                note.valueNormalized = nil
            }
            
            guard self.scaleNoteState.count > 4 else {
                return nil
            }
            guard self.scaleNoteState[handIndex][0].matchedTime != nil else {
                return nil
            }
            
            var timeIntervals:[Double] = []
            
            ///Calculate the the note durations for all notes except the first (from the previous note time)
            var lastMatch:Date? = nil //self.scaleNoteState[0].matchedTime
            var sumOfDurations:Double = 0
            var timedNotesCount = 0
            
            for note in self.scaleNoteState[handIndex] {
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
                for n in 0..<self.scaleNoteState[handIndex].count {
                    let note = scaleNoteState[handIndex][n]
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
                tempoSum += Int(tempo)
            }
            else {
                tempoSum += 0
            }
        }
        return tempoSum / 2
    }
    
    func resetMatchedData() {
        for handIndex in [0,1] {
            for state in self.scaleNoteState[handIndex] {
                state.matchedAmplitude = nil
                state.matchedTime = nil
                state.unmatchedTime = nil
            }
        }
    }
    
    func getStateForMidi(handIndex:Int, midi:Int, direction:Int) -> ScaleNoteState? {
        let start = direction == 0 ? 0 : self.scaleNoteState[handIndex].count / 2
        let end = direction == 0 ? self.scaleNoteState[handIndex].count / 2 : self.scaleNoteState[handIndex].count - 1
        for i in start...end {
            if self.scaleNoteState[handIndex][i].midi == midi {
                return self.scaleNoteState[handIndex][i]
            }
        }
        return nil
    }

    ///Calculate finger sequence breaks
    ///Set descending as key one below ascending break key
    private func setFingerBreaks(hand:Int) {
        for note in self.scaleNoteState[hand] {
            note.fingerSequenceBreak = false
        }
//        guard self.scaleShapeForFingering == .scale else {
//            return
//        }
        let halfway = self.scaleNoteState[hand].count/2-1
        if hand == 0 {
            var lastFinger = self.scaleNoteState[hand][0].finger
            for i in 1...halfway {
                let finger = self.scaleNoteState[hand][i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteState[hand][i].fingerSequenceBreak = true
                    self.scaleNoteState[hand][self.scaleNoteState[hand].count - i].fingerSequenceBreak = true
                }
                lastFinger = self.scaleNoteState[hand][i].finger
            }
        }
        else {
            var lastFinger = self.scaleNoteState[hand][halfway].finger
            for i in stride(from: halfway-1, to: 0, by: -1) {
                let finger = self.scaleNoteState[hand][i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteState[hand][i+1].fingerSequenceBreak = true
                    let mirror = halfway + (halfway - i) + 2
                    if mirror < self.scaleNoteState[hand].count - 1 {
                        self.scaleNoteState[hand][mirror].fingerSequenceBreak = true
                    }
                }
                lastFinger = self.scaleNoteState[hand][i].finger
            }
        }
    }
    
    func getMinMax(handIndex:Int) -> (Int, Int) {
        let mid = self.scaleNoteState[handIndex].count / 2
        return (self.scaleNoteState[handIndex][0].midi, self.scaleNoteState[handIndex][mid].midi)
    }
    
    func getMidisInScale(handIndex:Int) -> [Int] {
        var notes:[Int] = []
        for note in self.scaleNoteState[handIndex] {
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
        
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
            fingers = hand == 0 ? "124" : "531"
        }
        
        /// ========== Set fingering now given the finger sequence ==========
        if scaleType == .chromatic {
            applyChromaticFingers()
        }
        else {
            ///Apply the finger patterns for ascending and descending. The finger pattern used is the pattern for the right hand ascending.
            ///For LH ascending the pattern is applied to the middle of the LH scale. For LH contrary motion its applied to the start of the LH scale (the highest note)
            let halfway = scaleNoteState[hand].count / 2
            if hand == 0 {
                applyFingerPatternToScaleStart(halfway: halfway)
            }
            if hand == 1 {
                if scaleMotion == .similarMotion {
                    applyFingerPatternToScaleMiddle(halfway: halfway)
                }
                if scaleMotion == .contraryMotion {
                    applyFingerPatternToScaleStart(halfway: halfway)
                }
            }
        }
        
        func applyFingerPatternToScaleStart(halfway:Int) {
            var f = 0
            for i in 0..<halfway {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: i, fingers: fingers)
                f += 1
            }
            f -= 1
            var highNoteFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers) + 1
            if scaleShapeForFingering == .arpgeggio {
                if highNoteFinger < 5 {
                    highNoteFinger += 1
                }
            }
            scaleNoteState[hand][halfway].finger = highNoteFinger
            for i in (halfway+1..<scaleNoteState[hand].count) {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: f, fingers: fingers)
                f -= 1
            }
        }
        
        func applyFingerPatternToScaleMiddle(halfway:Int) {
            var f = 0
            ///For LH - start at the start of the LH scale then count forwards through fingers pattern. Work backwards down the scale and then mirror the fingering around the high note.
            for i in stride(from: halfway, through: 0, by: -1) {
                //for i in stride(from: halfway, to: 0, by: -1) {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: f, fingers: fingers)
                if ![.brokenChordMajor, .brokenChordMinor].contains(scaleType) {
                    scaleNoteState[hand][i + 2*f].finger = stringIndexToInt(index: f, fingers: fingers)
                }
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
                scaleNoteState[hand][0].finger = nextToLastFinger + leftHandLastFingerJump
                scaleNoteState[hand][scaleNoteState[hand].count - 1].finger = nextToLastFinger + leftHandLastFingerJump
            }
        }
        
        func applyChromaticFingers() {
            for i in 0..<scaleNoteState[hand].count {
                let noteState = scaleNoteState[hand][i]
                if noteState.isWhiteKey() {
                    if hand == 0 {
                        noteState.finger = [0, 5].contains(noteState.midi % 12) ? 2 : 1
                    }
                    else {
                        noteState.finger = [4, 11].contains(noteState.midi % 12) ? 2 : 1
                    }
                }
                else {
                    noteState.finger = 3
                }
            }
        }
        
//        func applyChromaticFingersOld() {
//            ///Note that for LH finger the given pattern goes from high to low notes (reversed)
//            var whiteCount = 0
//            if hand == 0 || self.scaleMotion == .contraryMotion {
//                if [0, 5].contains(scaleNoteState[hand][0].midi % 12) {
//                    whiteCount += 1
//                }
//            }
//            else {
//                if [4, 11].contains(scaleNoteState[hand][0].midi % 12) {
//                    whiteCount += 1
//                }
//            }
//            let midway = scaleNoteState[hand].count / 2
//            for i in 0..<scaleNoteState[hand].count {
//                let noteState = scaleNoteState[hand][i]
//                if noteState.isWhiteKey() {
//                    if hand == 0 || self.scaleMotion == .contraryMotion {
//                        if i <= midway {
//                            noteState.finger = whiteCount == 0 ? 1 : 2
//                        }
//                        else {
//                            noteState.finger = 1
//                            if whiteCount > 0 {
//                                if i > 0 {
//                                    scaleNoteState[hand][i-1].finger = 2
//                                }
//                            }
//                        }
//                    }
//                    else {
//                        if i <= midway {
//                            noteState.finger = 1
//                            if whiteCount > 0 {
//                                if i > 0 {
//                                    scaleNoteState[hand][i-1].finger = 2
//                                }
//                            }
//                        }
//                        else {
//                            noteState.finger = whiteCount == 0 ? 1 : 2
//                        }
//                    }
//                    whiteCount += 1
//                }
//                else {
//                    noteState.finger = 3
//                    whiteCount = 0
//                }
//                if i == midway {
//                    whiteCount = 0
//                    if hand == 0 || self.scaleMotion == .contraryMotion {
//                        if [4, 11].contains(scaleNoteState[hand][i].midi % 12) {
//                            whiteCount += 1
//                        }
//                    }
//                    else {
//                        if [0, 5].contains(scaleNoteState[hand][i].midi % 12) {
//                            whiteCount += 1
//                        }
//                    }
//                }
//            }
//        }
    }

    func getScaleName(handFull:Bool, octaves:Bool, tempo:Bool, dynamic:Bool, articulation:Bool) -> String {
        var name = scaleRoot.name + " " + scaleType.description
        if scaleMotion == .contraryMotion {
            name += ", " + scaleMotion.description
        }
        if self.hands.count == 1 {
            var handName = ""
            if handFull {
                switch self.hands[0] {
                case 0: handName = "Right Hand"
                case 1: handName = "Left Hand"
                default: handName = "Both Hands"
                }
            }
            else {
                switch self.hands[0] {
                case 0: handName = "RH"
                case 1: handName = "LH"
                default: handName = "Both"
                }
            }
            name += ", " + handName
        }
        if self.hands.count == 2 {
            name += handFull ? ", Both Hands" : " RH,LF"
        }
    
        if octaves {
            name += ", \(self.octaves) \(self.octaves > 1 ? "Octaves" : "Octave")"
        }
        if tempo {
            name += ", \(self.minTempo) BPM"
        }
        if dynamic {
            name += ", \(self.dynamicType.description)"
        }
        if articulation {
            name += ", \(self.articulationType.description)"
        }
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
