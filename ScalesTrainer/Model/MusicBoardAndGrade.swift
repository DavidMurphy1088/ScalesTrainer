import Foundation

class MusicBoardAndGrade: Codable, Identifiable {
    static var shared:MusicBoardAndGrade? //(board: MusicBoard(name: ""), grade: 0)
    let board:MusicBoard
    let grade:Int
    var scales:[Scale]
    var practiceChart:PracticeChart? = nil

    init(board:MusicBoard, grade:Int) {
        self.board = board
        self.grade = grade
        self.scales = []
        self.scales = MusicBoardAndGrade.setScales(boardName: board.name, grade: grade)
        if let chart = loadPracticeChartFromFile(board: board.name, grade: grade) {
            self.practiceChart = chart
        }
        else {
            self.practiceChart = PracticeChart(scales: self.scales, columnWidth: 3, minorScaleType: 0)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case boardName
        case grade
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boardName = try container.decode(String.self, forKey: .boardName)
        board = MusicBoard(name: boardName)
        grade = try container.decode(Int.self, forKey: .grade)
        self.scales = []
        self.scales = MusicBoardAndGrade.setScales(boardName: board.name, grade: grade)
        if let chart = loadPracticeChartFromFile(board: board.name, grade: grade) {
            self.practiceChart = chart
        }
        else {
            self.practiceChart = PracticeChart(scales: self.scales, columnWidth: 3, minorScaleType: 0)
        }
    }
    
    func getFileName() -> String {
        return "_"+self.board.name+"_"+String(self.grade)
    }
    
    func loadPracticeChartFromFile(board:String, grade:Int) -> PracticeChart? {
        let decoder = JSONDecoder()
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                Logger.shared.reportError(self, "Failed to load PracticeChart - file not found")
                return nil
            }
            
            let url = dir.appendingPathComponent(getFileName())
            let data = try Data(contentsOf: url)  // Read the data from the file
            let chart = try decoder.decode(PracticeChart.self, from: data)
            for r in 0..<chart.rows.count {
                let row:[PracticeChartCell] = chart.rows[r]
                for chartCell in row {
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
            Logger.shared.log(self, "Loaded PracticeChart ⬅️ from local file. Board:\(board) Grade:\(grade) DayOfWeek:\(chart.firstColumnDayOfWeekNumber)")
            chart.adjustForStartDay()
            return chart
         } catch {
            Logger.shared.reportError(self, "Failed to load PracticeChart: \(error)")
            return nil
        }
    }

    func encode(to encoder: Encoder) throws {
        ///Dont try to encode all the scale info - causes crash
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(board.name, forKey: .boardName)
        try container.encode(grade, forKey: .grade)
    }
    
    func getGradeName() -> String {
        //if let grade = self.grade {
            return "Grade " + String(grade) + " Piano"
//        }
//        else {
//            return ""
//        }
    }
    
    func getFullName() -> String {
        var name = self.board.name
        name += ", Grade " + String(grade) + " Piano"
        return name
    }

    func getScales() -> [Scale] {
        return self.scales
    }
    
    func savePracticeChartToFile() {
        guard let practiceChart = self.practiceChart else {
            return
        }
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                Logger.shared.reportError(self, "Failed to save PracticeChart")
                return
            }
            let url = dir.appendingPathComponent(getFileName())
            if let data = practiceChart.convertToJSON() {
                try data.write(to: url)  // Write the data to the file
                Logger.shared.log(self, "Saved PracticeChart for Board:\(self.board) Grade:\(self.grade) ➡️ to \(url) size:\(data.count)")
            }
            else {
                Logger.shared.log(self, "Cannot convert PracticeChart")
            }
        } catch {
            Logger.shared.reportError(self, "Failed to save PracticeChart \(error)")
        }
    }
    
    func deleteFile() {
        do {
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                Logger.shared.reportError(self, "Failed to save PracticeChart")
                return
            }
            let url = dir.appendingPathComponent(getFileName())
            try FileManager.default.removeItem(at: url)
            Logger.shared.log(self, "PracticeChart deleted: \(url.path)")
        } catch {
            Logger.shared.reportError(self, "Failed to delete PracticeChart \(error)")
        }
    }


    static func scalesTrinity(grade:Int) -> [Scale] {
        
        var scales:[Scale] = []
        
        if grade == 1 {
            let minTempo = 70
            let brokenChordTempo = 50
            let octaves = 1
            let dynamicTypes = [DynamicType.mf]
            let articulationTypes = [ArticulationType.legato]
            ///Trinity reinserts accidentals for note 'm' even after a previous note 'n' has the same MIDI when 'n exceeds some note distance from 'm'
            let maxAccidentalLoopbackCustomisation = ScaleCustomisation(maxAccidentalLookback: 1)
            
            ///Row 1
            if false && Settings.shared.isDeveloperMode() {
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            }
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes, scaleCustomisation: maxAccidentalLoopbackCustomisation))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Row 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes, scaleCustomisation: maxAccidentalLoopbackCustomisation))
            
            ///Row 3
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Row 4
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Row 5
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Row 6
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        }
        
        if grade == 2 {
            let minTempo = 80
            let arpeggioTempo = 60
            let dynamicTypes = [DynamicType.f, .p]
            let dynamicTypesArpgeggio = [DynamicType.mf]
            let octaves = 2
            let articulationTypes = [ArticulationType.legato]
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        }
        
        if grade == 3 {
            let minTempo = 90
            let arpeggioTempo = 70
            let dynamicTypes = [DynamicType.f, .p]
            let dynamicTypesArpgeggio = [DynamicType.mf]
            let articulationTypes = [ArticulationType.legato]
            
            let octaves = 2
            ///Both hands
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 51, startMidiLH: 39)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                scaleCustomisation: ScaleCustomisation(startMidiRH: 66, startMidiLH: 54)))
            
            ///Arpeggios
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 51)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(startMidiLH: 39)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypesArpgeggio, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
        }
        
        if grade == 4 {
            let minTempo = 100
            let arpeggioTempo = 80
            let dynamicTypes = [DynamicType.f, .p]
            let articulationTypes = [ArticulationType.legato, .staccato]
            let articulationTypesArpeggio = [ArticulationType.legato]
            let octaves = 2
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 52, startMidiLH: 40)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 52)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio,
                                scaleCustomisation: ScaleCustomisation(startMidiLH: 40)))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypesArpeggio))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: 1, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                scaleCustomisation: ScaleCustomisation(startMidiRH: 56, startMidiLH: 44, clefSwitch: false)))
        }

        if grade == 5 {
            let minTempo = 110
            let arpeggioTempo = 90
            let dynamicTypes = [DynamicType.f, .p]
            let articulationTypes = [ArticulationType.legato, .staccato]
            
            let octaves = 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(clefSwitch: false)))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 67, startMidiLH: 55, clefSwitch: false)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioDiminishedSeventh, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes,
                          scaleCustomisation: ScaleCustomisation(customScaleName: "Diminished 7th Arpeggio, Starting on B, Hands together",
                                                                 customScaleNameWheel: "Dim 7th Arp on B, Hands together",
                                                                 removeKeySig: true)))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: [ArticulationType.legato],
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
                                                                       customScaleName: "Chromatic, Contrary Motion, LH starting C, RH starting E",
                                                                       customScaleNameWheel: "Chrom Contrary, LH C, RH E")))
