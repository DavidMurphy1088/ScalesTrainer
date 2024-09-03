import Foundation

import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol {
    func metronomeStart()
    func soundMetronomeTick(timerTickerNumber:Int, leadingIn:Bool) -> Bool
    func metronomeStop()
}

class MetronomeModel:ObservableObject {
    @Published private(set) var isLeadingIn:Bool = false
    @Published var timerTickerCountPublished = 0
    private var timerTickerCount = 0
    
    public static let shared = MetronomeModel()
    var isTiming = false
    private let scalesModel = ScalesModel.shared
    private var audioPlayers:[AudioPlayer] = []
    private var tickTimer:AnyCancellable?
    private let audioManager = AudioManager.shared
    private var metronomeTimerNotificationProtocol:MetronomeTimerNotificationProtocol? = nil
    let ticker:MetronomeTicker = MetronomeTicker()
    
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
        ticker.metronomeStart()
    }
    
    func getTempoString(_ tempo:Int) -> String {
//        if tempo > 120 {
//            return "\u{266A}=\(tempo / 2)"
//        }
//        if useQuavers {
//            return "\u{266A}=\(tempo / 2)"
//        }
//        else {
            return "♩= \(tempo)"
//        }
    }
    
    func stop() {
        isTiming = false
        if let notified = metronomeTimerNotificationProtocol {
            notified.metronomeStop()
        }
        metronomeTimerNotificationProtocol = nil
        timerTickerCount = 0
    }
        
    public func startTimer(notified: MetronomeTimerNotificationProtocol, onDone:(() -> Void)?) {
        for player in self.audioPlayers {
            audioManager.mixer?.addInput(player)
        }
        timerTickerCount = 0
        var delay = (60.0 / Double(scalesModel.getTempo())) * 1000000
        delay = delay * Settings.shared.getSettingsNoteValueFactor()
        notified.metronomeStart()
        self.metronomeTimerNotificationProtocol = notified
        
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
            self.isTiming = true
            var setLeadingIn = false
            if Settings.shared.metronomeOn {
                if Settings.shared.scaleLeadInBarCount > 0 {
                    DispatchQueue.main.async {
                        self.isLeadingIn = true
                    }
                    setLeadingIn = true
                }
            }
            var firstNotifyTickNumber = 0
            if Settings.shared.metronomeOn {
                if Settings.shared.scaleLeadInBarCount > 0 {
                    firstNotifyTickNumber = Settings.shared.scaleLeadInBarCount * 4
                }
            }
            
            while self.isTiming {
                print("=================== Timer", timerTickerCount, self.isTiming, self.isLeadingIn, firstNotifyTickNumber)
                var stop = false
                if timerTickerCount < firstNotifyTickNumber {
                    ticker.soundMetronomeTick(timerTickerNumber: timerTickerCount, leadingIn: true)
                }
                else {
                    if setLeadingIn {
                        setLeadingIn = false
                        DispatchQueue.main.async {
                            self.isLeadingIn = false
                        }
                    }
                    stop = notified.soundMetronomeTick(timerTickerNumber: self.timerTickerCount, leadingIn: false)
                }
                if stop {
                    self.isTiming = false
                    usleep(useconds_t(delay / 1.0))
                    break
                }
                else {
                    self.timerTickerCount += 1
                    DispatchQueue.main.async {
                        self.timerTickerCountPublished = self.timerTickerCount
                    }
                    usleep(useconds_t(delay))
                }
            }
            
            if let onDone = onDone {
                onDone()
            }
        }
    }
}
