import SwiftUI
import CoreData

struct ScoreEntriesView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    var noteLayoutPositions:NoteLayoutPositions
    //var barLayoutPositions:BarLayoutPositions
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
        print("============== ScoreEntriesView, getBeamLine", "🥵🥵🥵🥵🥵NONE")
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
        
    func log(_ s:String, printIt:Bool) -> Bool {
        if (false && printIt) {
            print("=========== ScoreEntriesView", s)
        }
        return true
    }
//    func resetQuaverBeamsLayouts() {
//        print("==========🟢🟢reset")
//        noteLayoutPositions.positions = [:]
//    }
    func updateQuaverBeamsLayouts(mode:Int, timeSlice:TimeSlice, frame:CGRect) {
        ///Update note layout positions so the view can draw in quaver beams in the exact right x,y positions
        if noteLayoutPositions.storePosition(mode:mode, notes: timeSlice.getTimeSliceNotes(handType: staff.handType), rect: frame) {
            DispatchQueue.main.async {
//                let notes = timeSlice.getTimeSliceNotes(handType: .right) //♦️♦️♦️♦️♦️♦️♦️ Temporary ./...
//                if notes.count > 0 && notes[0].midi == 80 {
//                    print("==========🟢updateQuaverBeamsLayouts", "mode:", mode, "updateCount:", "pos:", frame.midX, "upd:", staff.notePositionsUpdates)
//                }
                ///Ensure note layout updates are published for subsequent drawing of quaver beams
                staff.notePositionsUpdates += 1
                //            if notes.count > 0 && notes[0].midi == 80 {
                //                print("==========updateQuaverBeamsLayouts DISPATCHED", onAppear, staff.beamUpdates)
                //            }
            }
        }
    }
    
    func updateBarPostionsLayouts(mode:Int, barLine:BarLine, frame:CGRect) {
        score.barLayoutPositions.storePosition(mode:mode, barLine: barLine, rect: frame)
        DispatchQueue.main.async {
            score.barPositionsUpdates += 1
        }
    }
    
    struct TimeSlicePositionPreferenceKey: PreferenceKey {
        // Store tuples of (TimeSlice, Anchor<CGPoint>)
        static var defaultValue: [(timeSlice: TimeSlice, position: Anchor<CGPoint>)] = []

        static func reduce(value: inout [(timeSlice: TimeSlice, position: Anchor<CGPoint>)],
                           nextValue: () -> [(timeSlice: TimeSlice, position: Anchor<CGPoint>)]) {
            value.append(contentsOf: nextValue())
        }
    }
    
    func convert(prefs: [(timeSlice: TimeSlice, position: Anchor<CGPoint>)], proxy:GeometryProxy) -> Bool {
        noteLayoutPositions.debug("1")
        for pref in prefs {
            let ts:TimeSlice = pref.timeSlice
            noteLayoutPositions.positions = [:]
            if ts.entries.count > 0 {
                if let note:StaffNote = ts.entries[0] as? StaffNote {
                    let pos = proxy[pref.position]
                    noteLayoutPositions.positions[note] = CGRect(origin: pos, size: CGSize(width: 1, height: 1))
                }
            }
        }
        noteLayoutPositions.debug("2")
        return true
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
                                .anchorPreference(
                                    key: TimeSlicePositionPreferenceKey.self,
                                    value: .center,
                                    transform: { [ (timeSlice, $0) ] } // Store the TimeSlice and its anchor
                                )
                                .background(GeometryReader { geometry in
                                    ///Record and store the note's position so we can later draw its stems which will be drawn with different stem lengths if the note is under a quaver beam.
                                    Color.clear
                                        .onAppear {
                                            self.updateQuaverBeamsLayouts(mode:0, timeSlice: timeSlice, frame: geometry.frame(in: .named("NotePositioningStack")))
                                        }
                                        .onChange(of: geometry.size) { oldSize, newSize in
                                            self.updateQuaverBeamsLayouts(mode:1, timeSlice: timeSlice,
                                                                          frame: geometry.frame(in: .named("NotePositioningStack")))
                                        }
                                })
                                    
                                StemView(score:score,
                                         staff:staff,
                                         notePositionLayout: noteLayoutPositions,
                                         notes: timeSlice.getTimeSliceNotes(handType: staff.handType))
                                //.border(Color.blue, width: 2)
                            }
                        }
                        
                        if entry is BarLine {
                            let barLine = entry as! BarLine
                            if barLine.visibleOnStaff || barLine.forStaffSpacing {
                                GeometryReader { geometry in
                                    BarLineView(score: score, entry: entry, staff: staff) //, staffLayoutSize: staffLayoutSize)
                                        .background(GeometryReader { geometry in
                                            ///Record and store the bar's postion. A bar line must later be drawn at the same position that covers both staffs in the score.
                                            Color.clear
                                            ///Adding the below breaks quaver beams
//                                                .onAppear {
//                                                    self.updateBarPostionsLayouts(mode: 0, barLine: barLine, frame: geometry.frame(in: .named("ScoreView")))
//                                                }
//                                                .onChange(of: geometry.size) { oldSize, newSize in
//                                                    self.updateBarPostionsLayouts(mode: 1, barLine: barLine, frame: geometry.frame(in: .named("ScoreView")))
//                                                }
                                        })

                                }
                            }
                        }
                        if entry is StaffClef {
                            //let clef = entry as! StaffClef
                            StaffClefView(score: score, staffClef: entry as! StaffClef, staff: staff)
                        }
                    }
                    .coordinateSpace(name: "VStack")
