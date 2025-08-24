import Foundation
import CoreData
import MessageUI
import WebKit

class ExerciseBadge : Encodable, Decodable {
    static let imageNames = ["badge_1", "badge_2", "badge_3", "badge_4", "badge_5", "badge_6", "badge_7", "badge_8", "badge_9", "badge_10",
                        "badge_11", "badge_12", "badge_13", "badge_14", "badge_15", "badge_16"]
    static let names = ["Stripey", "Pandy", "Hippo-Hop", "Cheeky Paws", "Peekaboo", "Trunky", "Whiskers", "Mittens", "Mango", "Cuddles", "Chipper", "Zippy", "Chomper","Rambo","Foxy","Mischief"]
    static var lastIdIssued:Int?
    
    let id:Int
    let imageName:String
    let name:String
    
    init(id:Int) {
        self.id = id
        imageName = ExerciseBadge.imageNames[id]
        name = ExerciseBadge.names[id]
    }
    
    static func getRandomExerciseBadge() -> ExerciseBadge {
        var random = 0
        while true {
            //random = Int.random(in: 0..<Badge.imageNames.count)
            random = Int.random(in: 0..<ExerciseBadge.names.count)
            if random != ExerciseBadge.lastIdIssued {
                ExerciseBadge.lastIdIssued = random
                break
            }
        }
        return ExerciseBadge(id: random)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageName
        case name
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(name, forKey: .name)
    }
}


