import Foundation
import SwiftUI


public class BarLine : ScoreEntry {
    let visibleOnStaff:Bool
    let forStaffSpacing: Bool
    
    init(visibleOnStaff:Bool, forStaffSpacing: Bool) {
        self.visibleOnStaff = visibleOnStaff
        self.forStaffSpacing = forStaffSpacing
    }
}

public class Tie : ScoreEntry {
}

public class Rest : TimeSliceEntry {
    public override init(timeSlice:TimeSlice, value:Double, segments:[Int], staffNum:Int) {
        super.init(timeSlice:timeSlice, value: value, segments: segments, staffNum: staffNum)
    }
    
    public init(r:Rest) {
        super.init(timeSlice: r.timeSlice, value: r.getValue(), segments: r.segments, staffNum: r.staffNum)
    }
}

public enum AccidentalType {
    case sharp
    case flat
}

public enum HandType {
    case left
    case right
}

public enum QuaverBeamType {
    case none
    case start
    case middle
    case end
}

public enum StemDirection {
    case up
    case down
}

public class NoteStaffPlacement {
    public var offsetFromStaffMidline:Int
    public var accidental: Int?
    
    init(noteValue:Int, offsetFroMidLine:Int, accidental:Int?=nil) {
        self.offsetFromStaffMidline = offsetFroMidLine
        self.accidental = accidental
    }
}

public class StaffNote : TimeSliceEntry, Comparable {
    static let MIDDLE_C = 60 //Midi pitch for C4
    static let OCTAVE = 12
    
    ///Defined as the number of notes in a single metronome click
    public static let VALUE_SEMIQUAVER = 0.25
    public static let VALUE_TRIPLET = 0.333333333333333333333
    public static let VALUE_QUAVER = 0.5
    public static let VALUE_QUARTER = 1.0
    public static let VALUE_HALF = 2.0
    public static let VALUE_WHOLE = 4.0

    public var midiNumber:Int
    public var isOnlyRhythmNote = false
    public var writtenAccidental:Int? = nil ///An accidental that was explicitly specified in content
    public var rotated:Bool = false ///true if note must be displayed vertically rotated due to closeness to a neighbor.
    
    ///Placements for the note on treble and bass staff
    var noteStaffPlacements:[NoteStaffPlacement?] = [nil, nil]
    
    ///Quavers in a beam have either a start, middle or end beam type. A standlone quaver type has type beamEnd. A non quaver has beam type none.
    public var beamType:QuaverBeamType = .none
    
    public var stemDirection:StemDirection = .up
    public var stemLength:Double = 0.0
    
    //the note where the quaver beam for this note ends
    var beamEndNote:StaffNote? = nil
    
    public static func < (lhs: StaffNote, rhs: StaffNote) -> Bool {
        return lhs.midiNumber < rhs.midiNumber
    }
    
    static func isSameNote(note1:Int, note2:Int) -> Bool {
        return (note1 % 12) == (note2 % 12)
    }
    
    public init(timeSlice:TimeSlice, midi:Int, value:Double, segments:[Int], staffNum:Int, writtenAccidental:Int?=nil) {
        self.midiNumber = midi
        super.init(timeSlice:timeSlice, value: value, segments: segments, staffNum: staffNum)
        self.writtenAccidental = writtenAccidental
    }
    
    public init(note:StaffNote) {
        self.midiNumber = note.midiNumber
        super.init(timeSlice:note.timeSlice, value: note.getValue(), segments: note.segments, staffNum: note.staffNum)
        self.timeSlice.sequence = note.timeSlice.sequence
        self.writtenAccidental = note.writtenAccidental
        self.isOnlyRhythmNote = note.isOnlyRhythmNote
        self.beamType = note.beamType
    }
    
    public func setIsOnlyRhythm(way: Bool) {
        self.isOnlyRhythmNote = way
        if self.isOnlyRhythmNote {
            self.midiNumber = StaffNote.MIDDLE_C + StaffNote.OCTAVE - 1
        }
    }
    
    public static func getNoteName(midiNum:Int) -> String {
        var name = ""
        let note = midiNum % 12 //self.midiNumber % 12
        switch note {
        case 0:
            name = "C"
        case 1:
            name = "C#"
        case 2:
            name = "D"
        case 3:
            name = "D#"
        case 4:
            name = "E"
        case 5:
            name = "F"
        case 6:
            name = "F#"
        case 7:
            name = "G"
        case 8:
            name = "G#"
        case 9:
            name = "A"
        case 10:
            name = "A#"
        case 11:
            name = "B"

        default:
            name = "\(note)"
        }
        return name
    }
    
    public static func getAllOctaves(note:Int) -> [Int] {
        var notes:[Int] = []
        for n in 0...88 {
            if note >= n {
                if (note - n) % 12 == 0 {
                    notes.append(n)
                }
            }
            else {
                if (n - note) % 12 == 0 {
                    notes.append(n)
                }
            }
        }
        return notes
    }
    
    public static func getClosestOctave(note:Int, toPitch:Int, onlyHigher: Bool = false) -> Int {
        let pitches = StaffNote.getAllOctaves(note: note)
        var closest:Int = note
        var minDist:Int?
        for p in pitches {
            if onlyHigher {
                if p < toPitch {
                    continue
                }
            }
            let dist = abs(p - toPitch)
            if minDist == nil || dist < minDist! {
                minDist = dist
                closest = p
            }
        }
        return closest
    }
    
