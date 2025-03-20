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
            self.visible = barLine.visibleOnStaff
        }
        else {
            self.visible = true
        }
    }
    
    public var body: some View {
        ///For some unfathomable reason the bar line does not show if its not in a geometry reader (-:
        GeometryReader { geometry in
            Rectangle()
                .fill(visible ? Color.black : Color.clear)
                .frame(width: 1.0, height: 4.0 * Double(score.lineSpacing))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(minWidth: Double(score.lineSpacing)  * 1.1)
        //.border(Color.red)
    }
}

public struct StaffClefView: View {
    var score:Score
    var staffClef:StaffClef
    var staff:Staff
    let isTransparent:Bool
    
    public init(score:Score, staffClef:StaffClef, staff: Staff) {
        self.score = score
        self.staffClef = staffClef
        self.staff = staff
        self.isTransparent = staff.handType == .left
        
    }
        
    func getClefSize(clefType:ClefType) -> Double {
        var size = 0.0
        if staffClef.clefType == .treble {
            size = score.lineSpacing * 8
        }
        else {
            size = score.lineSpacing * 5 ///31Jan2025 Too big, loose the ':'
            size = score.lineSpacing * 4
        }
        if score.getScale().getScaleNoteCount() > 32 {
            size = size * 0.75 ///2 octave chromatic
        }
        else {
            if score.getScale().getScaleNoteCount() > 24 {
                //size = size * 0.85 ///2 octave scale
            }
        }
        return size
    }
    
