import Foundation
import AVKit
import AVFoundation

//https://mammothmemory.net/music/sheet-music/reading-music/treble-clef-and-bass-clef.html

///Used to record view positions of notes as they are drawn by a view so that a 2nd drawing pass can draw quaver beams to the right points
///Jan18, 2024 Original version had positions as Published but this causes warning of updating publishable variable during view drawing
///Have now made postions not published and NoteLayoutPostions not observable.
///This assumes that all notes will be drawn and completed (and their postions recorded) by the time the quaver beam is drawn furhter down in ScoreEntriesView but this assumption seems to hold.
///This approach makes the whole drawing of quaver beams much simpler - as long as the assumption holds always.
public class NoteLayoutPositions { //}: ObservableObject {
    //@Published
    public var positions:[StaffNote: CGRect] = [:]

    var id:Int
    static var nextId = 0

    init(id:Int) {
        self.id = id
    }

    public func getPositions1() -> [(StaffNote, CGRect)] {
        //noteLayoutPositions.positions.sorted(by: { $0.key.timeSlice.sequence < $1.key.timeSlice.sequence })
        var result:[(StaffNote, CGRect)] = []
        let notes = positions.keys.sorted(by: { $0.timeSlice.sequence < $1.timeSlice.sequence })
        for n in notes {
            let rect:CGRect = positions[n]!
            let newNote = StaffNote(note: n)
            result.append((newNote, rect))
        }
        return result
    }

    func getPositionForSequence(sequence:Int) -> CGRect? {
        for k in positions.keys {
            if k.timeSlice.sequence == sequence {
                return positions[k]
            }
        }
        return nil
    }

    public func storePosition(onAppear:Bool, notes: [StaffNote], rect: CGRect) {
        if notes.count > 0 {
            if [StaffNote.VALUE_QUAVER, StaffNote.VALUE_TRIPLET].contains(notes[0].getValue()) {
                let rectCopy = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY), size: CGSize(width: rect.size.width, height: rect.size.height))
                //DispatchQueue.main.async {
                    ///Make sure this fires after all other UI is rendered
                    ///Also can cause 'Publishing changes from within view updates is not allowed, this will cause undefined behavior.' - but cant see how to stop it :(
                    //sleep(UInt32(0.25))
                    //sleep(UInt32(0.5))
                    self.positions[notes[0]] = rectCopy
                //}
            }
        }
    }
}

public class BarLayoutPositions: ObservableObject {
    @Published public var positions:[BarLine: CGRect] = [:]
    public init() {

    }
    public func storePosition(barLine:BarLine, rect: CGRect, ctx:String) {
        DispatchQueue.main.async {
            let rectCopy = rect
            self.positions[barLine] = rectCopy
        }
    }
}

public enum StaffType {
    case treble
    case bass
}

class StaffPlacementsByKey {
    var staffPlacement:[NoteStaffPlacement] = []
}

public class NoteOffsetsInStaffByKey {
    var noteOffsetByKey:[String] = []
    
