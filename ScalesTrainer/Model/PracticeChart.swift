import SwiftUI
import Foundation

///Requires custom CODABLE due to the @Published member
class PracticeChartCell: ObservableObject, Codable {
    var scale: Scale
    var row: Int
    var enabled: Bool = false
    
    @Published var isActive: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case scale
        case row
        case enabled
    }
    
    init(scale: Scale, row: Int, enabled: Bool = false) {
        self.scale = scale
        self.row = row
        self.enabled = enabled
        self.isActive = enabled  // Set isActive based on enabled during initialization
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scale = try container.decode(Scale.self, forKey: .scale)
        row = try container.decode(Int.self, forKey: .row)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        self.isActive = enabled
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale, forKey: .scale)
        try container.encode(row, forKey: .row)
        try container.encode(enabled, forKey: .enabled)
    }
    
    func setEnabled(way: Bool) {
        self.enabled = way
        DispatchQueue.main.async {
            self.isActive = way
        }
    }
}

class PracticeChart: Codable {
    static var shared:PracticeChart = PracticeChart(musicBoard: MusicBoard(name: ""), musicBoardGrade:MusicBoardGrade(grade: "0"), minorScaleType: 0)
    static let fileName = "practice_chart.json"
    var musicBoard:MusicBoard
    var musicBoardGrade:MusicBoardGrade
    var rows: Int
    var columns: Int
    var cells: [[PracticeChartCell]]
    var minorScaleType: Int
    
    init(musicBoard:MusicBoard, musicBoardGrade:MusicBoardGrade, minorScaleType:Int) {
        self.musicBoard = musicBoard
        self.musicBoardGrade = musicBoardGrade
        self.columns = 3
        self.rows = Settings.shared.isDeveloperMode() ? 7 : 6
        self.cells = []
        let scales = musicBoardGrade.getScales()
        var scaleCtr = 0
        self.minorScaleType = minorScaleType
        
        for _ in 0..<rows {
            var rowCells:[PracticeChartCell]=[]
            for _ in 0..<columns {
                //chartRow.append(scales[scaleCtr])
                rowCells.append(PracticeChartCell(scale: scales[scaleCtr], row: 0))
                scaleCtr += 1
                if scaleCtr >= scales.count {
                    scaleCtr = 0
                }
            }
            cells.append(rowCells)
        }
    }
    
    func shuffle() {
        let rows = self.cells.count
        let cells = self.cells[0].count
        let srcRow = (Int.random(in: 0..<rows))
        let srcCol = (Int.random(in: 0..<cells))
        let tarRow = (Int.random(in: 0..<rows))
        let tarCol = (Int.random(in: 0..<cells))
        let cell:PracticeChartCell = self.cells[srcRow][srcCol]
        self.cells[srcRow][srcCol] = self.cells[tarRow][tarCol]
        self.cells[tarRow][tarCol] = cell
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
        for row in cells {
            for col in row {
                result.append(col.scale)
            }
        }
        return result
    }
    
    func changeScaleTypes(oldTypes:[ScaleType], newType:ScaleType) {
        for row in cells {
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
    
    func savePracticeChartToFile(chart: PracticeChart) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted  // Optional: to make JSON output readable

        do {
            let data = try encoder.encode(chart)  // Encode the PracticeChart object
            
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = dir.appendingPathComponent(PracticeChart.fileName)
            try data.write(to: url)  // Write the data to the file
        } catch {
            Logger.shared.reportError(self, "Failed to save PracticeChart \(error)")
        }
    }
}

extension PracticeChart {
    static func loadPracticeChartFromFile() -> PracticeChart? {
        let decoder = JSONDecoder()
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent(PracticeChart.fileName)

        do {
            let data = try Data(contentsOf: url)  // Read the data from the file
            let chart = try decoder.decode(PracticeChart.self, from: data)  // Decode the data
            return chart
        } catch {
            Logger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
