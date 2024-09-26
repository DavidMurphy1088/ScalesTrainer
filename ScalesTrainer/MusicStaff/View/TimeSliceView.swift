import SwiftUI
import CoreData
import MessageUI
import CoreImage

public struct BarLineView: View {
    var score:Score
    var entry:ScoreEntry
    var staff:Staff
    let visible:Bool
    
    public init(score:Score, entry:ScoreEntry, staff: Staff) {
        self.score = score
        self.entry = entry
        self.staff = staff
        if let barLine = entry as? BarLine {
            self.visible = barLine.visible
        }
        else {
            self.visible = true
        }
    }
    
    public var body: some View {
        ///For some unfathomable reason the bar line does not show if its not in a gemetry reader (-:
        GeometryReader { geometry in
            Rectangle()
                .fill(visible ? Color.black : Color.clear)
                .frame(width: 1.0, height: 4.0 * Double(score.lineSpacing))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        //.frame(maxWidth: Double(staffLayoutSize.lineSpacing)  * 1.0)
        .frame(minWidth: Double(score.lineSpacing)  * 1.1)
        //.border(Color.red)
    }
}

public struct NoteHiliteView: View {
    @ObservedObject var entry:TimeSliceEntry
    var x:CGFloat
    var y:CGFloat
    var width:CGFloat
    
//    func log(entry:TimeSliceEntry) -> Bool {
//        return true
//    }
//    
    public var body: some View {
        VStack {
            //if log(entry: entry) {
                Ellipse()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: width, height: width)
                    .position(x: x, y:y)
            //}
        }
    }
}

public struct TimeSliceView: View {
    @ObservedObject var timeSlice:TimeSlice
    @ObservedObject var scalesModel:ScalesModel
    var staff:Staff
    var color: Color
    var lineSpacing:Double
    var noteWidth:Double
    var accidental:Int?
    
    public init(staff:Staff, timeSlice:TimeSlice, noteWidth:Double, lineSpacing: Double) {
        self.staff = staff
        self.timeSlice = timeSlice
        self.noteWidth = noteWidth
        self.color = Color.black
        self.lineSpacing = lineSpacing
        scalesModel = ScalesModel.shared
    }

    func getAccidental(accidental:Int) -> String {
//        if false {
//            ///requires quite a bit of work in staff placement to get the accidental correct
//            ///for scales (thus far) if an acciental is specified for note display (given the key) that accidental will always be a natural e.g. harmonic and melodic minor scales
//            if accidental < 0 {
//                return "\u{266D}"
//            }
//            else {
//                if accidental > 0 {
//                    return "\u{266F}"
//                }
//                else {
//                    return "\u{266E}"
//                }
//            }
//        }
//        else {
            if accidental == 0 {
                return "\u{266E}" //natural
            }
            else {
                if accidental > 0 {
                    return "\u{266F}"
                }
                else {
                    return "\u{266D}"
                }
            }
//        }
    }
    
    struct LedgerLine:Hashable, Identifiable {
        var id = UUID()
        var offsetVertical:Double
    }
    
