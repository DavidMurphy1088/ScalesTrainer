import Foundation

public class TapEvent:Hashable {
    let id = UUID()
    let midi:Int ///The octave adjusted midi used for matching
    let tapMidi:Int ///The origianl taop midi
    let scaleSequence:Int? ///The scale sequence index
    let amplitude:Float
    let key:PianoKeyModel?
    let tapNum:Int
    let pressedKey:Bool
    let ascending:Bool
    let onKeyboard:Bool
    let amplDiff:Double

    public init(tapNum:Int, onKeyboard:Bool, scaleSequence:Int?, midi:Int, tapMidi:Int, amplitude:Float, pressedKey: Bool, amplDiff:Double, ascending: Bool, key:PianoKeyModel?) {
        self.tapNum = tapNum
        self.midi = midi
        self.scaleSequence = scaleSequence
        self.pressedKey = pressedKey
        self.amplitude = amplitude
        self.key = key
        self.ascending = ascending
        self.onKeyboard = onKeyboard
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
        let row = "P:\(self.onKeyboard ? 1:0) \tM:\(self.midi),\(self.tapMidi) \tAsc:\(self.ascending ? 1:0) \tKey:\(self.pressedKey ? 1:0)\t\tAm:\(amps)\t▵:\(ampDiff)"
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
