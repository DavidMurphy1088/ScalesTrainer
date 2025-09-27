
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
    
    init(scaleType:ScaleType) {
        self.scaleType = scaleType
    }
    
    init(scaleType:ScaleType, hands : [Int], octaves:Int) {
        self.scaleType = scaleType
        let octaveOffset = -12
        if [.harmonicMinor].contains(scaleType) {
            let offsets = "C G Eb G   B G D G  Ab F C F   B G C G  Eb G Ab F  C F B  G   D G B G  C"
            chords = self.fromNoteNames(offsets, value: 0.5, octaveOffset: octaveOffset)
        }
        if [.melodicMinor].contains(scaleType) {
            let offsets = "C G Eb G   B G D G  Ab F C F   B G C G  Eb G B G   D G Ab F   C F B G  C"
            chords = self.fromNoteNames(offsets, value: 0.5, octaveOffset: octaveOffset)
        }
        if [.naturalMinor].contains(scaleType) {
            if octaves == 2 {
                let offsets = "C G Eb G   Bb G D G   Ab F C F   Bb G C G   Eb G Ab F   C F Bb G   D G Bb G   C"
                chords = self.fromNoteNames(offsets, value: 0.5, octaveOffset: octaveOffset)
            }
            if octaves == 1 {
                let offsets = "C G Eb G    Bb G D G   Ab F C F   Bb G C"
                chords = self.fromNoteNames(offsets, value: 0.5, octaveOffset: octaveOffset)
            }
        }

        //if [.major, .melodicMinor, .harmonicMinor, .naturalMinor].contains(scaleType) {
        if [.major].contains(scaleType) {
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
                // 1 - Tonic I
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [isMinor ? 3 : 4], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                // 2 - Dom V
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                // 3 - SubDom IV
                chords.append(BackingChord(pitches: [isMinor ? -4 : -3], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))

                // 4 - Dom V
                chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                
                // 5 - Tonic
                chords.append(BackingChord(pitches: [isMinor ? 3 : 4], value: 0.5, offset: octaveOffset))
                chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                if scaleType == .melodicMinor {
                    chords.append(BackingChord(pitches: [10], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                }
                else {
                    chords.append(BackingChord(pitches: [isMinor ? -4 : -3], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                }
                
                // 6 - Dom V
                if scaleType == .melodicMinor {
                    chords.append(BackingChord(pitches: [-1], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                }
                else {
                    chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                }

                // 7
                if scaleType == .melodicMinor {
                    chords.append(BackingChord(pitches: [8], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [0], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [5], value: 0.5, offset: octaveOffset))
                }
                else {
                    chords.append(BackingChord(pitches: [2], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [scaleType == .naturalMinor ? -2 : -1], value: 0.5, offset: octaveOffset))
                    chords.append(BackingChord(pitches: [7], value: 0.5, offset: octaveOffset))
                }

                // 8 - Tonic I
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

        ///Broken chords - Trinity, Grade 1 only
        if [.brokenChordMajor].contains(scaleType) {
            var value = 1.0 / 3.0
            let octaveOffset = 0
            for _ in 0..<7 {
                chords.append(BackingChord(pitches: [0], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [4, 7], value: value, offset: octaveOffset))
                chords.append(BackingChord(pitches: [4, 7], value: value, offset: octaveOffset))
            }
            value = 1.0
            //chords.append(BackingChord(pitches: [-12], value: value, offset: octaveOffset))
            chords.append(BackingChord(pitches: [0, 4, 7], value: value, offset: octaveOffset))
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
    
    func fromNoteNames(_ keyString: String, value:Double, octaveOffset:Int) -> [BackingChord] {
        // Map of note names to semitone offsets from C
        let noteMap: [String: Int] = [
                "C": 0,
                "C#": 1, "Db": 1, "D♭": 1,
                "D": 2,
                "D#": 3, "Eb": 3, "E♭": 3,
                "E": 4,
                "F": 5,
                "F#": 6, "Gb": 6, "G♭": 6,
                "G": 7,
                "G#": 8, "Ab": 8, "A♭": 8,
                "A": 9,
                "A#": 10, "Bb": 10, "B♭": 10,
                "B": 11
            ]
            
        
        // Split the string by spaces and convert each key
        let map = keyString.components(separatedBy: " ")
            .compactMap { key in
                let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : noteMap[trimmed]
            }
            .compactMap { $0 } // Remove any nils from unknown keys
        var chords:[BackingChord] = []
        for pitchOffset in map {
            let chord = BackingChord(pitches: [pitchOffset], value: value, offset: octaveOffset)
            chords.append(chord)
            
        }
        return chords
    }
}
