//import Foundation
//import SwiftUI
//import Combine
//import AVFoundation
//import AudioKit
//
//struct BadgesViewOLD: View {
//    @Environment(\.dismiss) private var dismiss
//    @State var user:User?
//    @State var badgeContainer:BadgeContainer?
//    @State var sortedScaleBadges:[BadgeContainer.ScaleBadges] = []
//    @State var groupByScaleBadges:[[BadgeContainer.ScaleBadges]] = []
//    let badgeSize = UIScreen.main.bounds.width * 0.03
//    
//    func sortBadges() -> [BadgeContainer.ScaleBadges] {
//        guard let badgeContainer = badgeContainer else {
//            return []
//        }
//
//        let sortedById = badgeContainer.scaleBadges.sorted { $0.scaleId < $1.scaleId }
//        var lastRowId:ScaleID?
//        var maxBadgeCount:Int = 0
//        var maxBadgesperScaleId: [ScaleID: Int] = [:]
//        
//        ///A scale set is the syllabus scale plus any off-syllabus RH or LH scales as add-ons
//        ///For each scale set determine its sort position based on the max number of badges for any of its syllabus or add-on scales
//        //////ScaleID is the ID of the row's scale without its hands attribute. i.e. all hand variations of scale have the same ScaleID
//        for row in sortedById {
//            //print("========", row.scaleId.scaleRoot.name, row.badges.count)
//            if let lastRowId = lastRowId {
//                if row.scaleId != lastRowId {
//                    maxBadgesperScaleId[lastRowId] = maxBadgeCount
//                    //print("  ========>setmax", lastRowId.scaleRoot.name, maxBadgeCount)
//                    maxBadgeCount = 0
//                }
//            }
//            if row.badges.count > maxBadgeCount {
//                maxBadgeCount = row.badges.count
//            }
//
//            lastRowId = row.scaleId
//        }
//        let sortedByBadgeCount = badgeContainer.scaleBadges.sorted {maxBadgesperScaleId[$0.scaleId] ?? -1 > maxBadgesperScaleId[$1.scaleId] ?? -1}
//        return sortedByBadgeCount
//    }
//    
//    func groupByScale() -> [[BadgeContainer.ScaleBadges]] {
//        var lastScaleId:ScaleID? = nil
//        var result:[[BadgeContainer.ScaleBadges]] = []
//        var resultRow:[BadgeContainer.ScaleBadges] = []
//        for row in self.sortedScaleBadges {
//            if let lastScaleId = lastScaleId {
//                if row.scaleId != lastScaleId {
//                    result.append(resultRow)
//                    resultRow = []
//                }
//            }
//            resultRow.append(row)
//            lastScaleId = row.scaleId
//        }
//        return result
//    }
//    
//    func name(scale:Scale) -> String {
//        return scale.getScaleDescriptionParts(name:true)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                ScrollView(.vertical, showsIndicators: true) {
//                    ForEach(Array(self.groupByScaleBadges.enumerated()), id: \.offset) { index, group in
//                        VStack {
//                            ForEach(Array(group.enumerated()), id: \.offset) { index, scaleBadges in
//                                HStack {
//                                    //Text("\(scaleBadges.scaleId.scaleRoot.name)").foregroundColor(scaleBadges.onSyllabus ? .black : .gray)
//                                    if scaleBadges.onSyllabus {
//                                        HStack {
//                                            Text("\(scaleBadges.scaleId.scaleRoot.name)").foregroundColor(scaleBadges.onSyllabus ? .black : .gray)
//                                            Text("\(scaleBadges.scaleId.scaleType.description)").foregroundColor(scaleBadges.onSyllabus ? .black : .gray)
//                                            Text("Both Hands")
//                                        }
//                                        .padding()
//                                        .frame(width: badgeSize * 8.0)
//                                        .background(
//                                            RoundedRectangle(cornerRadius: 12)
//                                                .fill(Color.white)
//                                        )
//                                        .overlay(
//                                            RoundedRectangle(cornerRadius: 12)
//                                                .stroke(Color.gray, lineWidth: 2)
//                                        )
//                                    }
//                                    else {
//                                        if scaleBadges.hands == [1] {
//                                            HStack {
//                                                Image("hand_left")
//                                                    .resizable()
//                                                    .renderingMode(.template)
//                                                    .aspectRatio(contentMode: .fit)
//                                                    .frame(width: badgeSize, height: badgeSize)
//                                                    .foregroundColor(.gray)
//                                                    .padding(6)
//                                                    .background(Color.white)
//                                                    .clipShape(Circle())
//                                                    .overlay(
//                                                        Circle()
//                                                            .stroke(Color.gray, lineWidth: 2)
//                                                    )
//                                            }
//                                            .frame(width: badgeSize * 8.0)
//                                       }
//                                        else {
//                                            HStack {
//                                                Image("hand_right")
//                                                    .resizable()
//                                                    .renderingMode(.template)
//                                                    .aspectRatio(contentMode: .fit)
//                                                    .frame(width: badgeSize, height: badgeSize)
//                                                    .foregroundColor(.gray)
//                                                    .padding(6) // space between image and border
//                                                    .background(Color.white) // background inside circle
//                                                    .clipShape(Circle()) // make the whole thing circular
//                                                    .overlay(
//                                                        Circle()
//                                                            .stroke(Color.gray, lineWidth: 2) // border
//                                                    )
//                                            }
//                                            .frame(width: badgeSize * 8.0)
//                                        }
//                                    }
//                                    
//                                    ScrollView(.horizontal, showsIndicators: true) {
//                                        HStack {
//                                            ForEach(Array(scaleBadges.badges.enumerated()), id: \.offset) { index, badge in
//                                                Image(systemName: "star.fill")
//                                                    .resizable()
//                                                    .scaledToFit()
//                                                    .frame(width: badgeSize, height: badgeSize)
//                                                    .foregroundColor(.yellow) // solid color
////                                                Image(badge.imageName)
////                                                    .resizable()
////                                                    .scaledToFit()
////                                                    .frame(width: badgeSize, height: badgeSize)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        .padding()
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                //.fill(Color(hue: 0.58, saturation: 0.18, brightness: 0.98)) // pastel light
//                                .fill(Color(hue: 0.58, saturation: 0.08, brightness: 0.98)) 
//                        )
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 16)
//                                .strokeBorder(Color.gray.opacity(2.0), lineWidth: 2)
//                        )
//                        .padding(.horizontal)
////                        .border(Color.green)
////                        .padding()
//                    }
//                }
//            }
//            .commonToolbar(
//                title: "Badges", onBack: {}
//            )
//            .onAppear {
//                self.user = Settings.shared.getCurrentUser()
//                badgeContainer = user!.getBadgeContainer()
//                for _ in 0..<2 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: 2), hands: [0,1],badge: Badge(id: r))
//                }
//                for _ in 0..<3 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: 2),
//                                             hands: [0], badge: Badge(id: r))
//                }
//                for _ in 0..<6 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: 2),
//                                             hands: [1], badge: Badge(id: r))
//                }
//                
//                for _ in 0..<1 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: 2),hands: [0,1], badge: Badge(id: r))
//                }
//                for _ in 0..<4 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: 2),hands: [1], badge: Badge(id: r))
//                }
//                
//                for _ in 0..<2 {
//                    let r = Int.random(in: 0...Badge.imageNames.count-1)
//                    badgeContainer!.addBadge(scaleId: ScaleID(scaleRoot: ScaleRoot(name: "C"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2),hands: [1], badge: Badge(id: r))
//                }
//
//                badgeContainer?.debug()
//                self.sortedScaleBadges = sortBadges()
//                self.groupByScaleBadges = self.groupByScale()
//            }
//        }
//        
//    }
//    
//}
