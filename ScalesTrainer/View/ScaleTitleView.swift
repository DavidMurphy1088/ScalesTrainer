import Foundation
import SwiftUI
        
//struct ScaleTitleView: View {
//    let scale:Scale
//    let isLandscape = false
//    let practiceModeHand:HandType?
//    
//    var body: some View {
//        if isLandscape {
//            HStack {
//                ScaleTitleView1(scale: scale, practiceModeHand: practiceModeHand)
//                //.commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading).padding(.horizontal, 0)
//                Spacer()
//                //SelectScaleParametersView().padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
//                if UIDevice.current.userInterfaceIdiom != .phone {
//                    HideAndShowView().padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
//                }
//                Spacer()
//            }
//            //.commonFrameStyle(backgroundColor: Color.white)
//        }
//        else {
//            HStack {
//                ScaleTitleView1(scale: scalesModel.scale, practiceModeHand: practiceModeHand)
//                //.commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading).padding(.horizontal, 0)
//            }
//            HStack {
//                Spacer()
//                SelectScaleParametersView().padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
//                if UIDevice.current.userInterfaceIdiom != .phone {
//                    HideAndShowView().padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
//                }
//                Spacer()
//            }
//            //.commonFrameStyle(backgroundColor: Color.white)
//        }
//    }
//}

struct ScaleTitleView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    let scale:Scale
    let practiceModeHand:HandType?
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
    
    func getTitle(practiceModeHand:HandType?) -> String {
        func getHandName() -> String? {
            var handName:String? = nil
            if scale.hands.count == 1 {
                switch scale.hands[0] {
                case 0: handName = "RH"
                case 1: handName = "LH"
                default: handName = "Together"
                }
            }
            else {
                if let practiceHand = practiceModeHand {
                    switch practiceHand {
                    case .right: handName = "RH"
                    default: handName = "LH"
                    }
                }
                else {
                    if scale.scaleMotion != .contraryMotion {
                        handName = "Together"
                    }
                }
            }
            return handName
        }
        
        var title = ""
        if let customisation = scale.scaleCustomisation {
            if let hand = self.practiceModeHand {
                if hand == .left {
                    if let customName = customisation.customScaleNameLH {
                        title = customName
                    }
                }
                if hand == .right {
                    if let customName = customisation.customScaleNameRH {
                        title = customName
                    }
                }
            }
            else {
                if let customName = customisation.customScaleName {
                    title = customName
                }
            }
            
        }
        if title.count == 0 {
            title = scale.scaleRoot.name + " " + scale.scaleType.description
            if scale.scaleMotion == .contraryMotion {
                title += " in Contrary Motion"
            }
            if let handName = getHandName() {
                title += ", " + handName
            }
        }
        if scale.octaves > 1 {
            title += ", \(scale.octaves) Octaves"
        }
        else {
            title += ", 1 Octave"
        }

        return title
    }
    
    func getTempoStr(tempo:Int, compound:Bool) -> String {
        var tempoStr = "\u{2669}"
        if compound {
            tempoStr += String("\u{00B7}")
            tempoStr += " "
        }
        tempoStr += "=\(scale.minTempo)"
        return tempoStr
    }
    
    var body: some View {
        let compoundTime = scale.timeSignature.top % 3 == 0
        let font:Font = .title
        VStack(spacing: 0) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                HStack {
                    Text("\(getTitle(practiceModeHand: practiceModeHand))")
                        .padding(.horizontal, 0)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(getTempoStr(tempo:scale.minTempo, compound: compoundTime)).padding(.horizontal, 0)
                        //.font(font)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    if practiceModeHand != nil {
                        Text("Separate Hand Practice Only").padding(.horizontal, 0).italic().foregroundColor(.white)
                    }
                }
                .font(.body)
            }
            else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("\(getTitle(practiceModeHand: practiceModeHand)), ").padding(.horizontal, 0)
                            .font(font)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(getTempoStr(tempo:scale.minTempo, compound: compoundTime)).padding(.horizontal, 0)
                            .font(font)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(", \(scale.getDynamicsDescription(long: true)), \(scale.getArticulationsDescription())").italic().padding(.horizontal, 0)
                            .font(font)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    if practiceModeHand != nil {
                        Text("Separate Hand Practice Only").padding(.horizontal, 0).italic().foregroundColor(.white)
                    }
                    
                }
                //.font(.body)
                ///Large ttitle font overflows on long titles
                .font(.title2)
            }
        }
        .padding(.vertical, 8) // Keeps height minimal
        .frame(maxWidth: .infinity) // Makes it take full device width
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            )
    }
}
