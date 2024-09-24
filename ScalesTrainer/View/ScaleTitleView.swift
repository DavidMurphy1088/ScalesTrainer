
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
                case 0: handName = "Right Hand"
                case 1: handName = "Left Hand"
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
        var tempo = "♩=\(scale.minTempo)"
        title += ", " + tempo
        return title
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(getTitle()).font(.title).padding(.horizontal, 0)
            Text(", mf").italic().font(.title).padding(.horizontal, 0)
            Text(", legato").font(.title).padding(.horizontal, 0)
        }
    }
}
