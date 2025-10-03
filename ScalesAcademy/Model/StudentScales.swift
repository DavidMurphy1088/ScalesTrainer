import SwiftUI
import Foundation

class StudentScale: ObservableObject, Codable, Identifiable, Hashable {
    static func == (lhs: StudentScale, rhs: StudentScale) -> Bool {
        lhs.id == rhs.id
    }
    
    //@Published
    var visible:Bool = true
    
    let id: UUID
    let scaleId: String
    var practiceDay: Int
    var scale: Scale?
    var badgeCount:Int
    var freeContent:Bool
    
    init(scale:Scale, scaleId: String, visible:Bool, day:Int, freeContent:Bool) {
        self.id = UUID()
        self.scale = scale
        self.scaleId = scaleId
        self.practiceDay = day
        self.badgeCount = 0
        self.freeContent = freeContent
    }
    
    func setVisible(way:Bool) {
        //DispatchQueue.main.async {
            self.visible = way
        //}
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case scaleId
        case practiceDay
        case badgeCount
        case freeContent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        scaleId = try container.decode(String.self, forKey: .scaleId)
        practiceDay = try container.decode(Int.self, forKey: .practiceDay)
        badgeCount = try container.decode(Int.self, forKey: .badgeCount)
        freeContent = try container.decode(Bool.self, forKey: .freeContent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(scaleId, forKey: .scaleId)
        try container.encode(practiceDay, forKey: .practiceDay)
        try container.encode(badgeCount, forKey: .badgeCount)
        try container.encode(freeContent, forKey: .freeContent)
    }
}

class StudentScales: Codable {
    let user:User
    var scalesPerDay: Int
    var studentScales:[StudentScale]
    var createdDayOfWeek:Int
    
    init(user:User) {
        self.user = user
        self.scalesPerDay = 3

        let scales:[Scale] = MusicBoardAndGrade.getScales(boardName: user.boardAndGrade.board.name,
                                                          grade: user.boardAndGrade.grade)
        self.studentScales = []
        self.createdDayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1 //zero base
        
        var count = 0
        for scale in scales {
            self.studentScales.append(StudentScale(scale: scale, scaleId: scale.getScaleIdentificationKey(),
                                                   visible: true, day: 0, freeContent: count < 400))
            count += 1
        }
        //debug("Init")
    }
    
    func arePracticeDaysSet() -> Bool {
        for studentScale in self.studentScales {
            if studentScale.practiceDay > 0 {
                return true
            }
        }
        return false
    }
    
    func setPracticeDaysForScales(studentScales:[StudentScale], minorType:ScaleType) {
        var dayCount = 0
        for studentScale in studentScales {
            guard let scale = studentScale.scale else {
                continue
            }
            if [.harmonicMinor, .melodicMinor, .naturalMinor].contains(scale.scaleType) {
                if scale.scaleType != minorType {
                    continue
                }
            }
            let dayOffset = dayCount % scalesPerDay
            studentScale.practiceDay = dayOffset
            dayCount += 1
        }
        saveToFile()
    }
    
    func shuffle() {
        guard let minorType = user.selectedMinorType else {
            return
        }
        setPracticeDaysForScales(studentScales: studentScales.shuffled(), minorType: minorType)
    }
    
