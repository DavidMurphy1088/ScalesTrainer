
import Foundation

class HearUserScale : MetronomeTimerNotificationProtocol {
    var direction = 0
    var nextKeyToPlay = 0
    var maxMidi = 0
    let keyboard = PianoKeyboardModel.sharedRightHand
    
    func metronomeStart() {
        for i in 0..<keyboard.pianoKeyModel.count {
            if keyboard.pianoKeyModel[i].keyWasPlayedState.tappedTimeAscending != nil {
                let key = keyboard.pianoKeyModel[i]
                if key.midi > maxMidi {
                    maxMidi = key.midi
                }
            }
        }
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        let audioManager = AudioManager.shared
        let sampler = audioManager.keyboardMidiSampler
        
        var key:PianoKeyModel? = nil
        ///Playing the user's scale
        
        if direction == 0 {
            while nextKeyToPlay <  keyboard.pianoKeyModel.count {
                if keyboard.pianoKeyModel[nextKeyToPlay].keyWasPlayedState.tappedTimeAscending != nil {
                    key = keyboard.pianoKeyModel[nextKeyToPlay]
                    if key?.midi == maxMidi {
                        nextKeyToPlay -= 1
                        direction = 1
                        ScalesModel.shared.setSelectedDirection(1)
                    }
                    else {
                        nextKeyToPlay += 1
                    }
                    break
                }
                nextKeyToPlay += 1
            }
        }
        else {
            while nextKeyToPlay >= 0 {
                if keyboard.pianoKeyModel[nextKeyToPlay].keyWasPlayedState.tappedTimeDescending != nil {
                    key = keyboard.pianoKeyModel[nextKeyToPlay]
                    nextKeyToPlay -= 1
                    break
                }
                nextKeyToPlay -= 1
            }

        }
        if let key = key {
            key.setKeyPlaying(ascending: direction, hilight: true)
            sampler?.play(noteNumber: UInt8(key.midi), velocity: 64, channel: 0)
        }
        //return true
        return key == nil
    }
    
    func metronomeStop() {
        ScalesModel.shared.setSelectedDirection(0)
    }
    
}
