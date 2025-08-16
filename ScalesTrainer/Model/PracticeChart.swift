import SwiftUI
import Foundation

///Requires custom CODABLE due to the @Published member
class PracticeChartCell: ObservableObject, Codable {
    @Published var updateCount: Int = 0
    @Published var badges:[Badge] = []
    
    weak var chart: PracticeChart?
    let board:String
    let grade:Int
    var scaleIDKey:String
    var scale: Scale
    var isLicensed:Bool = false
    var color:CodableColor
    
    enum CodingKeys: String, CodingKey {
        case board
        case grade
        case scaleIDKey
        //case isStarred
        //case badges
        case isLicensed
        case color
    }
    
    init(chart:PracticeChart?, board:String, grade:Int, scaleIDKey: String, isLicensed:Bool, color1:CodableColor) {
        self.chart = chart
        self.board = board
        self.grade = grade
        self.scaleIDKey = scaleIDKey
        self.scale = MusicBoardAndGrade.getScale(boardName: board, grade: grade, scaleKey: scaleIDKey)!
        self.badges = []
        self.isLicensed = isLicensed
        self.color = color1
    }
        
    func addBadge(badge:Badge, callback:@escaping ()->Void) {
        DispatchQueue.main.async {
            self.badges.append(badge)
            callback()
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        board = try container.decode(String.self, forKey: .board)
        grade = try container.decode(Int.self, forKey: .grade)
        scaleIDKey = try container.decode(String.self, forKey: .scaleIDKey)
        //isStarred = try container.decode(Bool.self, forKey: .isStarred)
        isLicensed = try container.decode(Bool.self, forKey: .isLicensed)
        color = try container.decode(CodableColor.self, forKey: .color)
        //badges = try container.decode([Badge].self, forKey: .badges)
        
        if let scale = MusicBoardAndGrade.getScale(boardName: board, grade: grade, scaleKey: scaleIDKey) {
            self.scale = scale
        }
        else {
            fatalError("PracticeChartCell - no scale for board:\(board), grade:\(grade) scaleKey:\(scaleIDKey)")
        }
        //self.isStarredPublished = self.isStarred
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(board, forKey: .board)
        try container.encode(grade, forKey: .grade)
        try container.encode(scaleIDKey, forKey: .scaleIDKey)
        //try container.encode(isStarred, forKey: .isStarred)
        try container.encode(isLicensed, forKey: .isLicensed)
        try container.encode(color, forKey: .color)
        //try container.encode(badges, forKey: .badges)
    }
}

class PracticeChart: Codable {
    let user:User
    var board:String
    var grade:Int
    var daysWidth: Int
    var rows: [[PracticeChartCell]]
    var minorScaleType: Int
    var firstColumnDayOfWeekNumber:Int
    var todaysColumn:Int
    
    init(user:User, board:String, grade:Int, columnWidth:Int = 3, minorScaleType:Int = 0) {
        self.user = user
        self.board = board
        self.grade = grade
        self.daysWidth = 3
        self.rows = []
        self.minorScaleType = minorScaleType
        
        let currentDate = Date()
        let calendar = Calendar.current
        self.firstColumnDayOfWeekNumber = calendar.component(.weekday, from: currentDate) - 1
        self.todaysColumn = 0
        
        var scaleCtr = 0
        let scales:[Scale] = MusicBoardAndGrade.getScales(boardName: board, grade: grade)
        
        let colors:[CodableColor] = [CodableColor(Figma.blue), CodableColor(Figma.red),
                                     CodableColor(Figma.orange), CodableColor(Figma.green)]
        
        var colorIndex = 0
        
        while true {
            var rowCells:[PracticeChartCell]=[]
            if scaleCtr < scales.count {
                for _ in 0..<columnWidth {
                    if scaleCtr < scales.count {
                        rowCells.append(PracticeChartCell(chart:self, board:self.board, grade:self.grade,
                                                          scaleIDKey: scales[scaleCtr].getScaleIdentificationKey(),
                                                          isLicensed: rowCells.count == 0 || LicenceManager.shared.isLicensed(),
                                                          color1: colors[colorIndex % colors.count]))
                        scaleCtr += 1
                        colorIndex += 1
                    }
                    else {
                        break
                    }
                }
                self.rows.append(rowCells)
            }
            else {
                break
            }
        }
    }
    
    func allCells() -> [PracticeChartCell] {
        return rows.flatMap { $0 }
    }
    
