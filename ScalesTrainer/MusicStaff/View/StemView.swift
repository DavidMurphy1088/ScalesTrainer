//import SwiftUI
//import CoreData
//
/////Draw the stem for a timeslice - either a note or a group of notes in a chord
//public struct StemView: View {
//    @ObservedObject var score: Score
//    @State var staff: Staff
//    @State var notePosition:CGRect
//    @State var notePositionsLayout: NoteLayoutPositions
//    var notes: [StaffNote]
//
//    func getStemLength() -> Double {
//        var len = 0.0
//        if notes.count > 0 {
//            len = notes[0].stemLength * score.lineSpacing
//        }
//        return len
//    }
//    
//    func getNoteWidth() -> Double {
//        return score.lineSpacing * 1.2
//    }
//
//    func midPointXOffset(notes:[StaffNote], staff:Staff, stemDirection:Double) -> Double {
//        let delta = stemDirection * -1.0 ///Slightly tighter fit to note head
//        return (stemDirection * -1.0 * getNoteWidth() - delta)
//    }
//
//    func getStaffNotes(staff:Staff) -> [StaffNote] {
//        var notes:[StaffNote] = []
//        for n in self.notes {
//            //if n.staffNum == staff.staffNum {
//                notes.append(n)
//            //}
//        }
//        return notes
//    }
//    
//    func log(startNote:StaffNote) -> Bool {
//        //print("========STEMVIEW", startNote.midi)
//        return true
//    }
//    
//    public var body: some View {
//        ZStack { //GeometryReader { geo in
//            //VStack {
//                let staffNotes = getStaffNotes(staff: staff)
//                if staffNotes.count > 0 {
//                    if staffNotes.count <= 1 {
//                        //let x = log(staffNotes[0])
//                        ///Draw in the stem lines for all notes under the current stem line if this is one.
//                        ///For a group of notes under a quaver beam the the stem direction (and later length...) is determined by only one note in the group
//                        let startBeamNote = staffNotes[0].getBeamStartNote(score: score, staff: staff, np: notePositionsLayout)
//                        let inErrorAjdust = 0.0 //notes.notes[0].noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
//                        if log(startNote: startBeamNote) {
//                            if startBeamNote.getValue() != StaffNote.VALUE_WHOLE {
//                                //if startNote.debug("VIEW staff:\(staff.staffNum)") {
//                                //Note this code eventually has to go adjust the stem length for notes under a quaver beam
//                                //3.5 lines is a full length stem
//                                let stemDirection = startBeamNote.stemDirection == .up ? -1.0 : 1.0
//                                //let midX = (geo.size.width + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection))) / 2.0
//                                let midX = notePosition.midX //+ (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection)) / 2.0
//                                //let midY = geo.size.height / 2.0
//                                let midY = 0
//                                let offsetY = CGFloat(notes[0].noteStaffPlacement.offsetFromStaffMidline) * 0.5 * score.lineSpacing + inErrorAjdust
//                                Circle().frame(width: 7, height: 7).foregroundColor(.purple).position(x: notePosition.midX, y: notePosition.midY)
//
////                                Path { path in
////                                    path.move(to: CGPoint(x: midX, y: midY - offsetY))
////                                    path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
////                                }
////                                .stroke(notes[0].getColor(staff: staff), lineWidth: 1.5)
//                            }
//                        }
//                    }
//                    else {
//                        ///This code assumes the stem for a chord wont (yet) be under a quaver beam
//                        //let furthestFromMidline = self.getFurthestFromMidline(noteArray: staffNotes)
//                        ZStack {
//                            ForEach(staffNotes) { note in
////                                let stemDirection = note.stemDirection == .up ? -1.0 : 1.0
////                                let midX:Double = (geo.size.width + (midPointXOffset(notes: staffNotes, staff: staff, stemDirection: stemDirection))) / 2.0
////                                let midY = geo.size.height / 2.0
////                                let inErrorAjdust = 0.0 //note.noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
////                                
////                                if note.getValue() != StaffNote.VALUE_WHOLE {
////                                    //if let placement = notes[0].noteStaffPlacement {
////                                    let offsetY = CGFloat(note.noteStaffPlacement.offsetFromStaffMidline) * 0.5 * score.lineSpacing + inErrorAjdust
////                                    Path { path in
////                                        path.move(to: CGPoint(x: midX, y: midY - offsetY))
////                                        path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength() - inErrorAjdust))))
////                                    }
////                                    .stroke(staffNotes[0].getColor(staff: staff), lineWidth: 1.5)
////                                }
//                            }
//                        }
//                    }
//                //}
//            }
//        }
//    }
//}
