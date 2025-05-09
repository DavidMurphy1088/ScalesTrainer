import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

class User : Encodable, Decodable, Hashable, Identifiable {
    var id:UUID
    var board:String
    var name:String
    var email:String
    var settings:UserSettings
    var isCurrentUser:Bool
    var grade:Int
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Combine the `id` property into the hasher
    }
    
    ///User settings irrespective of the grade the student is in.
    class UserSettings : Encodable, Decodable {
        //var keyboardColor:[Double] = [0.9999999403953552, 0.949024498462677, 0.5918447375297546, 1.0]
        //var keyboardColor:[Double] = [1.0, 0.949, 0.835, 1.0]
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
    
    init(board:String) {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.board = board
        self.grade = 1
        self.settings = UserSettings()
        self.isCurrentUser = false
    }
    
    func getTitle() -> String {
        var title = ""
        if !self.name.isEmpty {
            title = self.name
            if self.grade > 0 {
                title += ", " + self.board
                title += " Grade "
                title += String(grade)
            }
        }
        return title
    }
    
    func getPracticeChart() -> PracticeChart? {
        //if let grade = self.grade {
            if let loadedChart = PracticeChart.loadPracticeChartFromFile(user: self, board: self.board, grade: grade) {
                return loadedChart
            }
            else {
                return PracticeChart(user: self, board: self.board, grade: grade)
            }
        //}
        //return nil
    }
}
