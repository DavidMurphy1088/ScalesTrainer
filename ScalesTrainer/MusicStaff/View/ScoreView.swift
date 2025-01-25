import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    let scale:Scale
    @ObservedObject var score:Score
    //@ObservedObject 
    var barLayoutPositions:BarLayoutPositions
    let widthPadding:Bool
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    
    public init(scale:Scale, score:Score, barLayoutPositions:BarLayoutPositions, widthPadding:Bool) {
        self.scale = scale
        self.score = score
        self.widthPadding = widthPadding
        self.barLayoutPositions = barLayoutPositions
    }
    
    public var body: some View {
        
        HStack(spacing: 0) {
            if score.getStaffs().count > 1 {
                ///Draw staff brace
                Image("staff_brace")
                    .resizable()
                    .foregroundColor(.black)
                    .frame(width:UIScreen.main.bounds.width * 0.015, height: score.getBraceHeight())
                    .overlay(
                        HStack(spacing: 0) {
                            Spacer()
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(.black)
                        }
                    )
            }

            VStack {
                ForEach(score.getStaffs(), id: \.self.id) { staff in
                    StaffView(scale: scale, score: score, staff: staff, scoreView: self, widthPadding: widthPadding)
                        .frame(height: score.getStaffHeight())
                }
//                if score.staffs.count == 1 {
                ///Be careful - this can cause the end of staff double lines to be y direction misplaced. 
//                    Text(" ")
//                }
            }
            .overlay(
                ///For a hands-together staff bar lines must extend between the staves
                ZStack {
                    if scale.hands.count > 1 && score.barPositionsUpdates >= 0 {
                        let delta = UIScreen.main.bounds.width * 0.015
                        let height = score.lineSpacing * 12 //UIScreen.main.bounds.height * 0.09
                        ForEach(score.barLayoutPositions.positions.map { $0.key }, id: \.self) { barLine in
                            if let rect = score.barLayoutPositions.positions[barLine] {
                                Path { path in
                                    path.move(to: CGPoint(x: rect.midX - delta, y: rect.midY + 0))
                                    path.addLine(to: CGPoint(x: rect.midX - (delta * 1.0), y: rect.midY + height))
                                }
                                .stroke(Color.black, lineWidth: 1)
                            }
                        }
                    }
                }
            )
            ///End of staff lines. They must overlap staff lines
            .overlay(
                HStack(spacing: 0) {
                    Spacer()
                    let height = score.getStaffs().count > 1 ? score.getBraceHeight() : score.getBraceHeight() * 0.25
                    let width = score.lineSpacing * 0.5
                    Rectangle()
                        //.frame(width: 1)
                        .fill(Color.clear)
                        //.foregroundColor(.black)
                        .border(Color.black, width: 1)
                        //..frame(width:UIScreen.main.bounds.width * 0.005, height: height)
                        .frame(width:width, height: height)

//                    Rectangle()
//                        .frame(width: 1)
//                        .foregroundColor(.black)
//                        .frame(width:UIScreen.main.bounds.width * 0.002, height: height)
                }
            )
            //.border(Color.cyan)
            ///Padding for right edge
            Text(" ")
        }
        .onAppear() {
            //self.setOrientationLineSize(ctx: "🤢.Score View .onAppear") //, geometryWidth: geometry.size.width)
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .coordinateSpace(name: "ScoreView")
    }
}

