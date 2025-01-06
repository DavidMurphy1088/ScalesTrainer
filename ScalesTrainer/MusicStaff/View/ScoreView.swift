import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    @ObservedObject var score:Score
    let widthPadding:Bool
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    
    public init(score:Score, widthPadding:Bool) {
        self.score = score
        self.widthPadding = widthPadding
    }
    
//    func log(_ m:String) -> Bool {
//        return true
//    }
    
    public var body: some View {
        HStack {
            
        }
    }
    public var bodyOld: some View {
        
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
                    StaffView(score: score, staff: staff, widthPadding: widthPadding)
                        .frame(height: score.getStaffHeight())
                }
                if score.staffs.count == 1 {
                    Text(" ")
                }
            }
            .overlay(
                ///End of staff lines. They must overlap staff lines
                HStack(spacing: 0) {
                    Spacer()
                    let height = score.getStaffs().count > 1 ? score.getBraceHeight() : score.getBraceHeight() * 0.25
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.black)
                        .frame(width:UIScreen.main.bounds.width * 0.005, height: height)

                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.black)
                        .frame(width:UIScreen.main.bounds.width * 0.002, height: height)
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

