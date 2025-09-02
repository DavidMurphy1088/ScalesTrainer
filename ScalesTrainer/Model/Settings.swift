import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

class Settings : Encodable, Decodable {
    static var shared = Settings()
    var users:[User]
    var isDeveloperMode = false
    var requiredConsecutiveCount = 2
    var defaultOctaves = 2
    var amplitudeFilter:Double
    var currentUserId:UUID? = nil
    
    init() {
        self.users = []
//#if targetEnvironment(simulator)
        self.amplitudeFilter = 0.04
    }
    
    ///User could be new or existing
    func setUser(user: User) {
        var found = false
        for usr in users {
            if usr.id == user.id {
                usr.updateFromUser(user: user)
                found = true
                break
            }
        }
        if !found {
            self.users.append(user)
        }
        self.setCurrentUser(id: user.id)
        ScalesModel.shared.updateUserPublished(user: user)
        //save()
    }

    func deleteUser(user: User) {
        users.removeAll {$0.id == user.id}
        save()
    }

    func aValidUserIsDefined() -> Bool {
        if Settings.shared.users.count == 0 {
            return false
        }
        let user = Settings.shared.getCurrentUser()
        if user.name.isEmpty {
            return false
        }
        return true
    }
    
    func getUser(id:UUID) -> User? {
        for user in users {
            if user.id == id {
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
        self.currentUserId = id
        var fnd = false
        for user in users {
            if user.id == id {
                ViewManager.shared.updatePublishedUser(user: user)
                fnd = true
                break
            }
        }
        if fnd {
            self.save()
        }
        else {
            fatalError("Cant set current user. id:\(String(id.uuidString.suffix(4))) UsersCount:\(self.users.count)")
        }
    }
    
    func hasUsers() -> Bool {
        return self.users.count > 0
    }
    
    func hasUser(name:String) -> Bool {
        for user in users {
            if user.name == name {
                return true
            }
        }
        return false
    }

    func getCurrentUser() -> User {
        if self.currentUserId != nil {
            for user in self.users {
                if user.id == self.currentUserId {
                    return user
                }
            }
        }
        fatalError("No current user. CurrentIdL \(String(self.currentUserId?.uuidString.suffix(4) ?? "nil")) Count:\(self.users.count)")
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
                //let currentUser = self.getCurrentUser()
//                AppLogger.shared.log(self, "➡️ settings saved userCount:\(self.users.count) currentuser:\(currentUser.name) Grade:\(currentUser.board) \(currentUser.grade)")
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
                    AppLogger.shared.reportError(self, "load: cannot convert to JSON")
                    return
                }
                let jsonDecoder = JSONDecoder()
                let decoded = try jsonDecoder.decode(Settings.self, from: jsonData)
                self.users = decoded.users
                self.isDeveloperMode = decoded.isDeveloperMode
                self.requiredConsecutiveCount = decoded.requiredConsecutiveCount
                self.defaultOctaves = decoded.defaultOctaves
                self.amplitudeFilter = decoded.amplitudeFilter
                self.currentUserId = decoded.currentUserId
                let currentUser = self.getCurrentUser()
                ScalesModel.shared.updateUserPublished(user: currentUser)
                AppLogger.shared.log(self, "⬅️ settings load userCount:\(self.users.count) currentuser:\(currentUser.name)")
            } catch {
                AppLogger.shared.reportError(self, "load:" + error.localizedDescription)
            }
        }
    }
    
//    func debug11(_ ctx:String) {
//        print("Settings debug ============= \(ctx)")
//        for user in users {
//            print("  User", user.name, "Grade:", user.grade)
//        }
//        print()
//    }
        
    public func isDeveloperModeOn() -> Bool {
        return true
//        if users.count == 0 {
//            return false
//        }
//        for user in self.users {
//            if user.name.range(of: "dev", options: .caseInsensitive) != nil {
//                return true
//            }
//        }
//        return false
    }
}

