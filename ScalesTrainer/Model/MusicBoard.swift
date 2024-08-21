import Foundation

class MusicBoardGrade {
    let board:MusicBoard
    var scales:[PracticeJournalScale] = []
    
    init(board:MusicBoard) {
        self.board = board
        loadScales()
    }
    
    func loadScales() {
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .brokenChordMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .brokenChordMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .brokenChordMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .brokenChordMinor))

    }

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

class MusicBoard : Identifiable {
    let name:String
    let fullName:String
    let imageName:String
    var grades:[MusicBoardGrade] = []

    static let options = [
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
        self.grades.append(MusicBoardGrade(board: self))
    }
}
