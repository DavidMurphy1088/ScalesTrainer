import SwiftUI
import CoreData
import MessageUI

public struct StaffLinesView: View {
    var score:Score
    var staff:Staff
    let lineSpacing:Double
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                //let top:Double = (geometry.size.height/2.0) + Double(2 * self.lineSpacing)
                //let bottom:Double = (geometry.size.height/2.0) - Double(2 * self.lineSpacing)
                
                if staff.linesInStaff > 1 {
                    ForEach(-2..<3) { row in
                        Path { path in
                            let y:Double = (geometry.size.height / 2.0) + Double(row) * self.lineSpacing
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
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
            }
        }
    }
}

struct TimeSignatureView: View {
    var staff:Staff
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

struct ClefView: View {
    var score:Score
    var staff:Staff
    let lineSpacing:Double
    
    var body: some View {
        HStack {
            if staff.handType == HandType.right {
                Image("clef_treble")
                    .resizable()
                    .renderingMode(.template)
                    //.foregroundColor(entry.getColor(staff: staff))
                    .scaledToFit()
            }
            else {
                VStack {
                    Image("clef_bass")
                        .resizable()
                        .renderingMode(.template)
                        .padding(.top, 0.1 * self.lineSpacing)
                        .padding(.bottom, 0.5 * self.lineSpacing)
                        .scaledToFit()
                }
            }
        }
    }
}

struct KeySignatureView: View {
    var score:Score
    var staffOffsets:[Int]
    let lineSpacing:Double
    
    func getWidthMultiplier() -> Double {
        var widthMultiplier = staffOffsets.count <= 2 ? 1.0 : 0.7
        if UIDevice.current.userInterfaceIdiom == .phone {
            widthMultiplier = widthMultiplier * 0.7
        }
        return widthMultiplier
    }
    
    var body: some View {
        HStack(spacing: 0) {
            //let verfticalDelta = score.key.keySig.sharps.count > 0 ? 0.0 : self.lineSpacing * 0.2
            ForEach(staffOffsets, id: \.self) { offset in
                VStack {
                    Image(score.key.keySig.sharps.count > 0 ? "sharp" : "flat")
                        .resizable()
                        .foregroundColor(.black)
                        .scaledToFit()
                        .frame(width: self.lineSpacing * getWidthMultiplier() * (score.key.keySig.sharps.count > 0 ? 1 : 1.4))
                        .offset(y: 0 - Double(offset) * self.lineSpacing / 2.0 -
                                //(score.key.keySig.sharps.count > 0 ? 0 : self.lineSpacing * 0.50)
                                (score.key.keySig.sharps.count > 0 ? 0 : self.lineSpacing * 0.4)
                        )
//                      .border(Color.red)
                }
                .padding(0)
                .frame(width: self.lineSpacing * getWidthMultiplier())
            }
        }
    }
}

public struct StaffView: View {
    let scale:Scale
    @ObservedObject var score:Score
    let scoreView:ScoreView
    var staff:Staff
    var lineSpacing:Double
    let height:Double
    let linesInStaff:Int
    
    @State private var rotationId: UUID = UUID()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var position: CGPoint = .zero
    @State var isTempoHelpPopupPresented = false
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    var entryPositions:[Double] = []
    var totalDuration = 0.0
    
    init (scale:Scale, score:Score, staff:Staff, scoreView:ScoreView, showResults:Bool, height:Double, ledgerLines:Int) {
        self.scale = scale
        self.score = score
        self.staff = staff
        self.scoreView = scoreView
        self.height = height
        self.linesInStaff = 5 + 2*ledgerLines
        self.lineSpacing = height / Double(linesInStaff + 1)
        ///Needed so accidentals dont run over notes
        if scale.getScaleNoteCount() >= 16 {
            if !compact {
                self.lineSpacing = self.lineSpacing * 0.6
            }
        }
    }
    
    func clefWidth() -> Double {
        return Double(self.lineSpacing) * 3.0
    }
    
    func keySigOffsets(staff:Staff, keySignture:KeySignature) -> [Int] {
        var offsets:[Int] = []
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
        if keySignture.sharps.count > 5 {
            offsets.append(3)
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
        if keySignture.flats.count > 5 {
            offsets.append(1) //C Flat
        }
        if keySignture.flats.count > 6 {
            offsets.append(-3)
        }
        if staff.handType == .left {
            offsets = offsets.map { $0 - 2 }
        }
        return offsets
    }
    
    public func getStaffHeight() -> Double {
        //-->Jan2024 Leave room for notes on more ledger lines
        //let height = Double(getTotalStaffLineCount() + 3) * self.lineSpacing
        //let height = Double(score.getTotalStaffLineCount() + 5) * self.lineSpacing ///Jan2025 Bad case Trinity Gr5, G Harmonic minor
        //let height = Double(score.getTotalStaffLineCount() + 1) * self.lineSpacing ///Jan2025 Bad case Trinity Gr5, G Harmonic minor
        return self.height
    }
    
    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                if staff.linesInStaff != 1 {
                    //let w:Double = lineSpacing * 4.2
                    ClefView(score:score, staff: staff, lineSpacing: self.lineSpacing)
                    ///Both clefs MUST have the same width to ensure notes and bar lines of on both staves exactly align
                        //.frame(width: w) //, height: score.getStaffHeight())
                        .frame(height: lineSpacing * 7.0) //, height: score.getStaffHeight())
                        .padding([.leading], 0)
                        .overlay(
                            HStack(spacing: 0) {
                                let height = 4.0 * self.lineSpacing //score.getStaffs().count > 1 ? self.getBraceHeight() : self.getBraceHeight() * 0.23
                                let width = self.lineSpacing * 0.2
                                Rectangle()
                                    .fill(Color.clear)
                                    .border(Color.black, width: 1)
                                    .frame(width:width, height: height)
                                Spacer()
                            }
                        )
                        
                    if score.key.keySig.accidentalCount > 0 {
                        KeySignatureView(score: score,
                                         staffOffsets: keySigOffsets(staff: staff, keySignture: score.key.keySig), lineSpacing: self.lineSpacing)
                            .frame(height: getStaffHeight())
                            //.border(Color.red)
                    }
                }
                
                TimeSignatureView(staff: staff, timeSignature: score.timeSignature, lineSpacing: self.lineSpacing, clefWidth: clefWidth()/1.0)
                    .frame(height: getStaffHeight())
                    .padding([.trailing], self.lineSpacing)
                    
                ScoreEntriesView(score: score, staff: staff, scoreView: scoreView, lineSpacing: self.lineSpacing)
                    .frame(height: getStaffHeight())
                    .coordinateSpace(name: "StaffNotesView")
                .overlay(
                    ///End of staff
                    HStack(spacing: 0) {
                        Spacer()
                        let height = 4.0 * self.lineSpacing //score.getStaffs().count > 1 ? self.getBraceHeight() : self.getBraceHeight() * 0.23
                        let width = self.lineSpacing * 0.5
                        Rectangle()
                            .fill(Color.clear)
                            .border(Color.black, width: 1)
                            .frame(width:width, height: height)
                    }
                )
            }
            .padding([.leading, .trailing], 0)
            
            ///Make sure the lines are over the top of all notes. The notes in the staff may not be black but the staff line must show black.
            StaffLinesView(score:score, staff: staff, lineSpacing : self.lineSpacing)
                .frame(height: getStaffHeight())
                .padding([.leading, .trailing], 0)
        }
        .coordinateSpace(name: "StaffView.ZStack")
        .frame(height: getStaffHeight())
    }
}

