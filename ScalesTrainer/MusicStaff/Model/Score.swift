import Foundation
import AVKit
import AVFoundation

//public enum StaffType {
//    case bass
//    case treble
//}

public class RhythmTolerance {
    static func getTolerancePercent(_ setting:Int) -> Double {
//        switch setting {
//        case 0:
//            return 38.0
//            //return 30.0
//        case 1:
//            return 47.0
//        case 2:
//            return 56.0
//        default:
//            return 65.0
//        }        switch setting {
        switch setting {
            case 0:
                return 34.0
            case 1:
                return 43.0
            case 2:
                return 55.0
            default:
                return 65.0
            }
    }
    
    static public func getToleranceName(_ setting:Int) -> String {
        switch setting {
        case 0:
            return "Hardest"
        case 1:
            return "Hard"
        case 2:
            return "Moderate"
        case 3:
            return "Easy"
        default:
            return "Unknown"
        }
    }
}

public class ScoreEntry : ObservableObject, Identifiable, Hashable {
    public let id = UUID()
    var sequence:Int = 0

    public static func == (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public func getTimeSliceEntries(notesOnly:Bool?) -> [TimeSliceEntry] {
        var result:[TimeSliceEntry] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                if let notesOnly = notesOnly {
                    if notesOnly {
                        if entry is StaffNote {
                            result.append(entry)
                        }
                    }
                }
                else {
                    result.append(entry)
                }
            }
        }
        return result
    }
    
    public func getTimeSliceNotes(handType:HandType?) -> [StaffNote] {
        var result:[StaffNote] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                if entry is StaffNote {
                    let note = entry as! StaffNote
                    if let handType = handType {
                        if (note.handType == handType) {
                            result.append(note)
                        }
                    }
                    else {
                        result.append(note)
                    }
                }
            }
        }
        return result
    }
    
    public func getTimeSliceNotesForClef(clef:StaffClef?) -> [StaffNote] {
        var result:[StaffNote] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                if entry is StaffNote {
                    let note = entry as! StaffNote
                    if let clef = clef {
                        if (note.clef == clef) {
                            result.append(note)
                        }
                    }
                    else {
                        result.append(note)
                    }
                }
            }
        }
        return result
    }
}

public class StudentFeedback : ObservableObject {
    public var correct:Bool = false
    public var feedbackExplanation:String? = nil
    public var feedbackNotes:String? = nil
    public var tempo:Int? = nil
    public var rhythmTolerance:Int? = nil
}

public class Score : ObservableObject {
    let id:UUID
    
    private let scale:Scale
    public var timeSignature:TimeSignature
    public var key:StaffKey
    
    @Published public var scoreEntries:[ScoreEntry] = []
    public var staffs:[Staff] = [] ///0 is treble, 1 is bass

    @Published public var barLayoutPositions:BarLayoutPositions

    let ledgerLineCount =  2 //3//4 is required to represent low E
    
    public var studentFeedback:StudentFeedback? = nil
    public var tempo:Int?
    
    ///NB Changing this needs changes to getBraceHeight() for alignment
    public var lineSpacing:Double

    private var totalStaffLineCount:Int = 0
//    static var accSharp1 = "\u{266f}"
//    static var accNatural1 = "\u{266e}"
//    static var accFlat = "\u{266d}"
    public var label:String? = nil
    public var heightPaddingEnabled:Bool
    let showTempoVariation:Bool = false
    
