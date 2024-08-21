import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit

///The key parameter that determines the frequency at which the closure (handler) is called is the bufferSize.
///The bufferSize parameter specifies the number of audio samples that will be processed in each iteration before calling the closure with the detected pitch and amplitude values.
///By default, the bufferSize is set to 4096 samples. Assuming a typical sample rate of 44,100 Hz, this means that the closure will be called approximately 10.7 times per second (44,100 / 4096).
///To increase the frequency at which the closure is called, you can decrease the bufferSize value when initializing the PitchTap instance.

protocol TapHandlerProtocol {
    init(bufferSize:Int, scale:Scale?, amplitudeFilter:Double?)
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stopTappingProcess() -> TapEventSet
    func getBufferSize() -> Int
}

///Tap handlel to udate the model in real time as events are received
class RealTimeTapHandler : TapHandlerProtocol {
    let startTime:Date = Date()
    let bufferSize:Int
    let amplitudeFilter:Double?
    //let fromProcess:RunningProcess
    let minMidi:Int
    let maxMidi:Int
    var tapNum = 0
    //var hilightPlayingNotes:Bool
    var lastMidi:Int? = nil
    var lastMidiHiliteTime:Double? = nil
    var tapHandlerEventSet:TapEventSet
    
    required init(bufferSize:Int, scale:Scale? = nil, amplitudeFilter:Double?) {
        self.bufferSize = bufferSize
        self.amplitudeFilter = amplitudeFilter
        minMidi = ScalesModel.shared.scale.getMinMax().0
        maxMidi = ScalesModel.shared.scale.getMinMax().1
        tapNum = 0
        self.tapHandlerEventSet = TapEventSet(bufferSize: bufferSize, events: [])
    }
    
    func getBufferSize() -> Int {
        return self.bufferSize
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        let keyboardModel = PianoKeyboardModel.shared
        let scalesModel = ScalesModel.shared

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
        
        let aboveFilter =  self.amplitudeFilter == nil || amplitude > AUValue(self.amplitudeFilter!)
        let midi = Util.frequencyToMIDI(frequency: frequency)
        let ms = Int(Date().timeIntervalSince1970 * 1000) - Int(self.startTime.timeIntervalSince1970 * 1000)
        let secs = Double(ms) / 1000.0

        if aboveFilter {
            if let index = keyboardModel.getKeyIndexForMidi(midi: midi, direction: scalesModel.selectedDirection) {
                let keyboardKey = keyboardModel.pianoKeyModel[index]
                let hilightKey = true
                if hilightKey {
                    keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                    lastMidiHiliteTime = secs
                }
                lastMidi = keyboardKey.midi
            }
        }
        tapHandlerEventSet.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: frequency, amplitude: amplitude))
        tapNum += 1
    }
    
    func stopTappingProcess() -> TapEventSet {
        Logger.shared.log(self, "Practice tap handler recorded \(String(describing: tapHandlerEventSet.events.count)) tap events")
        return tapHandlerEventSet
    }
}
