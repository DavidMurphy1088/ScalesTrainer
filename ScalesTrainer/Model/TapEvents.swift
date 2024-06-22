import Foundation

public enum TapEventStatus {
    case none
    case keyPressWithoutScaleMatch
    case keyPressWithNextScaleMatch
    case keyPressWithFollowingScaleMatch
    case continued
    case farFromExpected
    case pastEndOfScale
    case keyNotOnKeyboard
    case outsideScale
}

public class TapEvent:Hashable {
    let id = UUID()
    let timestamp = Date()
    let tapNum:Int
    let amplitude:Float
    let frequency:Float
    
    let midi:Int ///The octave adjusted midi used for matching
    let status:TapEventStatus
    let tapMidi:Int ///The origianl taop midi
    let expectedScaleNoteState:ScaleNoteState? ///The scale sequence index
    let key:PianoKeyModel?
    let ascending:Bool
    let amplDiff:Double

    public init(tapNum:Int, frequency:Float, amplitude:Float, ascending: Bool, status:TapEventStatus, expectedScaleNoteState:ScaleNoteState?, midi:Int, tapMidi:Int,
                amplDiff:Double, key:PianoKeyModel?) {
        self.tapNum = tapNum
        self.amplitude = amplitude
        self.ascending = ascending
        self.frequency = frequency
        self.status = status
        self.midi = midi
        self.expectedScaleNoteState = expectedScaleNoteState
        self.key = key
        self.amplDiff = amplDiff
        self.tapMidi = tapMidi
    }
    
    public static func == (lhs: TapEvent, rhs: TapEvent) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    func tapData() -> String {
        let amps = String(format: "%.2f", self.amplitude)
        //let ampDiff = String(format: "%.2f", self.amplDiff)
        //let row = "\(self.tapNum) P:\(self.onKeyboard) \tM:\(self.midi) \tAsc:\(self.ascending) \tKey:\(self.pressedKey) \t\tAmpl:\(amps)"
        let expected:Int = expectedScaleNoteState?.midi ?? 0

        var row = "M:\(self.midi),\(self.tapMidi) Exp:\(expected)"
        var status = "\(self.status)"
        status = String(status.prefix(12))
        row += "\tA:\(self.ascending ? 1:0) \(status)"
        //row += "\t\tAm:\(amps)\t▵:\(ampDiff)"
        row += "  Am:\(amps)"
        return row
    }
}

public class TapEventSet {
    var events:[TapEvent] = []
    
    func debug112() {
        for event in events {
            print(event.tapData())
        }
    }
    
    func minMax() -> String {
        var min = Double.infinity
        var minMidi = 0
        var max = 0.0
        var maxMidi = 0
        
        for event in events {
            if Double(event.amplitude) > max {
                max = Double(event.amplitude)
                maxMidi = event.midi
            }
            if event.amplitude > 0 {
                if Double(event.amplitude) < min {
                    min = Double(event.amplitude)
                    minMidi = event.midi
                }
            }
        }
        return "[MAX Ampl:\(String(format: "%.4f", max)) maxMidi:\(maxMidi)] [MIN Amp:\(String(format: "%.4f", min)) minMidi:\(minMidi)]    "
    }
}
