import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    let scale:Scale
    @ObservedObject var score:Score
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    
    public init(scale:Scale, score:Score) {
        self.scale = scale
        self.score = score
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

            VStack(spacing: 0) {
                ForEach(score.getStaffs(), id: \.self.id) { staff in
                    StaffView(scale: scale, score: score, staff: staff, scoreView: self)
                        .frame(height: score.getStaffHeight())
                }
            }

            ///End of staff lines. They must overlap staff lines
            .overlay(
                HStack(spacing: 0) {
                    Spacer()
                    let height = score.getStaffs().count > 1 ? score.getBraceHeight() : score.getBraceHeight() * 0.24
                    let width = score.lineSpacing * 0.5
                    Rectangle()
                        .fill(Color.clear)
                        .border(Color.black, width: 1)
                        .frame(width:width, height: height)
                }
            )
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