    public init(scale:Scale, key:StaffKey, timeSignature:TimeSignature, linesPerStaff:Int, heightPaddingEnabled:Bool = true) {
        self.id = UUID()
        self.scale = scale
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.lineSpacing = 8.0
        }
        else {
            self.lineSpacing = scale.hands.count > 1 ? 8.0 : 10
        }
        self.timeSignature = timeSignature
        totalStaffLineCount = linesPerStaff + (2*ledgerLineCount)
        self.key = key
        barLayoutPositions = BarLayoutPositions()
        self.heightPaddingEnabled = heightPaddingEnabled
    }
    
    func getBraceHeight() -> Double {
        let heightMult:Double
        if UIDevice.current.userInterfaceIdiom == .phone {
            heightMult = scale.hands.count > 1 ? 1.47 : 1.54
        }
        else {
            heightMult = scale.hands.count > 1 ? 1.47 : 1.54
        }
        return getStaffHeight() * heightMult
    }
        
    public func hilightStaffNote(segment: Int, midi: Int, handType:HandType?) {
        let timeSlices = getAllTimeSlices()
        var staffNoteFound:StaffNote?

        for i in 0..<timeSlices.count {
            let ts = timeSlices[i]
            let timeSliceNotes = ts.getTimeSliceNotes(handType: handType)
            for staffNote in timeSliceNotes {
                if staffNote.midiNumber == midi && staffNote.segments[0] == segment {
                    staffNote.setShowIsPlaying(true)
                    staffNoteFound = staffNote
                    DispatchQueue.global(qos: .background).async {
                        usleep(UInt32(1000000 * PianoKeyModel.keySoundingSeconds))
                        DispatchQueue.main.async {
                            staffNote.setShowIsPlaying(false)
                        }
                    }
                    break
                }
            }
            if staffNoteFound != nil {
                break
            }
        }
    }
    
    public func createTimeSlice() -> TimeSlice {
        let ts = TimeSlice(score: self)
        ts.sequence = self.scoreEntries.count
        self.scoreEntries.append(ts)
        if self.scoreEntries.count > 16 {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ///With too many notes on the stave
                lineSpacing = lineSpacing * 0.95
            }
        }
        return ts
    }

    public func getStaffHeight() -> Double {
        //let height = Double(getTotalStaffLineCount() + 3) * self.lineSpacing ///Jan2024 Leave room for notes on more ledger lines
        ///9Nov24 - Trinity E minor LH broken chords needs 3 ledger lines aboave staff ☹️
        let height = Double(getTotalStaffLineCount() + 2) * self.lineSpacing ///Jan2024 Leave room for notes on more ledger lines
        return height
    }
    
    public func getBarCount() -> Int {
        var count = 0
        for entry in self.scoreEntries {
            if entry is BarLine {
                count += 1
            }
        }
        return count + 1
    }
        
    public func getTotalStaffLineCount() -> Int {
        return self.totalStaffLineCount
    }
    
    public func getAllTimeSlices() -> [TimeSlice] {
        var result:[TimeSlice] = []
        for scoreEntry in self.scoreEntries {
            if scoreEntry is TimeSlice {
                let ts = scoreEntry as! TimeSlice
                result.append(ts)
            }
        }
        return result
    }
    
    public func getTimeSliceForMidi(midi:Int, occurence:Int) -> TimeSlice? {
        let ts = getAllTimeSlices()
        var cnt = 0
        var result:TimeSlice?
        for timeSlice in ts {
            //for staffType in [StaffType.treble, StaffType.bass] {
            for handType in [HandType.right,HandType.left] {
                let ns = timeSlice.getTimeSliceNotes(handType:handType)
                if ns.count > 0 {
                    let note = ns[0]
                    if note.midiNumber == midi {
                        if cnt == occurence {
                            result = timeSlice
                            break
                        }
                        cnt += 1
                    }
                }
            }
        }
        return result
    }
    
    public func getTimeSlicesForBar(bar:Int) -> [TimeSlice] {
        var result:[TimeSlice] = []
        var barNum = 0
        for scoreEntry in self.scoreEntries {
            if scoreEntry is BarLine {
                barNum += 1
                continue
            }
            if barNum == bar {
                if let ts = scoreEntry as? TimeSlice {
                    result.append(ts)
                }
            }
        }
        return result
    }

    public func debug11(_ ctx:String, withBeam:Bool, toleranceLevel:Int) {
        let tolerance = RhythmTolerance.getTolerancePercent(toleranceLevel)
        print("\nSCORE DEBUG =====", ctx, "\tKey", key.getKeyName(withType: true)
              //"StaffCount", self.staffs.count,
//                "toleranceLevel:\(toleranceLevel)",
//                "toleranceLevel:\(tolerance)"
        )
        for entry in self.scoreEntries {
            if let timeSlice = entry as? BarLine {
                print("------------- Bar line", timeSlice.sequence)
                continue
            }
            if let timeSlice = entry as? StaffClef {
                print("------------- Staff Clef", timeSlice.sequence, timeSlice.clefType)
                continue
            }

            if let timeSlice = entry as? TimeSlice {
                print("TimeSlice, ", terminator: "")
                print("Seq", String(format: "%2d", timeSlice.sequence), terminator: "")
                print()
                for entryIndex in 0..<timeSlice.entries.count {
                    let entry = timeSlice.entries[entryIndex]
                    if let note = entry as? StaffNote {
                        if withBeam {
                            print(
                                //"type:", type(of: timeSlice.entries[0]),
                                "  midi:", note.midiNumber,
                                //"valuePoint:", String(format: "%.2f", timeSlice.valuePoint),
                                "[value:", String(format: "%.2f", timeSlice.getValue()),"]",
                                "[clef:", note.clef?.clefType ?? "_","]",
                                "[offset:", String(note.noteStaffPlacement.offsetFromStaffMidline),"]",
                                "[segments:", note.segments,"]",
                                //"[duration:", timeSlice.tapDurationNormalised ?? "_","]",
                                "[direction", note.stemDirection,"]",
                                "[stemLength", note.stemLength,"]",
                                "[accidental", note.writtenAccidental ?? 0,"]",
                                "[beamType:", note.beamType,"]",
                                //"[beamEndNoteSeq:", note.beamEndNote?.timeSlice.sequence ?? "_",
                                "]")
                        }
                        else {
                            print("  ", terminator: "")
                            print("Note#", String(format: "%2d", entryIndex), terminator: "")
                            //print(" [type:", type(of: timeSlice.entries[0]), "]", terminator: "")
                            print(" [midi:",note.midiNumber, "]", terminator: "")
                            //print(" [TapDuration Seconds:",String(format: "%.4f", timeSlice.tapDurationNormalised ?? 0),"]", timeSlice.sequence, terminator: "")
                            print(" [Note Value:", String(format: "%.2f", note.getValue()),"]", timeSlice.sequence, terminator: "")
                            print(" [Segments:", note.segments,"]", timeSlice.sequence, terminator: "")
                            print(" [status]",timeSlice.statusTag, terminator: "")
                            //print(" [beat]",timeSlice.valuePoint, timeSlice.sequence, terminator: "")
                            //print(" [writtenAccidental:",note.writtenAccidental ?? "","]", t.sequence, terminator: "")
                            
                            let note = timeSlice.entries[entryIndex] as! StaffNote
                            print("\thand:", note.handType, terminator: "")
                            print(",\toffset:", note.noteStaffPlacement.offsetFromStaffMidline, terminator: "")
                            print(", accidental:", note.noteStaffPlacement.accidental ?? " ", terminator: "")
                            
                            //print("[Staff:",note.staffNum,"]" t.sequence, terminator: "")
                            print()
                        }
                    }
                    else {
                        //let rest = t.
                        print("  Seq", timeSlice.sequence,
                              "[Type:", type(of: timeSlice.entries[0]), "]",
                              "[Rest:","R ", "]",
                              "[TapDuration Seconds:",String(format: "%.4f", timeSlice.tapDurationNormalised ?? 0),"]",
                              "[NoteValue:", timeSlice.getValue(),"]",
                              "[Status]",timeSlice.statusTag,
                              "[StartAtValue]",timeSlice.valuePoint,
                              "[Beat]",timeSlice.valuePointInBar,
                              "[WrittenAccidental:","_","]",
                              "[Staff:","_","]"
                        )
                    }
                }
            }
        }
    }

