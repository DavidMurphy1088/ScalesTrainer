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
    var tapNum = 0
    var tapHandlerEventSet:TapEventSet
    //var handIndex:Int
    var scale:Scale
    
    required init(bufferSize:Int, scale:Scale, amplitudeFilter:Double?) {
        self.bufferSize = bufferSize
        self.amplitudeFilter = amplitudeFilter
        tapNum = 0
        self.tapHandlerEventSet = TapEventSet(bufferSize: bufferSize, events: [])
        self.scale = scale
    }
    
    func getBufferSize() -> Int {
        return self.bufferSize
    }
    
    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        class PossibleKeyPlayed {
            let hand:Int
            let keyIndex: Int
            let inScale:Bool
            init(hand:Int, keyIndex:Int, inScale:Bool) {
                self.hand = hand
                self.keyIndex = keyIndex
                self.inScale = inScale
            }
        }
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
        
        if aboveFilter {
            var keyboards:[PianoKeyboardModel] = []
            if [0,2].contains(self.scale.hand) {
                keyboards.append(PianoKeyboardModel.sharedRightHand)
            }
            if [1,2].contains(self.scale.hand) {
                keyboards.append(PianoKeyboardModel.sharedLeftHand)
            }
            
            ///hand, keyboard key index, inScale
            var possibleKeysPlayed:[PossibleKeyPlayed] = []
            for i in 0..<keyboards.count{
                let keyboard = i == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
                if let index = keyboard.getKeyIndexForMidi(midi: midi, direction: scalesModel.selectedDirection) {
                    let inScale = scale.getStateForMidi(handIndex: keyboard.hand, midi: midi, direction: 0) != nil
                    possibleKeysPlayed.append(PossibleKeyPlayed(hand: keyboard.hand, keyIndex: index, inScale: inScale))
                }
            }
            if possibleKeysPlayed.count > 0 {
                //print("==============TAP:", tapNum, midi, "notes:", playedNotes)
                if keyboards.count == 1 {
                    let keyboard = keyboards[0]
                    let keyboardKey = keyboard.pianoKeyModel[possibleKeysPlayed[0].keyIndex]
                    keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                }
                else {
                    if let inScale = possibleKeysPlayed.first(where: { $0.inScale == true}) {
                        ///New option for scale Leacd in? - For all keys played show the played status only on one keyboard - RH or LH, not both
                        ///Find the first keyboard where the key played is in the scale. If found, hilight it on just that keyboard
                        let possibleKeyCount = possibleKeysPlayed.filter { $0.inScale == true }.count
                        for possibleKey in possibleKeysPlayed {
                            let keyboard = possibleKey.hand == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
                            let keyboardKey = keyboard.pianoKeyModel[possibleKey.keyIndex]
                            keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                        }
                    }
                    else {
                        ///Find the keyboard where the key played is not in the scale. If found, hilight it on just that keyboard
                        if let outOfScale = possibleKeysPlayed.first(where: { $0.inScale == false}) {
                            let keyboard = outOfScale.hand == 0 ? PianoKeyboardModel.sharedRightHand : PianoKeyboardModel.sharedLeftHand
                            let keyboardKey = keyboard.pianoKeyModel[outOfScale.keyIndex]
                            keyboardKey.setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
                        }
                    }
                }
            }
                
        }
        tapHandlerEventSet.events.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: frequency, amplitude: amplitude))
        tapNum += 1
    }
    
    func stopTappingProcess() -> TapEventSet {
        Logger.shared.log(self, "RealTime tap handler recorded \(String(describing: tapHandlerEventSet.events.count)) tap events")
        return tapHandlerEventSet
    }
}
