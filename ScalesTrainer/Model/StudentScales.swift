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
    
    init(scaleId: String, visible:Bool, day:Int) {
        self.id = UUID()
        self.scaleId = scaleId
        self.practiceDay = day
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
        //case visible
        case practiceDay
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        scaleId = try container.decode(String.self, forKey: .scaleId)
        practiceDay = try container.decode(Int.self, forKey: .practiceDay)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(scaleId, forKey: .scaleId)
        try container.encode(practiceDay, forKey: .practiceDay)
    }
}

class StudentScales: Codable {
    let user:User
    var board:String
    var grade:Int
    var scalesPerDay: Int
    var studentScales:[StudentScale]
    var minorScaleType: Int
    var createdDayOfWeek:Int
    
    init(user:User, board:String, grade:Int, minorScaleType:Int = 0) {
        self.user = user
        self.board = board
        self.grade = grade
        self.scalesPerDay = 3
        self.minorScaleType = minorScaleType
        
        //let currentDate = Date()
        //let calendar = Calendar.current
        
        var scaleCtr = 0
        let colors:[CodableColor] = [CodableColor(Figma.blue), CodableColor(Figma.red),
                                     CodableColor(Figma.orange), CodableColor(Figma.green)]
        var colorIndex = 0
        let scales:[Scale] = MusicBoardAndGrade.getScales(boardName: board, grade: grade)
        self.studentScales = []
        var dayCount = 0
        self.createdDayOfWeek = Calendar.current.component(.weekday, from: Date()) - 1 //zero base
        for scale in scales {
            let dayOffset = (dayCount / scalesPerDay) % scalesPerDay
            self.studentScales.append(StudentScale(scaleId: scale.getScaleIdentificationKey(),
                                                   visible: true, day: dayOffset))
            dayCount += 1
        }
        debug("Init")
    }
    
    //    func allCells() -> [PracticeChartCell] {
    //        return rows.flatMap { $0 }
    //    }
    
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
    
    func debug(_ ctx:String) {
        print("======== StudentScales", ctx)
        for r in 0..<self.studentScales.count {
            let x = self.studentScales[r]
            let name = x.scaleId + String(repeating: " ", count: 40 - x.scaleId.count)
            print("  \(name)", "\tvis:\(x.visible) \tday:\(x.practiceDay)")
        }
    }
    
    //    func getCellForScale(scale:Scale) -> PracticeChartCell? {
    //        for r in 0..<self.rows.count {
    //            let row = self.self.rows[r]
    //            for c in 0..<row.count {
    //                let cell = self.rows[r][c]
    //                if cell.scale.isSameScale(scale: scale) {
    //                    return cell
    //                }
    //            }
    //        }
    //        return nil
    //    }
    
    //    func getCellIDByScale(scale:Scale) -> PracticeChartCell? {
    //        for cells in rows {
    //            for row in cells {
    //                if row.scale.getScaleIdentificationKey() == scale.getScaleIdentificationKey() {
    //                    return row
    //                }
    //            }
    //        }
    //        return nil
    //    }
    
    func shuffle() {
        var indexes = Array(studentScales.indices)
        indexes.shuffle()
        var dayNumber = 0
        for i in indexes  {
            studentScales[i].practiceDay = dayNumber
            if dayNumber >= scalesPerDay - 1 {
                dayNumber = 0
            }
            else {
                dayNumber += 1
            }
        }
    }
    
//    func getScales() -> [Scale] {
//        var result:[Scale] = []
//        for cs in self.chartScales {
//            result.append(cs.scale)
//        }
//        return result
//    }
    
    func getScaleIds() -> [String] {
        var result:[String] = []
        for cs in self.studentScales {
            result.append(cs.scaleId)
        }
        return result
    }

//    func changeScaleTypes(selectedTypes:[ScaleType], selectedMotions:[ScaleMotion], newType:ScaleType) {
//        for row in rows {
//            for chartCell in row {
//                if selectedTypes.contains(chartCell.scale.scaleType) {
//                    if selectedMotions.contains(chartCell.scale.scaleMotion) {
//                        chartCell.scale = Scale(scaleRoot: chartCell.scale.scaleRoot, scaleType: newType, scaleMotion: chartCell.scale.scaleMotion,
//                                                octaves: chartCell.scale.octaves, hands: chartCell.scale.hands, minTempo: chartCell.scale.minTempo,
//                                                dynamicTypes: chartCell.scale.dynamicTypes, articulationTypes: chartCell.scale.articulationTypes,
//                                                scaleCustomisation: chartCell.scale.scaleCustomisation)
//                        chartCell.scaleIDKey = chartCell.scale.getScaleIdentificationKey()
//                    }
//                }
//            }
//        }
//    }
    
    func saveToFile() {
        do {
            //practiceChart.firstColumnDayOfWeekNumber -= 2///TEST ONLY
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                AppLogger.shared.reportError(self, "Failed to save PracticeChart")
                return
            }
            let fileName = StudentScales.getFileName(user: self.user, board: self.board, grade: self.grade)
            let url = dir.appendingPathComponent(fileName)
            if let data = self.convertToJSON() {
                try data.write(to: url)  // Write the data to the file
                //AppLogger.shared.log(self, "✅ Saved PracticeChart. Board:\(self.board) Grade:\(self.grade) toFile: \(fileName) size:\(data.count)")
            }
            else {
                AppLogger.shared.reportError(self, "Cannot convert PracticeChart")
            }
        } catch {
            AppLogger.shared.reportError(self, "Failed to save PracticeChart \(error)")
        }
    }
    
    static func getFileName(user:User, board:String, grade:Int) -> String {
        return "_" + user.name + "_" + board + "_" + String(grade)
    }
    
    static func loadFromFile(user:User, board:String, grade:Int) -> StudentScales? {
        let decoder = JSONDecoder()
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                if let notRegression = ProcessInfo.processInfo.environment["NOT_RUNNING_REGRESSION"] {
                    AppLogger.shared.log(self, "Failed to load PracticeChart - file not found")
                }
                return nil
            }
            let url = dir.appendingPathComponent(getFileName(user: user, board: board, grade: grade))
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: url.path) {
                return nil
            }
            let urlData = try Data(contentsOf: url)  // Read the data from the file
            let chart = try decoder.decode(StudentScales.self, from: urlData)
//            for r in 0..<chart.rows.count {
//                let row:[PracticeChartCell] = chart.rows[r]
//                for chartCell in row {
//                    chartCell.chart = chart
//                    chartCell.isLicensed = false
//                    if LicenceManager.shared.isLicensed() {
//                        chartCell.isLicensed = true
//                    }
//                    else {
//                        if r == 0 {
//                            chartCell.isLicensed = true
//                        }
//                    }
//                }
//            }
//            AppLogger.shared.log(self, "Loaded PracticeChart from local file. Board:\(board) Grade:\(grade) FirstColumnDayOfWeek:\(chart.firstColumnDayOfWeekNumber)")
            //chart.adjustForStartDay()
            return chart
        } catch {
            AppLogger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
