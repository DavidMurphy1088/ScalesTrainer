
import AVFoundation
import Foundation

class CalibrationResult : Identifiable {
    let id = UUID()
    let num:Int
    let amplitudeFilter:Double
    var lowestErrors = false
    let result:Result
    
    init(num:Int, result:Result, amplFilter: Double) {
        self.num = num
        self.result = result
        self.amplitudeFilter = amplFilter
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
        let calibrationResult = CalibrationResult(num: num, result: result, amplFilter: amplFilter)
        DispatchQueue.main.async {
            self.calibrationResults?.append(calibrationResult)
        }
    }
    
    func setEvents(tapEvents:[TapStatusRecord]) {
        DispatchQueue.main.async {
            self.calibrationEvents = []
            var tapNum = 0
            for event in tapEvents {
                self.calibrationEvents!.append(TapEvent(tapNum: tapNum, consecutiveCount: 1, frequency: event.frequency, amplitude: event.amplitude, status: .none))
//                self.calibrationEvents!.append(TapEvent(tapNum: tapNum, frequency: event.frequency, amplitude: event.amplitude, ascending: event.ascending, status: .none,
//                                                        expectedMidis:[], midi: event.midi, tapMidi: event.tapMidi, consecutiveCount: 1))
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
    
//    func analyseBestSettings(onNext:@escaping(_:Double)->Void, onDone:@escaping(_:Double?)->Void, tapBufferSize:Int) {
//        DispatchQueue.global(qos: .background).async {
//            self.calibrationResults = []
//            var higherThanMinCount = 0
//            let scalesModel = ScalesModel.shared
//            var minError:Int?
//            var index = 0
//            
//            while true {
//                let ampFilter = Double(index) * 0.005
//                onNext(ampFilter)
//                scalesModel.setRunningProcess(.recordScaleWithTapData, amplitudeFilter: ampFilter)
//                if let result = scalesModel.resultInternal {
//                    let totalErrors = result.getTotalErrors()
//                    self.appendResult(num: index, result: result, amplFilter: ampFilter)
//                    if minError == nil || totalErrors <= minError! {
//                        minError = totalErrors
//                        higherThanMinCount = 0
//                    }
//                    else {
//                        higherThanMinCount += 1
//                        if higherThanMinCount > 8 {
//                            break
//                        }
//                    }
//                    self.setStatus("Filter:\(ampFilter) Errors:\(totalErrors)")
//                }
//                index += 1
//            }
//            
//            ///Find the best results. Use the result in the middle of the lowest error results and save that callibration.
//            var first:Int?
//            var last:Int?
//            var bestResult:CalibrationResult?
//
//            for i in 0..<self.calibrationResults!.count {
//                let result = self.calibrationResults![i]
//                if result.result.getTotalErrors() == minError {
//                    if first == nil {
//                        first = i
//                    }
//                    last = i
//                    result.lowestErrors = true
//                }
//            }
//            if let first = first {
//                if let last = last {
//                    //let bestIndex = (first + last) / 2
//                    ///Seems overall better with lower value
//                    var bestIndex:Int
//                    if last == first {
//                        bestIndex = first
//                    }
//                    else {
//                        bestIndex = first + 1
//                    }
//                    bestResult = self.calibrationResults![bestIndex]
//                    
//                }
//            }
//            if let best = bestResult {
//                onDone(best.amplitudeFilter)
//            }
//            else {
//                onDone(nil)
//            }
//        
//        }
//    }
    
//    func run(amplitudeFilter: Double) {
//        let scalesModel = ScalesModel.shared
//        ///Show the result visually
//        scalesModel.setRunningProcess(.recordScaleWithTapData, amplitudeFilter: amplitudeFilter)
//    }
    
    func calculateAverageAmplitude() -> Double? {
        let scalesModel = ScalesModel.shared
        guard let eventSet = scalesModel.processedEventSet else {
            Logger.shared.reportError(self, "No events")
            return nil
        }
        var amplitudes:[Float] = []
        for event in eventSet.events {
            let amplitude = Float(event.amplitude)
            amplitudes.append(amplitude)
        }
        let n = 8
        guard amplitudes.count >= n else {
            Logger.shared.reportError(self, "Calibration amplitudes must contain at least \(n) elements.")
            return nil
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        //scalesModel.setAmplitudeFilter(avgAmplitude)
        //Settings.shared.save(amplitudeFilter: avgAmplitude)
        Logger.shared.log(self, "Calibration amplitude set at: \(avgAmplitude) from \(n) averages")
        
        ///Save events as callibration events
        self.setEvents(tapEvents: eventSet.events)
        return avgAmplitude
    }
}
