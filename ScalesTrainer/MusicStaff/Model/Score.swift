import Foundation
import AVKit
import AVFoundation

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
    
    public func getTimeSliceEntries() -> [TimeSliceEntry] {
        var result:[TimeSliceEntry] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                //if entry is Note {
                    result.append(entry)
                //}
            }
        }
        return result
    }
    
    public func getTimeSliceNotes(staffNum:Int? = nil) -> [StaffNote] {
        var result:[StaffNote] = []
        if self is TimeSlice {
            let ts:TimeSlice = self as! TimeSlice
            let entries = ts.entries
            for entry in entries {
                if entry is StaffNote {
                    if let staffNum = staffNum {
                        let note = entry as! StaffNote
                        if note.staffNum == staffNum {
                            result.append(note)
                        }
                    }
                    else {
                        result.append(entry as! StaffNote)
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
    
    public var timeSignature:TimeSignature
    public var key:StaffKey
    @Published public var barLayoutPositions:BarLayoutPositions

    @Published public var scoreEntries:[ScoreEntry] = []

    let ledgerLineCount =  2 //3//4 is required to represent low E
    public var staffs:[Staff] = []
    
    public var studentFeedback:StudentFeedback? = nil
    public var tempo:Int?
    
    //public var lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : 8.0
    //public var lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : 15.0
    public var lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 6.0 : 10.0
    //public var lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 10.0

    private var totalStaffLineCount:Int = 0
    static var accSharp = "\u{266f}"
    static var accNatural = "\u{266e}"
    static var accFlat = "\u{266d}"
    public var label:String? = nil
    public var heightPaddingEnabled:Bool
    let showTempoVariation:Bool = false
    
    public init(key:StaffKey, timeSignature:TimeSignature, linesPerStaff:Int, heightPaddingEnabled:Bool = true) {
        self.id = UUID()
        self.timeSignature = timeSignature
        totalStaffLineCount = linesPerStaff + (2*ledgerLineCount)
        self.key = key
        barLayoutPositions = BarLayoutPositions()
        self.heightPaddingEnabled = heightPaddingEnabled
    }
    
//    func clearAllPlayingNotes(besidesMidi:Int) {
//        for timeslice in getAllTimeSlices() {
//            let note = timeslice.entries[0] as! Note
//            if note.midiNumber != besidesMidi {
//                if note.status == .playedCorrectly {
//                    DispatchQueue.global(qos: .background).async { //in
//                        usleep(1000000 * UInt32(0.5))
//                        note.setStatus(status: .none)
//                    }
//                }
//            }
//        }
//    }
    
    public func setScoreNotePlayed(midi: Int, direction: Int) -> TimeSlice? {
        let timeSlices = getAllTimeSlices()
        var nearestDist = Int(Int64.max)
        let startIndex = direction == 0 ? 0 : timeSlices.count-1
        let endIndex = direction == 0 ? timeSlices.count-1 :0
        var noteFound:TimeSlice?
        //var nearestIndex = Int(Int64.max)
        //var nearestNote:StaffNote?

        for i in stride(from: startIndex, through: endIndex, by: direction == 0 ? 1 : -1) {
            let ts = timeSlices[i]
            let entry = ts.entries[0]
            let staffNote = entry as! StaffNote
            if staffNote.midiNumber == midi {
                ts.setShowIsPlaying(true) //setStatus(status: .playedCorrectly)
                noteFound = ts
                break
            }
            else {
                let dist = abs(staffNote.midiNumber - midi)
                if dist < nearestDist {
                    nearestDist = dist
                    //nearestIndex = i
                    //nearestNote = note
                }
            }
        }
        if let noteFound = noteFound {
            return noteFound
        }
        ///beyond here when reading notifcaions from test data causes a zero count in a timeslice
        return nil
        ///Show a wrong pitch
//        let ts = timeSlices[nearestIndex]
//        guard ts.entries.count > 0 else {
//            return nil
//        }
//        return nil
    }
    
    public func createTimeSlice() -> TimeSlice {
        let ts = TimeSlice(score: self)
        ts.sequence = self.scoreEntries.count
        self.scoreEntries.append(ts)
        if self.scoreEntries.count > 16 {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ///With too many note on the stave 
                lineSpacing = lineSpacing * 0.95
            }
        }
        return ts
    }

    public func getStaffHeight() -> Double {
        let height = Double(getTotalStaffLineCount() + 3) * self.lineSpacing ///Jan2024 Leave room for notes on more ledger lines
        //let cnt = staffs.count
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
    
    public func setLineSpacing(spacing:Double) {
        self.lineSpacing = spacing
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
    
    public func getTimeSliceForMidi(midi:Int, count:Int) -> TimeSlice? {
        let ts = getAllTimeSlices()
        var cnt = 0
        var result:TimeSlice?
        for t in ts {
            let ns = t.getTimeSliceNotes()
            if ns.count > 0 {
                let note = ns[0]
                if note.midiNumber == midi {
                    if cnt == count {
                        result = t
                        break
                    }
                    cnt += 1
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

    public func debugScore111(_ ctx:String, withBeam:Bool, toleranceLevel:Int) {
        let tolerance = RhythmTolerance.getTolerancePercent(toleranceLevel)
        print("\nSCORE DEBUG =====", ctx, "\tKey", key.keySig.accidentalCount, 
              //"StaffCount", self.staffs.count,
                "toleranceLevel:\(toleranceLevel)",
                "toleranceLevel:\(tolerance)"
        )
        for t in self.getAllTimeSlices() {
            if t.entries.count == 0 {
                print("ZERO ENTRIES")
                continue
            }
            if t.getTimeSliceNotes().count > 0 {
                let note = t.getTimeSliceNotes()[0]
                    if withBeam {
                        print("  Seq", t.sequence, 
                              "type:", type(of: t.entries[0]),
                              "midi:", note.midiNumber,
                              "beat:", t.beatNumber,
                              "value:", t.getValue() ,
                              "duration:", t.tapDuration ?? "_",
                              "stemDirection", note.stemDirection,
                              "stemLength", note.stemLength,
                              "writtenAccidental", note.writtenAccidental ?? 0,
                              "\t[beamType:", note.beamType,"]",
                              "beamEndNoteSeq:", note.beamEndNote?.timeSlice.sequence ?? "_",
                              "]")
                    }
                    else {
                        print(" Seq", t.sequence, terminator: "")
                        print(" [type:", type(of: t.entries[0]), "]", terminator: "")
                        print(" [midi:",note.midiNumber, "]", terminator: "")
                        print(" [TapDuration Seconds:",String(format: "%.4f", t.tapDuration ?? 0),"]", t.sequence, terminator: "")
                        print(" [Note Value:", note.getValue(),"]", t.sequence, terminator: "")
                        print(" [status]",t.statusTag, terminator: "")
                        print(" [beat]",t.beatNumber, t.sequence, terminator: "")
                        //print(" [writtenAccidental:",note.writtenAccidental ?? "","]", t.sequence, terminator: "")
                        let note = t.getTimeSliceNotes()[0]
                        print(" offset:", note.noteStaffPlacements[0]?.offsetFromStaffMidline ?? " ", terminator: "")
                        print(" accidental:", note.noteStaffPlacements[0]?.accidental ?? " ", terminator: "")
                        //print("[Staff:",note.staffNum,"]" t.sequence, terminator: "")
                        print()
                    }
            }
            else {
                //let rest = t.
                print("  Seq", t.sequence,
                      "[type:", type(of: t.entries[0]), "]",
                      "[rest:","R ", "]",
                      "[TapDuration Seconds:",String(format: "%.4f", t.tapDuration ?? 0),"]",
                      "[Note Value:", t.getValue(),"]",
                      "[status]",t.statusTag,
                      "[beat]",t.beatNumber,
                      "[writtenAccidental:","_","]",
                      "[Staff:","_","]"
                    )
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
    
    public func getLastNoteTimeSlice() -> TimeSlice? {
        var result:TimeSlice?
        for index in stride(from: scoreEntries.count - 1, through: 0, by: -1) {
            let entry = scoreEntries[index]
            if let ts = entry as? TimeSlice {
                if ts.getTimeSliceNotes().count > 0 {
                    result = ts
                    break
                }
            }
        }
        return result
    }

    public func updateStaffs() {
        for staff in staffs {
            staff.update()
        }
    }
    
    public func addStaff(num:Int, staff:Staff) {
        if self.staffs.count <= num {
            self.staffs.append(staff)
        }
        else {
            self.staffs[num] = staff
        }
    }
    
    public func getStaff() -> [Staff] {
        return self.staffs
    }
    
    public func setKey(key:StaffKey) {
        DispatchQueue.main.async {
            self.key = key
            self.updateStaffs()
        }
    }
    
    public func addBarLine() {
        let barLine = BarLine()
        barLine.sequence = self.scoreEntries.count
        self.scoreEntries.append(barLine)
    }
    
    public func addTie() {
        let tie = Tie()
        tie.sequence = self.scoreEntries.count
        self.scoreEntries.append(tie)
    }

    public func clear() {
        self.scoreEntries = []
        for staff in staffs  {
            staff.clear()
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
    func getStemDirection(staff:Staff, notes:[StaffNote]) -> StemDirection {
        var totalOffsets = 0
        for n in notes {
            if n.staffNum == staff.staffNum {
                let placement = staff.getNoteViewPlacement(note: n)
                totalOffsets += placement.offsetFromStaffMidline
            }
        }
        return totalOffsets <= 0 ? StemDirection.up: StemDirection.down
    }
    
    func addStemAndBeamCharaceteristics() {
        guard let timeSlice = self.getLastNoteTimeSlice() else {
            return
        }
        if timeSlice.entries.count == 0 {
            return
        }
        addBeatValues()
        if timeSlice.entries[0] is StaffNote {
            addStemCharaceteristics()
        }
    }
    
    ///For each time slice calculate its beat number in its bar
    func addBeatValues() {
        var beatCtr = 0.0
        for i in 0..<self.scoreEntries.count {
            if self.scoreEntries[i] is BarLine {
                beatCtr = 0
                continue
            }
            if let timeSlice = self.scoreEntries[i] as? TimeSlice {
                timeSlice.beatNumber = beatCtr
                beatCtr += timeSlice.getValue()
            }
        }
    }
    
    private func determineStemDirections(staff:Staff, notesUnderBeam:[StaffNote], linesForFullStemLength:Double) {
        
        ///Determine if the quaver group has up or down stems based on the overall staff placement of the group
        var totalOffset = 0
        for note in notesUnderBeam {
            let placement = staff.getNoteViewPlacement(note: note)
            totalOffset += placement.offsetFromStaffMidline
        }
        
        ///Set each note's beam type and calculate the nett above r below the staff line for the quaver group (for the subsequnet stem up or down decison)
        let startNote = notesUnderBeam[0]
        let startPlacement = staff.getNoteViewPlacement(note: startNote)

        let endNote = notesUnderBeam[notesUnderBeam.count - 1]
        let endPlacement = staff.getNoteViewPlacement(note: endNote)

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
                    let placement = staff.getNoteViewPlacement(note: note)
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
    private func addStemCharaceteristics() {
        
        func setStem(timeSlice:TimeSlice, beamType:QuaverBeamType, linesForFullStemLength:Double) {
            for staffIndex in 0..<self.staffs.count {
                let stemDirection = getStemDirection(staff: self.staffs[staffIndex], notes: timeSlice.getTimeSliceNotes())
                let staffNotes = timeSlice.getTimeSliceNotes(staffNum: staffIndex)
                for note in staffNotes {
                    note.stemDirection = stemDirection
                    note.stemLength = linesForFullStemLength
                    note.beamType = beamType
                    ///Dont try yet to beam semiquavers
                }
            }
        }
        
        func saveBeam(timeSlicesUnderBeam:[TimeSlice], linesForFullStemLength:Double) -> [TimeSlice] {
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
        
        ///Make quaver beams onto the main beats
        
        for scoreEntry in self.scoreEntries {
            guard scoreEntry is TimeSlice else {
                timeSlicesUnderBeam = saveBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }
            let timeSlice = scoreEntry as! TimeSlice
            if timeSlice.getTimeSliceNotes().count == 0 {
                timeSlicesUnderBeam = saveBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }
            let note = timeSlice.getTimeSliceNotes()[0]
            if note.getValue() != StaffNote.VALUE_QUAVER {
                setStem(timeSlice: timeSlice, beamType: .none, linesForFullStemLength: linesForFullStemLength)
                timeSlicesUnderBeam = saveBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                continue
            }

            let mainBeat = Int(timeSlice.beatNumber)
            if timeSlice.beatNumber == Double(mainBeat) {
                timeSlicesUnderBeam = saveBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
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
        timeSlicesUnderBeam = saveBeam(timeSlicesUnderBeam: timeSlicesUnderBeam, linesForFullStemLength: linesForFullStemLength)
        
        ///Join up adjoining beams where possible. Existing beams only span one main beat and can be joined in some cases

        var lastNote:StaffNote? = nil
        for scoreEntry in self.scoreEntries {
            guard let timeSlice = scoreEntry as? TimeSlice else {
                lastNote = nil
                continue
            }
            if timeSlice.getTimeSliceNotes().count == 0 {
                lastNote = nil
                continue
            }
            let note = timeSlice.getTimeSliceNotes()[0]
            if note.beamType == .none {
                lastNote = nil
                continue
            }
            if note.beamType == .start {
                if let lastNote = lastNote {
                    if lastNote.beamType == .end {
                        var timeSigAllowsJoin = true
                        if timeSignature.top == 4 {
                            /// 4/4 beats after 2nd cannot join to earlier beats
                            let beat = Int(note.timeSlice.beatNumber)
                            let startBeat = Int(lastNote.timeSlice.beatNumber)
                            timeSigAllowsJoin = beat < 2 || (startBeat >= 2)
                        }
                        if timeSigAllowsJoin {
                            lastNote.beamType = .middle
                            note.beamType = .middle
                        }
                    }
                }
            }
            lastNote = note
        }
        
        ///Determine stem directions for each quaver beam
        
        var notesUnderBeam:[StaffNote] = []
        for scoreEntry in self.scoreEntries {
            guard let timeSlice = scoreEntry as? TimeSlice else {
                lastNote = nil
                continue
            }
            if timeSlice.getTimeSliceNotes().count == 0 {
                lastNote = nil
                continue
            }
            let note = timeSlice.getTimeSliceNotes()[0]
            if note.beamType != .none {
                notesUnderBeam.append(note)
                if note.beamType == .end {
                    let staff = self.staffs[note.staffNum]
                    determineStemDirections(staff:staff, notesUnderBeam: notesUnderBeam, linesForFullStemLength: linesForFullStemLength)
                    notesUnderBeam = []
                }
            }
        }
    }
    
//    public func errorCount() -> Int {
//        var cnt = 0
//        for timeSlice in self.getAllTimeSlices() {
//            if [TimeSliceStatusTag.pitchError, TimeSliceStatusTag.rhythmError].contains(timeSlice.statusTag) {
//                cnt += 1
//            }
//        }
//        return cnt
//    }
    
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

    
//    public func resetTapToValueRatios() {
//        for i in 0..<self.scoreEntries.count {
//            if let ts = self.scoreEntries[i] as? TimeSlice {
//                ts.tapTempoRatio = nil
//            }
//        }
//    }
    
    public func processAllTimeSlices(processFunction:(_:TimeSlice) -> Void) {
        for i in 0..<self.scoreEntries.count {
            if let ts = self.scoreEntries[i] as? TimeSlice {
                processFunction(ts)
            }
        }
    }
    
    public func setNormalizedValues(scale:Scale) {
        for i in 0..<self.getAllTimeSlices().count {
            let ts = self.getAllTimeSlices()[i]
            ts.tapDuration = scale.scaleNoteState[i].valueNormalized
        }
    }

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
    
    public func isOnlyRhythm() -> Bool {
        if let last = self.getLastNoteTimeSlice() {
            if last.getTimeSliceNotes().count > 0 {
                if last.getTimeSliceNotes().count > 0 {
                    let lastNote = last.getTimeSliceNotes()[0]
                    return lastNote.isOnlyRhythmNote
                }
            }
        }
        return false
    }
    
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
            if e.getTimeSliceEntries().count > 0 {
                let entry = e.getTimeSliceEntries()[0]
                if entry is StaffNote {
                    break
                }
                totalDuration += entry.getValue()
            }
        }
        return totalDuration
    }
    
    func getNotesForLastBar(pitch:Int? = nil) -> [StaffNote] {
        var notes:[StaffNote] = []
        for entry in self.scoreEntries.reversed() {
            if entry is BarLine {
                break
            }
            if let ts = entry as? TimeSlice {
                if ts.getTimeSliceNotes().count > 0 {
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