    func convertToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            //let jsonString = String(data: data, encoding: .utf8)
            return data
        } catch {
            AppLogger.shared.reportError(self, "Failed to save PracticeChart \(error)")
            return nil
        }
    }
    
    func debug11(_ ctx:String) {
        for r in 0..<self.rows.count {
            let row = self.self.rows[r]
            for c in 0..<row.count {
                let cell = self.rows[r][c]
                print(r, c, "cell \(cell.scale.getScaleIdentificationKey())")
            }
        }
    }
    
    func getCellForScale(scale:Scale) -> PracticeChartCell? {
        for r in 0..<self.rows.count {
            let row = self.self.rows[r]
            for c in 0..<row.count {
                let cell = self.rows[r][c]
                if cell.scale.isSameScale(scale: scale) {
                    return cell
                }
            }
        }
        return nil
    }
    
    func getCellIDByScale(scale:Scale) -> PracticeChartCell? {
        for cells in rows {
            for row in cells {
                if row.scale.getScaleIdentificationKey() == scale.getScaleIdentificationKey() {
                    return row
                }
            }
        }
        return nil
    }
    
    ///Make the correct column hilighted if it is today
    ///If today cannot be shown on the current set of days for the chart rotate the chart to the next set of three days
    func adjustForStartDay() {
        let currentDate = Date()
        let calendar = Calendar.current
        let todaysDayNumber = calendar.component(.weekday, from: currentDate) - 1
        
        let dayDiff = todaysDayNumber - self.firstColumnDayOfWeekNumber
        if [0,1,2].contains(dayDiff) {
            ///Hilight the column for today
            self.todaysColumn = dayDiff
        }
        else {
            if [-6,-5].contains(dayDiff) {
                ///Hilight the column for today
                self.todaysColumn = 7 + dayDiff
            }
            else {
                ///Reset the chart's first column day
//                self.firstColumnDayOfWeekNumber += 3
//                if self.firstColumnDayOfWeekNumber > 6 {
//                    self.firstColumnDayOfWeekNumber -= 7
//                    for row in self.rows {
//                        for cell in row {
//                            cell.badges = []
//                        }
//                    }
//                }
                self.firstColumnDayOfWeekNumber = todaysDayNumber
                self.todaysColumn = 0
                savePracticeChartToFile()
                ///Reset the badge count
                for row in self.rows {
                    for cell in row {
                        cell.badges = []
                    }
                }
            }
        }
    }
    
    func shuffle() {
        for _ in 0..<64 {
            let rows = self.rows.count
            let cells = self.rows[0].count
            let srcRow = (Int.random(in: 0..<rows))
            let srcCol = (Int.random(in: 0..<cells))
            let tarRow = (Int.random(in: 0..<rows))
            let tarCol = (Int.random(in: 0..<cells))
            if srcCol >= self.rows[srcRow].count {
                return
            }
            if tarCol >= self.rows[tarRow].count {
                return
            }
            let cell:PracticeChartCell = self.rows[srcRow][srcCol]
            self.rows[srcRow][srcCol] = self.rows[tarRow][tarCol]
            self.rows[tarRow][tarCol] = cell
        }
        savePracticeChartToFile()
        //let secs = Double.random(in: 0..<0.75)
//        DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
//            cell.updateCount += 1
//            let secs = Double.random(in: 0..<0.75)
//            DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
//                cell.updateCount += 1
//                //cell.isStarredPublished = !cell.isStarredPublished
//            }
//        }
    }
    
    func getScales() -> [Scale] {
        var result:[Scale] = []
        for row in rows {
            for col in row {
                result.append(col.scale)
            }
        }
        return result
    }
    
    func changeScaleTypes(selectedTypes:[ScaleType], selectedMotions:[ScaleMotion], newType:ScaleType) {
        for row in rows {
            for chartCell in row {
                if selectedTypes.contains(chartCell.scale.scaleType) {
                    if selectedMotions.contains(chartCell.scale.scaleMotion) {
                        chartCell.scale = Scale(scaleRoot: chartCell.scale.scaleRoot, scaleType: newType, scaleMotion: chartCell.scale.scaleMotion,
                                                octaves: chartCell.scale.octaves, hands: chartCell.scale.hands, minTempo: chartCell.scale.minTempo,
                                                dynamicTypes: chartCell.scale.dynamicTypes, articulationTypes: chartCell.scale.articulationTypes,
                                                scaleCustomisation: chartCell.scale.scaleCustomisation)
                        chartCell.scaleIDKey = chartCell.scale.getScaleIdentificationKey()
                    }
                }
            }
        }
    }
    
    func savePracticeChartToFile() {
        do {
            //practiceChart.firstColumnDayOfWeekNumber -= 2///TEST ONLY
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                AppLogger.shared.reportError(self, "Failed to save PracticeChart")
                return
            }
            let fileName = PracticeChart.getFileName(user: self.user, board: self.board, grade: self.grade)
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
    
    static func loadPracticeChartFromFile(user:User, board:String, grade:Int) -> PracticeChart? {
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
            let chart = try decoder.decode(PracticeChart.self, from: urlData)
            for r in 0..<chart.rows.count {
                let row:[PracticeChartCell] = chart.rows[r]
                for chartCell in row {
                    chartCell.chart = chart
                    chartCell.isLicensed = false
                    if LicenceManager.shared.isLicensed() {
                        chartCell.isLicensed = true
                    }
                    else {
                        if r == 0 {
                            chartCell.isLicensed = true
                        }
                    }
                }
            }
//            AppLogger.shared.log(self, "Loaded PracticeChart from local file. Board:\(board) Grade:\(grade) FirstColumnDayOfWeek:\(chart.firstColumnDayOfWeekNumber)")
            chart.adjustForStartDay()
            return chart
        } catch {
            AppLogger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