//    public func getLastTimeSlice1() -> TimeSlice? {
//        var ts:TimeSlice?
//        for index in stride(from: scoreEntries.count - 1, through: 0, by: -1) {
//            let element = scoreEntries[index]
//            if element is TimeSlice {
//                ts = element as? TimeSlice
//                break
//            }
//        }
//        return ts
//    }    
    
//    public func getLastNoteTimeSlice() -> TimeSlice? {
//        var result:TimeSlice?
//        for index in stride(from: scoreEntries.count - 1, through: 0, by: -1) {
//            let entry = scoreEntries[index]
//            if let ts = entry as? TimeSlice {
//                if ts.getTimeSliceNotes().count > 0 {
//                    result = ts
//                    break
//                }
//            }
//        }
//        return result
//    }

    public func updateStaffs() {
        for staff in staffs {
            staff.update()
        }
    }
    
    public func addStaff(staff:Staff) {
//        if self.staffs.count <= num {
//            self.staffs.append(staff)
//        }
//        else {
//            self.staffs[num] = staff
//        }
        self.staffs.append(staff)
    }
    
    public func getStaffs() -> [Staff] {
        return self.staffs
    }
    
    public func addBarLine(visibleOnStaff:Bool, forStaffSpacing: Bool) {
        let barLine = BarLine(visibleOnStaff: visibleOnStaff, forStaffSpacing: forStaffSpacing)
        barLine.sequence = self.scoreEntries.count
        self.scoreEntries.append(barLine)
    }
    
    public func addStaffClef(clefType:ClefType, atValuePosition:Double) {
        //let clef = StaffClef(score:self, clefType: clefType, isVisible: isVisible)
        var totalValue = 0.0
        for i in 0..<self.scoreEntries.count {
            if self.scoreEntries[i] is TimeSlice {
                if atValuePosition == totalValue {
                    self.scoreEntries.insert(StaffClef(score: self, clefType: clefType), at: i)
                    break
                }
                let timeslice = self.scoreEntries[i] as! TimeSlice
                totalValue += timeslice.getValue()
            }
        }
    }
    
    public func getEntryForSequence(sequence:Int) -> ScoreEntry? {
        for entry in self.scoreEntries {
            if entry.sequence == sequence {
                return entry
            }
        }
        return nil
    }
    
    ///Determine if the stem for the note(s) should go up or down
    func getStemDirection(clef:StaffClef, notes:[StaffNote]) -> StemDirection {
        var totalOffsets = 0
        for n in notes {
            //if n.staffNum == staff.staffNum {
                let placement = clef.getNoteViewPlacement(note: n)
                totalOffsets += placement.offsetFromStaffMidline
            //}
        }
        return totalOffsets <= 0 ? StemDirection.up: StemDirection.down
    }
    
