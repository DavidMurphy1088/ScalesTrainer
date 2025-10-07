import Foundation
import SwiftUI

//https://mammothmemory.net/music/sheet-music/reading-music/treble-clef-and-bass-clef.html

///Jan 2025 - Map an array of position anchors to a dictionary with positions relative to the geometry proxy
public class NoteLayoutPositions {
    public var positions:[StaffNote: CGRect] = [:]

    init(scale:Scale, handType:HandType, prefs: [(scoreEntry: ScoreEntry, position: Anchor<CGRect>, isPortrait:Bool)], proxy:GeometryProxy) {
        positions = [:]
        for pref in prefs {
            if let ts:TimeSlice = pref.scoreEntry as? TimeSlice {
                if ts.entries.count > 0 {
                    let noteIndex = scale.hands.count == 1 ? 0 : (handType == .right ? 0 : 1)
                    if let note:StaffNote = ts.entries[noteIndex] as? StaffNote {
                        let pos = proxy[pref.position]
                        positions[note] = pos
                    }
                }
            }
        }
//        if ctx.count > 0 {
//            noteLayoutPositions.debug("\(ctx) After Convert", handType: handType)
//        }
    }
    
    func debug11(_ ctx:String, handType:HandType) -> Bool {
        print ("=============== NoteLayoutPos", ctx)
        var ctr = 0
        for k in positions.keys {
            if let pos = positions[k] {
                print(ctr, String(format: "%02d", k.timeSlice.sequence), "midi:", k.midi, "xy:", String(format: "%.2f", pos.midX), String(format: "%.2f", pos.midY))
            }
            ctr += 1
        }
        return true
    }
    
    func getPositionForSequence(sequence:Int) -> CGRect? {
        for k in positions.keys {
            if k.timeSlice.sequence == sequence {
                return positions[k]
            }
        }
        return nil
    }
}

public class BarLayoutPositions {
    public var positions:[BarLine: CGRect] = [:]
    var id:UUID
    static var nextId = 0

    init() {
        self.id = UUID()
    }

//    func getPositionForSequence(sequence:Int) -> CGRect? {
//        for k in positions.keys {
//            if k.timeSlice.sequence == sequence {
//                return positions[k]
//            }
//        }
//        return nil
//    }

    public func storePosition(mode:Int, barLine: BarLine, rect: CGRect) {
        let rectCopy = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY), size: CGSize(width: rect.size.width, height: rect.size.height))
        //DispatchQueue.main.async {
            ///Make sure this fires after all other UI is rendered
            ///Also can cause 'Publishing changes from within view updates is not allowed, this will cause undefined behavior.' - but cant see how to stop it :(
            //sleep(UInt32(0.25))
            //sleep(UInt32(0.5))
        self.positions[barLine] = rectCopy
    }
}

class StaffPlacementsByKey {
    var staffPlacement:[NoteStaffPlacement] = []
}

public class NoteOffsetsInScaleByKey {
    private var noteOffsetByKey:[String] = []
    
