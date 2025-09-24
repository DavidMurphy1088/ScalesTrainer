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
    var currentTempo = 0
    var warmupCount = 0
    
    init() {
        self._status = .notStarted
        self.statusPublished = .notStarted
        self.ticker = MetronomeTicker()
        self.ticker.metronomeStart()
        self.leadInCountdownPublished = 0
    }
    
    func getNotesPerClick() -> Int{
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return notesPerClick
    }
    
    func stop(_ ctx:String) {
        //print("====== Metronome ⏰ stop() \(ctx)")
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

    private func startTimerTask(_ ctx:String, doLeadIn:Bool) {
        self.timerTickCount = 0
        ///The metronome must notify for everfy note but may not tick for every note. e.g. in 3/8 it notifies every triplet but ticks on the first note only.
        let notesPerClick = self.getNotesPerClick()
        let threadWaitInSeconds = (60.0 / Double(self.currentTempo)) / Double(notesPerClick)
        AppLogger.shared.log(self, "Metronome thread starting, tempo:\(self.currentTempo) status:\(self.status) waitThread:\(threadWaitInSeconds) notesPerClick\(notesPerClick)")
        
        func wait() async {
            let threadWaitInSeconds = (60.0 / Double(self.currentTempo)) / Double(notesPerClick)
            let n = UInt64(threadWaitInSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: n)
        }
        
        Task.detached(priority: .high) { [weak self] in
            guard let self = self else { return }
            while (self.status != .notStarted) {
                if self.status == .warmingUp {
                    if self.warmupCount < 6 {
                        //print("====== Metronome ⏰ wamup \(self.warmupCount)")
                        self.warmupCount += 1
                        await wait()
                        continue
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
                
//                print("====== Metronome ⏰ tick", self.timerTickCount, ",Status", self.status, ", NotesPerClick:\(notesPerClick)",
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
                
                await wait()
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
        //print("====== Metronome ⏰ removeAllProcesses() \(ctx)")
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
