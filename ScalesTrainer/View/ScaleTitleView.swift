
import Foundation
import SwiftUI

struct ScaleTitleView: View {
    let scale:Scale
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
    
    func getTitle() -> String {
        var title = scale.scaleRoot.name + " " + scale.scaleType.description
        if scale.scaleMotion == .contraryMotion {
            title += " in Contrary Motion"
        }
        else {
            var handName = ""
            if scale.hands.count == 1 {
                switch scale.hands[0] {
                case 0: handName = "RH"
                case 1: handName = "LH"
                default: handName = "Both Hands"
                }
            }
            else {
                handName = "Both Hands"
            }
            title += " " + handName
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
                Text("\(getTitle())").padding(.horizontal, 0)
                HStack(spacing: 0) {
                    Text("min. ").padding(.horizontal, 0)
                    Image(compoundTime ? "crotchetDotted" : "crotchet")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width * (compoundTime ? 0.02 : 0.015))
                        ///Center it
                        .padding(.bottom, 4)
                    Text("=\(scale.minTempo)").padding(.horizontal, 0)
                    Text(", mf,").italic().padding(.horizontal, 0)
                    Text(" legato").padding(.horizontal, 0)
                }
            }
            .font(.body)
        }
        else {
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
                Text(", mf,").italic().padding(.horizontal, 0)
                Text(" legato").padding(.horizontal, 0)
            }
            //.font(.body)
            .font(.title)
        }
    }
}
