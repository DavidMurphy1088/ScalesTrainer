import SwiftUI
import CoreData
import MessageUI

public struct StaffLinesView: View {
    var score:Score
    @ObservedObject var staff:Staff
    var widthPadding:Bool

    public var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                let top:Double = (geometry.size.height/2.0) + Double(2 * score.lineSpacing)
                let bottom:Double = (geometry.size.height/2.0) - Double(2 * score.lineSpacing)
                if widthPadding {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: top))
                        path.addLine(to: CGPoint(x: 0, y: bottom))
                    }
                    .stroke(Color.black, lineWidth: Double(score.lineSpacing) / Double(score.lineSpacing))
                }
                
                if staff.linesInStaff > 1 {
                    ForEach(-2..<3) { row in
                        Path { path in
                            let y:Double = (geometry.size.height / 2.0) + Double(row) * score.lineSpacing
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        //.fill(Color(.black))
                        .stroke(Color.black, lineWidth: 1)
                    }
                }
                else {
                    Path { path in
                        let y:Double = geometry.size.height/2.0
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.black, lineWidth: 1)
                }
                
                // end of staff bar lines
                
                let x:Double = geometry.size.width - 2.0
                
                Path { path in
                    path.move(to: CGPoint(x: x, y: top))
                    path.addLine(to: CGPoint(x: x, y: bottom))
                }
                .stroke(Color.black, lineWidth: Double(score.lineSpacing) / 3)
                let x1:Double = geometry.size.width - (Double(score.lineSpacing) * 0.7)
                Path { path in
                    path.move(to: CGPoint(x: x1, y: top))
                    path.addLine(to: CGPoint(x: x1, y: bottom))
                }
                .stroke(Color.black, lineWidth: 1)
            }
        }
    }
}

struct TimeSignatureView: View {
    @ObservedObject var staff:Staff
    var timeSignature:TimeSignature
    var lineSpacing:Double
    var clefWidth:Double
    
    func fontSize(for height: CGFloat) -> CGFloat {
        // Calculate the font size based on the desired pixel height
        let desiredPixelHeight: CGFloat = 48.0
        let scaleFactor: CGFloat = 72.0 // 72 points per inch
        let points = (desiredPixelHeight * 90.0) / scaleFactor
        let scalingFactor = height / UIScreen.main.bounds.size.height
        return points * scalingFactor
    }

    var body: some View {
        let padding:Double = Double(lineSpacing) / 3.0
        let fontSize:Double = Double(lineSpacing) * (staff.linesInStaff == 1 ? 2.2 : 2.2)
        ///Bring number closer to midline, they should almost otuch midlline
        let yOffset = lineSpacing / 6.0
    
        if timeSignature.isCommonTime {
            Text(" C")
                .font(.custom("Times New Roman", size: fontSize * 1.5)).bold().foregroundColor(.black)
            //.font(.system(size: fontSize(for: geometry.size.height)))
        }
        else {
            VStack (spacing: 0) {
                Text(" \(timeSignature.top)").font(.system(size: fontSize * 1.1)).padding(.vertical, -padding).foregroundColor(.black)
                    .offset(y:yOffset)
                Text(" \(timeSignature.bottom)").font(.system(size: fontSize  * 1.1)).padding(.vertical, -padding).foregroundColor(.black)
                    .offset(y:0-yOffset)
            }
        }
    }
}

struct CleffView: View {
    var score:Score
    @ObservedObject var staff:Staff

    var body: some View {
        HStack {
            if staff.type == StaffType.treble {
                VStack {
                    Text("\u{1d11e}")
                        .foregroundColor(.black)
                        .font(.system(size: CGFloat(score.lineSpacing * 10)))
                        .padding(.top, 0.0)
                        .padding(.bottom, score.lineSpacing * 1.0)
                }
                //.border(Color.red)
            }
            else {
                Text("\u{1d122}")
                    .foregroundColor(.black)
                    .font(.system(size: CGFloat(Double(score.lineSpacing) * 6.5)))
            }
        }
        //.border(Color.green)
    }
}

struct KeySignatureView: View {

    var score:Score
    var staffOffsets:[Int]
    
