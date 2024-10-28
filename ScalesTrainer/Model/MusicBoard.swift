import Foundation

class MusicBoardGrade: Codable {
    //var board:MusicBoard
    let gradeIndex:Int
    var grade:String

    init(index:Int, grade:String) {
        self.grade = grade
        self.gradeIndex = 1 //index
    }
    
    func getScales() -> [Scale] {
        var scales:[Scale] = []
        let octaves = 1
        let minTempo = 70
        let brokenChordTempo = 50

        if self.gradeIndex == 0 {

        }
        
        if self.gradeIndex == 1 {
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

class MusicBoard : Identifiable, Codable {
    let name:String
    let fullName:String
    let imageName:String
    //var grades:[MusicBoardGrade] = []

    static let options = [
        MusicBoard(name1: "ABRSM", fullName:"The Associated Board of the Royal Schools of Music", imageName: "abrsm"),
        MusicBoard(name1: "AMEB", fullName: "Australian Music Examinations Board", imageName: "AMEB"),
        MusicBoard(name1: "中央", fullName: "Central Conservatory of Music", imageName: "Central_Conservatory_of_Music_logo"),
        MusicBoard(name1: "NZMEB", fullName: "New Zealand Music Examinations Board", imageName: "nzmeb"),
        MusicBoard(name1: "KOMCA", fullName: "Korea Music Association", imageName: "Korea_SJAlogo"),
        MusicBoard(name1: "Trinity", fullName: "Trinity College London", imageName: "trinity"),
    ]

    init(name:String) {
        self.name = name
        if let board = MusicBoard.options.first(where: { $0.name == name }) {
            self.fullName = board.fullName
            self.imageName = board.imageName
        }
        else {
            self.fullName = ""
            self.imageName = ""
        }
        //self.grades.append(MusicBoardGrade(grade: "1"))
    }
    
    init(name1:String, fullName:String, imageName:String) {
        self.name = name1
        self.imageName = imageName
        self.fullName = fullName
        //self.grades.append(MusicBoardGrade(grade: "1"))
    }
}