    public init (keyType:StaffKey.StaffKeyType) {
        //Defines which staff line (and accidental) is used to show a midi pitch in each key,
        //assuming key signature is not taken in account (it will be later in the note display code...)
        //offset, sign. sign = ' ' or -1=flat, 1=sharp (=natural,????)
        //modified July23 - use -1 for flat, 0 for natural, 1 for sharp. Done onlu so far for C and G
        //horizontal is the various keys
        //Vertical starts at showing which accidentals C, then C#, D, E♭ (row) are shown in that key (column) 
        //31Aug2023 - done for C, G, D, E
        if keyType == .major {
            //  Key                 C     D♭   D    E♭   E    F    G♭    G     A♭   A    B♭   B
            noteOffsetByKey.append("0     0    0    0    0    0    0     0     0    0,1  0    0")    //C
            noteOffsetByKey.append("0,1   1    0,1  1,0  0,1  1,0  1,-1  0,1   1    0    1,0  0,1")  //C#, D♭
            noteOffsetByKey.append("1     1,1  1    1    1    1    1     1     1,1  1    1    1")    //D
            noteOffsetByKey.append("2,-1  2    2,-1 2    1,1  2,0  2,-1  2,-1  2    1,2  2    1,1")  //D#, E♭
            noteOffsetByKey.append("2     2,1  2    2,1  2    2    2     2     2,1  2    2,1  2")    //E
            noteOffsetByKey.append("3     3    3    3    3    3    3     3     3    3,1  3    3")    //F
            noteOffsetByKey.append("3,1   4    3,1  4,0  3,1  4,0  4,-1  3,1   4,0  3    4,0  3,1")  //F#, G♭
            noteOffsetByKey.append("4     4,1  4    4    4    4    4     4     4    4,1  4    4")    //G
            //noteOffsetByKey.append("5,-1   5    4,1  5    4,1  5,0 5,-1  4,1   5    4    5,0  4,1")  //G#, A♭
            noteOffsetByKey.append("4,1   5    4,1  5    4,1  5,0 5,-1  4,1   5    4    5,0  4,1")  //G#, A♭ //Trinity needs G# not A ♭
            noteOffsetByKey.append("5     5,1  5    5,1  5    5    5     5     5,1  5    5    5")    //A
            noteOffsetByKey.append("6,-1  6    6,-1 6    6,-1 6    6,-1  6,-1  6    6,0  6    5,1")  //A#, B♭
            noteOffsetByKey.append("6     6,1  6    6,1  6    6,1  6     6     6,1  6    6,1  6")    //B
        }
        else {
            noteOffsetByKey.append("0     0,0  0    0    0    0    0     0     0    0    0    0")     //C
            noteOffsetByKey.append("1,-1  0,1  0,1  1,-1 0,1  1,0  0,1   1,-1  0,1  0,1  1,0  0,1")   //C#, D♭
            noteOffsetByKey.append("1     1    1    1    1    1    1     1     1    1    1    1")     //D
            noteOffsetByKey.append("2,-1  1,1  2,-1 2,-1 1,1  2,0  2,-1  2,-1  1,1  2,-1 2   1,1")    //D#, E♭
            noteOffsetByKey.append("2     2    2    2    2    2    2     2     2    2    2,1  2")     //E
            noteOffsetByKey.append("3     3    3    3    3    3    3     3     3    3    3    3")     //F
            noteOffsetByKey.append("4,-1  3,1  3,1  4,-1 3,1  4,0 3,1    3,1   3,1  3,1  4,0  3,1")   //F#, G♭
            noteOffsetByKey.append("4     4    4    4    4    4    4     4     4    4    4    4")     //G
            noteOffsetByKey.append("5,-1  4,1  4,1  5,-1 4,1  5,0  4,1   5,-1  4,1  4,1  5,0  4,1")   //G#, A♭
            noteOffsetByKey.append("5     5    5    5    5    5    5     5     5    5    5    5")     //A
            noteOffsetByKey.append("6,-1  5,1  6,-1 6,-1 6,-1 6    5,1   6,-1  5,1  6,-1 6    5,1")   //A#, B♭
            noteOffsetByKey.append("6     6    6    6    6    6,1  6     6     6    6    6,1  6")     //B
        }
    }

    func getValue(noteValue:Int, scaleDegree:Int, keyNum:Int) -> NoteStaffPlacement? {

        guard scaleDegree < self.noteOffsetByKey.count else {
            Logger.shared.reportError(self, "Invalid degree \(scaleDegree)")
            return nil
        }
        guard keyNum < 12 else {
            Logger.shared.reportError(self, "Invalid key \(scaleDegree)")
            return nil
        }

        let scaleDegreeComponentsLine = noteOffsetByKey[scaleDegree].components(separatedBy: " ")
        var scaleDegreeComponentsList:[String] = []
        for component in scaleDegreeComponentsLine {
            let c = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if c.count > 0 {
                scaleDegreeComponentsList.append(c)
            }
        }
        let scaleDegreeComponents = scaleDegreeComponentsList[keyNum]

        let offsetAndAccidental = scaleDegreeComponents.components(separatedBy: ",")
        let offset:Int? = Int(offsetAndAccidental[0])
        if let offset = offset {
            var accidental:Int? = nil
            if offsetAndAccidental.count > 1 {
                let accStr = offsetAndAccidental[1]
                accidental = Int(accStr)
            }
            let placement = NoteStaffPlacement(noteValue: noteValue, offsetFroMidLine: offset, accidental: accidental)

            return placement
        }
        else {
            Logger.shared.reportError(self, "Invalid data at row:\(scaleDegree), col:\(keyNum)")
            return nil
        }
    }
}

public class Staff : ObservableObject, Identifiable {
    public let id = UUID()
    @Published var publishUpdate = 0
    @Published public var noteLayoutPositions1:NoteLayoutPositions
    @Published var beamUpdates = 0
    
    let score:Score
    public var type:StaffType
    var lowestNoteValue:Int
    var highestNoteValue:Int
    public var middleNoteValue:Int
    var staffOffsets:[Int] = []
    var noteStaffPlacement:[NoteStaffPlacement]=[]
    public var linesInStaff:Int
    let noteOffsetsInStaffByKey:NoteOffsetsInStaffByKey