//                    .onChange(of: self.orientationInfo.isPortrait, {
//                        self.resetQuaverBeamsLayouts()
//                    })

                    //IMPORTANT - keep this coordinateSpace name since the quaver beam code needs to know exactly the note view width
                }

                ///Spacing before end of staff
                //Text("\(staff.beamUpdates)")
                Text(" ")
                    .frame(width:1.5 * noteWidth)
            }
            
            ///NEW fix for quaver beams
//            .overlayPreferenceValue(TimeSlicePositionPreferenceKey.self) { anchors in
//                GeometryReader { geo in
//                    if convert(prefs:anchors, proxy: geo) {
//                        ZStack {
//                            ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.timeSlice.sequence < $1.key.timeSlice.sequence }), id: \.key.id) {
//                                endNote, endNotePos1 in
//                                if endNote.beamType == .end || endNote.beamType == .none {
//                                    let startNote = endNote.getBeamStartNote(score: score, staff: staff, np:noteLayoutPositions)
//                                    if let line = getBeamLine(endNote: endNote,
//                                                              noteWidth: noteWidth,
//                                                              startNote: startNote) {
//                                        if log("----- Draw quaver beam \(line.0)", printIt: endNote.beamType == .end) {
//                                            quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: score.lineSpacing)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 0)
//                    }
//                        
//                }
//                    GeometryReader { proxy in
//                        Path { path in
//                            for (index, anchorInfo) in anchors.enumerated() {
////                                // Resolve the anchor to a CGPoint
////                                let position1 = proxy[anchorInfo.position]
////                                let timeSlice:TimeSlice = anchorInfo.timeSlice
////                                let ts = timeSlice.entries as [TimeSliceEntry]
////                                if let note = ts[0] as! StaffNote
////                                print("=========", timeSlice.sequence, note.midi)
////                                if timeSlice.getTimeSliceNotes(handType: .right).count > 0 {
////                                    let endNote = timeSlice.getTimeSliceNotes(handType: .right)[0]
////                                    if endNote.beamType == .end || endNote.beamType == .none {
////                                        for (index, anchorInfo) in anchors.enumerated() {
////                                            let timeSlice:TimeSlice = anchorInfo.timeSlice
////                                            if timeSlice.getTimeSliceNotes(handType: .right).count > 0 {
////                                                let note = timeSlice.getTimeSliceNotes(handType: .right)[0]
////                                                //let p:Anchor<CGPoint> = anchorInfo.position
////                                                let point = proxy[anchorInfo.position]
////                                                noteLayoutPositions.positions[note] = CGRect(origin: point, size: CGSize(width: 1, height: 1))
////                                            }
////                                        }
////                                        let startNote = endNote.getBeamStartNote(score: score, staff: staff, np:noteLayoutPositions)
////                                        if let line = getBeamLine(endNote: endNote,
////                                                                  noteWidth: noteWidth,
////                                                                  startNote: startNote) {
////                                            if log("----- Draw quaver beam \(line.0)", printIt: endNote.beamType == .end) {
////                                                quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: score.lineSpacing)
////                                            }
////                                        }
////                                    }
//////
//////                                    // Connect the time slices with lines
//////                                    if index == 0 {
//////                                    path.move(to: position)
//////                                } else {
//////                                    path.addLine(to: position)
//////                                }
////                            }
////
////                                // Optional: Print or use the TimeSlice for debugging
////                                //print("TimeSlice \(timeSlice.description) is at \(position)")
//                            }
//                        }
//                        .stroke(Color.red, lineWidth: 2)
//                    }
//                }
            .coordinateSpace(name: "NotePositioningStack")

            ///---------- Quaver beams ------------
            ///Draw quaver stems and beams over quavers that are beamed together.
            ///Staff noteLayoutPositions has recorded the position of each note to enable drawing the quaver beam.
            ///OLD quaver beams
        
            GeometryReader { geo in
                ZStack {
                    ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.timeSlice.sequence < $1.key.timeSlice.sequence }), id: \.key.id) {
                        endNote, endNotePos1 in
                            if endNote.beamType == .end || endNote.beamType == .none {
                                let startNote = endNote.getBeamStartNote(score: score, staff: staff, np:noteLayoutPositions)
                                if let line = getBeamLine(endNote: endNote,
                                                          noteWidth: noteWidth,
                                                          startNote: startNote) {
                                    //if log("----- Draw quaver beam \(line.0)", printIt: endNote.beamType == .end) {
                                        quaverBeamView(line: line, startNote: startNote, endNote: endNote, lineSpacing: score.lineSpacing)
                                    //}
                                }
                            }
                    }
                }
                .padding(.horizontal, 0)
            }
//            .padding(.horizontal, 0)
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

