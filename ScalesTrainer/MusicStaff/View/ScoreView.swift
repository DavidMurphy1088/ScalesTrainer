import SwiftUI
import CoreData
import MessageUI

public struct ScoreView: View {
    let scale:Scale
    @ObservedObject var score:Score
    ///NB 🟢 Changing this needs changes to getBraceHeight() for alignment
    //private(set) var lineSpacing:Double
    private(set) var lineSpacing:Double

    private let height:Double
    
    @State private var dragOffset = CGSize.zero
    @State var logCtr = 0
    @State var showResults:Bool
    
    public init(scale:Scale, score:Score, showResults:Bool, height:Double) {
        self.scale = scale
        self.score = score
        self.showResults = showResults
        
        //10 for single keyboard, one octave
        var scaleDown = 11.0
        if scale.getScaleNoteCount() >= 16 {
            scaleDown = scaleDown * 1.2
        }
        self.lineSpacing = height / scaleDown //8.0 //8.0
        self.height = height
    }

//    func getBraceHeight() -> Double {
//        let heightMult:Double
//        ///NB This needs to be changed if staff height is changed
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            heightMult = scale.hands.count > 1 ? 1.30 : 1.30
//        }
//        else {
//            heightMult = scale.hands.count > 1 ? 1.30 : 1.30
//        }
//        return getStaffHeight() * heightMult
//    }
    
    public var body: some View {
        HStack(spacing: 0) {
//            if score.getStaffs().count > 1 {
//                ///Draw staff brace
//                Image("staff_brace")
//                    .resizable()
//                    .foregroundColor(.black)
//                    .frame(width:UIScreen.main.bounds.width * 0.015, height: self.getBraceHeight())
//                    .overlay(
//                        HStack(spacing: 0) {
//                            Spacer()
//                            Rectangle()
//                                .frame(width: 1)
//                                .foregroundColor(.black)
//                        }
//                    )
//            }

            VStack(spacing: 0) {
                ForEach(score.getStaffs(), id: \.self.id) { staff in
                    StaffView(scale: scale, score: score, staff: staff, scoreView: self, showResults: showResults, lineSpacing: self.lineSpacing,
                              height: height, ledgerLines: 1)
                        //.border(.blue)
                }
            }
//            VStack {
//                Text("Score")
//            }

//            ///End of staff lines. They must overlap staff lines
//            .overlay(
//                ///End of staff
//                HStack(spacing: 0) {
//                    Spacer()
//                    let height = 5.1 * self.lineSpacing //score.getStaffs().count > 1 ? self.getBraceHeight() : self.getBraceHeight() * 0.23
//                    let width = self.lineSpacing * 0.5
//                    Rectangle()
//                        .fill(Color.clear)
//                        .border(Color.black, width: 1)
//                        .frame(width:width, height: height)
//                }
//            )
//            .overlay(
//                //Begin of staff
//                HStack(spacing: 0) {
//                    let height = 5 * self.lineSpacing //score.getStaffs().count > 1 ? self.getBraceHeight() : self.getBraceHeight() * 0.23
//                    let width = self.lineSpacing * 0.1
//                    Rectangle()
//                        .fill(Color.clear)
//                        .border(Color.black, width: 1)
//                        .frame(width:width, height: height)
//                    Spacer()
//                }
//            )

//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.white) //.opacity(opacityValue))
//                    //.shadow(color: .black.opacity(1.0), radius: 1, x: 4, y: 0)
//            )
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

