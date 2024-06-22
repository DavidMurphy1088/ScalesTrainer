
import AVFoundation
import Foundation

class CallibrationResult : Identifiable {
    let id = UUID()
    let num:Int
    let amplFilter: Double
    var best = false
    let result:Result
    
    init(num:Int, result:Result, amplFilter: Double) {
        self.num = num
        self.result = result
        self.amplFilter = amplFilter
    }
}

class CallibrationResults : ObservableObject {
    @Published var callibrationEvents:[TapEvent]? = nil
    @Published var results:[CallibrationResult]?
    
    func setEvents(tapEvents:[TapEvent]) {
        DispatchQueue.main.async {
            self.callibrationEvents = []
            var tapNum = 0
            for event in tapEvents {
                self.callibrationEvents!.append(TapEvent(tapNum: tapNum, frequency: event.frequency, amplitude: event.amplitude, ascending: event.ascending, status: .none, expectedScaleNoteState: .none, midi: event.midi, tapMidi: event.tapMidi, amplDiff: 0, key: .none))
                tapNum += 1
            }
            self.results = nil
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.callibrationEvents = nil
            self.results = nil
        }
    }
    
    func analyseBestSettings() {
        DispatchQueue.main.async {
            self.results = []
            var higherThanMinCount = 0
            let scalesModel = ScalesModel.shared
            var minError:Int?

            for i in 0..<40 {
                let ampFilter = Double(i) * 0.005
                scalesModel.setAmplitudeFilter(ampFilter)
                scalesModel.setRunningProcess(.recordScaleWithTapData)
                if let result = scalesModel.result {
                    let totalErrors = result.totalErrors()
                    self.results?.append(CallibrationResult(num: i, result: result, amplFilter: ampFilter))
                    if minError == nil || totalErrors <= minError! {
                        minError = totalErrors
                        higherThanMinCount = 0
                    }
                    else {
                        higherThanMinCount += 1
                        if higherThanMinCount > 8 {
                            break
                        }
                    }
                    //lastCount = result.totalErrors()
                }
            }

            for e in self.results! {
                if e.result.totalErrors() == minError {
                    e.best = true
                    scalesModel.setAmplitudeFilter(e.amplFilter)
                    //Settings.shared.amplitudeFilter = e.amplFilter
                    Settings.shared.save(amplitudeFilter: e.amplFilter)
                    ///Show the best result visually
                    scalesModel.setRunningProcess(.recordScaleWithTapData)
                }
            }
        }
    }
    
    func run(amplitudeFilter: Double) {
        let scalesModel = ScalesModel.shared
        scalesModel.setAmplitudeFilter(amplitudeFilter)
        //Settings.shared.save()
        ///Show the result visually
        scalesModel.setRunningProcess(.recordScaleWithTapData)
    }
    
    func calculateCallibration() {
        let scalesModel = ScalesModel.shared
        guard let eventSet = scalesModel.tapHandlerEventSet else {
            Logger.shared.reportError(self, "No events")
            return
        }
        var amplitudes:[Float] = []
        for event in eventSet.events {
            let amplitude = Float(event.amplitude)
            amplitudes.append(amplitude)
        }
        let n = 8
        guard amplitudes.count >= n else {
            Logger.shared.reportError(self, "Callibration amplitudes must contain at least \(n) elements.")
            return
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        scalesModel.setAmplitudeFilter(avgAmplitude)
        Settings.shared.save(amplitudeFilter: avgAmplitude)
        Logger.shared.log(self, "Callibration amplitude set at: \(avgAmplitude) from \(n) averages")
        
        ///Save events as callibration events
        self.setEvents(tapEvents: eventSet.events)
    }
}
