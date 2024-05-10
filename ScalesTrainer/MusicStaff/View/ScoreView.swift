import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    @ObservedObject var score:Score
    let widthPadding:Bool
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    
    public init(score:Score, widthPadding:Bool) {
        self.score = score
        self.widthPadding = widthPadding
    }
    
    public var body: some View {
        VStack {
            if let label = score.label {
                Text(label).font(.title).foregroundColor(.blue)
            }
            VStack {
                ForEach(score.getStaff(), id: \.self.id) { staff in
                    ZStack {
                        StaffView(score: score, staff: staff,
                                  widthPadding: widthPadding)
                            .frame(height: score.getStaffHeight())
                            //.border(Color .red, width: 2)
                    }
                    .border(Color.red)
                }
            }
        }

        .onAppear() {
            //self.setOrientationLineSize(ctx: "🤢.Score View .onAppear") //, geometryWidth: geometry.size.width)
            //UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        .onDisappear {
            //UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .coordinateSpace(name: "ScoreView")
        //.roundedBorderRectangle()
    }

}


//    func setOrientationLineSize(ctx:String) {//}, geometryWidth:Double) {
///Nov2023 NEVER USE THIS AGAIN. Set the line spacing based on some other criteria than the size of the screen
//Absolutley no idea - the width reported here decreases in landscape mode so use height (which increases)
//https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation
//var lineSpacing:Double
//        if self.staffLayoutSize.lineSpacing == 0 {
//            //if UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                lineSpacing = 10.0
//            }
//            else {
//                if !UIGlobalsCommon.isLandscape() == .portrait {
//                    lineSpacing = UIScreen.main.bounds.width / 64.0
//                }
//                else {
//                    lineSpacing = UIScreen.main.bounds.width / 128.0
//                }
//            }
//        }
//        else {
//            //make a small change only to force via Published a redraw of the staff views
//            lineSpacing = self.staffLayoutSize.lineSpacing
//            if UIGlobalsCommon.isLandscape() {
//                lineSpacing += 1
//            }
//            else {
//                lineSpacing -= 1
//            }
//        }
//self.staffLayoutSize.setLineSpacing(lineSpacing) ????????? WHY

//lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : UIScreen.main.bounds.width / 64.0
//score.lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : geometryWidth / 64.0
//score.lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 5.0 : 15

//??????????????????????????????
//score.lineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 5.0 : 8
//        print("\n👉 👉 setOrientationLineSize \(logCtr) \twidth::", UIScreen.main.bounds.width, "height:", UIScreen.main.bounds.height, "\tline spacing", score.lineSpacing)
//        UIGlobals.showDeviceOrientation()
//        logCtr += 1
//    }

//    func log() -> String {
//        print("🤔 =====> ScoreView Body",
//              "Score:", score.id.uuidString.suffix(4),
//              //"Width:", geometryWidth,
//              //"Portrait?", UIGlobalsCommon.isLandscape()
//              "lineSpacing", self.lineSpacing)
//
//        return ""
//    }
