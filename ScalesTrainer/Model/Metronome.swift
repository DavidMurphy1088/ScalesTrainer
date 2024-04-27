import Foundation
import Speech
import Combine

class MetronomeModel: ObservableObject {
    public static let shared = MetronomeModel()
    
    @Published private(set) var isRunning = false
    @Published var tempo: Int = 120 //90
    @Published private(set) var playingScale:Bool = false

    private let scalesModel = ScalesModel.shared
    private var timer: AnyCancellable?

    func playScale(scale:Scale) {
        DispatchQueue.main.async { [self] in
            playingScale = true
        }
        self.isRunning = true
        scalesModel.scale.resetPlayMidiStatus()
        DispatchQueue.global(qos: .background).async {
            let sampler = AudioManager.shared.midiSampler
            let delay = 60.0 / Double(self.tempo)
            //PianoKeyboardModel.shared.configureKeys(direction: 0)
            for ascendingDescending in 0..<2 {
                var start:Int
                var end:Int
                if ascendingDescending == 0 {
                    start = 0
                    end = scale.scaleNoteStates.count / 2
                }
                else {
                    start = (scale.scaleNoteStates.count / 2) + 1
                    end = scale.scaleNoteStates.count - 1
                }
                for s in start...end {
                    if !self.isRunning {
                        break
                    }
                    let state = scale.scaleNoteStates[s]
                    state.setPlayingMidi(true)
                    self.scalesModel.forceRepaint()
                    
                    sampler.play(noteNumber: UInt8(state.midi), velocity: 64, channel: 0)
                    let sleepDelay = 1000000 * delay
                    usleep(UInt32(sleepDelay))
                    sampler.stop(noteNumber: UInt8(state.midi), channel: 0)
                    state.setPlayingMidi(false)
                    self.scalesModel.forceRepaint()
                }
                self.scalesModel.setDirection(1)
                //PianoKeyboardModel.shared.configureKeys(direction: 1)
            }
            DispatchQueue.main.async { [self] in
                playingScale = false
            }
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
