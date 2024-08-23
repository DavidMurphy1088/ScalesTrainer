import Foundation

//class PracticeJournalScale : Identifiable { //} : Identifiable, Comparable {
//    static var orderIndex:Int = 0
//    
//    let scaleRoot:ScaleRoot
//    let scaleType:ScaleType
//    var progressLH = 0.0
//    var progressRH = 0.0
//    var orderIndex:Int
//    
//    init(scaleRoot:ScaleRoot, scaleType:ScaleType) {
//        self.orderIndex = PracticeJournalScale.orderIndex
//        PracticeJournalScale.orderIndex += 1
//        self.scaleRoot = scaleRoot
//        self.scaleType = scaleType
//        self.progressLH = getProgressPercentage(scaleType: scaleType)
//        self.progressRH = getProgressPercentage(scaleType: scaleType)
//    }
//    
//    func getProgressPercentage(scaleType:ScaleType) -> Double {
//        switch scaleType {
//        case .major:
//            return Double.random(in: 0.6...0.95)
//        default:
//            return Double.random(in: 0...0.50)
//        }
//    }
//    
////    func getScale(octaves:Int, hand:Int) -> Scale {
////        return Scale(scaleRoot: scaleRoot, scaleType: scaleType, octaves: octaves, hand: hand)
////    }
//    
//    func getName() -> String {
//        return scaleRoot.name + " " + scaleType.description
//    }
//}

//class PracticeJournalOld {
//    static var shared:PracticeJournalOld?
//    let scaleGroup: MusicBoard
//    let title:String
//    var randomScale: PracticeJournalScale? = nil
//    
//    init(scaleGroup: MusicBoard) {
//        self.scaleGroup = scaleGroup
//        self.title = scaleGroup.name
//    }
//    
////    func getScaleList() -> [String] {
////        var name:[String] = []
////        for scale in self.scaleGroup.scales {
////            name.append(scale.getName())
////        }
////        return name
////    }
//    
////    func makeRandomScale()  {
////        var r = Int.random(in: 0...scaleGroup.scales.count-1)
////        let scale = scaleGroup.scales[r]
////        let randomScale = PracticeJournalScale(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType)
////        r = Int.random(in: 0...1)
////        randomScale.hand = r 
////        r = Int.random(in: 1...2)
////        randomScale.octaves = r
////        self.randomScale = randomScale
////    }
//}


