import SwiftUI
import Foundation

//class PracticeCell {
//    var scaleRoot: ScaleRoot
//    var scaleType: ScaleType
//    var hand:Int
//    var selected: Bool
//    
//    init(scaleRootName: String, scaleType: ScaleType, hand:Int) {
//        self.scaleRoot = ScaleRoot(name: scaleRootName)
//        self.scaleType = scaleType
//        self.hand = hand
//        self.selected = false
//    }
//}

class PracticeChart {
    let musicBoardGrade:MusicBoardGrade
    var rows: Int
    var columns: Int
    var cells: [[Scale]]
    
    init(musicBoardGrade:MusicBoardGrade) {
        self.musicBoardGrade = musicBoardGrade
        self.columns = 3
        self.rows = 6
        self.cells = []
        let scales = musicBoardGrade.getScales()
        var scaleCtr = 0
        
        for _ in 0..<rows {
            var chartRow:[Scale] = []
            for _ in 0..<columns {
                chartRow.append(scales[scaleCtr])
                scaleCtr += 1
                if scaleCtr >= scales.count {
                    scaleCtr = 0
                }
            }
            cells.append(chartRow)
        }
    }

//    func initOld(musicBoardGrade:MusicBoardGrade) {
//        //self.musicBoardGrade = musicBoardGrade
//        self.columns = 3
//        self.cells = []
//        
//        ///Day 1: F major RH,   G major LH,   E minor RH,          C contrary,       G broken RH,     Dm broken LH
//        ///Day 2: F major LH,    D minor RH,  E minor LH,           F broken RH,   G broken LH,     Em broken RH
//        ///Day 3: G major RH,   D minor LH,   D chrom contrary, F broken LH,   Dm broken RH,   Em broken LH
//        
//        var row = [PracticeCell(scaleRootName: "F", scaleType: .major, hand: 0),
//                   PracticeCell(scaleRootName: "F", scaleType: .major, hand: 1),
//                   PracticeCell(scaleRootName: "G", scaleType: .major, hand: 0)]
//        cells.append(row)
//        
//        row = [PracticeCell(scaleRootName: "G", scaleType: .major, hand: 1),
//               PracticeCell(scaleRootName: "D", scaleType: .harmonicMinor, hand: 0),
//                   PracticeCell(scaleRootName: "D", scaleType: .harmonicMinor, hand: 1)]
//        cells.append(row)
//        
//        row = [PracticeCell(scaleRootName: "E", scaleType: .harmonicMinor, hand: 0),
//               PracticeCell(scaleRootName: "E", scaleType: .harmonicMinor, hand: 1),
//                   PracticeCell(scaleRootName: "D", scaleType: .chromatic, hand: 0)]
//        cells.append(row)
//
//        row = [PracticeCell(scaleRootName: "C", scaleType: .major, hand: 0),
//               PracticeCell(scaleRootName: "F", scaleType: .brokenChordMajor, hand: 0),
//                   PracticeCell(scaleRootName: "F", scaleType: .brokenChordMajor, hand: 1)]
//        cells.append(row)
//        
//        row = [PracticeCell(scaleRootName: "G", scaleType: .brokenChordMajor, hand: 0),
//               PracticeCell(scaleRootName: "G", scaleType: .brokenChordMajor, hand: 1),
//                   PracticeCell(scaleRootName: "D", scaleType: .brokenChordMinor, hand: 0)]
//        cells.append(row)
//
//        row = [PracticeCell(scaleRootName: "D", scaleType: .brokenChordMinor, hand: 1),
//               PracticeCell(scaleRootName: "E", scaleType: .brokenChordMinor, hand: 0),
//                   PracticeCell(scaleRootName: "E", scaleType: .brokenChordMinor, hand: 1)]
//        cells.append(row)
//        self.rows = cells.count
//    }

}
