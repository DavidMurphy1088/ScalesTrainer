import Foundation
import SwiftUI

class Result {
    let feedbackType:AppMode
    var missedCountAsc = 0
    var missedCountDesc = 0
    var wrongCountAsc = 0
    var wrongCountDesc = 0
    
    init(type:AppMode) {
        self.feedbackType = type
    }
    
    func buildResult(feedbackType:AppMode) {
        //PianoKeyboardModel.shared.debug2("test datax")
        //ScalesModel.shared.scale.debug("test datax")
        let keyboardModel = PianoKeyboardModel.shared

        guard let score = ScalesModel.shared.score else {
            return
        }
        
        ///the mapping of keys to scale notes can be different ascending vs. descending. e.g. melodic minor
        for direction in [0,1] {
            keyboardModel.mapScaleFingersToKeyboard(direction: direction)
            for i in 0..<keyboardModel.pianoKeyModel.count {
                let key = keyboardModel.pianoKeyModel[i]
                if key.scaleNoteState != nil {
                    if direction == 0 {
                        if key.keyClickedState.tappedTimeAscending == nil {
                            missedCountAsc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                    }
                    if direction == 1 {
                        if key.keyClickedState.tappedTimeDescending == nil {
                            missedCountDesc += 1
                            if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                                timeSlice.setStatusTag(.missingError)
                            }
                        }
                    }
                }
                else {
                    if direction == 0 {
                        if key.keyClickedState.tappedTimeAscending != nil {
                            wrongCountAsc += 1
                        }
                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                            timeSlice.setStatusTag(.pitchError)
                        }
                    }
                    if direction == 1 {
                        if key.keyClickedState.tappedTimeDescending != nil {
                            wrongCountDesc += 1
                        }
                        if let timeSlice = score.getTimeSliceForMidi(midi: key.midi, count: direction) {
                            timeSlice.setStatusTag(.pitchError)
                        }

                    }
                }
            }
        }
//        score.calculateTapToValueRatios()
//        for t in score.getAllTimeSlices() {
//            print(t.tapTempoRatio)
//        }
    }
}

struct ResultView: View {
    var keyboardModel:PianoKeyboardModel
    let result:Result
    
    func recordStatus() -> (Bool, String) {
        var status = ""
        if result.missedCountAsc == 0 && result.missedCountDesc == 0 && result.wrongCountAsc == 0 && result.wrongCountDesc == 0 {
            status = "Good job, your scale was correct."
        }
        else {
            status = "😔 Your scale was not correct. "
            if result.wrongCountAsc > 0 {
                status += "\nYou played \(result.wrongCountAsc) wrong \(result.wrongCountAsc > 1 ? "notes" : "note") ascending. "
            }
            else {
                ///Only show this if there were no wrong notes
                if result.missedCountAsc > 0 {
                    status += "\nYou missed \(result.missedCountAsc) \(result.missedCountAsc > 1 ? "notes" : "note") ascending. "
                }
            }
            if result.wrongCountDesc > 0 {
                status += "\nYou played \(result.wrongCountDesc) wrong \(result.wrongCountDesc > 1 ? "notes" : "note") descending. "
            }
            else {
                if result.missedCountDesc > 0 {
                    status += "\nYou missed \(result.missedCountDesc) \(result.missedCountDesc > 1 ? "notes" : "note") descending. "
                }
            }
        }
        if let tempo = ScalesModel.shared.scale.getTempo() {
            status += " Your tempo was \(tempo)."
        }
        let correct = result.wrongCountAsc == 0 && result.wrongCountDesc == 0 && result.missedCountAsc == 0 && result.missedCountDesc == 0
        return (correct, status)
    }
    
//    func scaleFollowStatus() -> (Bool, String) {
//        return (true, "finished scale follow")
//    }
    
    func status() -> (Bool, String)? {
//        if result.feedbackType == .assessWithScale {
            return recordStatus()
//        }
//        if result.feedbackType == .scaleFollow {
            //return scaleFollowStatus()
//        }
//        return nil
    }
    
    var body: some View {
        HStack {
            if let status = status() {
                if status.0 {
                    Image(systemName: "face.smiling")
                        .renderingMode(.template)
                        .foregroundColor(.green)
                        .font(.largeTitle)
                        .padding()
                }
                Text(status.1).padding()
            }
        }
    }
}

struct TapDataView: View {
    let scalesModel = ScalesModel.shared
    var keyboardModel:PianoKeyboardModel
        
    func amplData(key:PianoKeyModel) -> String {
        var asc:String = "______"
        if let a = key.keyClickedState.tappedAmplitudeAscending {
            asc = String(format: "%.4f", a)
        }
        return asc
    }
    
    func getColor(_ event:TapEvent) -> Color {
        var color = event.ascending ? Color.gray : Color.green
        if event.status == .keyPressWithNextScaleMatch {
            color = .blue
        }
        if event.status == .keyPressWithFollowingScaleMatch {
            color = .red
        }
        if event.status == .keyPressWithoutScaleMatch {
            color = .red
        }

        return color
    }
    
    var body: some View {
        VStack {
            Text("Notification Status").foregroundColor(Color .blue).font(.title3)//.padding()

            if let tapEvents = scalesModel.recordedEvents {
                ScrollView {
                    ForEach(tapEvents.events, id: \.self) { event in
                        Text(event.tapData()).foregroundColor(getColor(event))
                    }
                }
            }
            if let events = scalesModel.recordedEvents {
                Text("Stats: \(events.minMax())").foregroundColor(Color .blue).font(.title3).padding()
            }
            //Text("Config filter:\(result.amplitudeFilter) start:\(result.startAmplitude)").font(.title3).padding()
//            Text("Not in Scale").foregroundColor(Color .blue).font(.title3).padding()
        }
    }
}
