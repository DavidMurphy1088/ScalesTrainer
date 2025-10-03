import Foundation

public enum TapEventStatus {
    case none
    case belowAmplitudeFilter
    case outsideRange ///To far from the last key pressed. Probable frequency overtone
    case countTooLow
    case inScale
    case outOfScale
}

///The raw tap events collected by a tap handler.
///May also be compressed events where duplicate tap events are compressed into a single record. i.e. consecutiveCount > 1
public class TapEvent : Hashable, Identifiable  {
    public let id = UUID()
    var timestamp:Date
    let tapNum:Int
    var consecutiveCount:Int
    var amplitude:Float
    let frequency:Float
    let tapMidi:Int
    let status:TapEventStatus
    
    public init(tapNum:Int, consecutiveCount:Int, frequency:Float, amplitude:Float, status:TapEventStatus) {
        self.timestamp = Date()
        self.tapNum = tapNum
        self.consecutiveCount = consecutiveCount
        self.amplitude = amplitude
        self.frequency = frequency
        self.tapMidi = Util.frequencyToMIDI(frequency: frequency)
        self.status = status
    }
    
    public static func == (lhs: TapEvent, rhs: TapEvent) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func tapData() -> String {
        var row = "  "
        row += "    #:\(tapNum)"
        row += "    M:\(tapMidi)"
        row += "    Cnt:\(self.consecutiveCount)"
        let amps = String(format: "%.4f", self.amplitude)
        row += "   Amp:\(amps)"
        row += "   Status:\(status)"
        return row
    }
}

public enum TapRecordStatus {
    case none
    case info
    case keyPressed
    case sameMidiContinued
    case beforeScaleStart
    case afterScaleEnd
    case waitForMore
    
    ///TapEvents
    case belowAmplitudeFilter
    case outsideRange ///To far from the last key pressed. Probable frequency overtone
}

///The status of a tap event after processing
public class TapStatusRecord:Hashable {
    let id = UUID()
    var timestamp:Date
    let tapNum:Int
    let amplitude:Float
    let frequency:Float
    
    let tapMidi:Int ///The origianl tap midi
    let midi:Int? ///The octave adjusted midi used for matching
    let status:TapRecordStatus
    let expectedMidis:[Int]
    let ascending:Bool
    let infoMsg:String?
    var consecutiveCount:Int
    
    public init(tapNum:Int, frequency:Float, amplitude:Float, ascending:Bool, status:TapRecordStatus,
                expectedMidis:[Int], midi:Int?, tapMidi:Int, consecutiveCount:Int) {
        self.timestamp = Date()
        self.tapNum = tapNum
        self.amplitude = amplitude
        self.frequency = frequency
        self.status = status
        self.midi = midi
        self.expectedMidis = expectedMidis
        self.tapMidi = tapMidi
        self.infoMsg = nil
        self.ascending = ascending
        self.consecutiveCount = consecutiveCount
    }
    
    public init(tap:TapStatusRecord) {
        self.timestamp = tap.timestamp
        self.tapNum = tap.tapNum
        self.amplitude = tap.amplitude
        self.frequency = tap.frequency
        self.status = tap.status
        self.midi = tap.midi
        self.expectedMidis = tap.expectedMidis
        self.tapMidi = tap.tapMidi
        self.infoMsg = nil
        self.ascending = tap.ascending
        self.consecutiveCount = tap.consecutiveCount
    }
    
    public init(infoMsg:String) {
        self.timestamp = Date()
        self.tapNum = 0
        self.amplitude = 0
        self.ascending = true
        self.frequency = 0
        self.midi = nil
        self.status = TapRecordStatus.info
        self.expectedMidis = []
        self.tapMidi = 0
        self.infoMsg = infoMsg
        self.consecutiveCount = 0
    }
    
    public static func == (lhs: TapStatusRecord, rhs: TapStatusRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    func tapData() -> String {
        if self.status == .info {
            return self.infoMsg ?? "No info"
        }
        var row = "  "

        if expectedMidis.count == 0 {
            row += "Expect:__"
        }
        else {
            row += "Expect:\(String(expectedMidis[0]))"
        }
        let midi = self.midi == nil ? "00" : String(self.midi!)
        row += "    Midi:\(midi)"
        row += "    Tap:\(self.tapMidi)"
        //if let count = self.consecutiveCount {
        row += "    Count:\(self.consecutiveCount)"
        
        var status = "  \(self.status)"
        status = String(status.prefix(12))
        row += "   A:\(self.ascending ? 1:0)   \(status)"
        //row += "\t\tAm:\(amps)\t▵:\(ampDiff)"
        let amps = String(format: "%.4f", self.amplitude)
        row += "   Amp:\(amps)"
        
//        let minLength = 50
//        let paddingCount = minLength - row.count
//        let padding = String(repeating: "_", count: paddingCount)
//        let paddedString = row + padding
        return row
    }
}

public class TapEventSet {
    let bufferSize:Int
    var events:[TapEvent] = []
    
    init(bufferSize:Int, events:[TapEvent]) {
        self.bufferSize = bufferSize
        self.events = events
    }
    
    func debug11(_ ctx:String) {
        print(" ======== DEBUG TapEventSet", ctx)
        for event in self.events {
            print(event.tapNum, "time:", event.timestamp, ",", event.amplitude, ",", event.frequency, ",", event.tapMidi)
        }
    }
    
    func eventsOutOfScale() -> [TapEvent] {
        var result:[TapEvent] = []
        for event in self.events {
            if event.status == .none {
                result.append(event)
            }
        }
        return result
    }
}

public class TapStatusRecordSet {
    let description:String
    var events:[TapStatusRecord]
    
    init(description:String, events:[TapStatusRecord]) {
        self.description = description
        self.events = events
    }
        
    func minMax() -> String {
        var min = Double.infinity
        var minMidi = 0
        var max = 0.0
        var maxMidi = 0
        
        for event in events {
            if event.status == .keyPressed {
                if Double(event.amplitude) > max {
                    max = Double(event.amplitude)
                    if let midi = event.midi {
                        maxMidi = midi
                    }
                }
                if event.amplitude > 0 {
                    if Double(event.amplitude) < min {
                        min = Double(event.amplitude)
                        if let midi = event.midi {
                            minMidi = midi
                        }
                    }
                }
            }
        }
        return "[Correct-MaxA:\(String(format: "%.4f", max)) midi:\(maxMidi)] [MinA:\(String(format: "%.4f", min)) midi:\(minMidi)]"
    }
    
    func debug3(_ ctx:String) {
        print(" TapEventSet", ctx)
        for event in self.events {
            print(event.tapData())
        }
    }
}
