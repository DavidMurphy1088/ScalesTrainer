import Foundation
import SwiftUI
import Combine
import AVFoundation
import AudioKit

struct BadgesView: View {
    @Environment(\.dismiss) private var dismiss
    @State var user:User?
    @State var badgeContainer:BadgeContainer?
    
    func sortBadges() -> [BadgeContainer.ScaleBadges] {
//        guard let user = user else {
//            return []
//        }
        if let badgeContainer = badgeContainer {
            return badgeContainer.sortedScaleBadgesByBadgeCount()
        }
        else {
            return []
        }
    }
    
    func name(scale:Scale) -> String {
        return scale.getScaleDescriptionParts(name:true)
    }
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(Array(sortBadges().enumerated()), id: \.offset) { index, scalesBadges in
                        HStack() {
                            Text("OnSyllabus:\(scalesBadges.onSyllabus)")
                            if !scalesBadges.onSyllabus {
                                Text("   ")
                            }
                            Text("\(scalesBadges.scaleRoot.name)")
                            Text("\(scalesBadges.scaleType.description)")
                            Text("Hands: \(scalesBadges.hands.count)")
                        }
                    }
                }
            }
            .commonToolbar(
                title: "Badges", onBack: {}
            )
            .onAppear {
                self.user = Settings.shared.getCurrentUser()
                badgeContainer = user!.getBadgeContainer()
            }
        }
        
    }
    
}
