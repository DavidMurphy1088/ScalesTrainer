import Foundation

class BoardGrade: Codable, Identifiable {
    let board:MusicBoard
    let grade:Int
    var name:String
    var scales:[Scale]

    init(board:MusicBoard, grade:Int) {
        self.board = board
        self.grade = grade
        self.name = "Grade " + String(grade)
        self.scales = []
        self.scales = self.setScales()
        self.scales =  self.getScales()
        //print("========= Grade Init", board.name, "Scales", self.scales.count)
    }
    
    func getGradeName() -> String {
        return "Grade " + String(self.grade) + " Piano"
    }
    
    func getFullName() -> String {
        return self.board.name + ", Grade " + String(self.grade) + " Piano"
    }

    func getScales() -> [Scale] {
        return self.scales
    }
    
    func scalesTrinity(grade:Int) -> [Scale] {
        let octaves = 1
        let minTempo = 70
        let brokenChordTempo = 50
        var scales:[Scale] = []
        
        if grade == 1 {
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
            scales.append(Scale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major, scaleMotion: .similarMotion, octaves: octaves, hands: [0],
                                minTempo: minTempo, dynamicType: .mf, articulationType: .legato))
        }
        return scales
    }
    
    func setScales() -> [Scale] {
        var scales:[Scale] = []
        switch self.board.name {
            case "Trinity":
            return scalesTrinity(grade:self.grade)
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
    var grades:[BoardGrade]

    static let boards = [
        MusicBoard(name: "ABRSM", fullName:"The Associated Board of the Royal Schools of Music", imageName: "abrsm"),
        MusicBoard(name: "AMEB", fullName: "Australian Music Examinations Board", imageName: "AMEB"),
        MusicBoard(name: "中央", fullName: "Central Conservatory of Music", imageName: "Central_Conservatory_of_Music_logo"),
        MusicBoard(name: "NZMEB", fullName: "New Zealand Music Examinations Board", imageName: "nzmeb"),
        MusicBoard(name: "KOMCA", fullName: "Korea Music Association", imageName: "Korea_SJAlogo"),
        MusicBoard(name: "Trinity", fullName: "Trinity College London", imageName: "trinity"),
    ]

    init(name:String, fullName:String, imageName:String) {
        self.name = name
        self.imageName = imageName
        self.fullName = fullName
        grades = []
        
        switch name {
        case "Trinity":
            grades.append(BoardGrade(board: self, grade: 1))
            grades.append(BoardGrade(board: self, grade: 2))
            grades.append(BoardGrade(board: self, grade: 3))
            grades.append(BoardGrade(board: self, grade: 4))
            grades.append(BoardGrade(board: self, grade: 5))
        default:
            grades = []
        }
    }
    
    init (name:String) {
        self.name = name
        self.imageName = ""
        self.fullName = ""
        grades = []
        for board in MusicBoard.boards {
            if board.name == name {
                self.fullName = board.fullName
                self.imageName = board.imageName
                self.grades = board.grades
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
