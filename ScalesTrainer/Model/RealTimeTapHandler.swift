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
    init(bufferSize:Int, scale:Scale, amplitudeFilter:Double?)
    func tapUpdate(_ frequency: [AUValue], _ amplitude: [AUValue])
    func stopTappingProcess() -> TapEventSet
    func getBufferSize() -> Int
}

///Tap handler to udate the model in real time as events are received
class RealTimeTapHandler : TapHandlerProtocol {
    let startTime:Date = Date()
    let bufferSize:Int
    let amplitudeFilter:Double?
    var tapHandlerEventSet:TapEventSet
    var scale:Scale
    var tapNum = 0
    var consecutiveCount = 0
    var ascending = true
    var notifyFunction: ((Int, TapEventStatus ) -> Void)?
    
    class LastPlayedKey {
        let midi:Int
        let time:Date
        init(midi:Int) {
            self.midi = midi
            self.time = Date()
        }
    }
    var lastPlayedKey:LastPlayedKey? = nil
    
    required init(bufferSize:Int, scale:Scale, amplitudeFilter:Double?) {
        self.bufferSize = bufferSize
        self.amplitudeFilter = amplitudeFilter
        tapNum = 0
        self.tapHandlerEventSet = TapEventSet(bufferSize: bufferSize, events: [])
        self.scale = scale
        lastPlayedKey = nil
    }
    
    func getBufferSize() -> Int {
        return self.bufferSize
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        class PossibleKeyPlayed {
            let keyboard:PianoKeyboardModel
            let keyIndex: Int
            let inScale:Bool
            init(keyboard:PianoKeyboardModel, keyIndex:Int, inScale:Bool) {
                //self.hand = hand
                self.keyIndex = keyIndex
                self.inScale = inScale
                self.keyboard = keyboard
            }
        }
        var tapStatus:TapEventStatus = .none
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
        
        if aboveFilter {
            if [.belowAmplitudeFilter, .outsideRange].contains(tapStatus) {
                consecutiveCount = 0
            }
            if let lastPlayedKey = lastPlayedKey {
                //if midi % 12 == lastPlayedKey.midi % 12 {
                if midi == lastPlayedKey.midi {
                    consecutiveCount += 1
                }
                else {
                    consecutiveCount = 0
                }
            }
            
            if consecutiveCount < Settings.shared.requiredConsecutiveCount - 1 {
                tapStatus = .countTooLow
            }
            lastPlayedKey = LastPlayedKey(midi: midi)
        }
        else {
            tapStatus = .belowAmplitudeFilter
        }
        
        ///Determine if the midi represents a keyboard key.
        ///Hilight the keyboard key
        if tapStatus == .none {
            var keyboards:[PianoKeyboardModel] = []
            if self.scale.getKeyboardCount() == 1 {
                let keyboard = self.scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                keyboards.append(keyboard)
            }
            else {
                keyboards.append(PianoKeyboardModel.sharedLH)
                keyboards.append(PianoKeyboardModel.sharedRH)
            }
            
            ///A played MIDI may be in both the LH and RH keyboards.
            ///Determine which keyboard the MIDI was played on
            var possibleKeysPlayed:[PossibleKeyPlayed] = []
            for i in 0..<keyboards.count {
                let keyboard = keyboards[i]
                if let index = keyboard.getKeyIndexForMidi(midi: midi, direction: scalesModel.selectedDirection) {
                    let inScale = scale.getStateForMidi(handIndex: keyboard.keyboardNumber - 1, midi: midi, direction: 0) != nil
                    possibleKeysPlayed.append(PossibleKeyPlayed(keyboard: keyboard, keyIndex: index, inScale: inScale))
                }
            }
            
            if possibleKeysPlayed.count > 0 {
                if keyboards.count == 1 {
                    let keyboard = keyboards[0]
                    let keyboardKey = keyboard.pianoKeyModel[possibleKeysPlayed[0].keyIndex]
                    keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                    if possibleKeysPlayed[0].inScale {
                        tapStatus = .inScale
                    }
                    else {
                        tapStatus = .outOfScale
                    }
                }
                else {
                    if let inScale = possibleKeysPlayed.first(where: { $0.inScale == true}) {
                        ///New option for scale Leacd in? - For all keys played show the played status only on one keyboard - RH or LH, not both
                        ///Find the first keyboard where the key played is in the scale. If found, hilight it on just that keyboard
                        //let possibleKeyCount = possibleKeysPlayed.filter { $0.inScale == true }.count
                        for possibleKey in possibleKeysPlayed {
                            let keyboard = possibleKey.keyboard
                            let keyboardKey = keyboard.pianoKeyModel[possibleKey.keyIndex]
                            keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                        }
                        tapStatus = .inScale
                    }
                    else {
                        ///Find the keyboard where the key played is not in the scale. If found, hilight it on just that keyboard
                        if let outOfScale = possibleKeysPlayed.first(where: { $0.inScale == false}) {
                            let keyboard = outOfScale.keyboard
                            let keyboardKey = keyboard.pianoKeyModel[outOfScale.keyIndex]
                            keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                        }
                        tapStatus = .outOfScale
                    }
                }
            }
        }
        if let notifyFunction = notifyFunction {
            notifyFunction(midi, tapStatus)
        }
        tapHandlerEventSet.events.append(TapEvent(tapNum: tapNum, consecutiveCount: consecutiveCount, frequency: frequency, amplitude: amplitude,
                                                  status: tapStatus))
        tapNum += 1
    }
    
    func stopTappingProcess() -> TapEventSet {
        Logger.shared.log(self, "RealTime tap handler recorded \(String(describing: tapHandlerEventSet.events.count)) tap events")
        return tapHandlerEventSet
    }
}
