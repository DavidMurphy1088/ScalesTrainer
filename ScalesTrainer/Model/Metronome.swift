import Foundation
import Speech
import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol {
    func metronomeStart()
    func metronomeTicked(timerTickerNumber:Int) -> Bool
    func metronomeStop()
}

class MetronomeModel {
    public static let shared = MetronomeModel()

    var isTiming = false

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
        isTiming = false
        //timer?.cancel()
        //timer = nil
    }
    
    private func stopTicking(notified: MetronomeTimerNotificationProtocol) {
        notified.metronomeStop()
        DispatchQueue.main.async { [self] in
            self.isTiming = false
        }
//        for player in self.audioPlayers {
//            audioManager.mixer?.removeInput(player)
//        }
    }
    
    public func startTimer(notified: MetronomeTimerNotificationProtocol, countAtQuaverRate:Bool, onDone:(() -> Void)?) {
        self.isTiming = true
        for player in self.audioPlayers {
            audioManager.mixer?.addInput(player)
        }
        timerTickerNumber = 0
        var delay = (60.0 / Double(scalesModel.getTempo())) * 1000000
        if countAtQuaverRate {
            delay = delay * 0.5 ///Scales are written as 1/8 notes
        }
        notified.metronomeStart()
        ///Timer seems more accurate but using timer means the user cant vary the tempo during timing
//        if false {
//            DispatchQueue.global(qos: .background).async { [self] in
//                tickTimer = Timer.publish(every: delay, on: .main, in: .common)
//                    .autoconnect()
//                    .sink { _ in
//                        if !self.isTiming {
//                            self.tickTimer?.cancel()
//                            self.stopTicking(notified: notified)
//                        }
//                        else {
//                            let stop = notified.metronomeTicked(timerTickerNumber: self.timerTickerNumber)
//                            if stop {
//                                self.isTiming = false
//                            }
//                            else {
//                                self.timerTickerNumber += 1
//                            }
//                        }
//                    }
//            }
//        }
//        else {
            DispatchQueue.global(qos: .background).async { [self] in
                while self.isTiming {
                    let stop = notified.metronomeTicked(timerTickerNumber: self.timerTickerNumber)
                    if stop {
                        DispatchQueue.main.async { [self] in
                            self.isTiming = false
                        }
                        break
                    }
                    else {
                        self.timerTickerNumber += 1
                        usleep(useconds_t(delay))
                    }
                }
                ///Let the last 'played' key show for a short time
                let delay = (1.2) * 1000000
                usleep(useconds_t(delay))
                self.stopTicking(notified: notified)
                if let onDone = onDone {
                    onDone()
                }
            }
//        }
    }
    
}
