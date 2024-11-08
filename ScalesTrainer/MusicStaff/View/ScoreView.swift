import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    //@Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var score:Score
    let widthPadding:Bool
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    
    public init(score:Score, widthPadding:Bool) {
        self.score = score
        self.widthPadding = widthPadding
    }
    
    func log(_ m:String) -> Bool {
        print("========================ScoreView", m)
        return true
    }
    
    public var body: some View {

            VStack {
                ForEach(score.getStaff(), id: \.self.id) { staff in
                    //VStack {
                        StaffView(score: score, staff: staff, widthPadding: widthPadding)
                            .frame(height: score.getStaffHeight())
                            .border(Color .red, width: 2)
                        //padding(.vertical, 0)
                    //}
                }
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

