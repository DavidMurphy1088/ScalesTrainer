import Foundation

//enum ScaleHand {
//    case left
//    case right
//}

class PracticeJournalScale : Identifiable {
    let scaleRoot:ScaleRoot
    let scaleType:ScaleType
    ///Random selection
    var hand:Int? = nil
    var octaves:Int? = nil
    init(scaleRoot:ScaleRoot, scaleType:ScaleType) {
        self.scaleRoot = scaleRoot
        self.scaleType = scaleType
    }
    func completePercentage() -> Double {
        return Double.random(in: 0...0.85)
    }
    func getName() -> String {
        return scaleRoot.name + " " + scaleType.description
    }
    
    func getTempo() -> Int {
        return 90
    }
}

class PracticeJournal {
    static var shared:PracticeJournal?
    let scaleGroup: ScaleGroup
    let title:String
    
    init(scaleGroup: ScaleGroup) {
        self.scaleGroup = scaleGroup
        self.title = scaleGroup.name
    }
    
    func getRandomScale() -> PracticeJournalScale {
        var r = Int.random(in: 0...scaleGroup.scales.count-1)
        let scale = scaleGroup.scales[r]
        let randomScale = PracticeJournalScale(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType)
        r = Int.random(in: 0...1)
        randomScale.hand = r 
        r = Int.random(in: 1...2)
        randomScale.octaves = r
        return randomScale
    }
}


