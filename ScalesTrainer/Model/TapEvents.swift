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
    case discardedSingleton
    
    ///Practice TapHandlet
    //case farFromExpected
    //case pastEndOfScale
}

public class TapEvent:Hashable {
    let id = UUID()
    var timestamp = Date()
    let tapNum:Int
    let amplitude:Float
    let frequency:Float
    
    let midi:Int ///The octave adjusted midi used for matching
    let status:TapEventStatus
    let tapMidi:Int ///The origianl taop midi
    let expectedScaleNoteStates:[ScaleNoteState]?
    let ascending:Bool
    let infoMsg:String?
    
    public init(tapNum:Int, frequency:Float, amplitude:Float, ascending:Bool, status:TapEventStatus,
                expectedScaleNoteStates:[ScaleNoteState]?, midi:Int, tapMidi:Int) {
        self.tapNum = tapNum
        self.amplitude = amplitude
        //self.ascending = ascending
        self.frequency = frequency
        self.status = status
        self.midi = midi
        self.expectedScaleNoteStates = expectedScaleNoteStates
        //self.key = key
        self.tapMidi = tapMidi
        self.infoMsg = nil
        self.ascending = ascending
    }
    
    public init(infoMsg:String) {
        self.tapNum = 0
        self.amplitude = 0
        self.ascending = true
        self.frequency = 0
        self.midi = 0
        self.status = TapEventStatus.info
        self.expectedScaleNoteStates = nil
        //self.key = nil
        self.tapMidi = 0
        self.infoMsg = infoMsg
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
        var row = "" //[\(self.tapNum)] "
        if let expectedScaleNoteStates = expectedScaleNoteStates {
            if expectedScaleNoteStates.count > 0 {
                row += "Expect:\(expectedScaleNoteStates[0].midi)"
            }
        }
        row += " Use:\(self.midi)"
        row += " Tap:\(self.tapMidi)"
        
        var status = "\(self.status)"
        status = String(status.prefix(12))
        row += "\tA:\(self.ascending ? 1:0) \(status)"
        //row += "\t\tAm:\(amps)\t▵:\(ampDiff)"
        let amps = String(format: "%.4f", self.amplitude)
        row += "  Amp:\(amps)"
        return row
    }
}

public class TapEventSet {
    let amplitudeFilter:Double
    let description:String
    var events:[TapEvent] = []
    
    init(amplitudeFilter:Double, description:String) {
        self.amplitudeFilter = amplitudeFilter
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
                    maxMidi = event.midi
                }
                if event.amplitude > 0 {
                    if Double(event.amplitude) < min {
                        min = Double(event.amplitude)
                        minMidi = event.midi
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
