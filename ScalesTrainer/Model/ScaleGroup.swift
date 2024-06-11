import Foundation

class ScaleGroup : Identifiable {
    let name:String
    let imageName:String
    var scales:[PracticeJournalScale] = []
    
    static let options = [
        ScaleGroup(name: "ABRSM Grade 1", imageName: "abrsm"),
        ScaleGroup(name: "ABRSM Grade 2", imageName: "abrsm"),
        ScaleGroup(name: "ABRSM Grade 3", imageName: "abrsm"),
        
        ScaleGroup(name: "Central Conservatory of Music, Grade 1", imageName: "Central_Conservatory_of_Music_logo"),
        ScaleGroup(name: "Central Conservatory of Music, Grade 2", imageName: "Central_Conservatory_of_Music_logo"),
        ScaleGroup(name: "Central Conservatory of Music, Grade 3", imageName: "Central_Conservatory_of_Music_logo"),
        
//        ScaleGroup(name: "NZMEB Grade 1", imageName: "nzmeb"),
//        ScaleGroup(name: "NZMEB Grade 2", imageName: "nzmeb"),
//        ScaleGroup(name: "NZMEB Grade 3", imageName: "nzmeb"),
        
        ScaleGroup(name: "Korea Music Association Grade 1", imageName: "Korea_SJAlogo"),
        ScaleGroup(name: "Korea Music Association Grade 2", imageName: "Korea_SJAlogo"),
        ScaleGroup(name: "Korea Music Association Grade 3", imageName: "Korea_SJAlogo"),

        ScaleGroup(name: "Trinity Grade 1", imageName: "trinity"),
        ScaleGroup(name: "Trinity Grade 2", imageName: "trinity"),
        ScaleGroup(name: "Trinity Grade 3", imageName: "trinity")
    ]
    
    init() {
        self.name = "Empty"
        self.imageName = ""
    }

    init(name:String, imageName:String) {
        self.name = name
        self.imageName = imageName
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .naturalMinor))
        
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "C"), scaleType: .melodicMinor)) 
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .major))
        //scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .major))
        //scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .major))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .major))
        
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .naturalMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .harmonicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .melodicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .naturalMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .harmonicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .melodicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .naturalMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .harmonicMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .melodicMinor))
        
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "C"), scaleType: .arpeggioMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "G"), scaleType: .arpeggioMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMajor))
        //scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMajor))
        //scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "F"), scaleType: .arpeggioMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "B♭"), scaleType: .arpeggioMajor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E♭"), scaleType: .arpeggioMajor))

        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "A"), scaleType: .arpeggioMinor))
        scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "E"), scaleType: .arpeggioMinor))
        //scales.append(PracticeJournalScale(scaleRoot: ScaleRoot(name: "D"), scaleType: .arpeggioMinor))
    }
}
