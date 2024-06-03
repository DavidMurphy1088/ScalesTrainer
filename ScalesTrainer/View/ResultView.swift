import SwiftUI

struct ResultView: View {
    var keyboardModel:PianoKeyboardModel
    let result:Result
    let scalesModel = ScalesModel.shared
    
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
        
        if let tempo = ScalesModel.shared.scale.setNoteNormalizedValues() {
            status += " Your tempo was \(tempo)."
        }
        let correct = result.wrongCountAsc == 0 && result.wrongCountDesc == 0 && result.missedCountAsc == 0 && result.missedCountDesc == 0
        //ScalesModel.shared.scale.debug1("====Post Build, get tempo")
        return (correct, status)
    }

    func status() -> (Bool, String)? {
        if self.result.runningProcess == .recordingScale {
            return recordStatus()
        }
        if self.result.runningProcess == .followingScale {
            return (true, self.result.userMessage)
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(scalesModel.scale.getScaleName() + " ").hilighted()
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
}

//struct UserFeedbackView: View {
//    let scalesModel = ScalesModel.shared
//    let feedbackMsg:String
//    //var keyboardModel:PianoKeyboardModel
//
//    var body: some View {
//        Text(feedbackMsg)
//    }
//}

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
            color = .purple
        }
        if event.status == .keyPressWithoutScaleMatch {
            color = .red
        }
        return color
    }
    
    var body: some View {
        VStack {
            Text("Taps").foregroundColor(Color .blue).font(.title3)//.padding()

            if let tapEvents = scalesModel.recordedTapEvents {
                ScrollView {
                    ForEach(tapEvents.events, id: \.self) { event in
                        Text(event.tapData()).foregroundColor(getColor(event))
                    }
                }
            }
            if let events = scalesModel.recordedTapEvents {
                Text("Stats: \(events.minMax())").foregroundColor(Color .blue).font(.title3)
            }
            Text("AmplFilter: \(String(format: "%.4f", Settings.shared.amplitudeFilter))").foregroundColor(Color .blue).font(.title3)
        }
    }
}
