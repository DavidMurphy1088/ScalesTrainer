import Foundation

enum ScaleShape : Codable {
    case none
    case scale
    case arpgeggio
    case arpgeggio4Note
    case brokenChord
}

public enum DynamicType: String, CaseIterable, Comparable, Codable, CustomStringConvertible {
    case p = "p"
    case mf = "mf"
    case f = "f"
    
    public var description: String {
        switch self {
        case .mf:
            return "Mezzo-Forte"
        case .p:
            return "Piano"
        case .f:
            return "Forte"
        }
    }
    public var descriptionShort: String {
        switch self {
        case .mf:
            return "mf"
        case .p:
            return "p"
        case .f:
            return "f"
        }
    }

    public static func < (lhs: DynamicType, rhs: DynamicType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum ArticulationType: CaseIterable, Comparable, Codable {
    case legato
    case staccato
    var description: String {
        switch self {
        case .legato:
            return "legato"
        case .staccato:
            return "staccato"
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
    
    case trinityBrokenTriad
    
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
            return "Dom 7th Arpeggio"
        case .arpeggioMajorSeventh:
            return "Major 7th Arpeggio"
        case .arpeggioMinorSeventh:
            return "Minor 7th Arpeggio"
        case .arpeggioDiminishedSeventh:
            return "Dim 7th Arpeggio"
        case .arpeggioHalfDiminished:
            return "Half Dim Arpeggio"
        case .chromatic:
            return "Chromatic"
        case .brokenChordMajor:
            return "Major Broken Chord"
        case .brokenChordMinor:
            return "Minor Broken Chord"
        case .trinityBrokenTriad:
            return "Broken Triad"
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

public enum KeyboardColourType: CaseIterable, Comparable, Codable {
    case none
    case fingeringSequenceBreak
    case bySegment
    var description: String {
        switch self {
        case .fingeringSequenceBreak:
            return "Finger"
        case .bySegment:
            return "Segment"
        default:
            return "None"
        }
    }
}

public class ScaleCustomisation : Codable {
    let startMidiLH:Int?
    let startMidiRH:Int?
    let clefSwitch:Bool?
    let maxAccidentalLookback:Int?
    let customScaleName:String?
    let customScaleNameWheel:String?
    let customScaleNameRH:String?
    let customScaleNameLH:String?
    let removeKeySig:Bool?

    init (startMidiRH:Int? = nil, startMidiLH:Int? = nil, clefSwitch:Bool? = nil, maxAccidentalLookback:Int? = nil,
          customScaleName:String? = nil,
          customScaleNameLH:String? = nil, customScaleNameRH:String? = nil,
          customScaleNameWheel:String? = nil,
          removeKeySig:Bool? = nil) {
        self.startMidiRH = startMidiRH
        self.startMidiLH = startMidiLH
        self.clefSwitch = clefSwitch
        self.maxAccidentalLookback = maxAccidentalLookback
        self.customScaleName = customScaleName
        self.customScaleNameWheel = customScaleNameWheel
        self.customScaleNameRH = customScaleNameRH
        self.customScaleNameLH = customScaleNameLH
        self.removeKeySig = removeKeySig
    }
}

public class ScaleNoteState : Codable {
    let sequence:Int
    var midi:Int
    var value:Double
    var finger:Int = 0
    var keyboardColourType:KeyboardColourType = .none
//    {
//        didSet {
//            if midi > 60 {
//                print("Did set myVariable \(self.midi) from \(oldValue) to \(keyboardColourType)")
//            }
//        }
//    }
    
    var matchedTime:Date? = nil
    ///The time the note was flagged as missed in the scale playing
    var unmatchedTime:Date? = nil
    var matchedAmplitude:Double? = nil
    ///The tempo adjusted normalized duration (value) of the note
    var valueNormalized:Double? = nil
    ///The segment of the scale to show on the keyboard e.g. upwards or downwards in the scale. For broken chords the 3 notes in the arpeggio.
    ///Most notes have one segment. The top of the scale has the up and down segment.
    var segments:[Int]
    
    enum CodingKeys: String, CodingKey {
        case sequence
        case midi
        case value
        case valueNormalized
        case finger
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(midi, forKey: .midi)
        try container.encode(finger, forKey: .finger)
        try container.encode(value, forKey: .value)
        try container.encode(valueNormalized, forKey: .valueNormalized)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sequence = try container.decode(Int.self, forKey: .sequence)
        self.midi = try container.decode(Int.self, forKey: .midi)
        self.finger = try container.decode(Int.self, forKey: .finger)
        self.value = try container.decode(Double.self, forKey: .value)
        self.valueNormalized = try container.decode(Double.self, forKey: .valueNormalized)
        self.segments = []
    }

    init(sequence: Int, midi:Int, value:Double, segment:[Int]) {
        self.sequence = sequence
        self.midi = midi
        self.value = value
        self.segments = segment
    }
    
    func isWhiteKey() -> Bool {
        let offset = self.midi % 12
        return [0,2,4,5,7,9,11].contains(offset)
    }
    
    func toString() -> String {
        var res = "Seq:\(sequence) midi:\(midi)"
        return res
    }
}

public class Scale : Codable {
    //let id = UUID() ///Dont use - wrecks serialisation !
    static var createCount = 0
    private(set) var scaleRoot:ScaleRoot
    private var scaleNoteState:[[ScaleNoteState]]
    private var metronomeAscending = true
    var octaves:Int
    let hands:[Int]
    let minTempo:Int
    let dynamicTypes:[DynamicType]
    let articulationTypes:[ArticulationType]
    var scaleType:ScaleType
    var scaleMotion:ScaleMotion
    var scaleShapeForFingering:ScaleShape
    ///A segment is the number of beats that can be rendered before the keyboard needs to be refreshed
    ///e.g. a maj scale is octaves * 8 beats. A broken chord has 3 beats since the keyboard fingering needs to be refreshed for each new inverted chord arpeggio
    var notesPerSegment:Int
    var timeSignature:TimeSignature
    var debugOn:Bool
    var scaleCustomisation:ScaleCustomisation? = nil
    
    public init(scaleRoot:ScaleRoot, scaleType:ScaleType, scaleMotion:ScaleMotion,octaves:Int, hands:[Int],
                minTempo:Int, dynamicTypes:[DynamicType], articulationTypes:[ArticulationType],
                scaleCustomisation:ScaleCustomisation? = nil, debugOn:Bool = false) {
        self.scaleRoot = scaleRoot
        self.minTempo = minTempo
        self.dynamicTypes = dynamicTypes
        self.articulationTypes = articulationTypes
        self.octaves = octaves
        self.scaleType = scaleType
        self.scaleMotion = scaleMotion
        self.debugOn = debugOn
        
        scaleNoteState = []
        self.hands = hands
        self.scaleCustomisation = scaleCustomisation
        
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
            self.timeSignature = TimeSignature(top: 3, bottom: 8, visible: true)
        }
        else {
            self.timeSignature = TimeSignature(top: 4, bottom: 4, visible: true)
        }
        
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
        if let scaleCustomisation = self.scaleCustomisation {
            if let startMidiRH = scaleCustomisation.startMidiRH {
                firstMidi = startMidiRH
            }
        }
        if firstMidi == 0 {
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
        }
        
        self.scaleShapeForFingering = .none
        notesPerSegment = 0
        
        if [.major, .naturalMinor, .harmonicMinor, .melodicMinor].contains(self.scaleType) {
            self.scaleShapeForFingering = .scale
            notesPerSegment = (self.octaves *  7) + 1
        }
        if [.arpeggioMajor, .arpeggioMinor, .arpeggioDiminished].contains(self.scaleType) {
            self.scaleShapeForFingering = .arpgeggio
            notesPerSegment = (self.octaves *  3) + 1
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
            notesPerSegment = 3
            self.scaleShapeForFingering = .brokenChord
        }
        if [.arpeggioMajorSeventh, .arpeggioMinorSeventh, .arpeggioDominantSeventh, .arpeggioDiminishedSeventh].contains(self.scaleType) {
            notesPerSegment = (self.octaves *  4) + 1
            self.scaleShapeForFingering = .arpgeggio4Note
        }
        if [.chromatic].contains(self.scaleType) {
            notesPerSegment = (self.octaves *  12) + 1
        }
        if [.trinityBrokenTriad].contains(self.scaleType) {
            notesPerSegment = 3
        }
        
        ///Set midi values in scale
        
        let scaleOffsets:[Int] = getScaleOffsets(scaleType: scaleType)
        let scaleNoteValue = [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) ? StaffNote.VALUE_TRIPLET : StaffNote.VALUE_QUAVER
        
        func getSegment(hand:Int) -> Int {
            let totalValue = getTotalNoteValueInScale(handIndex: hand)
            var seg = (totalValue / scaleNoteValue) / Double(self.notesPerSegment)
            if scaleNoteValue != Double(Int(scaleNoteValue)) {
                ///truncating Int...total value 4.9999999 should be segment 5, not 4
                seg += 0.0001
            }
            if seg.isNaN || seg.isInfinite {
                return 0
            }
            else {
                return Int(seg)
            }
        }
        
        ///Get the start MIDI for the scale and hand
        ///The scale start might have been set by scale customisation
        func getStartMidi(hand:Int, midi:Int) -> Int {
            var startMidi = midi
            if let scaleCustomisation = self.scaleCustomisation {
                if hand == 0 {
                    if let startMidiRH = scaleCustomisation.startMidiRH {
                        return startMidiRH
                    }
                }
                
                if hand == 1 {
                    if let startMidiLH = scaleCustomisation.startMidiLH {
                        return startMidiLH
                    }
                }
            }
            if hand == 1 {
                startMidi = midi - 12
                if self.scaleMotion == .similarMotion {
                    if startMidi >= 53 {
                        startMidi -= 12
                    }
                }
            }
            if octaves > 1 {
                if hand == 0 {
                    if startMidi >= 65 {
                        startMidi -= 12
                    }
                }
            }
            return startMidi
        }
        
        for handIndex in [0,1] {
            var sequence = 0
            var nextMidi = getStartMidi(hand: handIndex, midi: firstMidi)
            //scaleOffsetsForHand =
            
            self.scaleNoteState.append([])
            if self.scaleType == .trinityBrokenTriad {
                scaleNoteState[handIndex].append(ScaleNoteState(sequence: 0, midi: nextMidi, value: 0.5, segment: [0]))
                scaleNoteState[handIndex].append(ScaleNoteState(sequence: 1, midi: nextMidi+4, value: 0.5, segment: [0]))
                scaleNoteState[handIndex].append(ScaleNoteState(sequence: 2, midi: nextMidi+7, value: 0.5, segment: [0,1]))
                scaleNoteState[handIndex].append(ScaleNoteState(sequence: 3, midi: nextMidi+4, value: 0.5, segment: [1]))
                scaleNoteState[handIndex].append(ScaleNoteState(sequence: 4, midi: nextMidi, value: 0.5, segment: [1]))
                continue
            }
            
            let scaleOffsetsForHand:[Int] = scaleOffsets
            for oct in 0..<octaves {
                for i in 0..<scaleOffsetsForHand.count {
                    var noteValue = scaleNoteValue //Settings.shared.getSettingsNoteValueFactor()
                    if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                        noteValue *= 3
                    }
                    if oct == 0 {
                        let segment = getSegment(hand: handIndex)
                        scaleNoteState[handIndex].append(ScaleNoteState(sequence: sequence, midi: nextMidi, value: noteValue,
                                                                        segment: [segment]))
                        let deltaDirection = 1
                        nextMidi += scaleOffsetsForHand[i] * deltaDirection
                    }
                    else {
                        let segment = getSegment(hand: handIndex)
                        scaleNoteState[handIndex].append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[handIndex][i % scaleOffsetsForHand.count].midi + (oct * 12),
                                                                         value: noteValue, segment: [segment]))
                    }
                    sequence += 1
                }
                ///Add top note
                if oct == octaves - 1 {
                    var noteValue = scaleNoteValue
                    if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) && sequence == 9 {
                        noteValue *= 3
                    }
                    let segment = getSegment(hand: handIndex)
                    let segments:[Int]
                    if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
                        segments = [segment]
                    }
                    else {
                        segments = [segment, segment+1]
                    }
                    ///The top note is in the upward and downward segment. i.e. it should show on both segments
                    scaleNoteState[handIndex].append(ScaleNoteState (sequence: sequence, midi: scaleNoteState[handIndex][0].midi + (octaves) * 12,
                                                                     value: noteValue, segment: segments))
                    sequence += 1
                }
            }
        }
        
