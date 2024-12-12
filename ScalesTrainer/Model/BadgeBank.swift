import Foundation
import CoreData
import MessageUI
import WebKit

class Badge : Encodable, Decodable {
    static let names = ["badge_1", "badge_2", "badge_3", "badge_4", "badge_5", "badge_6", "badge_7", "badge_8", "badge_9", "badge_10",
                        "badge_11", "badge_12", "badge_13", "badge_14", "badge_15", "badge_16"]
    static var lastIdIssued:Int?
    
    let id:Int
    let imageName:String
    
    init(id:Int) {
        self.id = id
        //imageName = "pet_dogface"
        imageName = Badge.names[id]
        print("========= BADGE INIT", id, imageName)
    }
    
    static func getRandomExerciseBadge() -> Badge {
        var random = 0
        while true {
            random = Int.random(in: 0..<Badge.names.count)
            if random != Badge.lastIdIssued {
                Badge.lastIdIssued = random
                break
            }
        }
        return Badge(id: random)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageName
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageName, forKey: .imageName)
    }
}

class BadgeBank : ObservableObject {
    static let shared = BadgeBank()

    @Published var badges:[Badge] = []
    @Published private(set) var totalCorrectPublished: Int = 0
    
    var totalCorrect: Int = 0
    func setTotalCorrect(_ value:Int) {
        self.totalCorrect = value
        DispatchQueue.main.async {
            self.totalCorrectPublished = self.totalCorrect
            //if self.totalCorrect >= self.numberToWin {
                //self.exerciseState = .won
            //}
        }
    }
    func addBadge(badge:Badge) {
        self.badges.append(badge)
    }
    
//    func clearMatches() {
//        setTotalCorrect(0)
//        DispatchQueue.main.async {
//            self.matches = []
//        }
//    }
}

