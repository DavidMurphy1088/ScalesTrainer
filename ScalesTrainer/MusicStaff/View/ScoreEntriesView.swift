import SwiftUI
import CoreData

struct ScoreEntriesView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    var noteLayoutPositions:NoteLayoutPositions
    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    let scoreView:ScoreView
    
    static var viewNum:Int = 0
    let viewNum:Int
    
    init(score:Score, staff:Staff, scoreView:ScoreView) {
        self.score = score
        self.staff = staff
        self.noteLayoutPositions = staff.noteLayoutPositions
        //self.barLayoutPositions = score.barLayoutPositions
        ScoreEntriesView.viewNum += 1
        self.viewNum = ScoreEntriesView.viewNum
        //self.noteOffsetsInStaffByKey1 = NoteOffsetsInStaffByKey(keyType: score.key.type == .major ? .major : .minor)
        self.scoreView = scoreView
    }
    
//    ///Return the start and end points for the quaver beam based on the note postions that were reported
    func getBeamLine(endNote:StaffNote, noteWidth:Double, startNote:StaffNote) -> (CGPoint, CGPoint)? {
        let stemDirection:Double = startNote.stemDirection == .up ? -1.0 : 1.0
//        if [TimeSliceStatusTag.rhythmError].contains(startNote.timeSlice.statusTag) {
//            return nil
//        }
        let stemLength = max(startNote.stemLength, endNote.stemLength) * score.lineSpacing
        //let endNotePos = noteLayoutPositions.positions[endNote]
        let endNotePos = noteLayoutPositions.getPositionForSequence(sequence: endNote.timeSlice.sequence)

        if let endNotePos = endNotePos {
            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
            
            let endPitchOffset = endNote.noteStaffPlacement.offsetFromStaffMidline
            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * score.lineSpacing * -0.5)
            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
            
            //start note
            let startNotePos = noteLayoutPositions.positions[startNote]
            if let startNotePos = startNotePos {
                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
                let startPitchOffset = startNote.noteStaffPlacement.offsetFromStaffMidline
                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * score.lineSpacing * -0.5)
                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
                let p1 = CGPoint(x:xEndMid, y: yEndNoteStemTip)
                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
                return (p1, p2)
            }
        }
        return nil
    }
    
    func getQuaverImage(note:StaffNote) -> Image {
        //return Image(note.midiNumber > 71 ? "quaver_arm_flipped_grayscale" : "quaver_arm_grayscale")
        return Image("")
    }
    
    func quaverBeamView(line: (CGPoint, CGPoint), startNote:StaffNote, endNote:StaffNote, lineSpacing: Double) -> some View {
        ZStack {
            if startNote.timeSlice.sequence == endNote.timeSlice.sequence {
                //An unpaired quaver
                let height = lineSpacing * 4.5
                let width = height / 3.0
                let flippedHeightOffset = startNote.midi > 71 ? height / 2.0 : 0.0
//                getQuaverImage(note:startNote)
//                    .resizable()
//                    .renderingMode(.template)
//                    .foregroundColor(startNote.getColor(staff: staff))
//                    .scaledToFit()
//                    .frame(height: height)
//                    .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset)
//                
//                if endNote.getValue() == StaffNote.VALUE_SEMIQUAVER {
//                    getQuaverImage(note:startNote)
//                        .resizable()
//                        .renderingMode(.template)
//                        .foregroundColor(startNote.getColor(staff: staff))
//                        .scaledToFit()
//                        .frame(height: height)
//                        .position(x: line.0.x + width / 3.0 , y: line.1.y + height / 3.5 - flippedHeightOffset + lineSpacing)
//                }
            }
            else {
                //A paired quaver
                Path { path in
                    path.move(to: CGPoint(x: line.0.x, y: line.0.y))
                    path.addLine(to: CGPoint(x: line.1.x, y: line.1.y))
                }
                .stroke(endNote.getColor(staff: staff), lineWidth: 3)
            }
        }
    }
        
