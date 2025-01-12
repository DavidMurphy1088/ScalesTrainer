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

public class Rest : TimeSliceEntry {
    public init(timeSlice:TimeSlice, value:Double, segments:[Int]) {
        super.init(timeSlice:timeSlice, value: value, handType: HandType.right, segments: segments)
    }
    
    public init(r:Rest) {
        super.init(timeSlice: r.timeSlice, value: r.getValue(), handType: r.handType, segments: r.segments)
    }
}

public enum AccidentalType {
    case sharp
    case flat
}

public enum QuaverBeamType {
    case none
    case start
    case middle
    case end
}

public enum StemDirection {
    case none
    case up
    case down
}

public class NoteStaffPlacement {
    let midi:Int
    public var offsetFromStaffMidline:Int
    public var accidental: Int?
    ///Some note placemts and accidentals have to be set by the scale type. e.g. double # for some minor scales.
    ///This field says that placement/accidentals and note name (e.g. E#) should not be adjusted when the note is placed on a staff. e.g. adjusted for key signature.
    var placementCanBeSetByKeySignature = true
    
    init(midi:Int, offsetFroMidLine:Int, accidental:Int?=nil, placementCanBeSetByKeySignature:Bool) {
        self.midi = midi
        self.offsetFromStaffMidline = offsetFroMidLine
        self.accidental = accidental
        self.placementCanBeSetByKeySignature = placementCanBeSetByKeySignature
    }
}

