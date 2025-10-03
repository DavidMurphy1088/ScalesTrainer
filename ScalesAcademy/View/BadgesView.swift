import Foundation
import SwiftUI
import Combine
import AVFoundation
import AudioKit

class ScaleBadges {
    let title:String
    let badges:Int
    
    init(title:String, badges:Int) {
        self.title = title
        self.badges = badges
    }
}

struct PulsatingChalice: View {
    let badgeSize: CGFloat
    @State private var pulsate = false
    
    var body: some View {
        Image("badge_chalice")
            .resizable()
            .scaledToFit()
            .frame(width: badgeSize, height: badgeSize)
            .scaleEffect(pulsate ? 1.1 : 1.0)        // Slight size pulsation
            .brightness(pulsate ? 0.2 : 0.0)         // Slight brightness pulsation
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                ) {
                    pulsate.toggle()
                }
            }
    }
}

struct BadgesView: View {
    @Environment(\.dismiss) private var dismiss
    @State var user:User?
    //@State var badgeContainer:BadgeContainer?
    //@State var sortedScaleBadges:[BadgeContainer.ScaleBadges] = []
    //@State var groupByScaleBadges:[[BadgeContainer.ScaleBadges]] = []
    let badgeSize = UIScreen.main.bounds.width * 0.03
    @State var scaleBadges:[ScaleBadges] = []
    let screenWidth = UIScreen.main.bounds.size.width
    func getScreenTitle() -> String {
        var title = "Exercise Badges"
        if let user = self.user {
            if let firstWord = user.name.split(separator: " ").first {
                title = "\(firstWord)'s \(title)"
            }
        }
        return title
    }
    var body: some View {
        let leftEdge = screenWidth * (UIDevice.current.userInterfaceIdiom == .phone ? 0.005 : 0.04)
        NavigationStack {
            VStack {
                HStack {
                    FigmaButton("Best Exercises", action: {
                        scaleBadges.sort { $0.badges > $1.badges }
                        //animaton...
                    })
                    Spacer()
                }
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(scaleBadges.indices, id: \.self) { index in
                            let scale = scaleBadges[index]
                            let chalices = scale.badges / 4
                            let remainder = scale.badges % 4
                            
                            //VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                let title = "\(scale.title)" // \(scale.badges)"
                                Text(title)
                                    .font(.headline)
                                    //.frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                HStack(alignment: .center, spacing: 6) {
                                    // Show chalices first (every 4 badges -> 1 chalice)
                                    ForEach(0..<chalices, id: \.self) { _ in
                                        PulsatingChalice(badgeSize: badgeSize)
                                    }
                                    // Show remaining badges as stars
                                    ForEach(0..<remainder, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: badgeSize, height: badgeSize)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.leading, leftEdge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .commonToolbar(
                title: getScreenTitle(), helpMsg: ""
            )
        }
        .onAppear() {
            let user = Settings.shared.getCurrentUser("BadgesView .onAppaer")
            self.user = user
            let board = MusicBoard.getSupportedBoards()[0]
            let grade = MusicBoardAndGrade(board: board, grade:1)
            let scales = grade.enumerateAllScales()
            for scale in scales {
                //scaleBadges.append(ScaleBadges(title: scale.getScaleName(handFull: true), badges: Int.random(in: 1...13)))
            }
        }
    }
}