//            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves-1, hands: [0,1],
//                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: [ArticulationType.legato],
//                                scaleCustomisation: ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
//                                                                       customScaleName: "Chromatic, Contrary Motion, LH starting C, RH starting E",
//                                                                       customScaleNameWheel: "Chrom Contrary, LH C, RH E")))
        }

        return scales
    }
    
    static func scalesABRSM(grade:Int) -> [Scale] {
        var scales:[Scale] = []
        let dynamicTypes = [DynamicType.mf]
        let articulationTypes = [ArticulationType.legato]
        
        if grade == 1 {
            let minTempo = 60
            let octaves = 1
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        }
        
        if grade == 2 {
            let minTempo = 70
            let octaves = 2
            let articulationTypes = [ArticulationType.legato]
            
            ///Both hands
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            ///Contrary
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Chromatic
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: 1, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Arpgeggios
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            ///Arpgeggios Minor
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        }
        
        return scales
    }

    static func setScales(boardName:String, grade:Int) -> [Scale] {
        let scales:[Scale] = []
        switch boardName {
        case "Trinity":
            return scalesTrinity(grade:grade)
        case "ABRSM":
            return scalesABRSM(grade:grade)
        default:
            return scales
        }
    }
}

class MusicBoard : Identifiable, Codable, Hashable {
    let name:String
    var fullName:String
    var imageName:String
    var gradesOffered:[Int]

    static func getSupportedBoards() -> [MusicBoard] {
        var result:[MusicBoard] = []
        result.append(MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: "trinity"))
        if true {
            result.append(MusicBoard(name: "ABRSM", fullName:"The Associated Board of the Royal Schools of Music", imageName: "abrsm"))
            //result.append(MusicBoard(name: "KOMCA", fullName: "Korea Music Association", imageName: "Korea_SJAlogo"))
            //result.append(MusicBoard(name: "中央", fullName: "Central Conservatory of Music", imageName: "Central_Conservatory_of_Music_logo"))
            result.append(MusicBoard(name: "NZMEB", fullName: "New Zealand Music Examinations Board", imageName: "nzmeb"))
            result.append(MusicBoard(name: "AMEB", fullName: "Australian Music Examinations Board", imageName: "AMEB"))
        }
        return result
    }

    init(name:String, fullName:String, imageName:String) {
        self.name = name
        self.imageName = imageName
        self.fullName = fullName
        gradesOffered = []
        
        switch name {
        case "Trinity":
            gradesOffered.append(1)
            gradesOffered.append(2)
            gradesOffered.append(3)
            gradesOffered.append(4)
            gradesOffered.append(5)

        case "ABRSM":
            gradesOffered.append(1)
            gradesOffered.append(2)
        default:
            gradesOffered = []
        }
    }
    
    init(name:String) {
        self.name = name
        self.imageName = ""
        self.fullName = ""
        gradesOffered = []
        for board in MusicBoard.getSupportedBoards() {
            if board.name == name {
                self.fullName = board.fullName
                self.imageName = board.imageName
                self.gradesOffered = board.gradesOffered
            }
        }
    }
    
    static func == (lhs: MusicBoard, rhs: MusicBoard) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