//    func addStemAndBeamCharaceteristics(staff:Staff) {
//        guard let timeSlice = self.getLastNoteTimeSlice() else {
//            return
//        }
//        if timeSlice.entries.count == 0 {
//            return
//        }
//        setTimesliceStartAtValues()
//        if timeSlice.entries[0] is StaffNote {
//            addStemCharaceteristics(staff: staff)
//        }
//    }
    
    ///For each time slice calculate its beat number in its bar
    func setTimesliceStartAtValues() {
        var barTotalValue = 0.0
        var totalValue = 0.0
        ///For broken chords its 3 1/8 notes per quaver group
        let maxGroupValue = [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType) ? 1.0 : 2.0
        let rangeMin  = maxGroupValue * 0.99
        let rangeMax  = maxGroupValue * 1.01
        
        for i in 0..<self.scoreEntries.count {
            if self.scoreEntries[i] is BarLine {
                //beatCtr = 0
                continue
            }
            if barTotalValue >= rangeMin && barTotalValue <= rangeMax {
                barTotalValue = 0
            }
            if let timeSlice = self.scoreEntries[i] as? TimeSlice {
                timeSlice.valuePointInBar = barTotalValue
                timeSlice.valuePoint = totalValue
                barTotalValue += timeSlice.getValue()
                totalValue += timeSlice.getValue()
            }
        }
    }
    
    private func determineStemDirections(clef:StaffClef, notesUnderBeam:[StaffNote], linesForFullStemLength:Double) {
        ///Determine if the quaver group has up or down stems based on the overall staff placement of the group
        var totalOffset = 0
        for note in notesUnderBeam {
            let placement = clef.getNoteViewPlacement(note: note)
            totalOffset += placement.offsetFromStaffMidline
        }
        
        ///Set each note's beam type and calculate the nett above r below the staff line for the quaver group (for the subsequnet stem up or down decison)
        let startNote = notesUnderBeam[0]
        let startPlacement = clef.getNoteViewPlacement(note: startNote)

        let endNote = notesUnderBeam[notesUnderBeam.count - 1]
        let endPlacement = clef.getNoteViewPlacement(note: endNote)

        var beamSlope:Double = Double(endPlacement.offsetFromStaffMidline - startPlacement.offsetFromStaffMidline)
        beamSlope = beamSlope / Double(notesUnderBeam.count - 1)

        var requiredBeamPosition = Double(startPlacement.offsetFromStaffMidline)
        
        //The number of staff lines for a full stem length
        
        var minStemLength = linesForFullStemLength
        
        for i in 0..<notesUnderBeam.count {
            let note = notesUnderBeam[i]
            if i == 0 {
                //note.beamType = .end
                note.stemLength = linesForFullStemLength
            }
            else {
                if i == notesUnderBeam.count-1 {
                    //note.beamType = .start
                    note.stemLength = linesForFullStemLength
                }
                else {
                    //note.beamType = .middle
                    let placement = clef.getNoteViewPlacement(note: note)
                    ///adjust the stem length according to where the note is positioned vs. where the beam slope position requires
                    let stemDiff = Double(placement.offsetFromStaffMidline) - requiredBeamPosition
                    note.stemLength = linesForFullStemLength + (stemDiff / 2.0 * (totalOffset > 0 ? 1.0 : -1.0))
                    if note.stemLength < minStemLength {
                        minStemLength = note.stemLength
                    }
                }
            }
            requiredBeamPosition += beamSlope
            note.stemDirection = totalOffset > 0 ? .down : .up
        }
        
        if minStemLength < 2 {
            let delta = 3 - minStemLength
            for i in 0..<notesUnderBeam.count {
                let note = notesUnderBeam[i]
                note.stemLength += delta
            }
        }
    }
    
    ///Determine whether quavers can be beamed within a bar's strong and weak beats
    ///StartBeam is the possible start of beam, lastBeat is the end of beam
    ///hand is 0 for the RH staff and 1 for the LH staff
    ///staff is the staff clef that is present just prior to the startEntryIndex, endEntryIndex set of notes, irrespective of being called on the LH or RH staff
    ///endEntryIndex is inclusive
    public func addStemCharacteristics(handType:HandType, clef:StaffClef, startEntryIndex:Int, endEntryIndex:Int) {
        
        func setStem(timeSlice:TimeSlice, beamType:QuaverBeamType, linesForFullStemLength:Double) {
            let staffNotes = timeSlice.getTimeSliceNotes(handType: handType)
            //let stemDirection = StemDirection.up
            let stemDirection = getStemDirection(clef: clef, notes: staffNotes)
            
            for note in staffNotes {
                note.stemDirection = stemDirection
                note.stemLength = linesForFullStemLength
                note.beamType = beamType
                ///Dont try yet to beam semiquavers
            }
        }
        
        ///Set the beam states of the notes and empty the notes under beam bucket
        func setNotesUnderBeam(timeSlicesUnderBeam:[TimeSlice], linesForFullStemLength:Double) -> [TimeSlice] {
            if timeSlicesUnderBeam.count == 0 {
                return []
            }
            for i in 0..<timeSlicesUnderBeam.count {
                if i == 0 {
                    if timeSlicesUnderBeam.count == 1 {
                        setStem(timeSlice: timeSlicesUnderBeam[i], beamType: .none, linesForFullStemLength: linesForFullStemLength)
                    }
                    else {
                        setStem(timeSlice: timeSlicesUnderBeam[i], beamType: .start, linesForFullStemLength: linesForFullStemLength)
                    }
                }
                else {
                    if i == timeSlicesUnderBeam.count - 1 {
                        setStem(timeSlice: timeSlicesUnderBeam[i], beamType: .end, linesForFullStemLength: linesForFullStemLength)
                    }
                    else {
                        setStem(timeSlice: timeSlicesUnderBeam[i], beamType: .middle, linesForFullStemLength: linesForFullStemLength)
                    }
                }
            }
            return []
        }
        
        enum InBeamState {
            case noBeam
            case beamStarted
        }

        var timeSlicesUnderBeam:[TimeSlice] = []
        let linesForFullStemLength = 3.5
        
        ///Group quavers under quaver beams
        for scoreEntryIndex in startEntryIndex...endEntryIndex {
            let scoreEntry = self.scoreEntries[scoreEntryIndex]
            guard scoreEntry is TimeSlice else {
                timeSlicesUnderBeam = setNotesUnderBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }
            let timeSlice = scoreEntry as! TimeSlice
            if timeSlice.getTimeSliceNotes(handType: handType).count == 0 {
                timeSlicesUnderBeam = setNotesUnderBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }
            
            let note = timeSlice.getTimeSliceNotes(handType: handType)[0] //.entries[handIndex]

            if ![StaffNote.VALUE_QUAVER, StaffNote.VALUE_TRIPLET].contains(note.getValue())  {
                setStem(timeSlice: timeSlice, beamType: .none, linesForFullStemLength: linesForFullStemLength)
                timeSlicesUnderBeam = setNotesUnderBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }
            
            if timeSlice.valuePointInBar == 0 {
                timeSlicesUnderBeam = setNotesUnderBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                timeSlicesUnderBeam.append(timeSlice)
            }
            else {
                if timeSlicesUnderBeam.count > 0 {
                    timeSlicesUnderBeam.append(timeSlice)
                }
                else {
                    setStem(timeSlice: timeSlice, beamType: .none, linesForFullStemLength: linesForFullStemLength)
                }
            }
        }
        timeSlicesUnderBeam = setNotesUnderBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
        
        ///Join up adjoining beams where possible. Existing beams only span one main beat and can be joined in some cases
        if false { ///10Nov2024 - does not appear to do anything?
            var lastNote:StaffNote? = nil
            for scoreEntryIndex in startEntryIndex...endEntryIndex {
                let scoreEntry = self.scoreEntries[scoreEntryIndex]
                guard let timeSlice = scoreEntry as? TimeSlice else {
                    lastNote = nil
                    continue
                }
                if timeSlice.getTimeSliceNotes(handType: handType).count == 0 {
                    lastNote = nil
                    continue
                }
                let note = timeSlice.getTimeSliceNotes(handType: handType)[0]
                if note.beamType == .none {
                    lastNote = nil
                    continue
                }
                if false {
                    if note.beamType == .start {
                        if let lastNote = lastNote {
                            if lastNote.beamType == .end {
                                var timeSigAllowsJoin = true
                                if timeSignature.top == 4 {
                                    /// 4/4 beats after 2nd cannot join to earlier beats
                                    let beat = Int(note.timeSlice.valuePointInBar)
                                    let startBeat = Int(lastNote.timeSlice.valuePointInBar)
                                    timeSigAllowsJoin = beat < 2 || (startBeat >= 2)
                                }
                                if timeSigAllowsJoin {
                                    lastNote.beamType = .middle
                                    note.beamType = .middle
                                }
                            }
                        }
                    }
                }
                lastNote = note
            }
        }
        
        ///Determine stem directions for each quaver beam
        
        var notesUnderBeam:[StaffNote] = []
        for scoreEntryIndex in startEntryIndex...endEntryIndex {
            let scoreEntry = self.scoreEntries[scoreEntryIndex]
            guard let timeSlice = scoreEntry as? TimeSlice else {
                //lastNote = nil
                continue
            }
            if timeSlice.getTimeSliceNotes(handType: handType).count == 0 {
                //lastNote = nil
                continue
            }
            let note = timeSlice.getTimeSliceNotes(handType: handType)[0]
            if note.beamType != .none {
                notesUnderBeam.append(note)
                if note.beamType == .end {
                    //let staff = self.staffs[note.staffType == .treble ? 0 : 1]
                    determineStemDirections(clef:clef, notesUnderBeam: notesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                    notesUnderBeam = []
                }
            }
        }
    }
        
    public func isNextTimeSliceANote(fromScoreEntryIndex:Int) -> Bool {
        if fromScoreEntryIndex > self.scoreEntries.count - 1 {
            return false
        }
        for i in fromScoreEntryIndex..<self.scoreEntries.count {
            if let timeSlice = self.scoreEntries[i] as? TimeSlice {
                if timeSlice.entries.count > 0 {
                    if timeSlice.entries[0] is StaffNote {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
        }
        return false
    }
    
    public func processAllTimeSlices(processFunction:(_:TimeSlice) -> Void) {
        for i in 0..<self.scoreEntries.count {
            if let ts = self.scoreEntries[i] as? TimeSlice {
                processFunction(ts)
            }
        }
    }
    
//    public func setNormalizedValues(scale:Scale, handIndex: Int) {
//        for i in 0..<self.getAllTimeSlices().count {
//            let ts = self.getAllTimeSlices()[i]
//            ts.tapDurationNormalised = scale.scaleNoteState[handIndex][i].valueNormalized
//        }
//    }

//    public func calculateTapToValueRatios() {
//        ///Calculate tapped time to note value with any trailing rests
//        ///The tapped value for a note must be compared against the note's value plus and traling rests
//        var lastValue:Double = 0
//        var lastNoteIndex:Int?
//        
//        func set(index:Int, lastValue:Double) {
//            if let ts:TimeSlice = self.scoreEntries[index] as? TimeSlice {
//                if let tapped = ts.tapSecondsNormalizedToTempo {
//                    if lastValue > 0 {
//                        let ratio = tapped / lastValue
//                        ts.tapTempoRatio = ratio
//                    }
//                }
//            }
//        }
//        
//        for i in 0..<self.scoreEntries.count {
//            if let ts = self.scoreEntries[i] as? TimeSlice {
//                if ts.entries.count > 0 {
//                    if ts.entries[0] is StaffNote {
//                        if let index = lastNoteIndex {
//                            set(index: index, lastValue: lastValue)
//                            lastValue = 0
//                        }
//                        lastValue += ts.getValue()
//                        lastNoteIndex = i
//                    }
//                    if ts.entries[0] is Rest {
//                        lastValue += ts.getValue()
//                    }
//                }
//            }
//        }
//        if let index = lastNoteIndex {
//            set(index: index, lastValue: lastValue)
//        }
//        
//        ///calculate the min, max ratios
//        var minRatio:Double?
//        var maxRatio:Double?
//        ///exclude the last tap which is often long and then skews the result
//        for i in 0..<self.scoreEntries.count-1 {
//            if let ts = self.scoreEntries[i] as? TimeSlice {
//                if let ratio = ts.tapTempoRatio {
//                    if minRatio == nil || ratio < minRatio! {
//                        minRatio = ratio
//                    }
//                    if maxRatio == nil || ratio > maxRatio! {
//                        maxRatio = ratio
//                    }
//                }
//            }
//        }
//        guard let maxRatio = maxRatio else {
//            return
//        }
//        guard let minRatio = minRatio else {
//            return
//        }
//
//        ///Scale all the ratios according to the min, max. Fill the space 0..1 so that the slowest ratio is 0 and the highest ratio is 1
//        for i in 0..<self.scoreEntries.count {
//            if let ts = self.self.scoreEntries[i] as? TimeSlice {
//                if let ratio = ts.tapTempoRatio {
//                    let scaled = (ratio - minRatio) / (maxRatio - minRatio)
//                    ts.tapTempoRatio = scaled
//                }
//            }
//        }
//    }
    
//    public func isOnlyRhythm() -> Bool {
//        if let last = self.getLastNoteTimeSlice() {
//            if last.getTimeSliceNotes().count > 0 {
//                if last.getTimeSliceNotes().count > 0 {
//                    let lastNote = last.getTimeSliceNotes()[0]
//                    return lastNote.isOnlyRhythmNote
//                }
//            }
//        }
//        return false
//    }
    
    public func getTrailingRestsDuration(index:Int) -> Double {
        var totalDuration = 0.0
        if index < self.scoreEntries.count {
            for i in index..<self.scoreEntries.count {
                if let ts = self.self.scoreEntries[i] as? TimeSlice {
                    if ts.entries.count > 0 {
                        if let rest = ts.entries[0] as? Rest {
                            totalDuration += rest.getValue()
                        }
                        else {
                            break
                        }
                    }
                }
            }
        }
        return totalDuration
    }
    
    public func getEndRestsDuration() -> Double {
        var totalDuration = 0.0
        for e in self.getAllTimeSlices().reversed() {
            if e.getTimeSliceEntries(notesOnly: false).count > 0 {
                let entry = e.getTimeSliceEntries(notesOnly: false)[0]
                if entry is StaffNote {
                    break
                }
                totalDuration += entry.getValue()
            }
        }
        return totalDuration
    }
    
    func getNotesForLastBarOLD(clef:StaffClef, pitch:Int? = nil) -> [StaffNote] {
        var notes:[StaffNote] = []
        for entry in self.scoreEntries.reversed() {
            if entry is BarLine {
                break
            }
            if let ts = entry as? TimeSlice {
                //if ts.getTimeSliceNotes(handType: clef.clefType).count > 0 {
                if ts.getTimeSliceNotesForClef(clef: clef).count > 0 {
                    if let note = ts.entries[0] as? StaffNote {
                        if let pitch = pitch {
                            if note.midiNumber == pitch {
                                notes.append(note)
                            }
                        }
                        else {
                            notes.append(note)
                        }
                    }
                }
            }
        }
        return notes
    }
    
    func getPreviousNotesInBar(clef:StaffClef, sequence:Int, pitch:Int?) -> [StaffNote] {
        var notes:[StaffNote] = []
        for entry in self.scoreEntries {
            if entry.sequence >= sequence {
                break
            }
            if entry is BarLine {
                notes = []
            }
            if let ts = entry as? TimeSlice {
                let clefNotes = ts.getTimeSliceNotesForClef(clef: clef)
                if clefNotes.count > 0 {
                    let note = clefNotes[0] as StaffNote
                    if note.timeSlice.sequence < sequence {
                        if let givenPitch = pitch {
                            if note.midiNumber == pitch {
                                notes.append(note)
                            }
                        }
                        else {
                            notes.append(note)
                        }
                    }
                }
            }
        }
        return notes
    }
    
    func searchTimeSlices(searchFunction:(_:TimeSlice)->Bool) -> [TimeSlice]  {
        var result:[TimeSlice] = []
        for entry in self.getAllTimeSlices() {
            if searchFunction(entry) {
                result.append(entry)
            }
        }
        return result
    }
    
    func searchEntries(searchFunction:(_:ScoreEntry)->Bool) -> [ScoreEntry]  {
        var result:[ScoreEntry] = []
        for entry in self.scoreEntries {
            if searchFunction(entry) {
                result.append(entry)
            }
        }
        return result
    }
}

