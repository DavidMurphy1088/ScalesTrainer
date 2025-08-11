import SwiftUI
import Foundation

class ScaleID: Codable, Comparable, Hashable  {
    var scaleRoot: ScaleRoot
    var scaleType: ScaleType
    var scaleMotion: ScaleMotion
    var octaves:Int

    init(scaleRoot: ScaleRoot, scaleType: ScaleType, scaleMotion:ScaleMotion, octaves:Int) {
        self.scaleRoot = scaleRoot
        self.scaleType = scaleType
        self.scaleMotion = scaleMotion
        self.octaves = octaves
    }
    
    static func == (lhs: ScaleID, rhs: ScaleID) -> Bool {
        return lhs.scaleRoot.name == rhs.scaleRoot.name &&
            lhs.scaleType.description == rhs.scaleType.description &&
            lhs.scaleMotion.description == rhs.scaleMotion.description &&
            lhs.octaves == rhs.octaves
    }
    
    static func < (lhs: ScaleID, rhs: ScaleID) -> Bool {
        if lhs.scaleRoot.name != rhs.scaleRoot.name {
                return lhs.scaleRoot.name < rhs.scaleRoot.name
        }
        if lhs.scaleType.description != rhs.scaleType.description {
            return lhs.scaleType.description < rhs.scaleType.description
        }
        if lhs.scaleMotion.description != rhs.scaleMotion.description {
            return lhs.scaleMotion.description < rhs.scaleMotion.description
        }
        return lhs.octaves < rhs.octaves
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(scaleRoot)
        hasher.combine(scaleType)
        hasher.combine(scaleMotion)
        hasher.combine(octaves)
    }
}

class BadgeContainer: ObservableObject, Codable {
    let user: User
    let board: String
    let grade: Int

    class ScaleBadges: Codable, Identifiable {
        var id = UUID()
        var scaleId:ScaleID
        var badges: [Badge]
        var hands:[Int]
        var onSyllabus:Bool
        
        init(_ scaleId: ScaleID, hands:[Int], onSyllabus:Bool) {
            self.scaleId = scaleId
            self.hands = hands
            self.onSyllabus = onSyllabus
            self.badges = []
        }

        enum CodingKeys: String, CodingKey {
            case scaleId
            case hands
            case badges
            case onSyllabus
        }
    }
    
    var scaleBadges: [ScaleBadges] = []
    
    enum CodingKeys: String, CodingKey {
        case user
        case board
        case grade
        case scaleBadges
    }

    init(user: User, board: String, grade: Int) {
        self.user = user
        self.board = board
        self.grade = grade
        self.scaleBadges = []
        let scales = MusicBoardAndGrade.getScales(boardName: user.board, grade: user.grade)
        for scale in scales {
            let scaleId = ScaleID(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType, scaleMotion:scale.scaleMotion,
                            octaves:scale.octaves)
            let syllabusBadges = ScaleBadges(scaleId, hands:scale.hands, onSyllabus: true)
            self.scaleBadges.append(syllabusBadges)
            
            ///Add places for badges if the scale can be practiced LH and Rh separately
            if scale.hands.count != 1 {
                let syllabusBadgesRH = ScaleBadges(scaleId, hands:[0], onSyllabus: false)
                self.scaleBadges.append(syllabusBadgesRH)
                let syllabusBadgesLH = ScaleBadges(scaleId, hands:[1], onSyllabus: false)
                self.scaleBadges.append(syllabusBadgesLH)
            }
        }
    }
    
    func debug() {
        print("======== Badge Container")
        for row in scaleBadges {
            print (row.scaleId.scaleRoot.name, row.scaleId.scaleType.description, "\t", "Hands: \(row.hands)", "Badges:", row.badges.count)
        }
    }
    
    func addBadge(scaleId:ScaleID, hands:[Int], badge:Badge) {
        for scaleBadges in self.scaleBadges {
            if scaleBadges.scaleId == scaleId {
                if scaleBadges.hands == hands {
                    scaleBadges.badges.append(badge)
                    break
                }
            }
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
        board = try container.decode(String.self, forKey: .board)
        grade = try container.decode(Int.self, forKey: .grade)
        scaleBadges = try container.decode([ScaleBadges].self, forKey: .scaleBadges)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        try container.encode(board, forKey: .board)
        try container.encode(grade, forKey: .grade)
        try container.encode(scaleBadges, forKey: .scaleBadges)
    }
    
    func saveBadgeContainer(_ container: BadgeContainer, to fileName: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // optional: human-readable JSON

        let data = try encoder.encode(container)

        let url = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(fileName)

        try data.write(to: url, options: .atomic)

        print("BadgeContainer saved to: \(url.path)")
    }
    
    static func getFileName(user:User, board:String, grade:Int) -> String {
        return "_" + user.name + "_" + board + "_" + String(grade) + "_badges"
    }
    
    static func loadFromFile(user:User, board:String, grade:Int) -> BadgeContainer? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            if let notRegression = ProcessInfo.processInfo.environment["NOT_RUNNING_REGRESSION"] {
                AppLogger.shared.log(self, "Failed to load PracticeChart - file not found")
            }
            return nil
        }
        let url = dir.appendingPathComponent(getFileName(user: user, board: board, grade: grade))
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode(BadgeContainer.self, from: data)
            }
        catch {
            AppLogger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