    func getLedgerLines(staff:Staff, note:StaffNote, noteWidth:Double, lineSpacing:Double) -> [LedgerLine] {
        var result:[LedgerLine] = []
        let p = note.getNoteDisplayCharacteristics(staff: staff)
        
        if p.offsetFromStaffMidline <= -6 {
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * 1.0))
        }
        if p.offsetFromStaffMidline <= -8 {
            result.append(LedgerLine(offsetVertical: 4 * lineSpacing * 1.0))
        }
        if p.offsetFromStaffMidline <= -10 {
            result.append(LedgerLine(offsetVertical: 5 * lineSpacing * 1.0))
        }
        
        if p.offsetFromStaffMidline >= 6 {
            result.append(LedgerLine(offsetVertical: 3 * lineSpacing * -1.0))
        }
        if p.offsetFromStaffMidline >= 8 {
            result.append(LedgerLine(offsetVertical: 4 * lineSpacing * -1.0))
        }
        if p.offsetFromStaffMidline >= 10 {
            result.append(LedgerLine(offsetVertical: 5 * lineSpacing * -1.0))
        }
        return result
    }
    
    func getTimeSliceEntries() -> [TimeSliceEntry] {
        var result:[TimeSliceEntry] = []
        for n in self.timeSlice.entries {
            result.append(n)
        }
        return result
    }
    
    func RestView(staff:Staff, entry:TimeSliceEntry, lineSpacing:Double, geometry:GeometryProxy) -> some View {
        ZStack {
            
            if entry.getValue() == 0 {
                Text("?")
                    .font(.largeTitle)
                    .foregroundColor(entry.getColor(ctx: "RestView1", staff: staff, adjustFor: false, log: true))
                Spacer()
            }
            else {
                if entry.getValue() == 1 {
                    Image("rest_quarter_grayscale")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(entry.getColor(ctx: "RestView2", staff: staff, adjustFor: false, log: true))
                        .scaledToFit()
                        .frame(height: lineSpacing * 3)
                }
                else {
                    if entry.getValue() == 2 {
                        let height = lineSpacing / 2.0
                        Rectangle()
                            .fill(entry.getColor(ctx: "RestView3", staff: staff, adjustFor: false, log: true))
                            .frame(width: lineSpacing * 1.5, height: height)
                            .offset(y: 0 - height / 2.0)
                    }
                    else {
                        if (entry.getValue() == 1.5) {
                            HStack {
                                Image("rest_quarter_grayscale")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(entry.getColor(ctx: "RestView4", staff: staff, adjustFor: false, log: true))
                                    .scaledToFit()
                                    .frame(height: lineSpacing * 3)
                                Text(".")
                                    .font(.largeTitle)
                                    .foregroundColor(entry.getColor(ctx: "RestView5", staff: staff, adjustFor: false, log: true))
                            }
                        }
                        else {
                            if (entry.getValue() == 4.0) {
                                let height = lineSpacing / 2.0
                                Rectangle()
                                    .fill(entry.getColor(ctx: "RestView6", staff: staff, adjustFor: false, log: true))
                                    .frame(width: lineSpacing * 1.5, height: height)
                                    .offset(y: 0 - height * 1.5)
                            }
                            else {
                                if (entry.getValue() == 0.5 ){
                                    Image("rest_quaver")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(entry.getColor(ctx: "RestView7", staff: staff, adjustFor: false, log: true))
                                        .scaledToFit()
                                        .frame(height: lineSpacing * 2)
                                    
                                }
                                else {
                                    VStack {
                                        Text("?")
                                            .font(.largeTitle)
                                            .foregroundColor(entry.getColor(ctx: "RestView8", staff: staff, adjustFor: false, log: true))
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        //.border(Color.red)
    }
    
    func NoteView(note:StaffNote, noteFrameWidth:Double, geometry: GeometryProxy, statusTag:TimeSliceStatusTag) -> some View {
        ZStack {
            let placement = note.getNoteDisplayCharacteristics(staff: staff)
            let offsetFromStaffMiddle = placement.offsetFromStaffMidline
            let accidental = placement.accidental

            let noteEllipseMidpoint:Double = geometry.size.height/2.0 - Double(offsetFromStaffMiddle) * lineSpacing / 2.0
            let noteValueUnDotted = note.isDotted() ? note.getValue() * 2.0/3.0 : note.getValue()
//            if placement.showOctaveOverlay {
//                VStack {
//                    Text("...")
//                    Spacer()
//                }
//            }
//            if statusTag != .noTag  {
//                Text("X").bold().font(.system(size: lineSpacing * 2.0)).foregroundColor(.red)
//                    .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
//                if note.staffNum == staff.staffNum  {
//                    NoteHiliteView(entry: note, x: noteFrameWidth/2, y: noteEllipseMidpoint, width: noteWidth * 1.7)
//                }
//            }
//            else {
                if note.staffNum == staff.staffNum  {
                    if timeSlice.showIsPlaying {
                        NoteHiliteView(entry: note, x: noteFrameWidth/2, y: noteEllipseMidpoint, width: noteWidth * 1.7)
                    }
                }
                
                if let accidental = accidental {
                    let yOffset = accidental == 1 ? lineSpacing / 5 : 0.0
                    Text(getAccidental(accidental: accidental))
                        .font(.system(size: lineSpacing * 3.0))
                        .frame(width: noteWidth * 1.0, height: CGFloat(Double(lineSpacing) * 1.0))
                        .position(x: noteFrameWidth/2 - lineSpacing * (timeSlice.anyNotesRotated() ? 3.0 : 1.2), //3.0 : 1.5
                                  y: noteEllipseMidpoint + yOffset)
                        .foregroundColor(note.getColor(ctx: "NoteView1", staff: staff, adjustFor: false))
                    
                }
                if [StaffNote.VALUE_QUARTER, StaffNote.VALUE_QUAVER, StaffNote.VALUE_SEMIQUAVER, StaffNote.VALUE_TRIPLET].contains(noteValueUnDotted )  {
                    Ellipse()
                    //Closed ellipse
                        .foregroundColor(note.getColor(ctx: "NoteView2", staff: staff, adjustFor: true))
                        //.foregroundColor(.green)
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 1.0))
                        .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                        //.position(x: noteFrameWidth/2 * (Int.random(in: 0...10) < 3 ? 1.5 : 1.0), y: noteEllipseMidpoint)
                }
                if noteValueUnDotted == StaffNote.VALUE_HALF || noteValueUnDotted == StaffNote.VALUE_WHOLE {
                    Ellipse()
                    //Open ellipse
                        .stroke(note.getColor(ctx: "NoteView3", staff: staff, adjustFor: false), lineWidth: 2)
                        .foregroundColor(note.getColor(ctx: "NoteView4", staff: staff, adjustFor: false))
                        .frame(width: noteWidth, height: CGFloat(Double(lineSpacing) * 0.9))
                        .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
                }
                
                if note.isDotted() {
                    //the dot needs to be moved off the note center to move the dot off a staff line
                    let yOffset = offsetFromStaffMiddle % 2 == 0 ? lineSpacing / 3.0 : 0
                    Ellipse()
                    //Open ellipse
                        .frame(width: noteWidth/3.0, height: noteWidth/3.0)
                        //.position(x: noteFrameWidth/2 + noteWidth/0.90, y: noteEllipseMidpoint - yOffset)
                        //.position(x: noteFrameWidth/2 + noteWidth/1.1, y: noteEllipseMidpoint - yOffset)
                        //.position(x: noteFrameWidth/2 + noteWidth/1.3, y: noteEllipseMidpoint - yOffset)
                        .position(x: noteFrameWidth/2 + noteWidth/1, y: noteEllipseMidpoint - yOffset)
                        .foregroundColor(note.getColor(ctx: "NoteView5", staff: staff, adjustFor: false))
                }
                
                if !note.isOnlyRhythmNote {
                    //if staff.type == .treble {
                    ForEach(getLedgerLines(staff: staff, note: note, noteWidth: noteWidth, lineSpacing: lineSpacing)) { line in
                        let y = geometry.size.height/2.0 + line.offsetVertical
                        ///offset - make sure ledger lines dont join on small wodth stafff's. ex melody examples
                        let xOffset = noteWidth * 0.2
                        let x = noteFrameWidth/2 - noteWidth - (note.rotated ? noteWidth : 0)
                        Path { path in
                            path.move(to: CGPoint(x: x + xOffset, y: y))
                            path.addLine(to: CGPoint(x: x + (2 * noteWidth) - xOffset, y: y))
                        }
                        .stroke(note.getColor(ctx: "NoteView6", staff: staff, adjustFor: false), lineWidth: 1)
                    }
                //}
            }
//            if let valueNormalized = note.valueNormalized {
//                VStack {
//                    Spacer()
//                    Rectangle()
//                    .fill(getTempoGradient(valueNormalized: valueNormalized))
//                    .frame(height: geometry.size.height / 10.0)
//                    //.border(Color.gray, width: 1)
//                    //.opacity(0.6)
//                }
//            }
        }
    }
    
    func getTempoGradient(valueNormalized:Double) -> LinearGradient {
        if valueNormalized < 0.66 {
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white, location: 0.0),
                    .init(color: Color.white, location: 0.2),
                    .init(color: Color(red: 1, green: 0, blue: 0, opacity: 0.6), location: 0.55),
                    .init(color: Color.white, location: 0.55)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        if valueNormalized >= 1.5 {
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white, location: 0.0),
                    .init(color: Color.white, location: 0.4),
                    .init(color: Color(red: 0, green: 0, blue: 1, opacity: 0.6), location: 0.50),
                    .init(color: Color(red: 0, green: 0, blue: 1, opacity: 0.6), location: 0.50),
                    .init(color: Color.white, location: 0.75)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white, location: 0.0),
                .init(color: Color.white, location: 0.99)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    func statusWidth() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                let noteFrameWidth = geometry.size.width * 1.0 //center the note in the space allocated by the parent for this note's view
                ForEach(getTimeSliceEntries(), id: \.id) { entry in
                    VStack {
                        if entry is StaffNote {
                            NoteView(note: entry as! StaffNote, noteFrameWidth: noteFrameWidth, geometry: geometry, statusTag: timeSlice.statusTag)
                            //.border(Color.green)
                        }
                        if entry is Rest {
                            RestView(staff: staff, entry: entry, lineSpacing: lineSpacing, geometry: geometry)
                                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
                            //.border(Color.blue)
                        }
                        
                    }
                }
                
                ///Error status or tempo indication if no error
                
                if let result = scalesModel.resultInternal {
                    VStack {
                        Spacer()
                        if result.noErrors() {
                            let duration = timeSlice.tapDurationNormalised
                            let showTempo = duration != nil && (duration! >= 1.5 || duration! < 0.66)
                            if showTempo {
                                Rectangle()
                                    .fill(getTempoGradient(valueNormalized: duration!))
                                    //.opacity(1)
                                    .frame(width: noteFrameWidth, height: 12)
                            }
                            else {
                                if timeSlice.statusTag == .correct {
                                    Circle()
                                        .fill(Color.green.opacity(0.4))
                                        .frame(width: statusWidth())
                                }
                            }
                        }
                        else {
                            if timeSlice.statusTag == .missingError {
                                Circle()
                                    .fill(Color.yellow.opacity(0.4))
                                    .frame(width: statusWidth())
                            }
                            if timeSlice.statusTag == .correct {
                                Circle()
                                    .fill(Color.green.opacity(0.4))
                                    .frame(width: statusWidth())
                            }
                        }
                    }
                }
            }
            .onAppear() {
                //ScalesModel.shared.score?.debugScore111("__CUCK", withBeam: false, toleranceLevel: 0)
            }
        }
    }
}

