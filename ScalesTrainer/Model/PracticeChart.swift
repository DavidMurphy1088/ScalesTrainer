import SwiftUI
import Foundation

class PracticeChartCellOld : ObservableObject, Codable {
    var scale:Scale
    var row:Int
    var enabled:Bool = false
    
    init(scale:Scale, row:Int) {
        self.scale = scale
        self.row = row
    }
    
    func setEnabled(way:Bool) {
        DispatchQueue.main.async {
            self.enabled = way
        }
    }
}

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
    static let fileName = "practice_chart.json"
    var musicBoard:MusicBoard
    var musicBoardGrade:MusicBoardGrade
    var rows: Int
    var columns: Int
    var cells: [[PracticeChartCell]]
    
    init(musicBoard:MusicBoard, musicBoardGrade:MusicBoardGrade) {
        self.musicBoard = musicBoard
        self.musicBoardGrade = musicBoardGrade
        self.columns = 3
        self.rows = 6
        self.cells = []
        let scales = musicBoardGrade.getScales()
        var scaleCtr = 0
        
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
            print("Failed to load PracticeChart: \(error)")
            return nil
        }
    }
}
