import Foundation

class BoardAndGrade: Codable, Identifiable {
    let board:MusicBoard
    let grade:Int
    var scales:[Scale]

    init(board:MusicBoard, grade:Int) {
        self.board = board
        self.grade = grade
        self.scales = []
        self.scales = self.setScales()
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
        self.scales = self.setScales()
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
    
    func getFileName() -> String {
        var name = self.board.name
        name += "=grade_"+String(grade)
        return name
    }

    func getScales() -> [Scale] {
        return self.scales
    }
    
    func scalesTrinity(grade:Int) -> [Scale] {
        
        var scales:[Scale] = []
        
        if grade == 1 {
            let minTempo = 70
            let brokenChordTempo = 50
            let octaves = 1
            ///Row 1
            if false && Settings.shared.isDeveloperMode() {
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
                scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            }
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Row 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Row 3
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Row 4
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Row 5
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Row 6
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0], minTempo: brokenChordTempo, dynamicType: .mf, articulationType: .legato))
        }
        
        if grade == 2 {
            let minTempo = 80
            let arpeggioTempo = 60
            
            let octaves = 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
        }
        
        if grade == 3 {
            let minTempo = 90
            let arpeggioTempo = 70

            let octaves = 2
            ///Both hands
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 51, startMidiLH: 39)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                scaleCustomisation: ScaleCustomisation(startMidiRH: 66, startMidiLH: 54)))
            
            ///Arpeggios
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 51)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiLH: 39)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
        }
        
        if grade == 4 {
            let minTempo = 100
            let arpeggioTempo = 80
            
            let octaves = 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 52, startMidiLH: 40)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 52)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiLH: 40)))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(clefSwitch:false)))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: 1, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                scaleCustomisation: ScaleCustomisation(startMidiRH: 56, startMidiLH: 44, clefSwitch: false)))
        }

        if grade == 5 {
            let minTempo = 110
            let arpeggioTempo = 90
            
            let octaves = 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G#"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(clefSwitch: false)))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 67, startMidiLH: 55, clefSwitch: false)))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioDiminishedSeventh, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: arpeggioTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "D♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato,
                                scaleCustomisation: ScaleCustomisation(startMidiRH: 64, startMidiLH: 48, clefSwitch: false), debug1: true))
        }

        return scales
    }
    
    func scalesABRSM(grade:Int) -> [Scale] {
        var scales:[Scale] = []
        
        if grade == 1 {
            let minTempo = 60
            let octaves = 1
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
        }
        
        if grade == 2 {
            let minTempo = 70
            let octaves = 2
            ///Both hands
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))

            ///Contrary
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Chromatic
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .chromatic, scaleMotion: .contraryMotion, octaves: 1, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Arpgeggios
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            ///Arpgeggios Minor
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
        }
        
        return scales
    }

    func setScales() -> [Scale] {
        var scales:[Scale] = []
        switch self.board.name {
        case "Trinity":
            return scalesTrinity(grade:grade)
        case "ABRSM":
            return scalesABRSM(grade:grade)
        default:
            return scales
        }

        return scales
    }
}

class MusicBoard : Identifiable, Codable, Hashable {
    let name:String
    var fullName:String
    var imageName:String
    var gradesOffered:[BoardAndGrade]

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
            gradesOffered.append(BoardAndGrade(board: self, grade: 1))
            gradesOffered.append(BoardAndGrade(board: self, grade: 2))
            gradesOffered.append(BoardAndGrade(board: self, grade: 3))
            gradesOffered.append(BoardAndGrade(board: self, grade: 4))
            gradesOffered.append(BoardAndGrade(board: self, grade: 5))

        case "ABRSM":
            gradesOffered.append(BoardAndGrade(board: self, grade: 1))
            gradesOffered.append(BoardAndGrade(board: self, grade: 2))
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
