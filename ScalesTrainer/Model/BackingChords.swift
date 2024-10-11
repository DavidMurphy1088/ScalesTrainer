
import Foundation

class BackingChords {
    class BackingChord {
        let pitches:[Int]
        let value:Double
        init(pitches:[Int], value:Double) {
            self.pitches = pitches
            self.value = value
        }
//        init(chordAndValue:BackingChord) {
//            self.pitches = Array(chordAndValue.pitches)
//            self.value = chordAndValue.value
//        }
    }
    
    let scaleType:ScaleType
    var chords:[BackingChord] = []
                              
    init(scaleType:ScaleType, octaves:Int) {
        self.scaleType = scaleType
        if [.major, .melodicMinor, .harmonicMinor, .naturalMinor].contains(scaleType) {
            chords.append(BackingChord(pitches: [0], value: 1))
            chords.append(BackingChord(pitches: [7], value: 1))
        }
    }
    
    init(scaleType:ScaleType) {
        self.scaleType = scaleType
    }

}
