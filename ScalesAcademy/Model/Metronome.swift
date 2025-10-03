import Foundation

import Combine
import Accelerate
import AVFoundation
import AudioKit

protocol MetronomeTimerNotificationProtocol: AnyObject {
    func metronomeStart()
    func metronomeTickNotification(timerTickerNumber:Int) //, leadingIn:Bool)
    func metronomeStop()
}

enum MetronomeStatus {
    case notStarted
    case warmingUp ///warmup the hardware to avoid a non tempo/jumpy start
    case leadingIn
    case running
}

class Metronome:ObservableObject {
    public static let shared = Metronome()
    
    @Published private(set) var statusPublished:MetronomeStatus
    private var startTickingTime:DispatchTime = DispatchTime.now()
    
    var _status = MetronomeStatus.notStarted
    private let accessQueue = DispatchQueue(label: "com.musicmastereducation.scalesacademy.metronome.status")
    var status: MetronomeStatus {
        get {
            return accessQueue.sync { _status }
        }
        set {
            accessQueue.sync {
                _status = newValue
                let currentStatus = _status  // Capture the value so main does not try to read _status
                DispatchQueue.main.async { [weak self] in
                    self?.statusPublished = currentStatus  // Use captured value
                }
            }
        }
    }
    @Published private(set) var leadInCountdownPublished:Int? // = nil
    func setLeadInCountdownPublished(_ n:Int?) {
        DispatchQueue.main.async {
            self.leadInCountdownPublished = n
        }
    }

    func setStatus(status:MetronomeStatus) {
        self.status = status
    }

    private var leadInCount:Int?
    private var timerTickCount = 0
    private let scalesModel = ScalesModel.shared
    private let audioManager = AudioManager.shared
    private var processesToNotify:[MetronomeTimerNotificationProtocol] = []
    private let ticker:MetronomeTicker
    private(set) var currentTempo = 0
    private var tickCount = 0
    var warmupCount = 0
    
    init() {
        self._status = .notStarted
        self.statusPublished = .notStarted
        self.ticker = MetronomeTicker()
        self.ticker.metronomeStart()
        self.leadInCountdownPublished = 0
    }
    
    func setTempoParameters(tempo:Int) {
        self.startTickingTime = DispatchTime.now()
        self.currentTempo = tempo
        self.tickCount = 0
    }
    
    func getNotesPerClick() -> Int{
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return notesPerClick
    }
    
    func stop(_ ctx:String) {
        self.setStatus(status: .notStarted)
        removeAllProcesses("from stop")
    }
    
    func start(_ ctx:String, doLeadIn:Bool, scale:Scale?) {
        if self.status != .notStarted {
            return
        }
        self.timerTickCount = 0
        self.warmupCount = 0
        setLeadInCountdownPublished(nil)
        
        if doLeadIn {
            if let scale = scale {
                self.leadInCount = scale.timeSignature.top % 3 == 0 ? 3 : 4
            }
        }

        if doLeadIn {
            //self.setStatus(status: .leadingIn)
            self.setStatus(status: .warmingUp)
        }
        else {
            self.setStatus(status: .running)
        }
        
        self.startTimerTask("Metronome start", doLeadIn: doLeadIn)
    }
    
