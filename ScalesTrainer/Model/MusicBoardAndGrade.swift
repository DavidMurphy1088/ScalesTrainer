import Foundation

class MusicBoardAndGrade: Codable, Identifiable {
    let board:MusicBoard
    let grade:Int
    var practiceChart:PracticeChart? = nil
    
    init(board:MusicBoard, grade:Int) {
        self.board = board
        self.grade = grade
//        if let chart = loadPracticeChartFromFile(board: board.name, grade: grade) {
//            self.practiceChart = chart
//            ///Testing only - to test adjust chart's hilighted 'today' column
////            self.practiceChart?.firstColumnDayOfWeekNumber -= 1
////            savePracticeChartToFile()
//        }
//        else {
//            self.practiceChart = PracticeChart(board: board.name, grade:grade, columnWidth: 3, minorScaleType: 0)
//        }
    }
    
    enum CodingKeys: String, CodingKey {
        case boardName
        case grade
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boardName = try container.decode(String.self, forKey: .boardName)
        var loadedBoard:MusicBoard?
        for board in MusicBoard.getSupportedBoards() {
            if board.name == boardName {
                loadedBoard = board
                break
            }
        }
        self.board = loadedBoard!
        grade = try container.decode(Int.self, forKey: .grade)
    }
    
    func encode(to encoder: Encoder) throws {
        ///Dont try to encode all the scale info - causes crash
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(board.name, forKey: .boardName)
        try container.encode(grade, forKey: .grade)
    }
    
//    func getGradeName() -> String {
//        return "Grade " + String(grade) + " Piano"
//    }
    
    func getFullName() -> String {
        var name = self.board.name
        name += ", Grade " + String(grade) + " Piano"
        return name
    }
    
    ///List the scales and include melodics and harmonic minors
    func enumerateAllScales() -> [Scale] {
        var allScales:[Scale] = []
        //for scale in self.scales {
        for scale in MusicBoardAndGrade.getScales(boardName: board.name, grade: grade) {
            allScales.append(scale)
            if scale.scaleMotion == .similarMotion {
                if scale.scaleType == .harmonicMinor {
                    let melodicScale = Scale(scaleRoot: scale.scaleRoot, scaleType: .melodicMinor, scaleMotion: scale.scaleMotion, octaves: scale.octaves, hands: scale.hands, minTempo: scale.minTempo, dynamicTypes: scale.dynamicTypes, articulationTypes: scale.articulationTypes,
                                             scaleCustomisation: scale.scaleCustomisation, debugOn: scale.debugOn)
                    allScales.append(melodicScale)
                }
            }
        }
        return allScales
    }
    
