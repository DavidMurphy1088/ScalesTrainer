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
    let amplitudeFilter:Double?
    let scale:Scale?
    let handIndex: Int
    var eventNumber = 0
    var recordedTapEvents:[TapEvent]
    var lastTappedTime:Date? = nil
    var lastTappedMidi = 0

    var midisInScale:[Int] = []
    var firstQuietTime:Date? = nil
    
    required init(bufferSize:Int, scale:Scale, handIndex:Int, amplitudeFilter:Double?) {
        self.recordedTapEvents = []
        self.bufferSize = bufferSize
        self.scale = scale
        self.handIndex = handIndex
        self.amplitudeFilter = amplitudeFilter
        midisInScale = scale.getMidisInScale(handIndex: handIndex)
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
        let event = TapEvent(tapNum: eventNumber, consecutiveCount: 1, frequency: frequency, amplitude: amplitude)
        self.recordedTapEvents.append(event)
        self.eventNumber += 1
        
        if false {
            if midisInScale.count > 0 && lastTappedMidi == midisInScale[0] {
                if let firstQuietTime = firstQuietTime {
                    let quietLen = Date().timeIntervalSince1970 - firstQuietTime.timeIntervalSince1970
                    if quietLen > 3 {
                        scalesModel.setRunningProcess(.none)
                    }
                }
            }
            
            if let amplitudeFilter = amplitudeFilter {
                if amplitude < Float(amplitudeFilter) {
                    if firstQuietTime == nil {
                        firstQuietTime = Date()
                    }
                }
                else {
                    firstQuietTime = nil
                }
            }
            if midisInScale.contains(tapMidi) {
                self.lastTappedMidi = tapMidi
            }
        }
        self.lastTappedTime = Date()
    }
    
    func stopTappingProcess() -> TapEventSet {
        let tapEventSet = TapEventSet(bufferSize: self.bufferSize, events: self.recordedTapEvents)
        return tapEventSet
    }
    
}
