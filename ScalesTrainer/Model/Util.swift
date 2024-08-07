import Foundation

public class Util {
    static func frequencyToMIDI(frequency: Float) -> Int {
        //let freqAdjust = 0.95
        let midiNoteNumber = 69 + 12 * log2((frequency) / 440.0)
        //let midiNoteNumber = 69 + 12 * log2((Double(frequency) * freqAdjust) / 440.0)
        if midiNoteNumber.isFinite && !midiNoteNumber.isNaN {
            return Int(round(midiNoteNumber))
        }
        else {
            return 0
        }
    }
}
