
import Foundation
import SwiftUI

struct ScaleTitleView: View {
    let scale:Scale
    let practiseModeOnly:Bool
    
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
    
    func getTitle() -> String {
        var title = ""
        if let customisation = scale.scaleCustomisation {
            if let custonName = customisation.customScaleName {
                title = custonName
            }
        }
        if title.count == 0 {
            title = scale.getTitle()
            if scale.scaleMotion == .contraryMotion {
                title += " in Contrary Motion"
            }
            else {
                var handName = ""
                if scale.hands.count == 1 {
                    switch scale.hands[0] {
                    case 0: handName = "RH"
                    case 1: handName = "LH"
                    default: handName = "Together"
                    }
                }
                else {
                    handName = " Together"
                }
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
    
    var body: some View {
        let compoundTime = scale.timeSignature.top % 3 == 0
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack {
                //HStack {
                    Text("\(getTitle())").padding(.horizontal, 0)
                //}
                HStack(spacing: 0) {
                    Text("min. ").padding(.horizontal, 0)
                    Image(compoundTime ? "crotchetDotted" : "crotchet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width * (compoundTime ? 0.02 : 0.015))
                    ///Center it
                        .padding(.bottom, 4)
                    Text("=\(scale.minTempo), ").padding(.horizontal, 0)
                    Text("\(scale.getDynamicsDescription(long: true)), \(scale.getArticulationsDescription())").italic().padding(.horizontal, 0)
                }
                if practiseModeOnly {
                    Text("Separate Hand Practise Only").padding(.horizontal, 0).italic().foregroundColor(.white)
                }
            }
            .font(.body)
        }
        else {
            VStack {
                HStack(spacing: 0) {
                    Text("\(getTitle()), min. ").padding(.horizontal, 0)
                    Image(compoundTime ? "crotchetDotted" : "crotchet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width * (compoundTime ? 0.02 : 0.015))
                    ///Center it
                        .padding(.bottom, 8)
                    //.padding(.top, 8)
                    Text("=\(scale.minTempo)").padding(.horizontal, 0)
                    //if !orientationInfo.isPortrait {
                        Text(", \(scale.getDynamicsDescription(long: true)), \(scale.getArticulationsDescription())").italic().padding(.horizontal, 0)
                    //}
                }
                if practiseModeOnly {
                    Text("Separate Hand Practise Only").padding(.horizontal, 0).italic().foregroundColor(.white)
                }
//                if orientationInfo.isPortrait {
//                    HStack {
//                        Text("\(scale.getDynamicsDescription(long: true)), \(scale.getArticulationsDescription())").italic().padding(.horizontal, 0)
//                    }
//                }
            }
            //.font(.body)
            ///Large ttitle font overflows on long titles
            .font(.title2)
        }
    }
}
