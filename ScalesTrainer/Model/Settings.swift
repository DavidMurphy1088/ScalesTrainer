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
    
    var grade:Int?
    //private var practiceChart:PracticeChart?
    
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
    
    init(board:String) {
        self.id = UUID()
        self.name = ""
        self.email = ""
        self.board = board
        self.grade = nil
        self.settings = UserSettings()
        self.isCurrentUser = false
    }
        
    func getTitle() -> String {
        var title = self.name// + (self.grade == nil ? "" : ",")
        if let grade = self.grade {
            title += ", Grade "
            title += String(grade)
        }
        return title
    }
    
    func getPracticeChart() -> PracticeChart? {
        if let grade = self.grade {
            if let loadedChart = PracticeChart.loadPracticeChartFromFile(user: self, board: self.board, grade: grade) {
                return loadedChart
            }
            else {
                return PracticeChart(user: self, board: self.board, grade: grade)
            }
        }
        return nil
    }
}

class Settings : Encodable, Decodable {
    static var shared = Settings()
    var users:[User]
    
    var isDeveloperMode = false
    var requiredConsecutiveCount = 2
    var defaultOctaves = 2
    var amplitudeFilter:Double
    
    init() {
        self.users = []
//#if targetEnvironment(simulator)
        self.amplitudeFilter = 0.04
    }
    
    func getUser(id:UUID) -> User? {
        for user in users {
            if user.id == id {
                return user
            }
        }
        return nil
    }
    
    func getUser(name:String) -> User? {
        for user in users {
            if user.name == name {
                return user
            }
        }
        return nil
    }

    func getDefaultBackgroundColor() -> Color {
        let red = CGFloat(0.8219926357269287)
        let green = CGFloat(0.8913233876228333)
        let blue = CGFloat(1.0000004768371582)
        let alpha = CGFloat(1)
        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return Color(uiColor)
    }
    
    func setCurrentUser(id:UUID) {
        for user in users {
            if user.id == id {
                user.isCurrentUser = true
                ViewManager.shared.updateCurrentPublished(user: user)
            }
            else {
                user.isCurrentUser = false
            }
        }
    }
    
    func addUser(user:User) {
        self.users.append(user)
    }
    
    func deleteUser(by id: UUID) {
        users.removeAll { $0.id == id }
    }

    func setUserGrade(_ user:User, _ grade:Int) {
        user.grade = grade
        if user.isCurrentUser {
            ViewManager.shared.updateCurrentPublished(user: user)
        }
    }
    
    func setUserName(_ user:User, _ name:String) {
        user.name = name
        if user.isCurrentUser {
            ViewManager.shared.updateCurrentPublished(user: user)
        }
    }
    
    func getCurrentUser() -> User? {
        for user in self.users {
            if user.isCurrentUser {
                return user
            }
        }
        if self.users.count > 0 {
            self.setCurrentUser(id: self.users[1].id)
            return self.users[1]
        }
        return nil
    }

    func save() {
        guard self.users.count > 0 else {
            return
        }
        guard self.users[0].name.count > 0 else {
            return
        }
        //return
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.set(jsonString, forKey: "settings")
                let currentUser = self.getCurrentUser()
                //Logger.shared.log(self, "➡️ settings saved userCount:\(self.users.count) currentuser:\(currentUser?.name ?? "none")")
            }
            else {
                AppLogger.shared.reportError(self, "save cannot form JSON")
            }
        } catch {
            AppLogger.shared.reportError(self, "save:" + error.localizedDescription)
        }
    }
    
    func load() {
        if let jsonString = UserDefaults.standard.string(forKey: "settings") {
            do {
                guard let jsonData = jsonString.data(using: .utf8) else {
                    AppLogger.shared.reportError(self, "load: cannot conver to JSON")
                    return
                }
                let jsonDecoder = JSONDecoder()
                let decoded = try jsonDecoder.decode(Settings.self, from: jsonData)
                self.users = decoded.users
                //self.currentUserIndex = decoded.currentUserIndex
                self.isDeveloperMode = decoded.isDeveloperMode
                self.requiredConsecutiveCount = decoded.requiredConsecutiveCount
                self.defaultOctaves = decoded.defaultOctaves
                self.amplitudeFilter = decoded.amplitudeFilter
                let currentUser = self.getCurrentUser()
                AppLogger.shared.log(self, "settings load userCount:\(self.users.count) currentuser:\(currentUser?.name ?? "none")")
            } catch {
                AppLogger.shared.reportError(self, "load:" + error.localizedDescription)
            }
        }
    }
    
    func debug11(_ ctx:String) {
        print("Settings debug ============= \(ctx)")
        for user in users {
            print("  User", user.name, "Grade:", user.grade ?? "")
        }
        print()
    }
        
    public func isDeveloperMode1() -> Bool {
        if users.count == 0 {
            return false
        }
        for user in self.users {
            if user.name.range(of: "dev", options: .caseInsensitive) != nil {
                return true
            }
        }
        return false
    }
}