    public init (keyType:StaffKey.StaffKeyType) {
        //Defines which staff line (and accidental) is used to show a midi pitch in each key,
        //assuming key signature is not taken in account (it will be later in the note display code...)
        //offset, sign. sign = ' ' or -1=flat, 1=sharp (=natural,????)
        //modified July23 - use -1 for flat, 0 for natural, 1 for sharp. Done only so far for C and G
        //horizontal is the various keys
        //Vertical starts at showing which accidentals and offset C, then C#, D, E♭ (the row) are shown in that key (column)
        //31Aug2023 - done for C, G, D, E
        //06Jan2025 NOTE - all chromatic scales are in the key of C. Changing the C column will affect chromatic accidentals
        
        if keyType == .major {
            //  Key                 C     D♭   D    E♭   E    F    G♭    G     A♭   A    B♭   B
//            noteOffsetByKey.append("0     0    0    0    0    0    0     0     0    0,1  0    0")    //C
//            //noteOffsetByKey.append("0,1   1    0,1  1,0  0,1  1,0  1,-1  0,1   1    0    1,0  0,1")  //C#, D♭
//            noteOffsetByKey.append("1,-1  1    0,1  1,0  0,1  1,0  1,-1  0,1   1    0    1,0  0,1")  //C#, D♭
//            noteOffsetByKey.append("1     1,1  1    1    1    1    1     1     1,1  1    1    1")    //D
//            noteOffsetByKey.append("1,1   2    1,-1 2    1,1  2,0  2,-1  2,-1  2    1,2  2    1,1")  //D#, E♭
//            noteOffsetByKey.append("2     2,1  2    2,1  2    2    2     2     2,1  2    2,1  2")    //E
//            noteOffsetByKey.append("3     3    3    3    3    3    3     3     3    3,1  3    3")    //F
//            noteOffsetByKey.append("3,1   4    3,1  4,0  3,1  4,0  4,-1  3,1   4,0  3    4,0  3,1")  //F#, G♭
//            noteOffsetByKey.append("4     4,1  4    4    4    4    4     4     4    4,1  4    4")    //G
//            //noteOffsetByKey.append("5,-1   5    4,1  5    4,1  5,0 5,-1  4,1   5    4    5,0  4,1")  //G#, A♭
//            noteOffsetByKey.append("5,-1  5    4,1  5    4,1  5,0 5,-1  4,1   5    4    5,0  4,1")  //G#, A♭ //Trinity needs G# not A ♭
//            noteOffsetByKey.append("5     5,1  5    5,1  5    5    5     5     5,1  5    5    5")    //A
//            noteOffsetByKey.append("6,-1  6    6,-1 6    6,-1 6    6,-1  6,-1  6    6,0  6    5,1")  //A#, B♭
//            noteOffsetByKey.append("6     6,1  6    6,1  6    6,1  6     6     6,1  6    6,1  6")    //B
            
            //Trinity needs G# not A ♭
            //ABRSM #5 needs F# not G ♭
            
            //  Key                 C     D♭   D    E♭   E    F    F#    G     A♭   A    B♭   B
            noteOffsetByKey.append("0     0    0    0    0    0    0     0     0    0,1  0    0")    //C
            noteOffsetByKey.append("1,-1  1    0,1  1,0  0,1  1,0  0,1   0,1   1    0    1,0  0,1")  //C#, D♭
            noteOffsetByKey.append("1     1,1  1    1    1    1    1     1     1,1  1    1    1")    //D
            noteOffsetByKey.append("1,1   2    1,-1 2    1,1  2,0  1,1   2,-1  2    1,2  2    1,1")  //D#, E♭
            noteOffsetByKey.append("2     2,1  2    2,1  2    2    2     2     2,1  2    2,1  2")    //E
            noteOffsetByKey.append("3     3    3    3    3    3    3     3     3    3,1  3    3")    //F
            noteOffsetByKey.append("3,1   4    3,1  4,0  3,1  4,0  3,1   3,1   4,0  3    4,0  3,1")  //F#, G♭
            noteOffsetByKey.append("4     4,1  4    4    4    4    4     4     4    4,1  4    4")    //G
            //noteOffsetByKey.append("5,-1   5    4,1  5    4,1  5,0 5,-1  4,1   5    4    5,0  4,1")  //G#, A♭
            noteOffsetByKey.append("5,-1  5    4,1  5    4,1  5,0  4,1   4,1   5    4    5,0  4,1")  //G#, A♭
            noteOffsetByKey.append("5     5,1  5    5,1  5    5    5     5     5,1  5    5    5")    //A
            noteOffsetByKey.append("6,-1  6    6,-1 6    6,-1 6    5,1   6,-1  6    6,0  6    5,1")  //A#, B♭
            noteOffsetByKey.append("6     6,1  6    6,1  6    6,1  6     6     6,1  6    6,1  6")    //B
        }
        else {
            noteOffsetByKey.append("0     0,0  0    0    0    0    0     0     0    0    0    0")     //C
            noteOffsetByKey.append("1,-1  0,1  0,1  1,-1 0,1  1,0  0,1   1,-1  0,1  0,1  1,0  0,1")   //C#, D♭
            noteOffsetByKey.append("1     1    1    1    1    1    1     1     1    1    1    1")     //D
            noteOffsetByKey.append("2,-1  1,1  2,-1 2,-1 1,1  2,0  1,1   2,-1  1,1  2,-1 2   1,1")    //D#, E♭
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

    ///Get the note's default placement given its midi value and the key of scale.
    ///Some notes in some minor scale are assigned specific non-default placements, accidentals and note names (e.g. E#)
    func getDefaultPlacement(scale:Scale, noteValue:Int, scaleDegree:Int, keyNum:Int) -> NoteStaffPlacement? {
        guard scaleDegree < self.noteOffsetByKey.count else {
            AppLogger.shared.reportError(self, "Invalid degree \(scaleDegree)")
            return nil
        }
        guard keyNum < 12 else {
            AppLogger.shared.reportError(self, "Invalid key \(scaleDegree)")
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
            let placement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: offset, accidental: accidental, placementCanBeSetByKeySignature: true)
            
            ///Overide the default accidentals for special cases.
            ///e.g. Do modification of 'unusual' required accidental notation when required.
            ///e.g. F# minor requires F natural to be shown as E# which is returned as the default placement
            ///The flag (allowModify) will cause subsequent processing to not modify the accidental or placement settings
            if [.harmonicMinor, .melodicMinor].contains(scale.scaleType) {
                if scale.scaleRoot.name == "F#" && noteValue % 12 == 5 {
                    var customPlacement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: placement.offsetFromStaffMidline-1, placementCanBeSetByKeySignature: false)
                    customPlacement.accidental = 1
                    return customPlacement
                }
                if scale.scaleRoot.name == "C#" && noteValue % 12 == 0 {
                    var customPlacement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: placement.offsetFromStaffMidline-1, placementCanBeSetByKeySignature: false)
                    customPlacement.accidental = 1
                    return customPlacement
                }
                if scale.scaleRoot.name == "G#" {
                    if noteValue % 12 == 7 {
                        var customPlacement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: placement.offsetFromStaffMidline-1, placementCanBeSetByKeySignature: false)
                        customPlacement.accidental = 2 //double sharp 
                        return customPlacement
                    }
                    if noteValue % 12 == 5 {
                        var customPlacement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: placement.offsetFromStaffMidline-1, placementCanBeSetByKeySignature: false)
                        customPlacement.accidental = 1
                        return customPlacement
                    }
                }
            }
            ///Ensure dim 7th is notated as minor 3rd on top of minor 3rd
            if scale.scaleType == .arpeggioDiminishedSeventh {
                if noteValue % 12 == 8 {
                    var customPlacement = NoteStaffPlacement(midi: noteValue, offsetFroMidLine: placement.offsetFromStaffMidline+1, placementCanBeSetByKeySignature: false)
                    customPlacement.accidental = -1
                    return customPlacement
                }
            }
            return placement
        }
        else {
            AppLogger.shared.reportError(self, "Invalid data at row:\(scaleDegree), col:\(keyNum)")
            return nil
        }
    }
}

