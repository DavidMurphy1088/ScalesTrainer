import Foundation
import Speech
import Combine

class MetronomeModel: ObservableObject {
    public static let shared = MetronomeModel()
    @Published var isRunning = false
    @Published var tempo: Int = 40 //90
    @Published var playingScale:Bool = false

    var timer: AnyCancellable?

    func playScale(scale:Scale) {
        DispatchQueue.main.async { [self] in
            playingScale = true
        }
        self.isRunning = true
        DispatchQueue.global(qos: .background).async {
            scale.scaleNoteStates[0].setPlayingMidi(true)
//            let sampler = AudioManager.shared.midiSampler
//            let delay = 60.0 / Double(self.tempo)
//            for state in scale.scaleNoteStates {
//                if !self.isRunning {
//                    break
//                }
//                state.setPlayingMidi(true)
//                sampler.play(noteNumber: UInt8(state.midi), velocity: 64, channel: 0)
//                let sleepDelay = 1000000 * delay
//                usleep(UInt32(sleepDelay))
//                sampler.stop(noteNumber: UInt8(state.midi), channel: 0)
//            }
//            DispatchQueue.main.async { [self] in
//                playingScale = false
//            }
        }
    }
    
    func start(tickCall:@escaping () -> Void) {
        isRunning = true
        timer = Timer.publish(every: 60.0 / Double(tempo), on: .main, in: .common).autoconnect()
            .sink { _ in
                //tickCall()
                print("Tick at \(self.tempo) BPM")
            }
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }
}
