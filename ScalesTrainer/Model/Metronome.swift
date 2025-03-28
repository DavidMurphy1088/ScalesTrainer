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
    case standby
    case leadingIn
    case running
}

class Metronome:ObservableObject {
    public static let shared = Metronome()
    
    private(set) var status:MetronomeStatus
    @Published private(set) var statusPublished:MetronomeStatus
    func setStatus(status:MetronomeStatus) {
        self.status = status
        DispatchQueue.main.async {
            self.statusPublished = status
        }
    }

    private var standbyCount:Int?

    private var leadInCount:Int?
    @Published private(set) var leadInCountdownPublished:Int? = nil

    @Published var tickedCountPublished = 0
    
    //private var isTicking:Bool
    //@Published var isTickingPublished:Bool

    public var threadRunCount = 0
    private let scalesModel = ScalesModel.shared
    private let audioManager = AudioManager.shared
    private var processesToNotify:[MetronomeTimerNotificationProtocol] = []
    private let ticker:MetronomeTicker
    
    init() {
        self.status = .notStarted
        self.statusPublished = .notStarted
        //self.isTicking = false
        self.ticker = MetronomeTicker()
        self.ticker.metronomeStart()
        //self.isTickingPublished = false
    }
    
    func getNotesPerClick() -> Int{
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return notesPerClick
    }
    
    func stop() {
        //self.isTicking = false
        self.setStatus(status: .notStarted)
        removeAllProcesses()
    }
    
    func start(doStandby:Bool, doLeadIn:Bool, scale:Scale?) {
        if self.status != .notStarted {
            return
        }
        self.threadRunCount = 0
        setLeadInCountdownPublished(count: 0)
        if doStandby {
            if let scale = scale {
                self.standbyCount = scale.timeSignature.top % 3 == 0 ? 3 : 4
            }
        }

        if doLeadIn {
            if let scale = scale {
                self.leadInCount = scale.timeSignature.top % 3 == 0 ? 3 : 4
            }
        }

        self.ticker.tickNum = 0
        //DispatchQueue.main.async {
            if doStandby {
                self.setStatus(status: .standby)
            }
            else {
                if doLeadIn {
                    self.setStatus(status: .leadingIn)
                }
                else {
                    self.setStatus(status: .running)
                }
            }
        //}
        self.startTimerTask("Metronome start")
    }

    func startTimerTask(_ ctx:String) {
        self.threadRunCount = 0
        ///The metronome must notify for everfy note but may not tick for every note. e.g. in 3/8 it notifies every triplet but ticks on the first note only.
        let notesPerClick = self.getNotesPerClick()
        let tempo = Double(scalesModel.getTempo("Metronom::startTimerThread"))
        let threadWaitInSeconds = (60.0 / tempo) / Double(notesPerClick)
        AppLogger.shared.log(self, "Metronome thread starting, tempo:\(tempo)")
        
        Task.detached(priority: .background) {
            while (self.status != .notStarted) {
                var remaining = 0
                if let leadInCount = self.leadInCount, let standbyCount = self.standbyCount {
                    if self.threadRunCount < standbyCount * notesPerClick {
                        self.setStatus(status: .standby)
                    }
                    else {
                        if self.threadRunCount < (leadInCount + standbyCount) * notesPerClick {
                            self.setStatus(status: .leadingIn)
                            remaining = ((leadInCount + standbyCount) * notesPerClick) - self.threadRunCount
                            remaining = (remaining + 1) / notesPerClick
                            //if remaining != self.leadInCountdownPublished {
                                self.setLeadInCountdownPublished(count: remaining)
                            //}
                        }
                        else {
                            if self.status != .running {
                                self.setStatus(status: .running)
                            }
                        }
                    }
                }
                else {
                    self.setStatus(status: .running)
                }
                //print("\n========== METRONOME", self.threadRunCount, "Status", self.status, "Countd", self.leadInCountdownPublished, "remain", remaining)
                
                self.ticker.metronomeTickNotification(timerTickerNumber: self.threadRunCount) //, leadingIn: leadingIn)
                
                if self.status == .running {
                    for toNotify in self.processesToNotify {
                        _ = toNotify.metronomeTickNotification(timerTickerNumber: self.threadRunCount)
                    }
                }
                let tickCount = self.threadRunCount % notesPerClick
                if tickCount == 0 {
                    DispatchQueue.main.async {
                        //print("     =========== Count \(self.threadRunCount) \(self.threadRunCount) TickCountPublished:\(self.tickedCountPublished)")
                        self.tickedCountPublished =  self.tickedCountPublished + 1
                    }
                }
                self.threadRunCount += 1
                
                let tempo = Double(self.scalesModel.getTempo("Metronom::startTimerThread"))
                let threadWaitInSeconds = (60.0 / tempo) / Double(notesPerClick)

                let n = UInt64(threadWaitInSeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: n)
                //print("+++===================== ✅ Background task iteration \(self.threadRunCount) TickCountPublished:\(self.tickedCountPublished)")
            }
        }
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
    
    ///What is the note value duration between notifications (not clicks)
    func getNoteValueDuration() -> Double {
        let notesPerClick = scalesModel.scale.timeSignature.top % 3 == 0 ? 3 : 2
        return 1.0 / Double(notesPerClick)
    }
        
}
