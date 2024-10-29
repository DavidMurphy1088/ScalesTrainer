import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

public class SettingsPublished : ObservableObject {
    static var shared = SettingsPublished()
    @Published var firstName = ""
    @Published var board = ""
    @Published var grade = ""
    
    func setBoardAndGrade(board:String, grade:String) {
        DispatchQueue.main.async {
            self.board = board
            self.grade = grade
        }
    }
    func setFirstName(firstName:String) {
        DispatchQueue.main.async {
            self.firstName = firstName
        }
    }
}

public class Settings : Codable  {
    static var shared = Settings()
    var developerMode1 = false
    var firstName = ""
    var musicBoard:MusicBoard
    var musicBoardGrade:MusicBoardGrade
    var defaultOctaves = 2
    var scaleLeadInBeatCountIndex:Int = 2
    var amplitudeFilter:Double = 0.04 //Trial and error - callibration screen is designed to calculate this. For the meantime, hard coded
    var practiceChartGamificationOn = true
    
    ///Default colors if not set by user
    //private var keyboardColor:[Double] = [1.0, 1.0, 1.0, 1.0]
    private var keyboardColor:[Double] = [0.9999999403953552, 0.949024498462677, 0.5918447375297546, 1.0]
    private var backgroundColor:[Double] = [0.8219926357269287, 0.8913233876228333, 1.0000004768371582, 1.0]
    
    var backingSamplerPreset:Int = 0 //2 //default is Moog, 0=Piano
    var requiredConsecutiveCount = 2
    var badgeStyle = 0
    
    private var wasLoaded = false
    
    init() {
        self.musicBoard = MusicBoard(name: "")
        self.musicBoardGrade = MusicBoardGrade(index: 0, grade: "")
        load()
    }
    
    public func isDeveloperMode() -> Bool {
        return self.firstName.range(of: "dev", options: .caseInsensitive) != nil
    }
    
    public func settingsExists() -> Bool {
       return wasLoaded
    }
    
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
    
    public func calibrationIsSet() -> Bool {
       return amplitudeFilter > 0
    }

    private func toJSON() -> String? {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            Logger.shared.reportError(self, "save:" + error.localizedDescription)
        }
        return nil
    }
    
    func toString() -> String {
        var str = "Settings amplitudeFilter:\(String(format: "%.4f", self.amplitudeFilter)) "
       
        str += " LeadIn:\(self.scaleLeadInBeatCountIndex)"
        str += " FirstName:\(self.firstName)"
        str += " Board:\(self.musicBoard)"
        str += " Grade:\(self.musicBoardGrade.grade)"
        str += " GradeIndex:\(self.musicBoardGrade.gradeIndex)"
        str += " Octaves:\(self.defaultOctaves)"
        str += " KeyboardColor:\(self.keyboardColor)"
        str += " BackingMidi:\(self.backingSamplerPreset)"
        str += " RequiredConsecutiveCount:\(self.requiredConsecutiveCount)"
        str += " BadgeStyle:\(self.badgeStyle)"
        str += " BackgroundColour:\(self.backgroundColor)"
        str += " Gamification:\(self.practiceChartGamificationOn)"
        return str
    }
    
    func save() {
        guard let str = toJSON() else {
            return
        }
        Logger.shared.log(self, "Setting saved, \(toString())")
        UserDefaults.standard.set(str, forKey: "settings")
        self.wasLoaded = true
    }
    
    func getName() -> String {
        let name = firstName
        let name1 = name + (name.count>0 ? "'s" : "")
        return name1
    }
    
//    func getSettingsNoteValueFactor() -> Double {
//        return self.scaleNoteValue == 4 ? 1.0 : 0.5
//    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.amplitudeFilter = loaded.amplitudeFilter
                    self.firstName = loaded.firstName
                    self.musicBoard = loaded.musicBoard
                    self.musicBoardGrade = loaded.musicBoardGrade
                    self.scaleLeadInBeatCountIndex = loaded.scaleLeadInBeatCountIndex
                    self.defaultOctaves = loaded.defaultOctaves
                    self.keyboardColor = loaded.keyboardColor
                    self.backingSamplerPreset = loaded.backingSamplerPreset
                    self.requiredConsecutiveCount = loaded.requiredConsecutiveCount
                    self.badgeStyle = loaded.badgeStyle
                    self.backgroundColor = loaded.backgroundColor
                    self.practiceChartGamificationOn  = loaded.practiceChartGamificationOn

                    SettingsPublished.shared.setBoardAndGrade(board: self.musicBoard.name, grade: self.musicBoardGrade.grade)
                    SettingsPublished.shared.setFirstName(firstName: self.firstName)
                    Logger.shared.log(self, "Settings loaded, \(toString())")
                    self.wasLoaded = true
                } catch {
                    Logger.shared.reportError(self, "Settings found but not loaded, data format has changed:" + error.localizedDescription)
                }
            }
        }
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
    
    func getKeyboardColor1() -> Color {
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

    func getBackgroundColor() -> Color {
        let red = CGFloat(self.backgroundColor[0])
        let green = CGFloat(self.backgroundColor[1])
        let blue = CGFloat(self.backgroundColor[2])
        let alpha = CGFloat(self.backgroundColor[3])
        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return Color(uiColor)
    }
    
    func isCustomColor() -> Bool {
        return keyboardColor.contains{ $0 != 1.0 }
    }
}
