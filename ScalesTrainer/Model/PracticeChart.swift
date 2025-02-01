import SwiftUI
import Foundation

///Requires custom CODABLE due to the @Published member
class PracticeChartCell: ObservableObject, Codable {
    @Published var isActive: Bool = false
    @Published var badges:[Badge] = []
    
    let board:String
    let grade:Int
    var scaleIDKey:String
    var scale: Scale
    var hilighted: Bool = false
    var isLicensed:Bool = false
    
    enum CodingKeys: String, CodingKey {
        case board
        case grade
        case scaleIDKey
        case hilighted
        case badges
        case isCorrectSet
    }
    
    init(board:String, grade:Int, scaleIDKey: String, isLicensed:Bool, hilighted: Bool = false) {
        self.board = board
        self.grade = grade
        self.scaleIDKey = scaleIDKey
        self.scale = MusicBoardAndGrade.getScale(boardName: board, grade: grade, scaleKey: scaleIDKey)!
        self.hilighted = hilighted
        self.isActive = hilighted  // Set isActive based on enabled during initialization
        self.badges = []
        self.isLicensed = isLicensed
    }
        
    func addBadge(badge:Badge) {
        DispatchQueue.main.async {
            self.badges.append(badge)
            MusicBoardAndGrade.shared?.savePracticeChartToFile()
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        board = try container.decode(String.self, forKey: .board)
        grade = try container.decode(Int.self, forKey: .grade)
        scaleIDKey = try container.decode(String.self, forKey: .scaleIDKey)
        hilighted = try container.decode(Bool.self, forKey: .hilighted)
        badges = try container.decode([Badge].self, forKey: .badges)
        self.isActive = hilighted
        if let scale = MusicBoardAndGrade.getScale(boardName: board, grade: grade, scaleKey: scaleIDKey) {
            self.scale = scale
        }
        else {
            fatalError("PracticeChartCell - no scale for board:\(board), grade:\(grade) scaleKey:\(scaleIDKey)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(board, forKey: .board)
        try container.encode(grade, forKey: .grade)
        try container.encode(scaleIDKey, forKey: .scaleIDKey)
        try container.encode(hilighted, forKey: .hilighted)
        //try container.encode(isCorrectSet, forKey: .isCorrectSet)
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
    var board:String
    var grade:Int
    var columns: Int
    var rows: [[PracticeChartCell]]
    var minorScaleType: Int
    var firstColumnDayOfWeekNumber:Int
    var todaysColumn:Int
    
    init(board:String, grade:Int, columnWidth:Int, minorScaleType:Int) {
        self.board = board
        self.grade = grade
        self.columns = 3
        self.rows = []
        self.minorScaleType = minorScaleType
        
        var scaleCtr = 0
        let scales:[Scale] = MusicBoardAndGrade.getScales(boardName: board, grade: grade)
        while true {
            var rowCells:[PracticeChartCell]=[]
            if scaleCtr < scales.count {
                for _ in 0..<columnWidth {
                    if scaleCtr < scales.count {
                        rowCells.append(PracticeChartCell(board:self.board, grade:self.grade,
                                                          scaleIDKey: scales[scaleCtr].getScaleIdentificationKey(),
                                                          isLicensed: rowCells.count == 0 || LicenceManager.shared.isLicensed()))
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
    }
    
    func convertToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            //let jsonString = String(data: data, encoding: .utf8)
            return data
        } catch {
            Logger.shared.reportError(self, "Failed to save PracticeChart \(error)")
            return nil
        }
    }
    
    func debug1(_ ctx:String) {
        print("====== DEUBG Chart Debug", ctx)
        for r in 0..<self.rows.count {
            let row = self.self.rows[r]
            for c in 0..<row.count {
                let cell = self.rows[r][c]
                print(r, c, "cell \(cell.scale.getScaleIdentificationKey())")
            }
        }
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
                MusicBoardAndGrade.shared?.savePracticeChartToFile()
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

}
