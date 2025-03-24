import Foundation

import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol: AnyObject {
    func metronomeStart()
    func metronomeTickNotification(timerTickerNumber:Int, leadingIn:Bool) 
    func metronomeStop()
}

class Metronome:ObservableObject {
    public static let shared = Metronome()

    @Published private(set) var leadInCountdownPublished:Int? = nil
    private var leadInCount:Int?

    @Published var timerTickerCountPublished = 0
    
    public var timerTickerCount = 0
    private let scalesModel = ScalesModel.shared
    private var tickTimer:AnyCancellable?
    private let audioManager = AudioManager.shared
    private var processesToNotify:[MetronomeTimerNotificationProtocol] = []
    private let ticker:MetronomeTicker
    private var isTicking:Bool
    
    init() {
        self.isTicking = false
        self.ticker = MetronomeTicker()
        self.ticker.metronomeStart()
    }
    
    func start(doLeadIn:Bool, scale:Scale?) {
        self.timerTickerCount = 0
        setLeadInCountdownPublished(count: 0)
        if doLeadIn {
            if let scale = scale {
                self.leadInCount = scale.timeSignature.top % 3 == 0 ? 3 : 4
            }
        }
        //self.setLeadInCount("MetronomeStart", count: leadInCount)
        self.ticker.tickNum = 0
        if self.tickTimer == nil {
            self.startTimerThread("Metronome start")
        }
    }
    
    func stop() {
        if let timer = self.tickTimer {
            timer.cancel()
            self.tickTimer = nil
        }
        self.isTicking = false
        removeAllProcesses()
    }

    func setTicking(way:Bool) {
        self.isTicking = way
    }
    
    func isMetronomeTicking() -> Bool {
        return self.isTicking
    }

    func setLeadInCountdownPublished(count:Int) {
        DispatchQueue.main.async {
            self.leadInCountdownPublished = count
        }
    }
    
    func getTempoString(_ tempo:Int) -> String {
        return "♩= \(tempo)"
    }
    
    func addProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
//        for i in 0..<self.processesToNotify.count {
//            self.processesToNotify[i].metronomeStop()
//        }
        self.processesToNotify.append(process)
        for i in 0..<self.processesToNotify.count {
            self.processesToNotify[i].metronomeStart()
        }
    }
    
    func removeAllProcesses() {
        for process in self.processesToNotify {
            process.metronomeStop()
            self.removeProcessesToNotify(process: process)
        }
    }
    
    func removeProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
        process.metronomeStop()
        for i in 0..<self.processesToNotify.count {
            if self.processesToNotify[i] === process {
                self.processesToNotify.remove(at: i)
                break
            }
        }
    }

    func getNotesPerClick() -> Int{
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return notesPerClick
    }
    
    ///What is the note value duration between notifications (not clicks)
    func getNoteValueDuration() -> Double {
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return 1.0 / Double(notesPerClick)
    }
        
    ///notified: MetronomeTimerNotificationProtocol, onDone:(() -> Void)?
    func startTimerThread(_ ctx:String) {
        ///Dont create another thread
        if self.tickTimer != nil {
            return
        }
        self.timerTickerCount = 0
        ///The metronome must notify for everfy note but may not tick for every note. e.g. in 3/8 it notifies every triplet but ticks on the first note only.
        let notesPerClick = self.getNotesPerClick()
        let tempo = Double(scalesModel.getTempo("Metronom::startTimerThread"))
        let threadWait = (60.0 / tempo) / Double(notesPerClick)
        AppLogger.shared.log(self, "Metronome thread starting, tempo:\(tempo)")
        //let leadInTicks = 4 //Settings.shared.getCurrentUser().settings.getLeadInBeats() * notesPerClick
        var leadingIn = false
        
        ///Timer seems more accurate but using timer means the user cant vary the tempo during timing
        if true {
            DispatchQueue.global(qos: .background).async { [self] in
                tickTimer = Timer.publish(every: threadWait, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        leadingIn = false
                        if let leadInCount = self.leadInCount {
                            if self.timerTickerCount < leadInCount  * notesPerClick {
                                let remaining:Int = (leadInCount * notesPerClick - self.timerTickerCount) / notesPerClick
                                self.setLeadInCountdownPublished(count: remaining)
                                leadingIn = true
                            }
                        }
                        //print("\n========== METRONOME", self.timerTickerCount, leadInCount, leadingIn)
                        self.ticker.metronomeTickNotification(timerTickerNumber: self.timerTickerCount, leadingIn: leadingIn)
                        if !leadingIn {
                            //print("  ========== METRONOME-Notify")
                            for toNotify in self.processesToNotify {
                                _ = toNotify.metronomeTickNotification(timerTickerNumber: self.timerTickerCount, leadingIn: leadingIn)
                            }
                        }
                        self.timerTickerCount += 1
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