    public init(score:Score, type:StaffType, linesInStaff:Int) {
        self.score = score
        self.type = type
        self.noteOffsetsInStaffByKey = NoteOffsetsInStaffByKey(keyType: score.key.type)
        self.linesInStaff = linesInStaff
        lowestNoteValue = 20 //MIDI C0
        highestNoteValue = 107 //MIDI B7
        middleNoteValue = type == StaffType.treble ? 71 : StaffNote.MIDDLE_C - StaffNote.OCTAVE + 2
        noteLayoutPositions1 = NoteLayoutPositions(id: 0)

        //Determine the staff placement for each note pitch

        var keyNumber:Int = 0
        if score.key.type == .major {
            if score.key.keySig.accidentalType == .sharp {
                if score.key.keySig.accidentalCount == 1 {
                    keyNumber = 7
                }
                if score.key.keySig.accidentalCount == 2 {
                    keyNumber = 2
                }
                if score.key.keySig.accidentalCount == 3 {
                    keyNumber = 9
                }
                if score.key.keySig.accidentalCount == 4 {
                    keyNumber = 4
                }
                if score.key.keySig.accidentalCount == 5 {
                    keyNumber = 11
                }
                if score.key.keySig.accidentalCount == 6 {
                    keyNumber = 6
                }
            }
            if score.key.keySig.accidentalType == .flat {
                if score.key.keySig.accidentalCount == 1 {
                    keyNumber = 5
                }
                if score.key.keySig.accidentalCount == 2 {
                    keyNumber = 10
                }
                if score.key.keySig.accidentalCount == 3 {
                    keyNumber = 3
                }
                if score.key.keySig.accidentalCount == 4 {
                    keyNumber = 8
                }
                if score.key.keySig.accidentalCount == 5 {
                    keyNumber = 1
                }
                if score.key.keySig.accidentalCount == 6 {
                    keyNumber = 6
                }
            }
        }
        else {
            if score.key.keySig.accidentalCount == 0 {
                keyNumber = 9 ///A minor
            }
            if score.key.keySig.accidentalType == .sharp {
                if score.key.keySig.accidentalCount == 1 {
                    keyNumber = 4
                }
                if score.key.keySig.accidentalCount == 2 {
                    keyNumber = 11
                }
                if score.key.keySig.accidentalCount == 3 {
                    keyNumber = 6
                }
                if score.key.keySig.accidentalCount == 4 {
                    keyNumber = 1
                }
                if score.key.keySig.accidentalCount == 5 {
                    keyNumber = 8
                }
                if score.key.keySig.accidentalCount == 6 {
                    keyNumber = 3
                }
            }
            if score.key.keySig.accidentalType == .flat {
                if score.key.keySig.accidentalCount == 1 {
                    keyNumber = 2
                }
                if score.key.keySig.accidentalCount == 2 {
                    keyNumber = 7
                }
                if score.key.keySig.accidentalCount == 3 {
                    keyNumber = 0
                }
                if score.key.keySig.accidentalCount == 4 {
                    keyNumber = 5
                }
                if score.key.keySig.accidentalCount == 5 {
                    keyNumber = 10
                }
                if score.key.keySig.accidentalCount == 6 {
                    keyNumber = 3
                }
            }
        }

        for noteValue in 0...highestNoteValue {
            //Fix - longer? - offset should be from middle C, notes should be displayed on both staffs from a single traversal of the score's timeslices

            let placement = NoteStaffPlacement(noteValue: 0, offsetFroMidLine: 0)
            noteStaffPlacement.append(placement)
            if noteValue < middleNoteValue - 6 * StaffNote.OCTAVE || noteValue >= middleNoteValue + 6 * StaffNote.OCTAVE {
                continue
            }

            var offsetFromTonic = (noteValue - StaffNote.MIDDLE_C) % StaffNote.OCTAVE
            if offsetFromTonic < 0 {
                offsetFromTonic = 12 + offsetFromTonic
            }

            guard let noteOffset = noteOffsetsInStaffByKey.getValue(noteValue: noteValue, scaleDegree: offsetFromTonic, keyNum: keyNumber) else {
                Logger.shared.reportError(self, "No note offset data for note \(noteValue)")
                break
            }
            var offsetFromMidLine = noteOffset.offsetFromStaffMidline

            var octave:Int
            let referenceNote = type == .treble ? StaffNote.MIDDLE_C : StaffNote.MIDDLE_C - 2 * StaffNote.OCTAVE
            if noteValue >= referenceNote {
                octave = (noteValue - referenceNote) / StaffNote.OCTAVE
            }
            else {
                octave = (referenceNote - noteValue) / StaffNote.OCTAVE
                octave -= 1
            }
            offsetFromMidLine += (octave - 1) * 7 //8 offsets to next octave
            offsetFromMidLine += type == .treble ? 1 : -1
            placement.offsetFromStaffMidline = offsetFromMidLine
            placement.accidental = noteOffset.accidental
            noteStaffPlacement[noteValue] = placement
        }
    }

    func update() {
        DispatchQueue.main.async {
            self.publishUpdate += 1
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.publishUpdate = 0
        }
    }

    //Tell a note how to display itself
    //Note offset from middle of staff is dependendent on the staff
    func getNoteViewPlacement(note:StaffNote) -> NoteStaffPlacement {
        let defaultPlacement:NoteStaffPlacement
        if note.midiNumber < 0 || note.midiNumber > noteStaffPlacement.count-1 {
            defaultPlacement = noteStaffPlacement[0]
        }
        else {
            defaultPlacement = noteStaffPlacement[note.midiNumber]
        }
        let placement = NoteStaffPlacement(noteValue: note.midiNumber, 
                                           offsetFroMidLine: defaultPlacement.offsetFromStaffMidline,
                                           accidental: defaultPlacement.accidental)
        return placement
    }

}