public enum ClefType {
    case treble
    case bass
}

public class StaffClef : ScoreEntry { 
    let scale:Scale
    let clefType:ClefType
    let score:Score
    var staffOffsets:[Int] = []
    private(set) var noteStaffPlacement:[NoteStaffPlacement]=[]
    var lowestNoteValue:Int
    var highestNoteValue:Int
    var middleNoteValue:Int
    
    init(scale:Scale, score:Score, clefType:ClefType) {
        self.scale = scale
        self.score = score
        self.clefType = clefType     
        self.lowestNoteValue = 20 //MIDI C0
        self.highestNoteValue = 107 //MIDI B7
        self.middleNoteValue = clefType == ClefType.treble ? 71 : StaffNote.MIDDLE_C - StaffNote.OCTAVE + 2
        self.middleNoteValue = clefType == .treble ? 71 : StaffNote.MIDDLE_C - StaffNote.OCTAVE + 2
        
        super.init()
        self.setPlacements(scale: scale)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    ///The placement tells a note how to display itself
    ///Note offset from middle of staff is dependendent on the staff
    func getNoteViewPlacement(note:StaffNote) -> NoteStaffPlacement {
        let defaultPlacement:NoteStaffPlacement
        if note.midi < 0 || note.midi > noteStaffPlacement.count-1 {
            defaultPlacement = noteStaffPlacement[0]
        }
        else {
            //this is wrong for Gr 1, D chromo, ascending G#
            defaultPlacement = noteStaffPlacement[note.midi]
        }
        let placement = NoteStaffPlacement(midi: note.midi,
                                           offsetFroMidLine: defaultPlacement.offsetFromStaffMidline,
                                           accidental: defaultPlacement.accidental, 
                                           placementCanBeSetByKeySignature: defaultPlacement.placementCanBeSetByKeySignature)
        return placement
    }
    
    ///Determine the staff placement for each note pitch
    func setPlacements(scale:Scale) {
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

        let noteOffsetsInScaleByKey = NoteOffsetsInScaleByKey(keyType: score.key.type)
        
        for midiValue in 0...highestNoteValue {
            //Fix - longer? - offset should be from middle C, notes should be displayed on both staffs from a single traversal of the score's timeslices
            let placement = NoteStaffPlacement(midi: 0, offsetFroMidLine: 0, placementCanBeSetByKeySignature: true)
            noteStaffPlacement.append(placement)
            if midiValue < middleNoteValue - 6 * StaffNote.OCTAVE || midiValue >= middleNoteValue + 6 * StaffNote.OCTAVE {
                continue
            }

            var offsetFromTonic = (midiValue - StaffNote.MIDDLE_C) % StaffNote.OCTAVE
            if offsetFromTonic < 0 {
                offsetFromTonic = 12 + offsetFromTonic
            }
           guard let notePlacement = noteOffsetsInScaleByKey.getDefaultPlacement(scale: scale, noteValue: midiValue, scaleDegree: offsetFromTonic, keyNum: keyNumber) else {
                AppLogger.shared.reportError(self, "No note offset data for note \(midiValue)")
                break
            }

            var offsetFromMidLine = notePlacement.offsetFromStaffMidline

            var octave:Int
            let referenceNote = self.clefType == .treble ? StaffNote.MIDDLE_C : StaffNote.MIDDLE_C - 2 * StaffNote.OCTAVE
            if midiValue >= referenceNote {
                octave = (midiValue - referenceNote) / StaffNote.OCTAVE
            }
            else {
                octave = (referenceNote - midiValue) / StaffNote.OCTAVE
                octave -= 1
            }
            offsetFromMidLine += (octave - 1) * 7 //8 offsets to next octave
            //offsetFromMidLine += self.clefType == .treble ? 1 : -1
            offsetFromMidLine += self.clefType == .treble ? 1 : -1
            placement.offsetFromStaffMidline = offsetFromMidLine
            placement.accidental = notePlacement.accidental
            placement.placementCanBeSetByKeySignature = notePlacement.placementCanBeSetByKeySignature
            noteStaffPlacement[midiValue] = placement
        }
    }
}
