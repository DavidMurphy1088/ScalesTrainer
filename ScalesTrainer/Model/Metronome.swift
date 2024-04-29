import Foundation
import Speech
import Combine
import Accelerate
import AVFoundation

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
        DispatchQueue.global(qos: .background).async { [self] in
            let originalDirection = scalesModel.selectedDirection
            let sampler = AudioManager.shared.midiSampler
            let delay = 60.0 / Double(self.tempo)
            PianoKeyboardModel.shared.mapPianoKeysToScaleNotes(direction: 0)
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
                    let scaleNote = scale.scaleNoteStates[s]
                    scaleNote.setPlayingMidi(true)
                    self.scalesModel.forceRepaint()
                    sampler.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
                    let sleepDelay = 1000000 * delay
                    usleep(UInt32(sleepDelay))
                    sampler.stop(noteNumber: UInt8(scaleNote.midi), channel: 0)
                    scaleNote.setPlayingMidi(false)
                }
                self.scalesModel.setDirection(1)
                ///Remap since finger number breaks will occur
                PianoKeyboardModel.shared.mapPianoKeysToScaleNotes(direction: 1)
                self.scalesModel.forceRepaint()
                scalesModel.scale.debug("======= Turnaround")
            }
            DispatchQueue.main.async { [self] in
                PianoKeyboardModel.shared.mapPianoKeysToScaleNotes(direction: originalDirection)
                self.scalesModel.forceRepaint()
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
    
    func countIn() {
        var audioPlayers:[AVAudioPlayer] = []
        let clapURL = Bundle.module.url(forResource: name, withExtension: ext)
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "aiff") else {
            print("File not found.")
            return
        }

        if clapURL == nil {
            Logger.logger.reportError(self, "Cannot load resource \(name)")
        }
        for _ in 0..<numAudioPlayers {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: clapURL!)
                audioPlayers.append(audioPlayer)
                audioPlayer.prepareToPlay()
                audioPlayer.volume = 1.0 // Set the volume to full
                audioPlayer.rate = 2.0
            }
            catch  {
                Logger.logger.reportError(self, "Cannot prepare AVAudioPlayer")
            }
        }
        Logger.logger.log(self, "Loaded \(numAudioPlayers) audio players")
        return audioPlayers
    }
}