    public var body: some View {
        VStack {
            if staffClef.clefType == .treble {
                Text("\u{1d11e}")
                    .foregroundColor(isTransparent ? .black : .clear)
                    .font(.system(size: CGFloat(getClefSize(clefType: staffClef.clefType))))
                    .padding(.top, 0.0)
                    .padding(.bottom, score.lineSpacing * 1.0)
            }
            else {
                Text("\u{1d122}")
                    .foregroundColor(isTransparent ? .black : .clear)
                    .font(.system(size: CGFloat(getClefSize(clefType: staffClef.clefType))))
                    //.padding()
            }
        }
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

struct StaffNoteView: View {
    //@EnvironmentObject var orientationInfo: OrientationInfo
    let staff:Staff
    let timeSlice:TimeSlice
    @ObservedObject var note:StaffNote
    let noteFrameWidth:Double
    let geometry: GeometryProxy
    let noteWidth:Double
    let lineSpacing:Double
    
    public init(staff:Staff, timeSlice:TimeSlice, note:StaffNote, noteFrameWidth:Double, geometry: GeometryProxy, noteWidth:Double, lineSpacing:Double ) {
        self.staff = staff
        self.timeSlice = timeSlice
        self.note = note
        self.noteFrameWidth = noteFrameWidth
        self.geometry = geometry
        self.noteWidth = noteWidth
        self.lineSpacing = lineSpacing
    }
    
    func getAccidental(accidental:Int) -> String {
        switch accidental {
        case 1:
            return "\u{266F}" //#
        case 2:
            return "\u{1D12A}" // double sharp
        case -1:
            return "\u{266D}" //♭
        default:
            return "\u{266E}" //natural
        }
    }
    
    func sizeMultiplier() -> Double {
        ///The closed ellipse on iPhone, landscape appears to be too small to draw. No idea why 🥵. So bump the closed ellipse size slightly to force it to draw.
        var multipler = 1.0
        if UIDevice.current.userInterfaceIdiom == .phone {
            //if orientationObserver.orientation.isAnyLandscape {
            //if !orientationInfo.isPortrait {
                multipler = 1.1
            //}
        }
        return multipler
    }
    
    struct LedgerLine:Hashable, Identifiable {
        var id = UUID()
        var offsetVertical:Double
    }
    
    func getLedgerLines(staff:Staff, note:StaffNote, noteWidth:Double, lineSpacing:Double) -> [LedgerLine] {
        var result:[LedgerLine] = []
        //let p = note.getNoteDisplayCharacteristics(staff: staff)
        let p = note.noteStaffPlacement

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
    
    public var body: some View {
        ZStack {
            let placement = note.noteStaffPlacement // note.getNoteDisplayCharacteristics(staff: staff)
            let offsetFromStaffMiddle = placement.offsetFromStaffMidline
            let accidental = placement.accidental

            let noteEllipseMidpoint:Double = geometry.size.height/2.0 - Double(offsetFromStaffMiddle) * lineSpacing / 2.0

            let noteValueUnDotted = note.getValue() //* 2.0/3.0 : note.getValue()

            if note.showIsPlaying {
                NoteHiliteView(entry: note, x: noteFrameWidth/2, y: noteEllipseMidpoint, width: noteWidth * 1.7)
            }
            
            if let accidental = accidental {
                let yOffset = accidental == 1 ? lineSpacing / 5 : 0.0
                Text(getAccidental(accidental: accidental))
                    //.font(.system(size: lineSpacing * 3.0)).bold()
                    .font(.system(size: lineSpacing * 2.5)).bold()
                    //.frame(width: noteWidth * 1.0, height: CGFloat(Double(lineSpacing) * 1.0))
                    .position(
                        x: noteFrameWidth/2 - lineSpacing * (timeSlice.anyNotesRotated() ? 3.0 : 1.2), //3.0 : 1.5
                        y: noteEllipseMidpoint + yOffset)
                    .foregroundColor(note.getColor(staff: staff))
            }
            if [StaffNote.VALUE_QUARTER, StaffNote.VALUE_QUAVER, StaffNote.VALUE_SEMIQUAVER, StaffNote.VALUE_TRIPLET].contains(noteValueUnDotted ) {
                Ellipse()
                //Closed ellipse
                    //.stroke(note.getColor(staff: staff), lineWidth: 2)
                    .foregroundColor(note.getColor(staff: staff))
                    .frame(width: noteWidth * self.sizeMultiplier(), height: CGFloat(Double(lineSpacing) * 1.0) * self.sizeMultiplier())
                    .position(x: noteFrameWidth/2 - (note.rotated ? noteWidth : 0), y: noteEllipseMidpoint)
            }
            if noteValueUnDotted == StaffNote.VALUE_HALF || noteValueUnDotted == StaffNote.VALUE_WHOLE {
                Ellipse()
                //Open ellipse
                    .stroke(note.getColor(staff: staff), lineWidth: 2)
                    .foregroundColor(note.getColor(staff: staff))
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
                    .foregroundColor(note.getColor(staff: staff))
            }
            
            ///Ledger lines
            if !note.isOnlyRhythmNote {
                ForEach(getLedgerLines(staff: staff, note: note, noteWidth: noteWidth, lineSpacing: lineSpacing)) { line in
                    let y = geometry.size.height/2.0 + line.offsetVertical
                    ///offset - make sure ledger lines dont join on small width stafff's. ex melody examples
                    let xOffset = noteWidth * 0.2
                    let x = noteFrameWidth/2 - noteWidth - (note.rotated ? noteWidth : 0)
                    Path { path in
                        path.move(to: CGPoint(x: x + xOffset, y: y))
                        path.addLine(to: CGPoint(x: x + (2 * noteWidth) - xOffset, y: y))
                    }
                    .stroke(note.getColor(staff: staff), lineWidth: 1)
                }
            }
        }
    }
}

public struct TimeSliceView: View {
    //@EnvironmentObject var orientationInfo: OrientationInfo
    @ObservedObject var timeSlice:TimeSlice
    @ObservedObject var scalesModel:ScalesModel
    var staff:Staff
    var color: Color
    var lineSpacing:Double
    var noteWidth:Double
    var accidental:Int?
    let isPortrait:Bool
    
    public init(staff:Staff, timeSlice:TimeSlice, noteWidth:Double, lineSpacing: Double, isPortrait:Bool) {
        self.staff = staff
        self.timeSlice = timeSlice
        self.noteWidth = noteWidth
        self.color = Color.black
        self.lineSpacing = lineSpacing
        scalesModel = ScalesModel.shared
        self.isPortrait = isPortrait
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
                    .foregroundColor(entry.getColor(staff: staff))
                Spacer()
            }
            else {
                if entry.getValue() == 1 {
                    Image("rest_quarter_grayscale")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(entry.getColor(staff: staff))
                        .scaledToFit()
                        .frame(height: lineSpacing * 3)
                }
                else {
                    if entry.getValue() == 2 {
                        let height = lineSpacing / 2.0
                        Rectangle()
                            .fill(entry.getColor(staff: staff))
                            .frame(width: lineSpacing * 1.5, height: height)
                            .offset(y: 0 - height / 2.0)
                    }
                    else {
                        if (entry.getValue() == 1.5) {
                            HStack {
                                Image("rest_quarter_grayscale")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(entry.getColor(staff: staff))
                                    .scaledToFit()
                                    .frame(height: lineSpacing * 3)
                                Text(".")
                                    .font(.largeTitle)
                                    .foregroundColor(entry.getColor(staff: staff))
                            }
                        }
                        else {
                            if (entry.getValue() == 4.0) {
                                let height = lineSpacing / 2.0
                                Rectangle()
                                    .fill(entry.getColor(staff: staff))
                                    .frame(width: lineSpacing * 1.5, height: height)
                                    .offset(y: 0 - height * 1.5)
                            }
                            else {
                                if (entry.getValue() == 0.5 ){
                                    Image("rest_quaver")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(entry.getColor(staff: staff))
                                        .scaledToFit()
                                        .frame(height: lineSpacing * 2)
                                    
                                }
                                else {
                                    VStack {
                                        Text("?")
                                            .font(.largeTitle)
                                            .foregroundColor(entry.getColor(staff: staff))
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
    
//    func log(geometry: GeometryProxy, noteFrameWidth:Double, frameHeight:Double, noteEllipseMidpoint:Double) -> Bool {
//        return false
//    }
//    
        
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
                        if let staffNote = entry as? StaffNote {
                            if (staffNote.handType == .right && self.staff.handType == .right) || (staffNote.handType == .left && self.staff.handType == .left) {
                                StaffNoteView(staff: staff, timeSlice: timeSlice, note: entry as! StaffNote, noteFrameWidth: noteFrameWidth,
                                              geometry: geometry, noteWidth: noteWidth, lineSpacing: lineSpacing)
//                                StaffNoteView(timeslice: timeSlice, note: entry as! StaffNote, noteFrameWidth: noteFrameWidth,
//                                              geometry: geometry, noteWidth: noteWidth, staff:staff)
//                                              //statusTag: timeSlice.statusTag)
                                //.border(Color.green)
                            }
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

        }
    }
}
