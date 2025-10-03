import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

class User : Encodable, Decodable, Hashable, Identifiable {
    var id:UUID
    var name:String
    var email:String
    var settings:UserSettings
    private var color:String
    var boardAndGrade:MusicBoardAndGrade
    var selectedMinorType:ScaleType?
    var testSerialise: String
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    init() {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.settings = UserSettings()
        self.color = ""
        self.boardAndGrade = MusicBoardAndGrade(board: MusicBoard.getSupportedBoards()[0], grade: 1)
        self.testSerialise = ""
    }
    
    init(boardAndGrade:MusicBoardAndGrade) {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.settings = UserSettings()
        self.boardAndGrade = boardAndGrade
        self.color = ""
        self.testSerialise = ""
        self.color = ""
    }
    
    func getColor() -> String {
        return color
    }
    
    func setColor() {
        if self.color.count > 0 {
            return
        }
        ///Select a color not already in use
        let shade = 3
        
        if Settings.shared.users.count == 0 {
            self.color = FigmaColors.shared.getColorHex("green", shade)
            return
        }
        var remainingColors:[String] = FigmaColors.shared.getColorHexes(shade:3)
        
        ///remove colors already used
        for i in 0..<Settings.shared.users.count {
            let user = Settings.shared.users[i]
            if user.id == self.id {
                continue
            }
            if remainingColors.contains(user.color) {
                remainingColors.removeAll { $0 == user.color }
            }
        }
        if remainingColors.count == 0 {
            ///All used now, pick one at random
            remainingColors = FigmaColors.shared.getColorHexes(shade:3)
        }
        let r = Int.random(in : 0..<remainingColors.count)
        self.color = remainingColors[r]
    }
    
    func updateFromUser(user:User) {
        self.name = user.name
        self.email = user.email
        self.boardAndGrade = user.boardAndGrade
        self.settings = user.settings
        self.color = user.color
        self.selectedMinorType = user.selectedMinorType
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
        let scales:StudentScales
        if let loadedChart = StudentScales.loadFromFile(user: self) {
            scales = loadedChart
        }
        else {
            scales = StudentScales(user: self)
        }

        return scales
    }
    
}