    private func processTick(notesPerClick:Int, doLeadIn:Bool) {
        if self.status == .warmingUp {
            if self.warmupCount < 6 {
                self.warmupCount += 1
                return
            }
        }
        var waitForLeadInTicks = 0
        var remainingBeats = 0

        if let leadInCount = self.leadInCount {
            waitForLeadInTicks = (leadInCount * notesPerClick) - self.timerTickCount
            if waitForLeadInTicks > 0 {
                self.setStatus(status: .leadingIn)
                remainingBeats = waitForLeadInTicks / notesPerClick
                if remainingBeats > 0 {
                    if waitForLeadInTicks % notesPerClick == 0 {
                        self.setLeadInCountdownPublished(remainingBeats)
                    }
                }
            }
            else {
                if self.status != .running {
                    self.setStatus(status: .running)
                }
            }
        }
        else {
            self.setStatus(status: .running)
        }
//                print("\n====== Metronome  tick", self.timerTickCount, ",Status", self.status, ", NotesPerClick:\(notesPerClick)",
//                      "lead in:\(self.leadInCount)", "  [waitTicks:\(waitForLeadInTicks), pub:\(waitForLeadInTicks % notesPerClick), beats:\(remainingBeats)]")
        
        if doLeadIn {
            if self.status != .running {
                //Sound tick for count in only but notifications must still go out after lead in
                self.ticker.metronomeTickNotification(timerTickerNumber: self.timerTickCount) //, leadingIn: leadingIn)
            }
        }
        else {
            self.ticker.metronomeTickNotification(timerTickerNumber: self.timerTickCount) //, leadingIn: leadingIn)
        }
        
        if self.status == .running {
            for toNotify in self.processesToNotify {
                _ = toNotify.metronomeTickNotification(timerTickerNumber: self.timerTickCount)
            }
        }
        self.timerTickCount += 1
    }

    private func startTimerTask(_ ctx:String, doLeadIn:Bool) {
        //AppLogger.shared.log(self, "Metronome thread starting, tempo:\(self.currentTempo) status:\(self.status)")
        Task.detached(priority: .high) { [weak self] in
            guard let self = self else { return }
            let notesPerClick = self.getNotesPerClick()
            setTempoParameters(tempo: self.currentTempo)
            
            while self.status != .notStarted {
                let currentTime = DispatchTime.now()
                let intervalMs = (60.0 / Double(self.currentTempo) * 1000.0) / Double(notesPerClick) // milliseconds per beat (857.14ms for 70 BPM)
                
                //print("===> ⏰ Metronome", tickCount, String(format: "\tActual: %.2f ms, \tExpected: %.2f ms", elapsedMs, expectedTimeMs), "\tDiff:\(elapsedMs - expectedTimeMs)")
                processTick(notesPerClick: notesPerClick, doLeadIn: doLeadIn)
                tickCount += 1
                
                // Calculate when the next tick should occur. adjut the wait time based on what time we should be at for this tick count
                let nextExpectedTimeMs = Double(tickCount) * intervalMs
                let timeAfterWork = DispatchTime.now()
                let elapsedAfterWorkMs = Double(timeAfterWork.uptimeNanoseconds - self.startTickingTime.uptimeNanoseconds) / 1_000_000.0
                // Calculate how long we need to wait
                let waitTimeMs = nextExpectedTimeMs - elapsedAfterWorkMs
                
                if waitTimeMs > 0 {
                    let waitTimeNanos = UInt64(waitTimeMs * 1_000_000)
                    // Sleep until the exact time for the next beat using Task.sleep
                    try? await Task.sleep(nanoseconds: waitTimeNanos)
                }
            }
        }
    }
    
    func getTempoString(_ tempo:Int) -> String {
        return "♩= \(tempo)"
    }
    
    func addProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
        self.processesToNotify.append(process)
        for i in 0..<self.processesToNotify.count {
            self.processesToNotify[i].metronomeStart()
        }
    }
    
    func removeAllProcesses(_ ctx:String) {
        for process in self.processesToNotify {
            process.metronomeStop()
            self.removeProcessesToNotify(process: process)
        }
    }
    
    private func removeProcessesToNotify(process:MetronomeTimerNotificationProtocol) {
        process.metronomeStop()
        for i in 0..<self.processesToNotify.count {
            if self.processesToNotify[i] === process {
                self.processesToNotify.remove(at: i)
                break
            }
        }
    }
    
    ///What is the note value duration between notifications (not clicks)
    func getNoteValueDuration() -> Double {
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return 1.0 / Double(notesPerClick)
    }
        
}
