import Foundation
import SwiftUI
        
struct ScaleTitleView: View {
    let scale:Scale
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
    
    var body: some View {
        VStack {
            let mainTitle = scale.getScaleDescriptionParts(name: true)
            let compact = UIDevice.current.userInterfaceIdiom == .phone
            Text("\(mainTitle)").font(compact ? .body :  .title2).foregroundColor(.blue)
            HStack {
                Spacer()
                let line = scale.getScaleDescriptionParts(hands: true) + ", " + scale.getScaleDescriptionParts(octaves:true) + ", " + scale.getScaleDescriptionParts(tempo:true)
                Text("\(line)").font(compact ? .footnote : .body)
                Spacer()
            }
            HStack {
                Spacer()
                Text("\(scale.getScaleDescriptionParts(dynamics: true))").italic().font(compact ? .footnote : .body)
//                if practiceModeHand != nil {
//                    //Spacer()
//                    Text("Separate Hand Practice Only").italic().foregroundColor(.blue).font(compact ? .footnote : .body)
//                }
                Spacer()
            }
        }
    }
}
