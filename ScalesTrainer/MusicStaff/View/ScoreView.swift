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
                    //.border(Color.red)
                }
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
        //.roundedBorderRectangle()
    }
}

