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
        //print("========= Grade Init", board.name, "Scales", self.scales.count)
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
        let minTempo = 70
        let brokenChordTempo = 50
        var scales:[Scale] = []
        
        if grade == 1 {
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
            let octaves = 2
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))

            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B"), scaleType: .arpeggioMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
        }
        
        if grade == 3 {
            //F# chromatic wrong
            let octaves = 2
            ///Both hands
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .harmonicMinor, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            
            scales.append(Scale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major, scaleMotion: .contraryMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F#"), scaleType: .chromatic, scaleMotion: .similarMotion, octaves: octaves, hands: [0,1], minTempo: minTempo, dynamicType: .mf, articulationType: .legato))

        }
        return scales
    }
    
    func scalesABRSM(grade:Int) -> [Scale] {
        let minTempo = 60
        let brokenChordTempo = 50
        var scales:[Scale] = []
        
        if grade == 1 {
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
//    func loadScales() {
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor))
//
//    }

//    func loadScales1() {
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .major))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .major))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major))
//        
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .melodicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .harmonicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .melodicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .harmonicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .melodicMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .harmonicMinor))
//
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMajor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor))
//        
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMinor))
//        
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioMinor))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMinor))
//        
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioDominantSeventh))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioDominantSeventh))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioDominantSeventh))
//        
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioDiminishedSeventh))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A♭"), scaleType: .arpeggioDiminishedSeventh))
//        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioDiminishedSeventh))
//    }
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
            result.append(MusicBoard(name: "KOMCA", fullName: "Korea Music Association", imageName: "Korea_SJAlogo"))
            result.append(MusicBoard(name: "中央", fullName: "Central Conservatory of Music", imageName: "Central_Conservatory_of_Music_logo"))
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