        ///Set MIDIS for downwards direction - Mirror notes with midis for the downwards direction
        let up = Array(scaleNoteState)
        var ctr = 0
        var lastMidi = 0
        var hands:[Int] = [0,1]
        if self.scaleType == .trinityBrokenTriad {
            hands = []
        }
        for handIndex in hands {
            var segmentCounter = 0
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
                let segment = getSegment(hand: handIndex)
                let descendingNote = ScaleNoteState(sequence: sequence, midi: downMidi, value: downValue, segment:[segment])
                scaleNoteState[handIndex].append(descendingNote)
                segmentCounter += 1
                lastMidi = downMidi
                ctr += 1
                sequence += 1
            }
            if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
                let segment = getSegment(hand: handIndex)
                let lastNote = ScaleNoteState(sequence: sequence, midi: lastMidi + 7, value: scaleNoteValue * 3,
                                              segment: [segment])
                scaleNoteState[handIndex].append(lastNote)
            }
        }
        
        ///Now adjust MIDIs for contrary motion if required - downwards direction, contrary
        if scaleMotion == .contraryMotion {
            ///The left hand start has to be the RH start pitch. The LH is switched from ascending then descending to descending then ascending.
            ///So interchange the two halves of the scale.
            if self.debugOn {
                
            }
            let leftHand = 1
            let middleIndex = (scaleNoteState[leftHand].count / 2) + 1
            let firstPart = scaleNoteState[leftHand].prefix(middleIndex)
            let secondPart = scaleNoteState[leftHand].suffix(middleIndex)
            let segmentsOfBottomNote = scaleNoteState[leftHand][middleIndex-1].segments
            
            scaleNoteState[leftHand] = []
            var seq = 0
            ///For octaves > 1 the top of the left hand scale is higher than the start of the right hand scale. So remove that overlap.
            let leftOverlapWithRight = octaves == 1 ? 0 : 12
            for state in secondPart {
                ///Need deep copy
                scaleNoteState[leftHand].append(ScaleNoteState(sequence: seq, midi: state.midi - leftOverlapWithRight, value: state.value, segment: [0]))
            }
            seq = 0
            for i in 1..<firstPart.count {
                scaleNoteState[leftHand].append(ScaleNoteState(sequence: seq, midi: firstPart[i].midi - leftOverlapWithRight, value: firstPart[i].value, segment: [1]))
            }
            ///The last note value is now in the middle of the scale ... so exchange it
            let lastNoteValue = scaleNoteState[leftHand][middleIndex - 1].value
            let firstNoteValue = scaleNoteState[leftHand][0].value
            scaleNoteState[leftHand][middleIndex - 1].value = firstNoteValue
            let lastNoteIndex = scaleNoteState[leftHand].count-1
            scaleNoteState[leftHand][lastNoteIndex].value = lastNoteValue
            ///In the LH previously, the highest note had segments 1 and 2. Now those segments have to be moved to the new lowest note (for the turnaround)
            scaleNoteState[leftHand][middleIndex-1].segments = segmentsOfBottomNote.map { $0 }
        }
        
        ///Set last note value
        
        for handIndex in [0,1] {
            var barValue = 0.0
            var lastNote:ScaleNoteState?
            for note in scaleNoteState[handIndex] {
                barValue += note.value + 0.0001
                let x = Int(barValue)
                if Int(barValue) >= self.getRequiredValuePerBar() {
                    barValue = 0
                }
                lastNote = note
            }
            if let lastNote = lastNote {
                lastNote.value = 1.0
            }
        }
        
        ///Fingering
        for hand in [0,1] {
            setFingers(hand: hand)
            
            ///Set finger breaks - thumb under etc
            if self.scaleType == .chromatic {
                ///Chromatic fingering is usually 1,3 whereas finger breaks for other scales are determined by a break in the finger number in the finger sequence.
                setChromaticFingerBreaks(hand: hand)
            }
            else {
                if [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) {
                    ///Set segments for Broken Chords. Broken chords color the chord arpeggios by segment
                    for hand in self.scaleNoteState {
                        for state in hand {
                            state.keyboardColourType = KeyboardColourType.bySegment
                        }
                    }
                }
                else {
                    setFingerBreaks(hand: hand)
                }
            }
        }
        
        Scale.createCount += 1
    }
    
    func getHandTypes() -> [HandType] {
        if self.hands.count == 2 {
            return [HandType.left, HandType.right]
        }
        if self.hands[0] == 0 {
            return [HandType.left]
        }
        else {
            return [HandType.right]
        }
    }
    
    func getMinMaxSegments() -> (min:Int, max:Int) {
        var scaleMin:Int = Int.max
        var scaleMax:Int = Int.min
        for hand in 0..<1 { //self.scaleNoteState.count {
            let handStates = scaleNoteState[hand]
            for state in handStates {
                if let min = state.segments.min() {
                    if min < scaleMin {
                        scaleMin = min
                    }
                }
                if let max = state.segments.max() {
                    if max > scaleMax {
                        scaleMax = max
                    }
                }
            }
        }
        return (scaleMin, scaleMax)
    }
    
    func isSameScale(scale:Scale) -> Bool {
        for hand in 0..<scaleNoteState.count {
            let match = self.scaleNoteState[hand].elementsEqual(scale.scaleNoteState[hand]) { $0.midi == $1.midi && $0.value == $1.value }
            if !match {
                return false
            }
        }
        return self.hands == scale.hands
    }
    
    //    func getArticulationsDescription() -> String {
    //        var desc = ""
    //        var d = 0
    //        for articulationType in articulationTypes {
    //            if d > 0 {
    //                desc += " or "
    //            }
    //            desc += String(articulationType.description)
    //            d += 1
    //        }
    //        return desc
    //    }
    
    
    //    func getScaleNoteState(handType:HandType, index:Int) -> ScaleNoteState {
    //        let states = self.scaleNoteState[handType == .right ? 0 : 1]
    //        return states[index]
    //    }
    func getScaleNoteState(handType: HandType, index: Int) -> ScaleNoteState? {
        guard index < self.scaleNoteState[0].count else {
            return nil
        }
        let states = self.scaleNoteState[handType == .right ? 0 : 1]
        return states[index]
    }
    func getScaleNoteStates(handType:KeyboardType) -> [ScaleNoteState] {
        return self.scaleNoteState[handType == .right ? 0 : 1]
    }
    
    ///Return the remaining number of beats for a specified time signature for the scale's last bar. Remaining is the full bar minus the scale's last note value.l
    func getRemainingBeatsInLastBar(timeSignature:TimeSignature) -> Int {
        if timeSignature.top == 3 {
            return 0
        }
        let totalNoteValue = self.getTotalNoteValueInScale(handIndex: 0)
        let totalValue = Int(totalNoteValue.rounded())
        let lastBarTotalValue = totalValue % timeSignature.top
        if lastBarTotalValue == 0 {
            return 0
        }
        let remaining = timeSignature.top - lastBarTotalValue
        return remaining
    }
    
    func setChromaticFingerBreaks(hand:Int) {
        let midway = self.scaleNoteState[hand].count / 2
        for i in 0...midway {
            let scaleNote = self.scaleNoteState[hand][i]
            if hand == 0 {
                if scaleNote.isWhiteKey() {
                    //scaleNote.fingerSequenceBreak = [0, 5].contains(scaleNote.midi % 12) ? false : true
                    scaleNote.keyboardColourType = [0, 5].contains(scaleNote.midi % 12) ? .none : .fingeringSequenceBreak
                }
            }
            if hand == 1 {
                if scaleMotion == .contraryMotion {
                    if scaleNote.isWhiteKey() {
                        //scaleNote.fingerSequenceBreak = [4, 11].contains(scaleNote.midi % 12) ? false : true
                        scaleNote.keyboardColourType = [4, 11].contains(scaleNote.midi % 12) ? .none : .fingeringSequenceBreak
                    }
                }
                else {
                    //scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
                    scaleNote.keyboardColourType = scaleNote.isWhiteKey() ? .none : .fingeringSequenceBreak
                }
            }
        }
        for i in midway+1..<self.scaleNoteState[hand].count {
            let scaleNote = self.scaleNoteState[hand][i]
            if hand == 0 {
                //scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
                scaleNote.keyboardColourType = scaleNote.isWhiteKey() ? .none : .fingeringSequenceBreak
            }
            if hand == 1 {
                if scaleMotion == .contraryMotion {
                    //scaleNote.fingerSequenceBreak = !scaleNote.isWhiteKey()
                    scaleNote.keyboardColourType = scaleNote.isWhiteKey() ? .none : .fingeringSequenceBreak
                }
                else {
                    if scaleNote.isWhiteKey() {
                        //scaleNote.fingerSequenceBreak = [4, 11].contains(scaleNote.midi % 12) ? false : true
                        scaleNote.keyboardColourType = [4, 11].contains(scaleNote.midi % 12) ? .none : .fingeringSequenceBreak
                    }
                }
            }
        }
    }
    
    func getHighestSegment() -> Int {
        var max = 0
        for state in self.scaleNoteState[0] {
            let maxForState = state.segments.max()
            if let maxForState = maxForState {
                if maxForState > max {
                    max = maxForState
                }
            }
        }
        return max
    }
    
    func makeNewScale(offset:Int) -> Scale {
        let scale = Scale(scaleRoot: self.scaleRoot, scaleType: self.scaleType, scaleMotion: self.scaleMotion, octaves: self.octaves, hands: self.hands,
                          minTempo: self.minTempo, dynamicTypes: self.dynamicTypes, articulationTypes: self.articulationTypes)
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
            scaleOffsets = [4, 3, -3,   3, 5, -5,   5, 4, -4]
        case .brokenChordMinor:
            scaleOffsets = [3, 4, -4,   4, 5, -5,   5, 3, -3]
            
        case .trinityBrokenTriad:
            scaleOffsets = [4,3,-3,-4, 0]
        }
        return scaleOffsets
    }
    
    func needsTwoKeyboards() -> Bool {
        return self.hands.count > 1 //&& self.scaleMotion != .contraryMotion1
    }
    
    func getBackingChords() -> BackingChords? {
        if self.scaleNoteState.count == 0 {
            return nil
        }
        if self.scaleMotion == .contraryMotion {
            return nil
        }
        var backingChords:BackingChords? = nil
        if [.major, .melodicMinor, .harmonicMinor, .naturalMinor].contains(scaleType) {
            backingChords = BackingChords(scaleType: self.scaleType, hands: self.hands, octaves: self.octaves)
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(scaleType) {
            backingChords = BackingChords(scaleType: self.scaleType, hands: self.hands, octaves: self.octaves)
        }
        if [.arpeggioDiminished, .arpeggioDiminishedSeventh, .arpeggioMajor, .arpeggioMinor, .arpeggioMajorSeventh, .arpeggioMinorSeventh].contains(scaleType) {
            backingChords = BackingChords(scaleType: self.scaleType, hands: self.hands, octaves: self.octaves)
        }
        
        guard let backingChords = backingChords else {
            return nil
        }
        
        ///Transpose to scale's key
        var transposedChords = BackingChords(scaleType: self.scaleType)
        var rootPitch:Int
        rootPitch = self.scaleNoteState[0][0].midi
        
        for backingChord in backingChords.chords {
            var pitches = Array(backingChord.pitches)
            for i in 0..<pitches.count {
                pitches[i] += rootPitch
            }
            let transposedChord = BackingChords.BackingChord(pitches: pitches, value: backingChord.value, offset: 0)
            transposedChords.chords.append(transposedChord)
        }
        return transposedChords
    }
    
    func getScaleNoteCount() -> Int {
        return self.scaleNoteState[0].count
    }
    
    func abbreviateFileName(name:String) -> String {
        var out = name
        out = out.replacingOccurrences(of: "Harmonic", with: "Harm")
        out = out.replacingOccurrences(of: "Motion", with: "")
        out = out.replacingOccurrences(of: "Broken", with: "Br. ")
        return out
    }
    
    func debug1(_ msg:String, short:Bool=false)  {
        if !self.debugOn {
            //return
        }
        print("==========Scale  Debug \(msg)", scaleRoot.name, scaleType, "Hands:", self.hands, "octaves:", self.octaves,
              "motion:", self.scaleMotion)
        
        func getValue(_ value:Double?) -> String {
            if value == nil {
                return "None"
            }
            else {
                return String(format: "%.2f", value!)
            }
        }
        for handIndex in [0,1] {
            var idx = 0
            for state in self.scaleNoteState[handIndex] {
                print("Hand", handIndex, "idx:", String(format: "%2d", idx), "seg:", state.segments,
                      "\tMidi:", state.midi,  "value:",
                      String(format: "%.2f", state.value),
                      "finger:", state.finger,
                      "break:", state.keyboardColourType,
                      "matched:", state.matchedTime != nil
                )
                idx += 1
                if idx % 4 == 0 {
                    print()
                }
                if short {
                    break
                }
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
    
    func getStateForMidi(handType:HandType, midi:Int, scaleSegment:Int) -> ScaleNoteState? {
        let hand = handType == .right ? 0 : 1
        for state in self.scaleNoteState[hand] {
            for i in 0..<state.segments.count {
                if state.segments[i] == scaleSegment {
                    if state.midi == midi {
                        return state
                    }
                }
            }
        }
        return nil
    }
    func getTotalNoteValueInScale(handIndex:Int) -> Double {
        var total = 0.0
        for state in self.scaleNoteState[handIndex] {
            total += state.value
        }
        return total
    }
    
    ///Calculate finger sequence breaks
    ///Set descending as the key one below ascending break key
    private func setFingerBreaks(hand:Int) {
        for note in self.scaleNoteState[hand] {
            note.keyboardColourType = .none
        }
        
        let halfway = self.scaleNoteState[hand].count/2-1
        if hand == 0 {
            var lastFinger = self.scaleNoteState[hand][0].finger
            for i in 1...halfway {
                let finger = self.scaleNoteState[hand][i].finger
                let diff = abs(finger - lastFinger)
                if diff > 1 {
                    self.scaleNoteState[hand][i].keyboardColourType = .fingeringSequenceBreak
                    self.scaleNoteState[hand][self.scaleNoteState[hand].count - i].keyboardColourType = .fingeringSequenceBreak
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
                    self.scaleNoteState[hand][i+1].keyboardColourType = .fingeringSequenceBreak
                    let mirror = halfway + (halfway - i) + 2
                    if mirror < self.scaleNoteState[hand].count - 1 {
                        self.scaleNoteState[hand][mirror].keyboardColourType = .fingeringSequenceBreak
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
    
    func getHandStartMidis() -> [Int] {
        if hands.count > 1 {
            return [self.scaleNoteState[1][0].midi, self.scaleNoteState[0][0].midi]
        }
        else {
            if hands[0] == 1 {
                return [self.scaleNoteState[1][0].midi]
            }
            else {
                return [self.scaleNoteState[0][0].midi]
            }
        }
    }
    
    
    func getMinMaxMidis() -> (Int, Int) {
        var min = 0
        var max = 0
        if self.hands.count == 1 {
            let handIndex = self.hands[0]
            let states = self.scaleNoteState[handIndex]
            if let m = states.min(by: { $0.midi < $1.midi })?.midi {
                min = m
            }
            if let m = states.max(by: { $0.midi < $1.midi })?.midi {
                max = m
            }
        }
        else {
            let statesLH = self.scaleNoteState[self.hands[self.hands[1]]]
            if let m = statesLH.min(by: { $0.midi < $1.midi })?.midi {
                min = m
            }
            let statesRH = self.scaleNoteState[self.hands[self.hands[0]]]
            if let m = statesRH.max(by: { $0.midi < $1.midi })?.midi {
                max = m
            }
        }
        return (min, max)
    }
    
    func getMidisInScale(handIndex:Int) -> [Int] {
        var notes:[Int] = []
        for note in self.scaleNoteState[handIndex] {
            notes.append(note.midi)
        }
        return notes
    }
    
    func getStatesInScale(handIndex:Int) -> [ScaleNoteState] {
        var states:[ScaleNoteState] = []
        for note in self.scaleNoteState[handIndex] {
            states.append(note)
        }
        return states
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
        var rightHandLastFingerJump = 1 ///For RH - what finger jump for highest note.
        var fingeringSpecifiedByNote:[Int]? =  nil
        if self.debugOn {
            
        }
        ///Regular scale
        let defaultfingers = "1231234"
        
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
                    if scaleType == .harmonicMinor {
                        fingers = hand == 0 ? "3412312" : "4123123"
                    }
                    else {
                        if hand == 0 {
                            fingeringSpecifiedByNote = [2,3,1,2,  3,4,1,2,  3,1,2,3,  4,1,3,2,  1,3,2,1, 4,3,2,1,  3,2,1,3, 2]
                        }
                        else {
                            fingers = "4123123"
                        }
                    }
                }
            case "G♭":
                if scaleType == .major {
                    fingers = hand == 0 ? "2341231" : "4123123"
                }
                else {
                    fingers = hand == 0 ? "2312341" : "4123123"
                }
                //            case "F#":
                //                ///Variants beside melodic minor can default
                //                if scaleType == .melodicMinor {
                //                    fingers = hand == 0 ? "2312341" : "4123123"
                //                }
            case "G#":
                fingers = hand == 0 ? "3412312" : "212341231234123"
                if scaleType == .melodicMinor {
                    ///Cannot use any formula since the melodic down direction changes white note to black and forces a new fingering throughout the descending.
                    ///Not required for G# harmonic (or major)
                    if hand == 1 {
                        fingeringSpecifiedByNote = [3,2,1, 4,3,2,1,  3,2,1, 4,3,2,1, 2,  3,1, 2,3,1, 2,3,4,1, 2,3,1,  2,3]
                    }
                }
                leftHandLastFingerJump = 0
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
                    if hand == 0 {
                        if scaleType == .melodicMinor {
                            fingeringSpecifiedByNote = [2,3,1,2,  3,4,1,2,  3,1,2,3,  4,1,3,2,  1,3,2,1,  4,3,2,1, 3,2,1,3, 2]
                        }
                        else {
                            fingeringSpecifiedByNote = [2,3,1,  2,3,1,  2,3,4, 1,2,3, 1,2,3, 2,1,  3,2,1, 4,3,2,1, 3,2,1, 3,2  ]
                        }
                    }
                }
            default:
                fingers = ""
            }
        }
        if fingers.count == 0 {
            fingers = defaultfingers
        }
        
        ///Three note arpeggio
        
        if scaleShapeForFingering == .arpgeggio {
            if self.debugOn {
            }
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
                    //leftHandLastFingerJump =
                    fingers = hand == 0 ? "123" : "124"
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
            case "F#":
                fingers = hand == 0 ? "412" : "241"
            case "C#":
                fingers = hand == 0 ? "412" : "241"
            case "G#":
                fingers = hand == 0 ? "412" : "241"
            case "B♭":
                if [.major, .arpeggioMajor].contains(scaleType) {
                    if hand == 0 {
                        fingeringSpecifiedByNote = [2, 1,2,4, 1,2,4, 2,1, 4,2,1,2]
                    }
                    else {
                        fingeringSpecifiedByNote = [3,2,1,  3,2,1, 2,  1,2,3, 1,2,3]
                    }
                }
                else {
                    if debugOn {
                    }
                    rightHandLastFingerJump = 0 ///Match Trinity forr Gr 5
                    fingers = hand == 0 ? "231" : "312"
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
            fingers = hand == 0 ? "135125135" : "531531521"
        }
        
        /// Set fingering now given the finger sequence
        if self.debugOn {
        }
        
        var handled = false
        if scaleType == .chromatic {
            applyChromaticFingers()
            handled = true
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(scaleType) {
            applyBrokenChordFingers()
            handled = true
        }
        if [.trinityBrokenTriad].contains(scaleType) {
            fingeringSpecifiedByNote = [1,2,4, 2,1]
            handled = true
        }
        
        ///Fingering is simply the fingers in the specified array
        if let fingeringSpecifiedByNote = fingeringSpecifiedByNote {
            if fingeringSpecifiedByNote.count != self.scaleNoteState[hand].count {
                fatalError("Wrong fingering count. Specified:\(fingeringSpecifiedByNote.count) scale:\(scaleNoteState[hand].count)")
            }
            for f in 0..<fingeringSpecifiedByNote.count {
                self.scaleNoteState[hand][f].finger = fingeringSpecifiedByNote[f]
            }
            handled = true
        }
        
        if !handled {
            ///Apply the regular (as defined above) finger patterns for ascending and descending. The finger pattern used is the pattern for the right hand ascending.
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
            
            ///For scales starting on a black note adjust the first and last finger to 2
            if hand == 0 || (hand == 1 && self.scaleMotion == .contraryMotion) {
                ///All RH scales and arpggeios starting on black note have first finger = 2
                ///But only the first, after that revert to the regular fingering from the pattern.
                for n in 0..<scaleNoteState[0].count-1 {
                    let state = self.scaleNoteState[hand][n]
                    if state.isWhiteKey() {
                        break
                    }
                    else {
                        state.finger = 2 + n
                        let lastNote = self.scaleNoteState[hand].count-n-1
                        self.scaleNoteState[hand][lastNote].finger = 2 + n
                    }
                }
            }
            if hand == 1 && (self.scaleMotion != .contraryMotion){
                ///All LH scales and arpggeios highest on a black note have first finger 2 on that high note
                let state = self.scaleNoteState[hand][halfway]
                let startsOnBlack = !state.isWhiteKey()
                if startsOnBlack {
                    scaleNoteState[hand][halfway].finger = 2
                }
            }
            
        }
        
        func setFinger(hand:Int, index:Int, finger:Int) {
            scaleNoteState[hand][index].finger = finger
        }
        
        func applyFingerPatternToScaleStart(halfway:Int) {
            var f = 0
            ///The ascending section
            for i in 0..<halfway {
                let finger = stringIndexToInt(index: i, fingers: fingers)
                setFinger(hand: hand, index: i, finger: finger)
                f += 1
            }
            f -= 1
            if debugOn {
            }
            var highNoteFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers) + 1
            if scaleShapeForFingering == .arpgeggio {
                if highNoteFinger < 5 {
                    highNoteFinger += rightHandLastFingerJump
                }
            }
            scaleNoteState[hand][halfway].finger = highNoteFinger
            
            ///The descending section
            setFinger(hand: hand, index: halfway, finger: highNoteFinger)
            for i in (halfway+1..<scaleNoteState[hand].count) {
                //scaleNoteState[hand][i].finger = stringIndexToInt(index: f, fingers: fingers)
                setFinger(hand: hand, index: i, finger: stringIndexToInt(index: f, fingers: fingers))
                f -= 1
            }
        }
        
        func applyFingerPatternToScaleMiddle(halfway:Int) {
            ///RULE: All LH scales starting on a black note have finger 2 as their highest note.
            let firstNote = self.scaleNoteState[hand][0]
            var f = 0
            ///For LH - start at the start of the LH scale then count forwards through fingers pattern. Work backwards down the scale and then mirror the fingering around the high note.
            for i in stride(from: halfway, through: 0, by: -1) {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: f, fingers: fingers)
                if ![.brokenChordMajor, .brokenChordMinor].contains(scaleType) {
                    scaleNoteState[hand][i + 2*f].finger = stringIndexToInt(index: f, fingers: fingers)
                }
                f += 1
            }
            
            //if startsOnBlack {
            ///Highest note
            //                scaleNoteState[hand][halfway].finger = 2
            //}
            
            if leftHandLastFingerJump > 0  {
                ///Adjust last note played
                let nextToLastFinger = stringIndexToInt(index: fingers.count - 1, fingers: fingers)
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
        
        func applyBrokenChordFingers() {
            let halfway = (scaleNoteState[hand].count / 2) - 1
            for i in 0..<halfway {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: i, fingers: fingers)
            }
            let longNoteFinger = stringIndexToInt(index: halfway-2, fingers: fingers)
            scaleNoteState[hand][halfway].finger = longNoteFinger
            let fingersReversed = String(fingers.reversed())
            var ctr = 0
            for i in halfway+1..<scaleNoteState[hand].count {
                scaleNoteState[hand][i].finger = stringIndexToInt(index: ctr, fingers: fingersReversed)
                ctr += 1
            }
        }
    }
    
    func getRequiredValuePerBar() -> Int {
        //return [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) ? 24 : 4
        return [.brokenChordMajor, .brokenChordMinor].contains(self.scaleType) ? 1 : 4
    }
    
    func getScaleName(showHands:Bool=true, handFull:Bool, octaves:Bool? = nil) -> String {
        var name = scaleRoot.name + " " + scaleType.description
        if scaleMotion == .contraryMotion {
            name += " " + scaleMotion.description
        }
        if showHands {
            if self.scaleMotion != .contraryMotion {
                if self.hands.count == 1 {
                    var handName = ""
                    if handFull {
                        switch self.hands[0] {
                        case 0: handName = "Right Hand"
                        case 1: handName = "Left Hand"
                        default: handName = "Together"
                        }
                    }
                    else {
                        switch self.hands[0] {
                        case 0: handName = "RH"
                        case 1: handName = "LH"
                        default: handName = "Together"
                        }
                    }
                    //name += ", " + handName
                    name += " " + handName
                }
                else {
                    //name += handFull ? ", Together" : ", Together"
                    name += " Together" //handFull ? " Together" : " Together"
                }
            }
        }
        if let octaves = octaves {
            if octaves {
                name += ", \(self.octaves) \(self.octaves > 1 ? "Octaves" : "Octave")"
            }
        }
        return name
    }
    
    ///Firebase Realtime causes exception with a label with a '#'
    func getScaleIdentificationKey() -> String {
        var key = self.getScaleName(handFull: false, octaves: true)
        key = key.replacingOccurrences(of: "#", with: "Sharp")
        key = key.replacingOccurrences(of: " ", with: "_")
        key = key.replacingOccurrences(of: ",", with: "")
        return key
    }
    
    func getScaleDescriptionParts(name:Bool? = nil, hands:Bool?=nil, octaves:Bool? = nil, tempo:Bool? = nil, dynamics:Bool? = nil) -> String {
        var description = ""
        if let name = name {
            description = scaleRoot.name + " " + scaleType.description
            if scaleMotion == .contraryMotion {
                description += " " + scaleMotion.description
            }
        }
        if let hands = hands {
            //if self.scaleMotion != .contraryMotion {
                if self.hands.count == 1 {
                    var handName = ""
                    if true {
                        switch self.hands[0] {
                        case 0: handName = "Right Hand"
                        case 1: handName = "Left Hand"
                        default: handName = "Together"
                        }
                    }
                    else {
                        switch self.hands[0] {
                        case 0: handName = "RH"
                        case 1: handName = "LH"
                        default: handName = "Together"
                        }
                    }
                    description = handName
                }
                else {
                    description = "Together"
                }
            //}
        }
        if let octaves = octaves {
            if octaves {
                description = "\(self.octaves) \(self.octaves > 1 ? "Octaves" : "Octave")"
            }
        }
        if let tempo = tempo {
            description = "\u{2669}"
            if self.timeSignature.top % 3 == 0 {
                description += String("\u{00B7}")
                description += " "
            }
            description += "=\(self.minTempo)"
        }
        if let dynamics = dynamics {
            var d = 0
            description = ""
            for dynamic in self.dynamicTypes {
                if d > 0 {
                    description += " or "
                }
                if false { //&& long {
                    description += String(dynamic.description)
                }
                else {
                    description += String(dynamic.descriptionShort)
                }
                d += 1
            }
        }
        return description
    }
    
    func getScaleAttributes(showTempo:Bool) -> String {
        var name = ""
        if showTempo {
            name += "\(self.minTempo) BPM, "
        }
        var d = 0
        for dynamicType in self.dynamicTypes {
            if d > 0 {
                name += ","
            }
            name += "\(dynamicType.description)"
            d += 1
        }
        d = 0
        for articulationType in self.articulationTypes {
            if d > 0 {
                name += ","
            }
            name += "\(articulationType.description)"
            d += 1
        }
        return name
    }
    
    func getHandsImageName() -> String {
        if hands.isEmpty {
            return ""
        }
        if self.hands.count == 2 {
            return "figma_hands_together"
        }
        else {
            return self.hands[0] == 0 ? "figma_right_hand" : "figma_left_hand"
        }
    }
    
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
            
        case "Dominant 7th Arpeggio":
            return ScaleType.arpeggioDominantSeventh
        case "Major 7th Arpeggio":
            return ScaleType.arpeggioMajorSeventh
        case "Minor 7th Arpeggio":
            return ScaleType.arpeggioMinorSeventh
        case "Diminished Arpeggio":
            return ScaleType.arpeggioDiminished
        case "Diminished 7th Arpeggio":
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
