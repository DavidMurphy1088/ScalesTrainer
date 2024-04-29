import Foundation
import Speech
import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol {
    func metronomeStart()
    func metronomeNext(timerTickerNumber:Int) -> Bool
    func metronomeStop()
}

class MetronomeModel: ObservableObject {
    public static let shared = MetronomeModel()
    
    @Published private(set) var isRunning = false
    @Published var tempo: Int = 90 //90
    @Published private(set) var playingScale:Bool = false
    @Published var isTiming = false

    private let scalesModel = ScalesModel.shared
    private var audioPlayers:[AudioPlayer] = []
    private var timerTickerNumber = 0
    private var tickTimer:AnyCancellable?
    private let audioManager = AudioManager.shared
    
    init() {
        for i in 0..<2 {
            audioPlayers.append(AudioPlayer())
            let name = i == 0 ? "metronome_mechanical_high" : "metronome_mechanical_low"
            guard let fileURL = Bundle.main.url(forResource: name, withExtension: "aiff") else {
                Logger.shared.reportError(self, "Audio file not found ")
                return
            }
            audioPlayers.append(AudioPlayer())

            do {
                let file = try AVAudioFile(forReading: fileURL)
                try? audioPlayers[i].load(file: file)
            }
            catch {
                Logger.shared.reportError(self, "Audio player cannot load \(error.localizedDescription)")
            }
        }
    }
    
    func stop() {
        isRunning = false
        //timer?.cancel()
        //timer = nil
    }
    
//    func setTimer(_ way:Bool) {
//        if way {
//            startTimer()
//        }
//        DispatchQueue.main.async { [self] in
//            self.isTiming = way
//        }
//    }
    
//    private func onTick() {
//        let playerNum = (self.beatNum % 4) == 0 ? 0 : 1
//        let audioPlayer = self.audioPlayers[playerNum]
//        audioPlayer.play()
//        //print("Playback completed.")
//        self.beatNum += 1
//
//    }
    
    private func stopTicking(notified: MetronomeTimerNotificationProtocol) {
        notified.metronomeStop()
        DispatchQueue.main.async { [self] in
            self.isTiming = false
        }
        for player in self.audioPlayers {
            audioManager.mixer.removeInput(player)
        }
    }
    
    public func startTimer(notified: MetronomeTimerNotificationProtocol) {
        DispatchQueue.main.async { [self] in
            self.isTiming = true
        }
        for player in self.audioPlayers {
            audioManager.mixer.addInput(player)
        }
        timerTickerNumber = 0
        let delay = 60.0 / Double(self.tempo)
        notified.metronomeStart()
        DispatchQueue.global(qos: .background).async { [self] in
            tickTimer = Timer.publish(every: delay, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if !self.isTiming {
                        self.tickTimer?.cancel()
                        self.stopTicking(notified: notified)
                    }
                    else {
                        let stop = notified.metronomeNext(timerTickerNumber: self.timerTickerNumber)
                        
                        if stop {
                            self.isTiming = false
                        }
                        else {
                            self.timerTickerNumber += 1
                        }
                    }
                }
        }
    }
    
    func playScale_NOT_USED(scale:Scale) {
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
    
//    func start(tickCall:@escaping () -> Void) {
//        isRunning = true
//        timer = Timer.publish(every: 60.0 / Double(tempo), on: .main, in: .common).autoconnect()
//            .sink { _ in
//                //tickCall()
//                print("Tick at \(self.tempo) BPM")
//            }
//    }


    
}
