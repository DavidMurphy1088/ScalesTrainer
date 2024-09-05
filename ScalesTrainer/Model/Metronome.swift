import Foundation

import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol: AnyObject {
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
    private var processesToNotify:[MetronomeTimerNotificationProtocol] = []
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
    
    func addProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
        if self.processesToNotify.count == 0 {
            self.startTimerThread()
            self.isTiming = true
        }
        process.metronomeStart()
        self.processesToNotify.append(process)
    }
    
    func removeProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
        process.metronomeStop()
        for i in 0..<self.processesToNotify.count {
            if self.processesToNotify[i] === process {
                self.processesToNotify.remove(at: i)
                break
            }
        }
        if self.processesToNotify.count == 0 {
            self.isTiming = false
        }
    }
    
    func removeAllProcesses() {
        for  proc in self.processesToNotify {
            self.removeProcessesToNotify(process: proc)
        }
    }

//    private func stopTimerThread() {
//        isTiming = false
//        for notified in self.processesToNotify {
//            notified.metronomeStop()
//        }
//        processesToNotify = []
//        timerTickerCount = 0
//    }
        
    ///notified: MetronomeTimerNotificationProtocol, onDone:(() -> Void)?
    ///
    func startTimerThread() {
        timerTickerCount = 0
        var delay = (60.0 / Double(scalesModel.getTempo())) //* 1000000
        delay = delay * Settings.shared.getSettingsNoteValueFactor()
        print("=========== START Metro Thread ======")
        //notified.metronomeStart()
        //self.metronomeTimerNotificationProtocol = notified
        
        ///Timer seems more accurate but using timer means the user cant vary the tempo during timing
        if true {
            DispatchQueue.global(qos: .background).async { [self] in
                tickTimer = Timer.publish(every: delay, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        if !self.isTiming {
                            self.tickTimer?.cancel()
                            print("========= ENDED Metro Thread ======")
                        }
                        else {
                            for toNotify in self.processesToNotify {
                                toNotify.soundMetronomeTick(timerTickerNumber: self.timerTickerCount, leadingIn: false)
                            }
                            let stop = false //notified.metronomeTicked(timerTickerNumber: self.timerTickerNumber)
                            if stop {
                                self.isTiming = false
                            }
                            else {
                                self.timerTickerCount += 1
                            }
                        }
                    }
            }
        }
//        else {
        ///Currently user can only vary tempo when metronome thread is stopped
//        DispatchQueue.global(qos: .background).async { [self] in
//            self.isTiming = true
//            var setLeadingIn = false
//            if Settings.shared.metronomeOn {
//                if Settings.shared.scaleLeadInBarCount > 0 {
//                    DispatchQueue.main.async {
//                        self.isLeadingIn = true
//                    }
//                    setLeadingIn = true
//                }
//            }
//            var firstNotifyTickNumber = 0
//            if Settings.shared.metronomeOn {
//                if Settings.shared.scaleLeadInBarCount > 0 {
//                    firstNotifyTickNumber = Settings.shared.scaleLeadInBarCount * 4
//                }
//            }
//            
//            while self.isTiming {
//                var stop = false
//                if timerTickerCount < firstNotifyTickNumber {
//                    ticker.soundMetronomeTick(timerTickerNumber: timerTickerCount, leadingIn: true)
//                }
//                else {
//                    if setLeadingIn {
//                        setLeadingIn = false
//                        DispatchQueue.main.async {
//                            self.isLeadingIn = false
//                        }
//                    }
//                    stop = notified.soundMetronomeTick(timerTickerNumber: self.timerTickerCount, leadingIn: false)
//                }
//                if stop {
//                    self.isTiming = false
//                    usleep(useconds_t(delay / 1.0))
//                    break
//                }
//                else {
//                    self.timerTickerCount += 1
//                    DispatchQueue.main.async {
//                        self.timerTickerCountPublished = self.timerTickerCount
//                    }
//                    usleep(useconds_t(delay))
//                }
//            }
//            
//            if let onDone = onDone {
//                onDone()
//            }
//        }
    }
}
