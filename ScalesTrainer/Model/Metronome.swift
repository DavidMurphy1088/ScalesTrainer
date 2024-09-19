import Foundation

import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol: AnyObject {
    func metronomeStart()
    func metronomeTickNotification(timerTickerNumber:Int, leadingIn:Bool) -> Bool
    func metronomeStop()
}

class MetronomeModel:ObservableObject {
    @Published private(set) var isLeadingIn:Bool = false
    @Published var timerTickerCountPublished = 0
    private var timerTickerCount = 0
    
    public static let shared = MetronomeModel()
    var isTiming = false
    private let scalesModel = ScalesModel.shared
    private var tickTimer:AnyCancellable?
    private let audioManager = AudioManager.shared
    private var processesToNotify:[MetronomeTimerNotificationProtocol] = []
    let ticker:MetronomeTicker
    var makeSilent = false
    
    init() {
        self.ticker = MetronomeTicker()
        self.ticker.metronomeStart()
    }
    
    func setLeadingIn(way:Bool) {
        DispatchQueue.main.async {
            self.isLeadingIn = way
        }
    }
    
    func setTimerTickerCountPublished(count:Int) {
        DispatchQueue.main.async {
            self.timerTickerCountPublished = count
        }
    }
    
    func getTempoString(_ tempo:Int) -> String {
        return "♩= \(tempo)"
    }
    
    func setTicking(on:Bool) {
        if on {
            self.makeSilent = false
            self.startTimerThread()
            self.isTiming = true
        }
        else {
            self.isTiming = false
        }
    }
    
    func DontUse() {
        self.startTimerThread()
        self.isTiming = true
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
        Logger.shared.log(self, "Metronome thread starting, tempo:\(scalesModel.getTempo())")

        ///Timer seems more accurate but using timer means the user cant vary the tempo during timing
        if true {
            DispatchQueue.global(qos: .background).async { [self] in
                tickTimer = Timer.publish(every: delay, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        if !self.isTiming {
                            self.tickTimer?.cancel()
                            Logger.shared.log(self, "Metronome thread ended count:\(self.timerTickerCount)")
                        }
                        else {
                            for toNotify in self.processesToNotify {
                                _ = toNotify.metronomeTickNotification(timerTickerNumber: self.timerTickerCount, leadingIn: false)
                            }
                            if !self.makeSilent {
                                _ = self.ticker.metronomeTickNotification(timerTickerNumber: self.timerTickerCount, leadingIn: false)
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
