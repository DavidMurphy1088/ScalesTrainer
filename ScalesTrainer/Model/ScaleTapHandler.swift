import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit
import Foundation

class ScaleTapHandler : TapHandlerProtocol  {
    let scalesModel = ScalesModel.shared
    let bufferSize:Int
    var eventNumber = 0
    var recordedTapEvents:[TapEvent]
    var startTappingTime:Date? = nil
    var startTappingAvgAmplitude:Float? = nil
    var startTappingAmplitudes:[Float] = []
    var noteAmplitudeHeardCount = 0
    var endTappingLowAmplitudeCount = 0
    
    required init(bufferSize:Int) {
        self.recordedTapEvents = []
        self.startTappingTime = nil
        self.bufferSize = bufferSize
    }
    
    func getBufferSize() -> Int {
        return self.bufferSize
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        var frequency:Float
        var amplitude:Float
        if amplitudes[0] > amplitudes[1] {
            frequency = frequencies[0]
            amplitude = amplitudes[0]
        }
        else {
            frequency = frequencies[1]
            amplitude = amplitudes[1]
        }
        let tapMidi = Util.frequencyToMIDI(frequency: frequency)
        let event = TapEvent(tapNum: eventNumber, frequency: frequency, amplitude: amplitude, ascending: true, status: .none,
                             expectedMidis: [], midi: 0, tapMidi: tapMidi, consecutiveCount: 1)
//        if eventNumber % 8 == 0 {
//            print("-------------------------------------- Tapped \(eventNumber) \(self.bufferSize) \(self.eventNumber) midi:\(tapMidi) \(amplitude)")
//        }
        self.recordedTapEvents.append(event)
        self.eventNumber += 1
        ///Try to figure out when the recording should stop without the user stopping it with a button push
        ///Wait for at least a few likely actual taps with enough amplitude
        if self.startTappingTime == nil {
            self.startTappingTime = Date()
        }
        if self.startTappingAvgAmplitude == nil {
            if startTappingAmplitudes.count < 20 {
                startTappingAmplitudes.append(amplitude)
            }
            else {
                let sum = startTappingAmplitudes.reduce(0, +)
                self.startTappingAvgAmplitude = sum / Float(startTappingAmplitudes.count)
            }
        }
        if amplitude > 0.02 {
            self.noteAmplitudeHeardCount += 1
        }

        if let startTime = self.startTappingTime {
            let seconds = Date().timeIntervalSince(startTime)
            if seconds > 4 {
                if self.noteAmplitudeHeardCount > 4 {
                    if let startingAmplitude = self.startTappingAvgAmplitude {
                        if amplitude < startingAmplitude {
                            endTappingLowAmplitudeCount += 1
                            if endTappingLowAmplitudeCount > 10 {
                                scalesModel.setRunningProcess(.none)
                            }
                        }
                        else {
                            endTappingLowAmplitudeCount = 0
                        }
                    }
                }
            }
        }
    }
    
    func stopTappingProcess() -> TapEventSet {
        let tapEventSet = TapEventSet(bufferSize: self.bufferSize, description: "")
        tapEventSet.events = self.recordedTapEvents
        return tapEventSet
    }
    
}
