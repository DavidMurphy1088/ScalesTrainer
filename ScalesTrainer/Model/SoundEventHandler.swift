import AudioKit
import SoundpipeAudioKit
import AVFoundation
import Foundation
import AudioKitEX
import Foundation
import UIKit

protocol SoundEventHandlerProtocol {
//    init(scale:Scale)
//    func setFunctionToNotify(functionToNotify: @escaping (Int, TapEventStatus) -> Void)
    func setFunctionToNotify(functionToNotify: ((Int) -> Void)?)
    func start()
    func stop()
}

class SoundEventHandler  {
    let scale:Scale
    
    ///The feature function that is called when a new MIDI notification arrives
    //var functionToNotify: ((Int, TapEventStatus) -> Void)?
    var functionToNotify: ((Int) -> Void)?

    required init(scale: Scale) {
        self.scale = scale
    }
    
    func setFunctionToNotify(functionToNotify: ((Int) -> Void)?) {
        self.functionToNotify = functionToNotify
    }
    
    func stop() {
    }
    
    ///Determine if the midi represents a keyboard key.
    ///If its a key hilight and sound the key.
    func hilightKeysAndStaff(midi:Int) {
        class PossibleKeyPlayed {
            let keyboard:PianoKeyboardModel
            let keyIndex: Int
            let inScale:Bool
            init(keyboard:PianoKeyboardModel, keyIndex:Int, inScale:Bool) {
                self.keyIndex = keyIndex
                self.inScale = inScale
                self.keyboard = keyboard
            }
        }

        let scalesModel = ScalesModel.shared
        var keyboards:[PianoKeyboardModel] = []
        if self.scale.getKeyboardCount() == 1 {
            let keyboard = self.scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
            keyboards.append(keyboard)
        }
        else {
            if let combinedKeyboard = PianoKeyboardModel.sharedCombined {
                keyboards.append(combinedKeyboard)
            }
            else {
                keyboards.append(PianoKeyboardModel.sharedLH)
                keyboards.append(PianoKeyboardModel.sharedRH)
            }
        }

        ///A MIDI heard may be in both the LH and RH keyboards.
        ///Determine which keyboard the MIDI was played on
        var possibleKeysPlayed:[PossibleKeyPlayed] = []
        for i in 0..<keyboards.count {
            let keyboard = keyboards[i]
            if let index = keyboard.getKeyIndexForMidi(midi: midi, segment: scalesModel.selectedScaleSegment) {
                let handType = keyboard.keyboardNumber - 1 == 0 ? HandType.right : HandType.left
                //let inScale = scale.getStateForMidi(handIndex: keyboard.keyboardNumber - 1, midi: midi, scaleSegment: scalesModel.selectedScaleSegment) != nil
                let inScale = scale.getStateForMidi(handType: handType, midi: midi, scaleSegment: scalesModel.selectedScaleSegment) != nil
                possibleKeysPlayed.append(PossibleKeyPlayed(keyboard: keyboard, keyIndex: index, inScale: inScale))
            }
        }
        
        if possibleKeysPlayed.count > 0 {
            if keyboards.count == 1 {
                let keyboard = keyboards[0]
                let keyboardKey = keyboard.pianoKeyModel[possibleKeysPlayed[0].keyIndex]
                keyboardKey.setKeyPlaying()
            }
            else {
                if possibleKeysPlayed.first(where: {$0.inScale == true}) == nil {
                    ///Note played not in the scale
                    ///Find the keyboard where the key played is not in the scale. If found, hilight it on just that keyboard
                    if let outOfScale = possibleKeysPlayed.first(where: { $0.inScale == false}) {
                        let keyboard = outOfScale.keyboard
                        let keyboardKey = keyboard.pianoKeyModel[outOfScale.keyIndex]
                        keyboardKey.setKeyPlaying()
                    }
                }
                else {
                    ///Note played is in the scale
                    ///New option for scale Lead in? - For all keys played show the played status only on one keyboard - RH or LH, not both
                    ///Find the first keyboard where the key played is in the scale. If found, hilight it on just that keyboard
                    for possibleKey in possibleKeysPlayed {
                        let keyboard = possibleKey.keyboard
                        let keyboardKey = keyboard.pianoKeyModel[possibleKey.keyIndex]
                        keyboardKey.setKeyPlaying()
                    }
                }
            }
        }
    }
}

class AcousticSoundEventHandler : SoundEventHandler, SoundEventHandlerProtocol {
    let bufferSize = 4096
    var consecutiveCount = 0
    let amplitudeFilter = Settings.shared.amplitudeFilter
    class LastPlayedKey {
        let midi:Int
        let time:Date
        init(midi:Int) {
            self.midi = midi
            self.time = Date()
        }
    }
    var lastPlayedKey:LastPlayedKey? = nil
    
    required init(scale:Scale) {
        super.init(scale: scale)
    }
    
    func getBufferSize() -> Int {
        return self.bufferSize
    }
    
    func start() {
        consecutiveCount = 0
    }

    func tapUpdate(_ frequencies: [AudioKit.AUValue], _ amplitudes: [AudioKit.AUValue]) {
        var tapStatus:TapEventStatus = .none
        //let scalesModel = ScalesModel.shared
        
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
        
        let aboveFilter =  amplitude > AUValue(self.amplitudeFilter)
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
        
//        if [.belowAmplitudeFilter, .countTooLow].contains(status) {
//            return
//        }

        if tapStatus == .none {
            self.hilightKeysAndStaff(midi: midi)
            if let notify = self.functionToNotify {
                //notify(midi, .inScale)
                notify(midi)
            }
        }
    }
}

class MIDISoundEventHandler : SoundEventHandler, SoundEventHandlerProtocol {
    func start() {
        let midiManager = MIDIManager.shared
        midiManager.installNotificationTarget(target: self.MIDIManagerNotificationTarget(msg:))
        if let testMidiNotes = midiManager.testMidiNotes {
            if testMidiNotes.scaleId == self.scale.id {
                self.sendTestMidiNotes(notes: testMidiNotes)
            }
        }
    }

    ///Call the feature function that is specified when a new MIDI notification arrives
    func MIDIManagerNotificationTarget(msg:MIDIMessage) {
        //print("========== Handler NotificationTarget", msg.midi)
        if let notify = self.functionToNotify {
            notify(msg.midi)
        }
    }
    
    func sendTestMidiNotes(notes:TestMidiNotes) {
        Logger.shared.log(self, "sending NoteSets \(notes) notify:\(self.functionToNotify != nil)")
        if let notify = self.functionToNotify {
            DispatchQueue.global(qos: .background).async {
                for noteSet in notes.noteSets {
                    DispatchQueue.main.async {
                        for note in noteSet.notes {
                            notify(note)
                        }
                        usleep(UInt32(0.2 * 1000000))
                    }
                    let noteSetDelay = UInt32(1000000 * notes.noteSetWait)
                    usleep(noteSetDelay)
                }
            }
        }
    }
}
