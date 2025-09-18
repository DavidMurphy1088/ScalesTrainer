import SwiftUI
import CoreData

struct ScoreEntriesView: View {
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation

    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    @State var resultWidth:CGFloat = 0
    
    let scoreView:ScoreView
    
    static var viewNum:Int = 0
    let viewNum:Int
    let lineSpacing:Double
    
    init(score:Score, staff:Staff, scoreView:ScoreView, lineSpacing:Double) {
        self.score = score
        self.staff = staff
        ScoreEntriesView.viewNum += 1
        self.viewNum = ScoreEntriesView.viewNum
        self.scoreView = scoreView
        self.lineSpacing = lineSpacing
    }
    
    ///Return the start and end points for the quaver beam based on the note postions that were reported
    func getBeamLine(noteLayoutPositions:NoteLayoutPositions, endNote:StaffNote, noteWidth:Double, startNote:StaffNote) -> (CGPoint, CGPoint)? {
        let stemDirection:Double = startNote.stemDirection == .up ? -1.0 : 1.0
        let stemLength = max(startNote.stemLength, endNote.stemLength) * self.lineSpacing
        //let endNotePos = noteLayoutPositions.positions[endNote]
        let endNotePos = noteLayoutPositions.getPositionForSequence(sequence: endNote.timeSlice.sequence)

        if let endNotePos = endNotePos {
            let xEndMid = endNotePos.origin.x + endNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
            let yEndMid = endNotePos.origin.y + endNotePos.size.height / 2.0
            
            let endPitchOffset = endNote.noteStaffPlacement.offsetFromStaffMidline
            let yEndNoteMiddle:Double = yEndMid + (Double(endPitchOffset) * self.lineSpacing * -0.5)
            let yEndNoteStemTip = yEndNoteMiddle + stemLength * stemDirection
            
            let startNotePos = noteLayoutPositions.positions[startNote]
            if let startNotePos = startNotePos {
                let xStartMid = startNotePos.origin.x + startNotePos.size.width / 2.0 + (noteWidth / 2.0 * stemDirection * -1.0)
                let yStartMid = startNotePos.origin.y + startNotePos.size.height / 2.0
                let startPitchOffset = startNote.noteStaffPlacement.offsetFromStaffMidline
                let yStartNoteMiddle:Double = yStartMid + (Double(startPitchOffset) * self.lineSpacing * -0.5)
                let yStartNoteStemTip = yStartNoteMiddle + stemLength * stemDirection
                let p1 = CGPoint(x:xEndMid, y: yEndNoteStemTip)
                let p2 = CGPoint(x:xStartMid, y:yStartNoteStemTip)
                return (p1, p2)
            }
        }
        return nil
    }
    
