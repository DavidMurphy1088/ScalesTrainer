
import Foundation

class BackingChords {
    class BackingChord {
        var pitches:[Int]
        let value:Double
        init(pitches inPitches:[Int], value:Double, offset:Int) {
            self.pitches = []
            for pitch in inPitches {
                self.pitches.append(pitch + offset)
            }
            self.value = value
        }
    }
    
    let scaleType:ScaleType
    var chords:[BackingChord] = []
                              
    init(scaleType:ScaleType, hands : [Int], octaves:Int) {
        self.scaleType = scaleType
        let octaveOffset = -12
        
        if [.major, .melodicMinor, .harmonicMinor, .naturalMinor].contains(scaleType) {
            let isMinor = [.melodicMinor, .harmonicMinor, .naturalMinor].contains(scaleType)
            if octaves == 1 {
                //Tonic I
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [isMinor ? 3 : 4], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                //Dom V
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                //SubDom IV
                chords.append(BackingChord(pitches: [isMinor ? -4 : -3], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                
                //Tonic I
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0,isMinor ? 3 : 4], value: 1, offset: octaveOffset))
            }
            if octaves == 2 {
                //Tonic I
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [isMinor ? 3 : 4], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                //Dom V
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                //SubDom IV
                chords.append(BackingChord(pitches: [isMinor ? -4 : -3], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))

                //Dom V
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                //------------------
                chords.append(BackingChord(pitches: [isMinor ? 3 : 4], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [isMinor ? -4 : -3], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))

                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))

                chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))

                //Tonic I
                chords.append(BackingChord(pitches: [0,isMinor ? 3 : 4], value: 2.0, offset: octaveOffset))
            }
        }
        
        if [.arpeggioDiminished, .arpeggioMajor, .arpeggioMinor, .arpeggioMajorSeventh, .arpeggioMinorSeventh].contains(scaleType) {
            let minor = [.arpeggioMinor, .arpeggioMinorSeventh].contains(scaleType)
            for _ in 0..<3 {
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7, 7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7, 7], value: 0.5, offset: octaveOffset))
            }
            chords.append(BackingChord(pitches: [0], value: 2.0, offset: octaveOffset))
        }
        if [.arpeggioDiminishedSeventh].contains(scaleType) {
            let minor = true //[.arpeggioMinor, .arpeggioMinorSeventh].contains(scaleType)
            for _ in 0..<4 {
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7, 7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [minor ? 3 : 4, 7, 7], value: 0.5, offset: octaveOffset))
            }
            chords.append(BackingChord(pitches: [0], value: 4.0, offset: octaveOffset))
        }

        ///Broekn chords - Trinity, Grade 1 only
        if [.brokenChordMajor].contains(scaleType) {
            let value = 1.0 / 3.0
            let octaveOffset = 0
            for _ in 0..<7 {
                chords.append(BackingChord(pitches: [0], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [4, 7], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [4, 7], value: value, offset: octaveOffset))
            }
            chords.append(BackingChord(pitches: [7], value: 1, offset: octaveOffset))
        }
        if [.brokenChordMinor].contains(scaleType) {
            let value = 1.0 / 3.0
            let octaveOffset = 0
            for _ in 0..<7 {
                chords.append(BackingChord(pitches: [-12], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [3, 7], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [3, 7], value: value, offset: octaveOffset))
            }
            chords.append(BackingChord(pitches: [7], value: 1, offset: octaveOffset))
        }
    }
    
    init(scaleType:ScaleType) {
        self.scaleType = scaleType
    }

}
