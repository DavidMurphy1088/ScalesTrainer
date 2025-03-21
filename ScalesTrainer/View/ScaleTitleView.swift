import Foundation
import SwiftUI
        
struct ScaleTitleView: View {
    let scale:Scale
    let practiceModeHand:HandType?
    
    func getHelp(topic:String) -> String? {
        return HelpMessages.shared.messages[topic] ?? ""
    }
    
    var body: some View {
        VStack {
            //Text("ScaleTitleView")
            let mainTitle = scale.getScaleDescription(name: true)
            let compact = UIDevice.current.userInterfaceIdiom == .phone
            Text("\(mainTitle)").font(compact ? .body :  .title2).foregroundColor(.blue)
            HStack {
                Spacer()
                let line = scale.getScaleDescription(hands: true) + ", " + scale.getScaleDescription(octaves:true) + ", " + scale.getScaleDescription(tempo:true)
                Text("\(line)").font(compact ? .footnote : .body)
                Spacer()
            }
            HStack {
                Spacer()
                Text("\(scale.getScaleDescription(dynamics: true))").italic().font(compact ? .footnote : .body)
                if practiceModeHand != nil {
                    //Spacer()
                    Text("Separate Hand Practice Only").italic().foregroundColor(.blue).font(compact ? .footnote : .body)
                }
                Spacer()
            }
        }
    }
    
//    var body1: some View {
//        let compoundTime = scale.timeSignature.top % 3 == 0
//        let font:Font = .title
//        VStack(spacing: 0) {
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                HStack {
//                    Text("\(getTitle(practiceModeHand: practiceModeHand))")
//                        .padding(.horizontal, 0)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                    Text(getTempoStr(tempo:scale.minTempo, compound: compoundTime)).padding(.horizontal, 0)
//                        //.font(font)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                    if practiceModeHand != nil {
//                        Text("Separate Hand Practice Only").padding(.horizontal, 0).italic().foregroundColor(.white)
//                    }
//                }
//                .font(.body)
//            }
//            else {
//                VStack(spacing: 0) {
//                    HStack(spacing: 0) {
//                        Text("\(getTitle(practiceModeHand: practiceModeHand)), ").padding(.horizontal, 0)
//                            .font(font)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                        Text(getTempoStr(tempo:scale.minTempo, compound: compoundTime)).padding(.horizontal, 0)
//                            .font(font)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                        Text(", \(scale.getDynamicsDescription(long: true)), \(scale.getArticulationsDescription())").italic().padding(.horizontal, 0)
//                            .font(font)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                    if practiceModeHand != nil {
//                        Text("Separate Hand Practice Only").padding(.horizontal, 0).italic().foregroundColor(.white)
//                    }
//                    
//                }
//                //.font(.body)
//                ///Large ttitle font overflows on long titles
//                .font(.title2)
//            }
//        }
//        .padding(.vertical, 8) // Keeps height minimal
//        .frame(maxWidth: .infinity) // Makes it take full device width
//        .background(
//            LinearGradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
//                           startPoint: .topLeading, endPoint: .bottomTrailing)
//            )
//    }
}