///Contains the layout of how a note is displayed on a staff
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
    
    public var midi:Int
    public var isOnlyRhythmNote = false
    public var writtenAccidental:Int? = nil ///An accidental that was explicitly specified in content
    public var rotated:Bool = false ///true if note must be displayed vertically rotated due to closeness to a neighbor.
    public var clef:StaffClef? = nil ///The clef that this note is prefixed by. e.g. in LH staff that clef might still be the treble clef
    
    ///Placements for the note on treble and bass staff
    //var noteStaffPlacements:[NoteStaffPlacement?] = [nil, nil]
    var noteStaffPlacement:NoteStaffPlacement = NoteStaffPlacement(midi: 0, offsetFroMidLine: 0, placementCanBeSetByKeySignature: true)

    ///Quavers in a beam have either a start, middle or end beam type. A standlone quaver type has type beamEnd. A non quaver has beam type none.
    public var beamType:QuaverBeamType = .none
    public var stemDirection:StemDirection = .none
    public var stemLength:Double = 0.0
    
    //the note where the quaver beam for this note ends
    var beamEndNote:StaffNote? = nil
    
    public static func < (lhs: StaffNote, rhs: StaffNote) -> Bool {
        return lhs.midi < rhs.midi
    }
    
    static func isSameNote(note1:Int, note2:Int) -> Bool {
        return (note1 % 12) == (note2 % 12)
    }
    
    public init(timeSlice:TimeSlice, midi:Int, value:Double, handType:HandType, segments:[Int], writtenAccidental:Int?=nil) {
        self.midi = midi
        super.init(timeSlice:timeSlice, value: value, handType:handType, segments: segments)
        self.writtenAccidental = writtenAccidental
    }
    
    public init(note:StaffNote) {
        self.midi = note.midi
        super.init(timeSlice:note.timeSlice, value: note.getValue(), handType: note.handType, segments: note.segments)
        self.timeSlice.sequence = note.timeSlice.sequence
        self.writtenAccidental = note.writtenAccidental
        self.isOnlyRhythmNote = note.isOnlyRhythmNote
        self.beamType = note.beamType
    }
    
    public func setIsOnlyRhythm(way: Bool) {
        self.isOnlyRhythmNote = way
        if self.isOnlyRhythmNote {
            self.midi = StaffNote.MIDDLE_C + StaffNote.OCTAVE - 1
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
    public func getBeamStartNote(score:Score, staff:Staff, np: NoteLayoutPositions) -> StaffNote {
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
                //let notes = ts.getTimeSliceNotes(staffType: staff.type)
                let notes = ts.getTimeSliceNotes(handType: staff.handType)
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
}

///Called as notes are added to the score to determine their placement and accidentals.
///This function sets note placement and accidentals just for the individual note.
///
///The note has a default accidental determined by which key the score is in but can be overidden by content specifying a written accidental
///The written accidental must overide the default accidental and the note's offset adjusted accordingly.
///When a written accidental is specified this code checks the note offset positions for this staff (coming from the score's key) and decides how the note should move from its
///default staff offset based on the written accidental. e.g. a note at MIDI 75 would be defaulted to show as E ♭ in C major but may be speciifed to show as D# by a written
///accidentail. In that case the note must shift down 1 unit of offset.

///The notes placement and accidentals may be adjusted later as the note is positioned on a staff. (e.g. to adjust accidentals for a staff key signature)
//func setNotePlacementAndAccidentalOLD(score:Score, clef:StaffClef, maxAccidentalLoopback:Int?) {
//        let defaultNotePlacement = clef.getNoteViewPlacement(note: self)
//        if !defaultNotePlacement.placementCanBeSetByKeySignature {
//            let placement = defaultNotePlacement
//            self.noteStaffPlacement = placement
//            return
//        }
//        var offsetFromMiddle = defaultNotePlacement.offsetFromStaffMidline
//        var offsetAccidental:Int? = nil
//        if self.isOnlyRhythmNote {
//            offsetFromMiddle = 0
//        }
//        if let writtenAccidental = self.writtenAccidental {
//            //Content provided a specific accidental
//            offsetAccidental = writtenAccidental
//            if writtenAccidental != defaultNotePlacement.accidental {
//                let defaultNoteStaffPlacement = clef.noteStaffPlacement[self.midiNumber]
//                let targetOffsetIndex = self.midiNumber - writtenAccidental
//                let targetNoteStaffPlacement = clef.noteStaffPlacement[targetOffsetIndex]
//                let adjustOffset = defaultNoteStaffPlacement.offsetFromStaffMidline - targetNoteStaffPlacement.offsetFromStaffMidline
//                offsetFromMiddle -= adjustOffset
//            }
//        }
//        else {
//            ///Look back from this note for notes previous in the bar whose accidentals might affect which accidental this note should show
//            ///e.g. we have a B flat in the bar already and a b natural arrives. The 2nd note needs a natural accidental
//            ///Trinity ignores previous note accidentals if the previous note is too far back.
//            ///10Jan2025 we decided to use bar lines so just follow the usual rules for processing accidentals given previous notes in the bar.
//            offsetAccidental = defaultNotePlacement.accidental
//            let barPreviousNotes = score.getPreviousNotesInBar(clef: clef, sequence: self.timeSlice.sequence, pitch: nil).reversed()
//            var lookback = 0
//            let maxAccidentalLookback:Int = maxAccidentalLoopback == nil ? Int.max : maxAccidentalLoopback!
//            var matchedAccidental = false
//
//            ///Adjust this note's accidental to counter a previous note's accidental if the note was at the same staff offset but a different MIDI.
//            ///If the MIDI is the same as the previous note at the staff offset, set this note's accidental to nil since it's accidental conveys from the previous note.
//            ///This code must take priority over subsequent accidental determinations.
//            for prevNote in barPreviousNotes {
//                if prevNote.noteStaffPlacement.offsetFromStaffMidline == offsetFromMiddle {
//                    if let lastAccidental = prevNote.noteStaffPlacement.accidental {
//                        if prevNote.midiNumber > self.midiNumber {
//                            offsetAccidental = lastAccidental - 1
//                            matchedAccidental = true
//                            break
//                        }
//                        if prevNote.midiNumber < self.midiNumber {
//                            offsetAccidental = lastAccidental + 1
//                            matchedAccidental = true
//                            break
//                        }
//                        if prevNote.midiNumber == self.midiNumber {
//                            offsetAccidental = nil
//                            matchedAccidental = true
//                            break
//                        }
//                    }
//                }
//            }
////            if self.midiNumber == stop {
////                print("==========", self.timeSlice.sequence, self.midiNumber, self.noteStaffPlacement.offsetFromStaffMidline, self.noteStaffPlacement.accidental ?? "_", "maxLoopback:", maxAccidentalLoopback ?? "_")
////                print("     =====", "00", defaultNotePlacement.offsetFromStaffMidline, defaultNotePlacement.accidental ?? "_")
////            }
//
//            ///If not already matched, adjust the note's accidental based on the key signature
//            if !matchedAccidental {
//                ///Use no accidental since the key signature has it
//                if clef.score.key.hasKeySignatureNote(note: self.midiNumber) {
//                    offsetAccidental = nil
//                    matchedAccidental = true
//                }
//                ///Use the natural accidental to differentiate note from the key signature
//                if clef.score.key.keySig.flats.count > 0 {
//                    if clef.score.key.hasKeySignatureNote(note: self.midiNumber-1) {
//                        offsetAccidental = 0
//                        matchedAccidental = true
//                    }
//                }
//                if clef.score.key.keySig.sharps.count > 0 {
//                    if clef.score.key.hasKeySignatureNote(note: self.midiNumber+1) {
//                        if !defaultNotePlacement.placementCanBeSetByKeySignature {
//                            offsetAccidental = 0
//                            matchedAccidental = true
//                        }
//                    }
//                }
//            }
//
//            ///If a nearby previous note is the same MIDI rely on its accidental and make the accidental for the current note nil.
//            ///If previous same MIDI note is too far back let the default accidental by added to this note.
//            ///Trinity adds accidentals back to notes already shown with accidentals if the previous note was too far back.
//            ///This distance is set using a scale customisation.
//            ///10Jan2025 We just use bar lines now to determine accidentals
////            if !matchedAccidental {
////                for prevNote in barPreviousNotes {
////                    if prevNote.midiNumber == self.midiNumber {
////                        if lookback < maxAccidentalLookback {
////                            offsetAccidental = nil
////                            break
////                        }
////                    }
////
////                    lookback += 1
////                }
////            }
//            let placement = NoteStaffPlacement(midi: midiNumber, offsetFroMidLine: offsetFromMiddle, accidental: offsetAccidental,
//                                               placementCanBeSetByKeySignature: defaultNotePlacement.placementCanBeSetByKeySignature)
//            self.noteStaffPlacement = placement
//        }
//        //self.debug("setNoteDisplayCharacteristics")
//    }

