import Foundation

public enum TapEventStatus {
    case causedKeyPressWithoutScaleMatch
    case causedKeyPressWithScaleMatch
    case continued
    case farFromExpected
    case pastEndOfScale
    case keyNotOnKeyboard
}

public class TapEvent:Hashable {
    let id = UUID()
    let midi:Int ///The octave adjusted midi used for matching
    let status:TapEventStatus
    let tapMidi:Int ///The origianl taop midi
    let expectedScaleNoteState:ScaleNoteState? ///The scale sequence index
    let amplitude:Float
    let key:PianoKeyModel?
    let tapNum:Int
    let ascending:Bool
    let amplDiff:Double

    public init(tapNum:Int, status:TapEventStatus, expectedScaleNoteState:ScaleNoteState?, midi:Int, tapMidi:Int, amplitude:Float,
                amplDiff:Double, ascending: Bool, key:PianoKeyModel?) {
        self.tapNum = tapNum
        self.status = status
        self.midi = midi
        self.expectedScaleNoteState = expectedScaleNoteState
        self.amplitude = amplitude
        self.key = key
        self.ascending = ascending
        
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
        let ampDiff = String(format: "%.2f", self.amplDiff)
        //let row = "\(self.tapNum) P:\(self.onKeyboard) \tM:\(self.midi) \tAsc:\(self.ascending) \tKey:\(self.pressedKey) \t\tAmpl:\(amps)"
        var row = "M:\(self.midi),\(self.tapMidi) \tAsc:\(self.ascending ? 1:0) \t\(self.status)"
        let expected:Int = expectedScaleNoteState?.midi ?? 0
        row += "\tExpect:\(expected)"
        row += "\t\tAm:\(amps)\t▵:\(ampDiff)"
        return row
    }
}

public class TapEvents {
    var event:[TapEvent] = []
    
    func debug11() {
        for event in event {
            print(event.tapData())
        }
    }
}
