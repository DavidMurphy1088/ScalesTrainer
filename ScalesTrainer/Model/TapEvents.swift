import Foundation

public class TapEvent:Hashable {
    let id = UUID()
    let midi:Int
    let amplitude:Float
    let key:PianoKeyModel?
    let tapNum:Int
    
    public init(tapNum:Int, midi:Int, amplitude:Float, key:PianoKeyModel?) {
        self.tapNum = tapNum
        self.midi = midi
        self.amplitude = amplitude
        self.key = key
    }
    
    public static func == (lhs: TapEvent, rhs: TapEvent) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    func tapData() -> String {
        let amps = String(format: "%.4f", self.amplitude)
        let row = "\(self.tapNum) \tMidi:\(self.midi) \tAmpl:\(amps)"
        return row
    }
}

public class TapEvents {
    var event:[TapEvent] = []
    
    func debug() {
        for event in event {
            print(event.tapData())
        }
    }
}
