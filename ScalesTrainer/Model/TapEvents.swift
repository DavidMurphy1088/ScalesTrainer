import Foundation

//public enum TapEventStatus1 {
//    case none
//    case info
//    
//    case pressWithoutScaleMatch
//    
//    ///Pressed the expected next note
//    case pressNextScaleMatch
//    
//    ///Pressed note 1 further on than the one expected
//    case pressFollowingScaleMatch
//    
//    ///Pressed wrong note but wait for one more wrong before reporting it. The singleton supposed error maybe only a harmonic
//    case wrongButWaitForNext
//    
//    case continued
//    case farFromExpected
//    case pastEndOfScale
//    case belowAmplitudeFilter
//    case beforeScaleStart
//    case keyNotOnKeyboard
//    case outsideScale
//    case singleton
//
//}
public enum TapEventStatus {
    case none
    case info
    case keyPressed
    case sameMidiContinued
    case belowAmplitudeFilter
    case beforeScaleStart
    case afterScaleEnd
    //case keyNotOnKeyboard
    //case outsideScale
    case waitForMore
    
    ///Practice TapHandlet
    //case farFromExpected
    //case pastEndOfScale
}

public class TapEvent:Hashable {
    let id = UUID()
    var timestamp:Date
    let tapNum:Int
    let amplitude:Float
    let frequency:Float
    
    let midi:Int? ///The octave adjusted midi used for matching
    let status:TapEventStatus
    let tapMidi:Int ///The origianl tap midi
    let expectedMidis:[Int]
    let ascending:Bool
    let infoMsg:String?
    var consecutiveCount:Int
    
    public init(tapNum:Int, frequency:Float, amplitude:Float, ascending:Bool, status:TapEventStatus,
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
    
    public init(tap:TapEvent) {
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
        self.status = TapEventStatus.info
        self.expectedMidis = []
        self.tapMidi = 0
        self.infoMsg = infoMsg
        self.consecutiveCount = 0
    }
    
    public static func == (lhs: TapEvent, rhs: TapEvent) -> Bool {
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
//        }
//        else {
//            row += "  Count _"
//        }
        //row += midi == nil ? "  " : "**"
        
        var status = "  \(self.status)"
        status = String(status.prefix(12))
        row += "   A:\(self.ascending ? 1:0)   \(status)"
        //row += "\t\tAm:\(amps)\t▵:\(ampDiff)"
        let amps = String(format: "%.2f", self.amplitude)
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
    let description:String
    var events:[TapEvent] = []
    
    init(bufferSize:Int, description:String) {
        self.bufferSize = bufferSize
        self.description = description
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
    
//    func debug(_ ctx:String) {
//        print(" TapEventSet", ctx)
//        for event in self.events {
//            print(event.tapData())
//        }
//    }
}
