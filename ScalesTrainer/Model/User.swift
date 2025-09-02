import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

class UserPublished : ObservableObject {
    @Published var name = ""
    @Published var board = ""
    @Published var grade = 0
    @Published var color = ""
}

class User : Encodable, Decodable, Hashable, Identifiable {
    var id:UUID
    var name:String
    var email:String
    var settings:UserSettings
    var color:String
    var boardAndGrade:MusicBoardAndGrade
    var selectedMinorType:ScaleType?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.settings = UserSettings()
        let colorNames = [
            "red", "orange", "yellow", "green",
            "mint", "teal", "cyan", "blue",
            "indigo", "purple", "pink"
        ]
        self.color = colorNames.randomElement()!
        self.boardAndGrade = MusicBoardAndGrade(board: MusicBoard.getSupportedBoards()[0], grade: 1)
    }
    
    init(boardAndGrade:MusicBoardAndGrade) {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.settings = UserSettings()
        self.boardAndGrade = boardAndGrade
        self.color = ""
        setColor()
    }
    
    func setColor() {
        let colorNames = [
            "red", "yellow", "green",
            "mint", "teal",
            "indigo"
        ]
        self.color = colorNames.randomElement()!

    }
    
    func updateFromUser(user:User) {
        self.name = user.name
        self.email = user.email
        self.boardAndGrade = user.boardAndGrade
        self.settings = user.settings
        self.color = user.color
        self.selectedMinorType = user.selectedMinorType
    }
    
    static func color(from name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray // fallback
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combine the `id` property into the hasher
    }
    
    func debug(_ ctx:String) {
        print("===== User", ctx, self.name, self.boardAndGrade.board, "Grade:", self.boardAndGrade.grade, "MinorType", self.selectedMinorType)
    }
    
    ///User settings irrespective of the grade the student is in.
    class UserSettings : Encodable, Decodable {
        var keyboardColor:[Double] = [1.0, 0.9647, 1.0, 1.0]
        var backgroundColor:[Double] = [0.8219926357269287, 0.8913233876228333, 1.0000004768371582, 1.0]
        var backingSamplerPreset:Int = 0
        var badgeStyle = 0
        var practiceChartGamificationOn = true
        var useMidiSources = false
        var scaleLeadInBeatCountIndexOld:Int = 2
        
        public func getLeadInBeatsOld() -> Int {
            switch scaleLeadInBeatCountIndexOld {
            case 1:
                return 2
            case 2:
                return 4
            default:
                return 0
            }
        }
        
        func isCustomColor() -> Bool {
            return keyboardColor.contains{ $0 != 1.0 }
        }

        ///Default colors if not set by user
        func getBackgroundColor() -> Color {
            let red = CGFloat(self.backgroundColor[0])
            let green = CGFloat(self.backgroundColor[1])
            let blue = CGFloat(self.backgroundColor[2])
            let alpha = CGFloat(self.backgroundColor[3])
            let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            return Color(uiColor)
        }
        
        func getKeyboardColor() -> Color {
            let red = CGFloat(self.keyboardColor[0])
            let green = CGFloat(self.keyboardColor[1])
            let blue = CGFloat(self.keyboardColor[2])
            let alpha = CGFloat(self.keyboardColor[3])
            let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            return Color(uiColor)
        }
        
        func setBackgroundColor(_ color: Color) {
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            self.backgroundColor = [Double(red), Double(green), Double(blue), Double(alpha)]
        }
        func setKeyboardColor(_ color: Color) {
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            self.keyboardColor = [Double(red), Double(green), Double(blue), Double(alpha)]
        }
    }
    
    func getTitle() -> String {
        var title = ""
        if !self.name.isEmpty {
            title = self.name
            title += ", " + self.boardAndGrade.board.name
            title += " Grade "
            title += String(self.boardAndGrade.board.name)
        }
        return title
    }
    
    func getStudentScales() -> StudentScales {
        if let loadedChart = StudentScales.loadFromFile(user: self) {
            return loadedChart
        }
        else {
            return StudentScales(user: self)
        }
    }
    
}