    func getQuaverImage(note:StaffNote) -> Image {
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
        
    func log(_ s:String) -> Bool {
        return true
    }
    
    struct TimeSlicePositionPreferenceKeyOLD: PreferenceKey {
        static var defaultValue: [(timeSlice: TimeSlice,
                                   position: Anchor<CGRect>,
                                  isPortrait: Bool)] = []

        static func reduce(
            value: inout [(timeSlice: TimeSlice, position: Anchor<CGRect>, isPortrait: Bool)],
            nextValue: () -> [(timeSlice: TimeSlice, position: Anchor<CGRect>, isPortrait: Bool)]
        ) {
            value.append(contentsOf: nextValue())
        }
    }
    
    struct TimeSlicePositionPreferenceKey: PreferenceKey {
        static var defaultValue: [(scoreEntry: ScoreEntry,
                                   position: Anchor<CGRect>,
                                   isPortrait: Bool)] = []

        static func reduce(
            value: inout [(scoreEntry: ScoreEntry, position: Anchor<CGRect>, isPortrait: Bool)],
            nextValue: () -> [(scoreEntry: ScoreEntry, position: Anchor<CGRect>, isPortrait: Bool)]
        ) {
            value.append(contentsOf: nextValue())
        }
    }

    func getNoteWidth() -> Double {
        var noteWidth = self.lineSpacing * 1.1
        if score.getScale().getScaleNoteCount() > 32 { //Chromatic has many notes
            if self.orientation.isPortrait {
                noteWidth = noteWidth * 0.85
            }
            else {
                noteWidth = noteWidth * 1.0
            }
        }
        return noteWidth
    }
    
    var body: some View {
        ZStack {
            let noteWidth = getNoteWidth()
            
            HStack(spacing: 0) { //HStack - score entries display along the staff
                ForEach(score.scoreEntries) { entry in
                    ZStack {
                        if entry is TimeSlice {
                            let timeSlice = entry as! TimeSlice
                            
                            ZStack { // Each note frame in the timeslice shares the same same vertical space
                                GeometryReader { proxy1 in
                                    TimeSliceView(staff: staff,
                                                  timeSlice: timeSlice,
                                                  noteWidth: noteWidth,
                                                  lineSpacing: self.lineSpacing,
                                                  isPortrait: self.orientation.isPortrait)
                                    
                                    .anchorPreference(
                                        key: TimeSlicePositionPreferenceKey.self,
                                        value: .bounds,
                                        transform: { anchor in
                                            [(scoreEntry: timeSlice, position: anchor, orientation.isPortrait)]
                                        }
                                    )
                                }

                            }
                         }
                        
                        if entry is BarLine {
                            let barLine = entry as! BarLine
                            if barLine.visibleOnStaff || barLine.forStaffSpacing {
                                GeometryReader { geometry in
                                    BarLineView(score: score, entry: entry, staff: staff, lineSpacing: self.lineSpacing) //, staffLayoutSize: staffLayoutSize)
                                        .anchorPreference(
                                            key: TimeSlicePositionPreferenceKey.self,
                                            value: .bounds,
                                            transform: { anchor in
                                                [(scoreEntry: barLine, position: anchor, orientation.isPortrait)]
                                            }
                                        )
                                }
                            }
                        }
                        if log("clefView") {
                            if entry is StaffClef {
                                StaffClefView(score: score, staffClef: entry as! StaffClef, staff: staff, lineSpacing: self.lineSpacing)
                            }
                        }
                    }
                }

                ///Spacing before end of staff
                //Text("\(staff.beamUpdates)")
                Text(" ").frame(width:1.5 * noteWidth)
            }
            
            ///Quaver beams, note stems and dual-staff bar lines are drawn using the note positions that were recorded in the anchorPositions
            .overlayPreferenceValue(TimeSlicePositionPreferenceKey.self) { anchorPositions in
                GeometryReader { geo in
                    let noteLayoutPositions = NoteLayoutPositions(scale:score.getScale(), handType: staff.handType, prefs:anchorPositions, proxy: geo)
                    ZStack {
                        ForEach(noteLayoutPositions.positions.sorted(by: { $0.key.timeSlice.sequence < $1.key.timeSlice.sequence }), id: \.key.id) {
                            note, notePosition in
                            if note.beamType == .end || note.beamType == .none {
                                let startNote = note.getBeamStartNote(score: score, staff: staff, np:noteLayoutPositions)
                                
                                if let line = getBeamLine(noteLayoutPositions: noteLayoutPositions,
                                                          endNote: note,
                                                          noteWidth: noteWidth,
                                                          startNote: startNote) {
                                    quaverBeamView(line: line, startNote: startNote, endNote: note, lineSpacing: self.lineSpacing)
                                }
                            }

                            StemView(
                                notePosition: notePosition,
                                notes: [note],
                                notePositionsLayout: noteLayoutPositions,
                                geoWidth: geo.size.width,
                                geoHeight: geo.size.height
                            )
                            //Circle().frame(width: 7, height: 7).foregroundColor(.purple).position(x: notePosition.midX, y: notePosition.midY)
                        }
                        ///Bar lines must cover both staves
                        if score.getStaffs().count > 1 {
                            ForEach(Array(anchorPositions.enumerated()), id: \.offset) { index, anchor in
                                if anchor.scoreEntry is BarLine {
                                    let pos: CGRect = geo[anchor.position]
                                    let y = staff.handType
                                    Path { path in
                                        path.move(to: CGPoint(x: pos.midX, y: pos.midY))
                                        path.addLine(to: CGPoint(x: pos.midX, y: staff.handType == .right ? pos.maxY : 0))
                                    }
                                    .stroke(Color.black, lineWidth: 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                }
            }
            .coordinateSpace(name: "NotePositioningStack")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            ///This forces the view to reload.
            orientation = UIDevice.current.orientation
        }
        .id(orientation.isPortrait)
    }
    
    ///----------------------------- Stem View ------------------------------
    ///26Jan2025 When the device rotates, the GeometryReader recalculates its size and position, which can lead to changes in the coordinate space.
    ///This code must be in the the ScoreEntriesView to ensure that it executes in the same view-body co-ordinate space as the the notes were drawn in.
    ///If this code lives in a different View struct there is no way to ensure the co-ordinate space that the stems are drawn in is the same co-ordinate space as where the notes were drawn in.
    
    func getStemLength(notes:[StaffNote]) -> Double {
        var len = 0.0
        if notes.count > 0 {
            len = notes[0].stemLength * self.lineSpacing
        }
        return len
    }
    
    func midPointXOffset(notes:[StaffNote], staff:Staff, stemDirection:Double) -> Double {
        let delta = stemDirection * -1.0
        return (stemDirection * -1.0 * getNoteWidth() - delta)
    }
    
    func StemView(notePosition: CGRect, notes: [StaffNote], notePositionsLayout: NoteLayoutPositions, geoWidth:Double, geoHeight:Double) -> some View {
        ZStack {
            let staffNotes = notes// getStaffNotes(staff: staff)
            if staffNotes.count > 0 {
                if staffNotes.count <= 1 {
                    ///Draw in the stem lines for all notes under the current stem line if this is one.
                    ///For a group of notes under a quaver beam the the stem direction (and later length...) is determined by only one note in the group
                    let startBeamNote = staffNotes[0].getBeamStartNote(score: score, staff: staff, np: notePositionsLayout)
                    let inErrorAjdust = 0.0 //notes.notes[0].noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0
                    if startBeamNote.getValue() != StaffNote.VALUE_WHOLE {
                        //if startNote.debug("VIEW staff:\(staff.staffNum)") {
                        //Note this code eventually has to go adjust the stem length for notes under a quaver beam
                        //3.5 lines is a full length stem
                        let stemDirection = startBeamNote.stemDirection == .up ? -1.0 : 1.0
                        let midX = notePosition.midX + (midPointXOffset(notes: notes, staff: staff, stemDirection: stemDirection)) / 2.0
                        let midY = geoHeight / 2.0
                        let offsetY = CGFloat(notes[0].noteStaffPlacement.offsetFromStaffMidline) * 0.5 * self.lineSpacing + inErrorAjdust
                        //Test- Circle().frame(width: 7, height: 7).foregroundColor(.purple).position(x: notePosition.midX, y: notePosition.midY)
                        Path { path in
                            path.move(to: CGPoint(x: midX, y: midY - offsetY))
                            path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength(notes: notes) - inErrorAjdust))))
                        }
                        .stroke(notes[0].getColor(staff: staff, resultStatus: nil), lineWidth: 1.5)
                    }
                }
                else {
                    ///This code assumes the stem for a chord wont (yet) be under a quaver beam
                    ZStack {
                        ForEach(staffNotes) { note in
                            let stemDirection = note.stemDirection == .up ? -1.0 : 1.0
                            let midX:Double = (geoWidth + (midPointXOffset(notes: staffNotes, staff: staff, stemDirection: stemDirection))) / 2.0
                            let midY = geoHeight / 2.0
                            let inErrorAjdust = 0.0 //note.noteTag == .inError ? lineSpacing.lineSpacing/2.0 : 0

                            if note.getValue() != StaffNote.VALUE_WHOLE {
                                //if let placement = notes[0].noteStaffPlacement {
                                let offsetY = CGFloat(note.noteStaffPlacement.offsetFromStaffMidline) * 0.5 * self.lineSpacing + inErrorAjdust
                                Path { path in
                                    path.move(to: CGPoint(x: midX, y: midY - offsetY))
                                    path.addLine(to: CGPoint(x: midX, y: midY - offsetY + (stemDirection * (getStemLength(notes: notes) - inErrorAjdust))))
                                }
                                .stroke(staffNotes[0].getColor(staff: staff), lineWidth: 1.5)
                            }
                        }
                    }
                }
            }
        }
    }
    

}

