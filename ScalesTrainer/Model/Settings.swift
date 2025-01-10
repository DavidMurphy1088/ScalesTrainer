import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

public class SettingsPublished : ObservableObject {
    static var shared = SettingsPublished()
    @Published var boardAndGrade:MusicBoardAndGrade?
    @Published var grade:Int?
    @Published var firstName = ""
    
    func setBoardAndGrade(boardAndGrade:MusicBoardAndGrade) {
        DispatchQueue.main.async {
            self.boardAndGrade = boardAndGrade
            self.grade = boardAndGrade.grade
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
    var firstName = ""
    var emailAddress = ""
    var musicBoardName:String? = nil
    var musicBoardGrade:Int?
    var defaultOctaves = 2
    var scaleLeadInBeatCountIndex:Int = 2
    var amplitudeFilter:Double
    var practiceChartGamificationOn = true
    var useMidiConnnections = false
    var customTrinity = true
    
    ///Default colors if not set by user
    //private var keyboardColor:[Double] = [1.0, 1.0, 1.0, 1.0]
    private var keyboardColor:[Double] = [0.9999999403953552, 0.949024498462677, 0.5918447375297546, 1.0]
    private var backgroundColor:[Double] = [0.8219926357269287, 0.8913233876228333, 1.0000004768371582, 1.0]
    
    var backingSamplerPreset:Int = 0 //2 //default is Moog, 0=Piano
    var requiredConsecutiveCount = 2
    var badgeStyle = 0
    
    init() {
#if targetEnvironment(simulator)
        self.amplitudeFilter = 0.04
#else
        self.amplitudeFilter = 0.04
#endif
        if loadFromFile() {
            if let name = self.musicBoardName {
                if let grade = self.musicBoardGrade {
                    MusicBoardAndGrade.shared = MusicBoardAndGrade(board: MusicBoard(name: name), grade: grade)
                }
            }
        }
        if self.useMidiConnnections {
            MIDIManager.shared.setupMIDI()
        }
    }
    
    public func isDeveloperMode() -> Bool {
        return self.firstName.range(of: "dev", options: .caseInsensitive) != nil
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
    
//    func getBoardAndGrade() -> MusicBoardAndGrade? {
//        if let boardName = self.musicBoardName {
//            let board = MusicBoard(name: boardName)
//            if let grade = self.musicBoardGrade {
//                let boardAndGrade = MusicBoardAndGrade(board: board, grade: grade)
//                return boardAndGrade
//            }
//        }
//        return nil
//    }
    
    func toString() -> String {
        var str = "Settings amplitudeFilter:\(String(format: "%.4f", self.amplitudeFilter)) "
        str += " LeadIn:\(self.scaleLeadInBeatCountIndex)"
        str += " FirstName:\(self.firstName)"
        str += " Board/Grade:\(self.musicBoardName)/\(self.musicBoardGrade)"
        str += " Octaves:\(self.defaultOctaves)"
        str += " KeyboardColor:\(self.keyboardColor)"
        str += " BackingMidi:\(self.backingSamplerPreset)"
        str += " RequiredConsecutiveCount:\(self.requiredConsecutiveCount)"
        str += " BadgeStyle:\(self.badgeStyle)"
        //str += " BackgroundColour:\(self.backgroundColor)"
        str += " email:\(self.emailAddress)"
        str += " Gamification:\(self.practiceChartGamificationOn)"
        str += " useMIDI:\(self.useMidiConnnections)"
        return str
    }
    
    func save() {
        guard let str = toJSON() else {
            return
        }
        UserDefaults.standard.set(str, forKey: "settings")
        Logger.shared.log(self, "Setting saved, \(toString())")
    }
    
    func getName() -> String {
        let name = firstName
        let name1 = name + (name.count>0 ? "'s" : "")
        return name1
    }
    
    func loadFromFile() -> Bool {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.amplitudeFilter = loaded.amplitudeFilter
                    self.firstName = loaded.firstName
                    self.emailAddress = loaded.emailAddress
                    self.scaleLeadInBeatCountIndex = loaded.scaleLeadInBeatCountIndex
                    self.defaultOctaves = loaded.defaultOctaves
                    self.keyboardColor = loaded.keyboardColor
                    self.backingSamplerPreset = loaded.backingSamplerPreset
                    self.requiredConsecutiveCount = loaded.requiredConsecutiveCount
                    self.badgeStyle = loaded.badgeStyle
                    self.backgroundColor = loaded.backgroundColor
                    self.practiceChartGamificationOn  = loaded.practiceChartGamificationOn
                    self.useMidiConnnections = loaded.useMidiConnnections
                    self.musicBoardName = loaded.musicBoardName
                    self.musicBoardGrade = loaded.musicBoardGrade
                    SettingsPublished.shared.setFirstName(firstName: self.firstName)
                    if let board = self.musicBoardName, let grade = self.musicBoardGrade {
                        SettingsPublished.shared.setBoardAndGrade(boardAndGrade: MusicBoardAndGrade(board: MusicBoard(name: board), grade: grade))
                    }
                    Logger.shared.log(self, "Settings loaded, \(toString())")
                    return true
                } catch {
                    Logger.shared.reportError(self, "Settings found but not loaded, data format has changed:" + error.localizedDescription)
                }
            }
        }
        else {
            Logger.shared.log(self, "No settings file")
        }
        return false
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