    static func scalesTrinity(grade:Int) -> [Scale] {
        var scales:[Scale] = []
        if grade == 0 {
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: 1, hands: [1],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .trinityBrokenTriad, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .trinityBrokenTriad, scaleMotion: .similarMotion, octaves: 1, hands: [1],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 1, hands: [1],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .trinityBrokenTriad, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .trinityBrokenTriad, scaleMotion: .similarMotion, octaves: 1, hands: [1],
                                minTempo: 60, dynamicTypes: [.mf], articulationTypes: [.legato]))
        }

        if grade == 1 {
            let minTempo = 70
            let brokenChordTempo = 50
            let octaves = 1
            let dynamicTypes = [DynamicType.mf]
            let articulationTypes = [ArticulationType.legato]
            ///Trinity reinserts accidentals for note 'm' even after a previous note 'n' has the same MIDI when 'n exceeds some note distance from 'm'
            let maxAccidentalLoopbackCustomisation = ScaleCustomisation(maxAccidentalLookback: 1)
            
            ///Row 1
            if false && Settings.shared.isDeveloperMode1() {
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
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: 1, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: [.legato],
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
                                scaleCustomisation: ScaleCustomisation(customScaleName: "Diminished 7th Arpeggio Starting on B, Hands Together",
                                                                       customScaleNameLH: "Diminished 7th Arpeggio Starting on B, LH",
                                                                       customScaleNameRH: "Diminished 7th Arpeggio Starting on B, RH",
                                                                       customScaleNameWheel: "Dim 7th Arp on B, Tog",
                                                                       removeKeySig: true)))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: [ArticulationType.legato],
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false,
                                                                       customScaleName: "Chromatic in Contrary Motion, LH starting C, RH starting E",
                                                                       customScaleNameLH: "Chromatic in Contrary Motion, LH starting C",
                                                                       customScaleNameRH: "Chromatic in Contrary Motion, RH starting E",
                                                                       customScaleNameWheel: "Chrom Contrary, LH C, RH E")))
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
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
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
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

             
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: 1, hands: [0],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: 1, hands: [1],
                                minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            
            for hand in [0,1] {
                scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: 2, hands: [hand],
                                    minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
                
                scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: 2, hands: [hand],
                                    minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
                
                scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [hand],
                                    minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
                
                scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [hand],
                                    minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
            }
        }
        
        return scales
    }
    static func scalesGeneric(grade:Int) -> [Scale] {
        var scales:[Scale] = []
        let dynamicTypes = [DynamicType.mf]
        let articulationTypes = [ArticulationType.legato]
        
        let minTempo = 60
        let octaves = 1
        scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

        scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [0],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [0],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: 2, hands: [1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))

        scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        
        scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                            minTempo: minTempo, dynamicTypes: dynamicTypes, articulationTypes: articulationTypes))
        return scales
    }
    
    static func getScales(boardName:String, grade:Int) -> [Scale] {
        let scales:[Scale] = []
        switch boardName {
        case "Trinity":
            return scalesTrinity(grade:grade)
        case "ABRSM":
            return scalesABRSM(grade:grade)
        case "NZMEB":
            return scalesGeneric(grade:grade)
        case "AMEB":
            return scalesGeneric(grade:grade)

        default:
            return scales
        }
    }
    
    static func getScale(boardName:String, grade:Int, scaleKey:String) -> Scale? {
        let scales = MusicBoardAndGrade.getScales(boardName: boardName, grade: grade)
        for gradeScale in scales {
            var scalesToSearch:[Scale] = [gradeScale]
            ///Board grades are defined with harmonic minors but the melodic minor might be requested also look for that.
            if gradeScale.scaleType == ScaleType.harmonicMinor {
                var melodicScale = Scale(scaleRoot: gradeScale.scaleRoot, scaleType: .melodicMinor, scaleMotion: gradeScale.scaleMotion,
                                     octaves: gradeScale.octaves, hands: gradeScale.hands, minTempo: gradeScale.minTempo,
                                     dynamicTypes: gradeScale.dynamicTypes, articulationTypes: gradeScale.articulationTypes,
                                     scaleCustomisation: gradeScale.scaleCustomisation)
                var naturalScale = Scale(scaleRoot: gradeScale.scaleRoot, scaleType: .naturalMinor, scaleMotion: gradeScale.scaleMotion,
                                     octaves: gradeScale.octaves, hands: gradeScale.hands, minTempo: gradeScale.minTempo,
                                     dynamicTypes: gradeScale.dynamicTypes, articulationTypes: gradeScale.articulationTypes,
                                     scaleCustomisation: gradeScale.scaleCustomisation)
                scalesToSearch.append(melodicScale)
                scalesToSearch.append(naturalScale)
            }
            for scale in scalesToSearch {
                let key = scale.getScaleIdentificationKey()
                if key == scaleKey {
                    return scale
                }
            }
        }
        return nil
    }
}

class MusicBoard : Identifiable, Codable, Hashable {
    let id:UUID
    let name:String
    var fullName:String
    var imageName:String
    var gradesOffered:[Int]

    static func getSupportedBoards() -> [MusicBoard] {
        var result:[MusicBoard] = []
        result.append(MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: "trinity"))
        result.append(MusicBoard(name: "ABRSM", fullName:"The Associated Board of the Royal Schools of Music", imageName: "abrsm"))
        //result.append(MusicBoard(name: "KOMCA", fullName: "Korea Music Association", imageName: "Korea_SJAlogo"))
        //result.append(MusicBoard(name: "中央", fullName: "Central Conservatory of Music", imageName: "Central_Conservatory_of_Music_logo"))
        result.append(MusicBoard(name: "NZMEB", fullName: "New Zealand Music Examinations Board", imageName: "nzmeb"))
        result.append(MusicBoard(name: "AMEB", fullName: "Australian Music Examinations Board", imageName: "AMEB"))
        return result
    }

    init(name:String, fullName:String, imageName:String) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.fullName = fullName
        gradesOffered = []
        
        switch name {
        case "Trinity":
            //gradesOffered.append(0) ///initial
            gradesOffered.append(1)
            gradesOffered.append(2)
            gradesOffered.append(3)
            gradesOffered.append(4)
            gradesOffered.append(5)

        case "ABRSM":
            gradesOffered.append(1)
            gradesOffered.append(2)
        default:
            gradesOffered.append(1)
            gradesOffered.append(2)

        }
    }
    
//    init(name:String) {
//        self.id = UUID()
//        self.name = name
//        self.imageName = ""
//        self.fullName = ""
//        gradesOffered = []
//        for board in MusicBoard.getSupportedBoards() {
//            if board.name == name {
//                self.fullName = board.fullName
//                self.imageName = board.imageName
//                self.gradesOffered = board.gradesOffered
//            }
//        }
//    }
    
    static func == (lhs: MusicBoard, rhs: MusicBoard) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