    func convertToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            AppLogger.shared.reportError(self, "Failed to save PracticeChart \(error)")
            return nil
        }
    }
    
    func processAllScales(procFunction: (_:StudentScale) -> Void) {
        for scale in studentScales {
            procFunction(scale)
        }
    }
    
    func debug11(_ ctx:String) {
        print("======== StudentScales", ctx)
        for r in 0..<self.studentScales.count {
            let x = self.studentScales[r]
            let name = x.scaleId + String(repeating: " ", count: 60 - x.scaleId.count)
            print("  \(name)", "\tvis:\(x.visible) \tday:\(x.practiceDay)")
        }
    }
    
    func getScaleIds() -> [String] {
        var result:[String] = []
        for cs in self.studentScales {
            result.append(cs.scaleId)
        }
        return result
    }

    func saveToFile() {
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                AppLogger.shared.reportError(self, "Failed to save PracticeChart")
                return
            }
            let fileName = StudentScales.getFileName(user: self.user)
            let url = dir.appendingPathComponent(fileName)
            if let data = self.convertToJSON() {
                try data.write(to: url)  // Write the data to the file
                //AppLogger.shared.log(self, "✅ Saved StudenScales. Board:\(self.board) Grade:\(self.grade) toFile: \(fileName) size:\(data.count)")
            }
            else {
                AppLogger.shared.reportError(self, "Cannot convert PracticeChart")
            }
        } catch {
            AppLogger.shared.reportError(self, "Failed to save PracticeChart \(error)")
        }
    }
    
    //static func getFileName(user:User, board:String, grade:Int) -> String {
    static func getFileName(user:User) -> String {
        return "SA_" + user.name + "_" + user.boardAndGrade.board.name + "_" + String(user.boardAndGrade.grade)
    }
    
    func getScaleTypes() -> [ScaleType] {
        var allTypesSet: Set<ScaleType> = []
        for studentScale in studentScales {
            if let scale = studentScale.scale {
                allTypesSet.insert(scale.scaleType)
            }
        }
        
        ///Make sure the list is in the order specified here
        var scaleTypes:[ScaleType] = []
        //for scaleTypeOrder in [ScaleType.harmonicMinor, ScaleType.naturalMinor, .melodicMinor] {
            for studentScale in studentScales {
                if let scale = studentScale.scale {
                    //if scale.scaleType == scaleTypeOrder {
                        if allTypesSet.contains(scale.scaleType) {
                            scaleTypes.append(scale.scaleType)
                            allTypesSet.remove(scale.scaleType)
                        }
                    //}
                }
            }
        //}
        return scaleTypes
    }
    
    func getScaleMotions() -> [ScaleMotion] {
        var allMotionsSet: Set<ScaleMotion> = []
        for studentScale in studentScales {
            if let scale = studentScale.scale {
                allMotionsSet.insert(scale.scaleMotion)
            }
        }
        
        ///Make sure the list is in the order specified here
        var scaleMotions:[ScaleMotion] = []
        for studentScale in studentScales {
            if let scale = studentScale.scale {
                //if scale.scaleType == scaleTypeOrder {
                if allMotionsSet.contains(scale.scaleMotion) {
                    scaleMotions.append(scale.scaleMotion)
                    allMotionsSet.remove(scale.scaleMotion)
                }
            }
        }
        return scaleMotions
    }
    
    func getScaleKeys() -> [String] {
        ///Make sure the list is in the order in which the type is first seen in the syllabus
        var allKeysSet: Set<String> = []
        for studentScale in studentScales {
            if let scale = studentScale.scale {
                allKeysSet.insert(scale.scaleRoot.name)
            }
        }
        
        var uniqueKeys:[String] = []
        for studentScale in studentScales {
            if let scale = studentScale.scale {
                let name = scale.scaleRoot.name
                if allKeysSet.contains(name) {
                    uniqueKeys.append(name)
                    allKeysSet.remove(name)
                }
            }
        }
        
//        var scored:[(Int, String)] = []
//        ///Order the keys by thier Keysignature complexity
//        for key in uniqueKeys {
//            let words = key.components(separatedBy: " ")
//            let keySig = KeySignature(keyName: words[0], keyType: words[1] == "Major" ? .major : .minor)
//            var score = keySig.accidentalType == .flat ? keySig.accidentalCount * 10 : keySig.accidentalCount * 10
//            scored.append((score, key))
//        }
//        let sorted = scored.sorted { $0.0 < $1.0 }
        let sorted = uniqueKeys.sorted{$0 < $1}
        var scaleKeys:[String] = []
        for score in sorted {
            scaleKeys.append(score)
        }
        return scaleKeys
    }

    static func loadFromFile(user:User) -> StudentScales? {
        let decoder = JSONDecoder()
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                if let notRegression = ProcessInfo.processInfo.environment["NOT_RUNNING_REGRESSION"] {
                    AppLogger.shared.reportError(self, "Failed to load PracticeChart - file not found")
                }
                return nil
            }
            let url = dir.appendingPathComponent(getFileName(user: user))
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: url.path) {
                return nil
            }
            let urlData = try Data(contentsOf: url)  // Read the data from the file
            let chart = try decoder.decode(StudentScales.self, from: urlData)

//            AppLogger.shared.log(self, "Loaded PracticeChart from local file. Board:\(board) Grade:\(grade) FirstColumnDayOfWeek:\(chart.firstColumnDayOfWeekNumber)")s
            
            ///Only the scale Id is serialized on save so get the scale itself
            for studentScale in chart.studentScales {
                let user = Settings.shared.getCurrentUser("Student Scales load from File")
                let boardGrade = user.boardAndGrade // MusicBoardAndGrade(board: board, grade: user.grade)
                for scale in boardGrade.enumerateAllScales() {
                    if scale.getScaleIdentificationKey() == studentScale.scaleId {
                        studentScale.scale = scale
                    }
                }
            }
            return chart
        } catch {
            AppLogger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
