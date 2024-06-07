import Foundation

class PracticeJournalScale : Identifiable {
    let scaleRoot:ScaleRoot
    let scaleType:ScaleType
    var completePercentage = Double.random(in: 0...1.0)
    init(scaleRoot:ScaleRoot, scaleType:ScaleType) {
        self.scaleRoot = scaleRoot
        self.scaleType = scaleType
    }
    func getName() -> String {
        return scaleRoot.name + " " + scaleType.description
    }
    func getTempo() -> Int {
        return 90
    }
}


