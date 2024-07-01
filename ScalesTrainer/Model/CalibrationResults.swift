
import AVFoundation
import Foundation

class CalibrationResult : Identifiable {
    let id = UUID()
    let num:Int
    let amplFilter: Double
    var lowestErrors = false
    let result:Result
    
    init(num:Int, result:Result, amplFilter: Double) {
        self.num = num
        self.result = result
        self.amplFilter = amplFilter
    }
}

class CalibrationResults : ObservableObject {
    @Published var calibrationEvents:[TapEvent]? = nil
    @Published var calibrationResults:[CalibrationResult]?
    @Published var status:String? = nil
    
    func setStatus(_ msg:String) {
        DispatchQueue.main.async {
            self.status = msg
        }
    }
    
    func appendResult(num: Int, result: Result, amplFilter:Double) {
        DispatchQueue.main.async {
            let calibrationResult = CalibrationResult(num: num, result: result, amplFilter: amplFilter)
            self.calibrationResults?.append(calibrationResult)
        }
    }
    
    func setEvents(tapEvents:[TapEvent]) {
        DispatchQueue.main.async {
            self.calibrationEvents = []
            var tapNum = 0
            for event in tapEvents {
                self.calibrationEvents!.append(TapEvent(tapNum: tapNum, frequency: event.frequency, amplitude: event.amplitude, ascending: event.ascending, status: .none, expectedScaleNoteState: .none, midi: event.midi, tapMidi: event.tapMidi, amplDiff: 0, key: .none))
                tapNum += 1
            }
            self.calibrationResults = nil
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.calibrationEvents = nil
            self.calibrationResults = nil
            self.status = nil
        }
    }
    
    func analyseBestSettings(onDone:()->Void) {
        DispatchQueue.global(qos: .background).async {
            self.calibrationResults = []
            var higherThanMinCount = 0
            let scalesModel = ScalesModel.shared
            var minError:Int?
            var index = 0
            
            while true {
                let ampFilter = Double(index) * 0.005
                scalesModel.setAmplitudeFilter(ampFilter)
                scalesModel.setRunningProcess(.recordScaleWithTapData)
                if let result = scalesModel.result {
                    let totalErrors = result.totalErrors()
                    self.appendResult(num: index, result: result, amplFilter: ampFilter)
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
                    self.setStatus("Filter:\(ampFilter) Errors:\(totalErrors)")
                }
                index += 1
            }

            ///Find the best results. Use the result in the middle of the lowest error results.
            var first:Int?
            var last:Int?
            for i in 0..<self.calibrationResults!.count {
                let result = self.calibrationResults![i]
                if result.result.totalErrors() == minError {
                    if first == nil {
                        first = i
                    }
                    last = i
                    result.lowestErrors = true
                }
            }
            if let first = first {
                if let last = last {
                    //let bestIndex = (first + last) / 2
                    ///Seems overall better with lower value
                    var bestIndex:Int
                    if last == first {
                        bestIndex = first
                    }
                    else {
                        bestIndex = first + 1
                    }
                    let result = self.calibrationResults![bestIndex]                    
                    scalesModel.setAmplitudeFilter(result.amplFilter)
                    Settings.shared.save(amplitudeFilter: result.amplFilter)
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
