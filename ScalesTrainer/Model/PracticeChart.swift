import SwiftUI
import Foundation

///Requires custom CODABLE due to the @Published member
class PracticeChartCell: ObservableObject, Codable {
    @Published var isActive: Bool = false
    @Published var badges:[Badge] = []

    var scale: Scale
    var hilighted: Bool = false
    var isLicensed:Bool = false

    enum CodingKeys: String, CodingKey {
        case scale
        case hilighted
        case badges
    }
    
    init(scale: Scale, isLicensed:Bool, hilighted: Bool = false) { 
        self.scale = scale
        self.hilighted = hilighted
        self.isActive = hilighted  // Set isActive based on enabled during initialization
        self.badges = []
        self.isLicensed = isLicensed
    }
    
//    func setBadgesCount(count:Int) {
//        DispatchQueue.main.async {
//            //self.badgeCount += delta
//            //self.badgeCount = count
//            PracticeChart.shared.saveToFile()
//        }
//    }
    
    func addBadge(badge:Badge) {
        DispatchQueue.main.async {
            self.badges.append(badge)
            MusicBoardAndGrade.shared?.savePracticeChartToFile()
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scale = try container.decode(Scale.self, forKey: .scale)
        hilighted = try container.decode(Bool.self, forKey: .hilighted)
        badges = try container.decode([Badge].self, forKey: .badges)
        self.isActive = hilighted
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale, forKey: .scale)
        try container.encode(hilighted, forKey: .hilighted)
        try container.encode(badges, forKey: .badges)
    }
    
    func setHilighted(way: Bool) {
        self.hilighted = way
        DispatchQueue.main.async {
            self.isActive = way
        }
    }
}

class PracticeChart: Codable {
    var columns: Int
    var rows: [[PracticeChartCell]]
    var minorScaleType: Int
    var firstColumnDayOfWeekNumber:Int
    var todaysColumn:Int
    
    init(scales:[Scale], columnWidth:Int, minorScaleType:Int) {
        //self.boardAndGrade = boardAndGrade
        self.columns = 3
        self.rows = []
        let scales:[Scale] = scales // = self.boardAndGrade.getScales()
        self.minorScaleType = minorScaleType
        
        var scaleCtr = 0
        while true {
            var rowCells:[PracticeChartCell]=[]
            if scaleCtr < scales.count {
                for c in 0..<columnWidth {
                    if scaleCtr < scales.count {
                        rowCells.append(PracticeChartCell(scale: scales[scaleCtr], isLicensed: rowCells.count == 0 || LicenceManager.shared.isLicensed()))
                        scaleCtr += 1
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
        
        let currentDate = Date()
        let calendar = Calendar.current
        self.firstColumnDayOfWeekNumber = calendar.component(.weekday, from: currentDate) - 1
        self.todaysColumn = 0
        //debug1("Init")
    }
    
    func convertToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(self)
            let jsonString = String(data: data, encoding: .utf8)
            return data
        } catch {
            Logger.shared.reportError(self, "Failed to save PracticeChart \(error)")
            return nil
        }
    }
    
    func debug11(_ ctx:String) {
        print("====== DEUBG Chart Debug", ctx)
        for r in 0..<self.rows.count {
            let row = self.self.rows[r]
            for c in 0..<row.count {
                let cell = self.rows[r][c]
                print(r, c, "cell \(cell.scale.getScaleName(handFull: false))")
            }
        }
    }
    
//    func reset() {
//        for row in rows {
//            for cell in row {
//                cell.badges = []
//                self.saveToFile()
//            }
//        }
//    }
    
    func getCellIDByScale(scale:Scale) -> PracticeChartCell? {
        for cells in rows {
            for row in cells {
                if row.scale.getScaleName(handFull: false) == scale.getScaleName(handFull: false) {
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
        
        while true {
            let dayDiff = todaysDayNumber - self.firstColumnDayOfWeekNumber
            if [0,1,2].contains(dayDiff) {
                ///Hilight the column for today
                self.todaysColumn = dayDiff
                break
            }
            if [-6,-5].contains(dayDiff) {
                ///Hilight the column for today
                self.todaysColumn = 7 + dayDiff
                break
            }

            ///Reset the chart's first column day
            self.firstColumnDayOfWeekNumber += 3
//            if self.firstColumnDayOfWeekNumber > 6 {
//                self.firstColumnDayOfWeekNumber -= 7
//                for row in self.rows {
//                    for cell in row {
//                        cell.badgeCount = 0
//                    }
//                }
//            }
        }
    }
    
    func shuffle() {
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
        let secs = Double.random(in: 0..<0.75)
        DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
            cell.isActive = !cell.isActive
            let secs = Double.random(in: 0..<0.75)
            DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
                cell.isActive = !cell.isActive
            }
        }
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
    
    func changeScaleTypes(oldTypes:[ScaleType], newType:ScaleType) {
        for row in rows {
            for chartCell in row {
                //if chartCell.scale.scaleRoot.name == scale.scaleRoot.name {
                    if oldTypes.contains(chartCell.scale.scaleType) {
                        chartCell.scale = Scale(scaleRoot: chartCell.scale.scaleRoot, scaleType: newType, scaleMotion: chartCell.scale.scaleMotion,
                                                octaves: chartCell.scale.octaves, hands: chartCell.scale.hands, minTempo: chartCell.scale.minTempo,
                                                dynamicType: chartCell.scale.dynamicType, articulationType: chartCell.scale.articulationType)
                    }
                //}
            }
        }
    }

}

//extension PracticeChart {
//    static func getFileName(board:String, grade:Int) -> String {
//        return "_"+board+"_"+String(grade)
//    }
//    
//    static func loadPracticeChartFromFile(board:String, grade:Int) -> PracticeChart? {
//        let decoder = JSONDecoder()
//        do {
//            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//                Logger.shared.reportError(self, "Failed to load PracticeChart - file not found")
//                return nil
//            }
//            
//            let url = dir.appendingPathComponent(PracticeChart.getFileName(board: board, grade: grade))
//            let data = try Data(contentsOf: url)  // Read the data from the file
//            let chart = try decoder.decode(PracticeChart.self, from: data)
//            for r in 0..<chart.rows.count {
//                let row:[PracticeChartCell] = chart.rows[r]
//                for chartCell in row {
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
//            Logger.shared.log(self, "Loaded PracticeChart from local file. dayOfWeek:\(chart.firstColumnDayOfWeekNumber)")
//            return chart
//         } catch {
//            Logger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
//            return nil
//        }
//    }
//}
