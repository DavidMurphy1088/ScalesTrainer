import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

public class SettingsPublished : ObservableObject {
    static var shared = SettingsPublished()
    @Published var board:String? 
    @Published var grade:Int?
    @Published var name = ""
    
    func setBoardAndGrade(board:String, grade:Int?) {
        DispatchQueue.main.async {
            self.board = board
            self.grade = grade
        }
    }
    
//    func setFirstName(firstName:String) {
//        DispatchQueue.main.async {
//            self.name = firstName
//        }
//    }
}

class User {
    let settingsPublished = SettingsPublished.shared

    class UserSettings {
        var keyboardColor:[Double] = [0.9999999403953552, 0.949024498462677, 0.5918447375297546, 1.0]
        var backgroundColor:[Double] = [0.8219926357269287, 0.8913233876228333, 1.0000004768371582, 1.0]
        var leadInCOunt:Int = 0
        var backingSamplerPreset:Int = 0
        var badgeStyle = 0
        var practiceChartGamificationOn = true
        var useMidiConnnections = false
        var scaleLeadInBeatCountIndex:Int = 2
        
        public func getLeadInBeats() -> Int {
            switch scaleLeadInBeatCountIndex {
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
    
    var name:String
    var email:String
    var board:String?
    var grade:Int?
    var settings:UserSettings

    init() {
        self.name = ""
        self.email = ""
        self.board = nil
        self.grade = nil
        self.settings = UserSettings()
    }

}

class Settings {
    static var shared = Settings()
    
    var currentUser:User?
    var users:[User]
    private var currentUserIndex = 0
    
    var isDeveloperMode = false
    var requiredConsecutiveCount = 2
    var defaultOctaves = 2
    var amplitudeFilter:Double
    let settingsPublished = SettingsPublished.shared
    
    init() {
        self.users = []
        self.currentUser = nil
//#if targetEnvironment(simulator)
        self.amplitudeFilter = 0.04
    }
    
    func save() {
    }
    
    func loadFromFile() -> Bool {
        return true
    }
    
    func addUser(user:User) {
        self.users.append(user)
        updatePublished()
    }
    
    func setUserGrade(_ grade:Int) {
        self.getCurrentUser().grade = grade
        updatePublished()
    }
    
    func setUserName(_ name:String) {
        self.getCurrentUser().name = name
        updatePublished()
    }
    
    private func updatePublished() {
        let user = self.getCurrentUser()
        if user.name.count > 0 {
            DispatchQueue.main.async {
                self.settingsPublished.name = user.name
                self.settingsPublished.board = user.board
                self.settingsPublished.grade = user.grade
            }
        }
    }
    
    func getCurrentUser() -> User {
        if users.count == 0 {
            return User()
        }
        return users[currentUserIndex]
    }
    
    public func isDeveloperMode1() -> Bool {
        if users.count == 0 {
            return false
        }
        let user = self.getCurrentUser()
        return user.name.range(of: "dev", options: .caseInsensitive) != nil
    }

}

