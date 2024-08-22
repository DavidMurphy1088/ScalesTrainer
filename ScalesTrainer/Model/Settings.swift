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
    var recordDataMode = false
    var firstName = ""
    var board = ""
    var grade = ""
    var defaultOctaves = 2
    var scaleLeadInBarCount:Int = 0
    var amplitudeFilter:Double = 0.04 //Trial and error - callibration screen is designed to calculate this. For the meantime, hard coded
    var scaleNoteValue = 4 // What note values the score is written with  1/4, 1/8 or 1/16
    private var keyColor:[Double] = [1.0, 1.0, 1.0, 1.0]
    var backingSamplerPreset:Int = 0
    
    private var wasLoaded = false
    
    init() {
        load()
    }
    
    public func settingsExists() -> Bool {
       return wasLoaded
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
        str += " LeadIn:\(self.scaleLeadInBarCount)"
        str += " RecordDataMode:\(self.recordDataMode)"
        str += " FirstName:\(self.firstName)"
        str += " Board:\(self.board)"
        str += " Grade:\(self.grade)"
        str += " Octaves:\(self.defaultOctaves)"
        str += " ScaleNoteValue:\(self.scaleNoteValue)"
        str += " KeyColor:\(self.keyColor)"
        str += " BackingMidi:\(self.backingSamplerPreset)"
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
    
    func getMusicBoardAndGrade() -> MusicBoardGrade? {
        if let board = MusicBoard.options.first(where: { $0.name == self.board}) {
            let board = MusicBoard(name: board.name, fullName: board.fullName, imageName: board.imageName)
            return MusicBoardGrade(board: board)
        }
        return nil
    }

    func getName() -> String {
        let name = firstName
        let name1 = name + (name.count>0 ? "'s" : "")
        return name1
    }
    
    func getSettingsNoteValueFactor() -> Double {
        return self.scaleNoteValue == 4 ? 1.0 : 0.5
    }
    
    func load() {
        if let jsonData = UserDefaults.standard.string(forKey: "settings") {
            if let data = jsonData.data(using: .utf8) {
                do {
                    let jsonDecoder = JSONDecoder()
                    let decoded = try jsonDecoder.decode(Settings.self, from: data)
                    let loaded = decoded
                    self.recordDataMode = loaded.recordDataMode
                    self.amplitudeFilter = loaded.amplitudeFilter
                    self.firstName = loaded.firstName
                    self.board = loaded.board
                    self.grade = loaded.grade
                    self.scaleLeadInBarCount = loaded.scaleLeadInBarCount
                    self.defaultOctaves = loaded.defaultOctaves
                    self.scaleNoteValue = loaded.scaleNoteValue
                    self.keyColor = loaded.keyColor
                    self.backingSamplerPreset = loaded.backingSamplerPreset
                    SettingsPublished.shared.setBoardAndGrade(board: self.board, grade: self.grade)
                    SettingsPublished.shared.setFirstName(firstName: self.firstName)
                    Logger.shared.log(self, "Settings loaded, \(toString())")
                    self.wasLoaded = true
                } catch {
                    Logger.shared.reportError(self, "Settings found but not loaded, data format has changed:" + error.localizedDescription)
                }
            }
        }
    }
    
    func setKeyColor(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.keyColor = [Double(red), Double(green), Double(blue), Double(alpha)]
    }
    
    func getKeyColor() -> Color {
//        guard array.count == 4 else {
//            return Color.black
//        }
        let red = CGFloat(self.keyColor[0])
        let green = CGFloat(self.keyColor[1])
        let blue = CGFloat(self.keyColor[2])
        let alpha = CGFloat(self.keyColor[3])
        let uiColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return Color(uiColor)
    }
}