    ///Find the first note for this quaver group
    public func getBeamStartNote(score:Score, np: NoteLayoutPositions) -> StaffNote {
        let endNote = self
        if endNote.beamType != .end {
            return endNote
        }
        var result:StaffNote? = nil
        var idx = score.scoreEntries.count - 1
        var foundEndNote = false
        while idx>=0 {
            let ts = score.scoreEntries[idx]
            if ts is TimeSlice {
                let notes = ts.getTimeSliceNotes()
                if notes.count > 0 {
                    let note = notes[0]
                    if note.timeSlice.sequence == endNote.timeSlice.sequence {
                        foundEndNote = true
                    }
                    else {
                        if foundEndNote {
                            if note.beamType == .start {
                                result = note
                                break
                            }
                            else {
                                if [StaffNote.VALUE_QUAVER, StaffNote.VALUE_TRIPLET].contains(note.getValue()) {
                                    if note.beamType == .end {
                                        break
                                    }
                                }
                                else {
                                    break
                                }
                            }
                        }
                    }
                }
            }
            if ts is BarLine {
                if foundEndNote {
                    break
                }
            }

            idx = idx - 1
        }
        if result == nil {
            return endNote
        }
        else {
            return result!
        }
    }
    
    public func getNoteDisplayCharacteristics(staff:Staff) -> NoteStaffPlacement {
        return self.noteStaffPlacements[staff.staffNum]!
    }
    
    ///The note has a default accidental determined by which key the score is in but can be overidden by content specifying a written accidental
    ///The written accidental must overide the default accidental and the note's offset adjusted accordingly.
    ///When a written accidental is specified this code checks the note offset positions for this staff (coming from the score's key) and decides how the note should move from its
    ///default staff offset based on the written accidental. e.g. a note at MIDI 75 would be defaulted to show as E ♭ in C major but may be speciifed to show as D# by a written
    ///accidentail. In that case the note must shift down 1 unit of offset.
    ///
    func setNotePlacementAndAccidental(score:Score, staff:Staff) {
        let barAlreadyHasNote = score.getNotesForLastBar(pitch:self.midiNumber).count > 1
        let defaultNotePlacement = staff.getNoteViewPlacement(note: self)
        var offsetFromMiddle = defaultNotePlacement.offsetFromStaffMidline
        var offsetAccidental:Int? = nil
        if self.isOnlyRhythmNote {
            offsetFromMiddle = 0
        }

        if let writtenAccidental = self.writtenAccidental {
            //Content provided a specific accidental
            offsetAccidental = writtenAccidental
            if writtenAccidental != defaultNotePlacement.accidental {
                let defaultNoteStaffPlacement = staff.noteStaffPlacement[self.midiNumber]
                let targetOffsetIndex = self.midiNumber - writtenAccidental
                let targetNoteStaffPlacement = staff.noteStaffPlacement[targetOffsetIndex]
                let adjustOffset = defaultNoteStaffPlacement.offsetFromStaffMidline - targetNoteStaffPlacement.offsetFromStaffMidline
                offsetFromMiddle -= adjustOffset
            }
        }
        else {
            //Determine if the note's accidental is implied by the key signature
            //Or a note has to have a natural accidental to offset the key signature

            let keySignatureHasNote = staff.score.key.hasKeySignatureNote(note: self.midiNumber)

            if let defaultAccidental = defaultNotePlacement.accidental {
                if !keySignatureHasNote {
                    if !barAlreadyHasNote {
                        offsetAccidental = defaultAccidental
                    }
                }
            }
            else {
                ///Check if the key signature causes show should be a nautural accidental to be required
                let keySignatureHasNote:Bool
                if staff.score.key.keySig.flats.count > 0 {
                    keySignatureHasNote = self.midiNumber > 0 && staff.score.key.hasKeySignatureNote(note: self.midiNumber - 1)
                }
                else {
                    keySignatureHasNote = staff.score.key.hasKeySignatureNote(note: self.midiNumber + 1)
                }
                if keySignatureHasNote {
                    if !barAlreadyHasNote {
                        offsetAccidental = 0
                    }
                }
            }
            ///Determine if an accidental for this note is required to cancel the accidental of a previous note in the bar at the same offset.
            ///e.g. we have a b flat in the bar already and a b natural arrives. The 2nd note needs a natural accidental
            var lastNoteAtOffset:StaffNote? = nil
            //var lastStaffPlacement:NoteStaffPlacement? = nil
            var barPreviousNotes = score.getNotesForLastBar(pitch:nil)
            if barPreviousNotes.count > 1 {
                ///Dont consider current note
                barPreviousNotes.removeFirst()
            }
            for prevNote in barPreviousNotes {
                if let prevPlacement = prevNote.noteStaffPlacements[staff.staffNum] {
                    if prevPlacement.offsetFromStaffMidline == offsetFromMiddle {
                        if prevPlacement.accidental != nil {
                            lastNoteAtOffset = prevNote
                            break
                        }
                    }
                }
            }
            if let lastNoteAtOffset = lastNoteAtOffset {
                if let lastAccidental = lastNoteAtOffset.noteStaffPlacements[staffNum]?.accidental {
                    if lastNoteAtOffset.midiNumber > self.midiNumber {
                        offsetAccidental = lastAccidental - 1
                    }
                    if lastNoteAtOffset.midiNumber < self.midiNumber {
                        offsetAccidental = lastAccidental + 1
                    }
                }
            }
        }
        let placement = NoteStaffPlacement(noteValue: midiNumber, offsetFroMidLine: offsetFromMiddle, accidental: offsetAccidental)
        self.noteStaffPlacements[staff.staffNum] = placement
        //self.debug("setNoteDisplayCharacteristics")
    }
}