//    func log(_ s:String) -> Bool {
//    }
    
    func updateQuaverBeamsLayouts(timeSlice:TimeSlice, frame:CGRect) {
        ///Update note layout positions so the view can draw in quaver beams in the exact right x,y positions
        noteLayoutPositions.storePosition(onAppear: true, notes: timeSlice.getTimeSliceNotes(handType: staff.handType), rect: frame)
        DispatchQueue.main.async {
            ///Ensure note layout updates are published for subsequent drawing of quaver beams
            staff.beamUpdates += 1
        }
    }
    
    var body: some View {
        ZStack {
            let noteWidth = score.lineSpacing * 1.1 * (self.orientationInfo.isPortrait ? 1.0 : 1.0)
            HStack(spacing: 0) { //HStack - score entries display along the staff
                ForEach(score.scoreEntries) { entry in
                    ZStack {
                        if entry is TimeSlice {
                            let timeSlice = entry as! TimeSlice
                            ZStack { // Each note frame in the timeslice shares the same same vertical space
                                TimeSliceView(staff: staff,
                                              timeSlice: timeSlice,
                                              noteWidth: noteWidth,
                                              lineSpacing: score.lineSpacing,
                                              isPortrait: self.orientationInfo.isPortrait)
                                .background(GeometryReader { geometry in
                                    ///Record and store the note's postion so we can later draw its stems which maybe dependent on the note being in a quaver group with a quaver beam
                                    Color.clear
                                        .onChange(of: self.orientationInfo.isPortrait, {
                                            self.updateQuaverBeamsLayouts(timeSlice: timeSlice, frame: geometry.frame(in: .named("NotePositioningStack")))
                                        })
                                        .onAppear {
                                            self.updateQuaverBeamsLayouts(timeSlice: timeSlice, frame: geometry.frame(in: .named("NotePositioningStack")))
                                        }
                                    })
                                    
                                    StemView(score:score,
                                             staff:staff,
                                             notePositionLayout: noteLayoutPositions,
                                             notes: timeSlice.getTimeSliceNotes(handType: staff.handType))
                            }
                        }
                        
                        if entry is BarLine {
                            let barLine = entry as! BarLine
                            if barLine.visibleOnStaff || barLine.forStaffSpacing {
                                GeometryReader { geometry in
                                    BarLineView(score: score, entry: entry, staff: staff) //, staffLayoutSize: staffLayoutSize)
                                        .frame(height: score.getStaffHeight())
                                        .onAppear {
                                            let barLine = entry as! BarLine
                                            score.barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onAppear")
                                        }
//                                        .onChange(of: score.lineSpacing) { oldValue, newValue in
//                                            let barLine = entry as! BarLine
//                                            score.barLayoutPositions.storePosition(barLine: barLine, rect: geometry.frame(in: .named("ScoreView")), ctx: "onChange")
//                                        }
                                }
                            }
                        }
                        if entry is StaffClef {
                            let clef = entry as! StaffClef
                            StaffClefView(score: score, staffClef: entry as! StaffClef, staff: staff)
                        }
                    }
                    .coordinateSpace(name: "VStack")
                    //IMPORTANT - keep this coordinateSpace name since the quaver beam code needs to know exactly the note view width
                }

                ///Spacing before end of staff
                Text(" ")
                    .frame(width:1.5 * noteWidth)
            }
            .coordinateSpace(name: "NotePositioningStack")

            ///---------- Quaver beams ------------
            ///Draw quaver stems and beams over quavers that are beamed together
            ///noteLayoutPositions has recorded the position of each note to enable drawing the quaver beam
            
            GeometryReader { geo in
                ZStack {
                    ZStack {
                        ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.timeSlice.sequence < $1.key.timeSlice.sequence }), id: \.key.id) {
                            endNote, endNotePos in
                            if endNote.beamType == .end || endNote.beamType == .none {
                                let startNote = endNote.getBeamStartNote(score: score, staff: staff, np:noteLayoutPositions)
                                if let line = getBeamLine(endNote: endNote,
                                                          noteWidth: noteWidth,
                                                          startNote: startNote) {
                                    quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: score.lineSpacing)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, 0)
                .onAppear() {
                    //_ = log(ctx: "BeamView OnAppear")
                }
            }
            .padding(.horizontal, 0)
        }
        .coordinateSpace(name: "ZStack0")
        .onAppear() {
        }
    }
    
//    func getNote(entry:ScoreEntry) -> StaffNote? {
//        if entry is TimeSlice {
//            let notes = entry.getTimeSliceNotes()
//            if notes.count > 0 {
//                return notes[0]
//            }
//        }
//        return nil
//    }
//
//    ///Return the start and end points for te quaver beam based on the note postions that were reported
//    func getBeamLine(endNote:Note, noteWidth:Double, startNote:Note, stemLength:Double) -> (CGPoint, CGPoint)? {
//        let stemDirection:Double = startNote.stemDirection == .up ? -1.0 : 1.0
//        if [StatusTag.rhythmError].contains(startNote.timeSlice.statusTag) {
//            return nil
//        }
//        let endNotePos = noteLayoutPositions.positions[endNote]
//        if let endNotePos = endNotePos {
//            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
//            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
//
//            let endPitchOffset = endNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
//            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * score.lineSpacing * -0.5)
//            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
//
//            //start note
//            let startNotePos = noteLayoutPositions.positions[startNote]
//            if let startNotePos = startNotePos {
//                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0) - noteWidth/.0
//                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
//                let startPitchOffset = startNote.getNoteDisplayCharacteristics(staff: staff).offsetFromStaffMidline
//                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * score.lineSpacing * -0.5)
//                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
//                let p1 = CGPoint(x:5, y: yEndNoteStemTip)
//                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
//                return (p1, p2)
//            }
//        }
//        return nil
//    }
}

