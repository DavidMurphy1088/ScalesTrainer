import SwiftUI

struct HideAndShowView: View {
    @ObservedObject var logger = AppLogger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    let compact:Bool
    
    var body: some View {
        HStack {
            Button(action: {
                scalesModel.setShowKeyboard(!scalesModel.showKeyboard)
            }) {
                Text(scalesModel.showKeyboard ? NSLocalizedString("Hide Keyboard", comment: "LegendView") : "Show Keyboard")
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.vertical, 0)

            if scalesModel.showKeyboard {
                Button(action: {
                    scalesModel.setShowFingers(!scalesModel.showFingers)
                }) {
                    Text(scalesModel.showFingers ? NSLocalizedString("Hide Fingers", comment: "LegendView") : "Show Fingers")
                }
                .padding(.horizontal)
                .padding(.vertical, 0)
            }
            
            Button(action: {
                scalesModel.setShowStaff(!scalesModel.showStaff)
            }) {
                Text(scalesModel.showStaff ? NSLocalizedString("Hide Staff", comment: "LegendView") : "Show Staff")
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
            .padding(.vertical, 0)
        }
    }
}

struct LegendViewUNUSED: View {
    let hands:[Int]
    let scale:Scale
    @ObservedObject var logger = AppLogger.shared
    @ObservedObject var scalesModel = ScalesModel.shared
    @State private var scrollToEnd = false
    @State private var proxy: ScrollViewProxy? = nil
    @State private var legendIndex = 0
    
    func getColor(_ val:Double) -> Color {
        if val > logger.hiliteLogValue {
            return .red
        }
        return .black
    }
        
    func fingerChangeName(keyboardHand:Int, scaleMotion:ScaleMotion) -> String {
        var result:String
        let hand = keyboardHand
        if hand == 0 {
            if scalesModel.selectedScaleSegmentPublished == 0 {
                result = NSLocalizedString("Thumb Under", comment: "Menu")
            }
            else {
                result = "Finger Over"
            }
        }
        else {
            if scaleMotion == .contraryMotion {
                result = scalesModel.selectedScaleSegment == 0 ? NSLocalizedString("Thumb Under", comment: "Menu") :  "Finger Over"
            }
            else {
                result = scalesModel.selectedScaleSegment == 0 ? "Finger Over" :  NSLocalizedString("Thumb Under", comment: "Menu")
            }
        }
        return result
    }
    
    func width() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    func title(hand:Int) -> String? {
        if !scalesModel.showKeyboard {
            return ""
        }
        var title = hand == 0 ? NSLocalizedString("Right Hand", comment: "Menu") : NSLocalizedString("Left Hand", comment: "Menu")
        if scalesModel.runningProcess == .leadingTheScale  {
            title = "Practice"
        }
        else {
            if scalesModel.resultPublished != nil {
                title = "Results"
            }
        }
        return title
    }
    
    func legendForHandView(hand:Int) -> some View {
        HStack {
            if let title = title(hand: hand) {
                Text(" \(title) ").bold().foregroundColor(.white) // White text
                    //.padding() //.padding(.horizontal).hilighted().padding(.top, 2)
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    .padding(.horizontal)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            if scalesModel.resultPublished == nil {
                if scalesModel.showKeyboard {
                    if scalesModel.showFingers {
                        HStack(spacing: 0) {
                            //Spacer()
                            Text("●").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold().font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                            Text(NSLocalizedString("Finger Number", comment: "LegendView")).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                            
                            //Spacer()
                            Text(" ●").foregroundColor(AppOrange).font(.title2).bold().font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                            Text(fingerChangeName(keyboardHand: hand, scaleMotion: self.scale.scaleMotion)).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                            //Spacer()
                        }
                    }
                }
            }
//            if false && scalesModel.runningProcess == .leadingTheScale {
//                Spacer()
//                Circle()
//                    .stroke(Color.green.opacity(1.0), lineWidth: 3)
//                    .frame(width: width())
//                Text("Correctly Played")
//                Spacer()
//                Circle()
//                    .stroke(Color.red.opacity(1.0), lineWidth: 3)
//                    .frame(width: width())
//                //Text("Played But Not in Scale")
//                Text("Not in Scale")
//                Spacer()
//            }
            
//            if let result = scalesModel.resultPublished  {
//                Spacer()
//                Circle()
//                    .fill(Color.green.opacity(0.4))
//                    .frame(width: width())
//                Text("Correctly Played")
//                if result.getTotalErrors() > 0 {
//                    Spacer()
//                    Circle()
//                        .fill(Color.red.opacity(0.4))
//                        .frame(width: width())
//                    Text("Not in Scale")
//                    Spacer()
//                    Circle()
//                        .fill(Color.yellow.opacity(0.4))
//                        .frame(width: width())
//                    //Text("In Scale But Not Played")
//                    Text("Missing")
//                }
//                Spacer()
//            }
            Spacer()
        }
        
    }
    
    var body: some View {
        HStack {
            ///LH first
            ForEach(hands.sorted(by: >), id: \.self) { hand in
                legendForHandView(hand:hand)
            }
        }
        
    }
}