    func getWidthMultiplier() -> Double {
        var widthMultiplier = staffOffsets.count <= 2 ? 1.0 : 0.7
        if UIDevice.current.userInterfaceIdiom == .phone {
            widthMultiplier = widthMultiplier * 0.7
        }
        return widthMultiplier
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(staffOffsets, id: \.self) { offset in
                //let yAdjust = score.key.keySig.flats.count > 0 ? score.lineSpacing / 1.1 : 0
                VStack {
                    Image(score.key.keySig.sharps.count > 0 ? "Sharp" : "Flat")
                        .resizable()
                        .foregroundColor(.black)
                        .scaledToFit()
                        .frame(width: score.lineSpacing * getWidthMultiplier())
                        .offset(y: 0 - Double(offset) * score.lineSpacing / 2.0)
                        .border(Color.red)
                }
                .padding(0)
                .frame(width: score.lineSpacing * getWidthMultiplier())
            }
        }
    }
}

public struct StaffView: View {
    @ObservedObject var score:Score
    @ObservedObject var staff:Staff
    let widthPadding:Bool
    
    @State private var rotationId: UUID = UUID()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var position: CGPoint = .zero
    @State var isTempoHelpPopupPresented = false
    
    var entryPositions:[Double] = []
    var totalDuration = 0.0
    
    init (score:Score, staff:Staff, widthPadding:Bool) {
        self.score = score
        self.staff = staff
        self.widthPadding = widthPadding
    }
    
    func clefWidth() -> Double {
        return Double(score.lineSpacing) * 3.0
    }
    
    func getNotes(entry:ScoreEntry) -> [Note] {
        if entry is TimeSlice {
            let ts = entry as! TimeSlice
            return ts.getTimeSliceNotes()
        }
        else {
            let n:[Note] = []
            return n
        }
    }
    
    func keySigOffsets(staff:Staff, keySignture:KeySignature) -> [Int] {
        var offsets:[Int] = []
        if staff.type == .treble {
            //Key Sig offsets on staff
            if keySignture.sharps.count > 0 {
                offsets.append(4)
            }
            if keySignture.sharps.count > 1 {
                offsets.append(1)
            }
            if keySignture.sharps.count > 2 {
                offsets.append(5)
            }
            if keySignture.sharps.count > 3 {
                offsets.append(2)
            }
            if keySignture.sharps.count > 4 {
                offsets.append(-1)
            }
            
            if keySignture.flats.count > 0 {
                offsets.append(0)
            }
            if keySignture.flats.count > 1 {
                offsets.append(3)
            }
            if keySignture.flats.count > 2 {
                offsets.append(-1)
            }
            if keySignture.flats.count > 3 {
                offsets.append(2)
            }
            if keySignture.flats.count > 4 {
                offsets.append(-2)
            }
        }
        else {

        }
        return offsets
    }
    
    public var body: some View {
        ZStack {
            StaffLinesView(score:score, staff: staff, widthPadding: widthPadding)
                .frame(height: score.getStaffHeight())
                .padding([.leading, .trailing], widthPadding ? score.lineSpacing * 4 : 0)
            HStack(spacing: 0) {
                if staff.linesInStaff != 1 {
                    CleffView(score:score, staff: staff)
                        .frame(height: score.getStaffHeight())
                        .padding([.leading], widthPadding ? score.lineSpacing * 1 : 0)
                    //.border(Color.red)
                    if score.key.keySig.accidentalCount > 0 {
                        KeySignatureView(score: score,
                                         staffOffsets: keySigOffsets(staff: staff, keySignture: score.key.keySig))
                            .frame(height: score.getStaffHeight())
                            
                    }
                }

                TimeSignatureView(staff: staff, timeSignature: score.timeSignature, lineSpacing: score.lineSpacing, clefWidth: clefWidth()/1.0)
                    .frame(height: score.getStaffHeight())
                //    .border(Color.red)

                ScoreEntriesView(score: score, staff: staff)
                    .frame(height: score.getStaffHeight())
                    .coordinateSpace(name: "StaffNotesView")
            }
            .padding([.leading, .trailing], widthPadding ? score.lineSpacing * 4 : 0)
            
        }
        .coordinateSpace(name: "StaffView.ZStack")
        .frame(height: score.getStaffHeight())
        

    }
}

