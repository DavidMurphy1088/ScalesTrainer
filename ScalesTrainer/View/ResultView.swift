import SwiftUI

struct ResultView: View {
    var keyboardModel:PianoKeyboardModel
    let result:Result
    let scalesModel = ScalesModel.shared
    
    func getaAllCorrect() -> Bool {
        return result.missedCountAsc == 0 && result.missedCountDesc == 0 && result.wrongCountAsc == 0 && result.wrongCountDesc == 0
    }
    
    func recordStatus() -> (Bool, String) {
        var status = ""
        if getaAllCorrect() {
            status = "Good job, your scale was correct."
        }
        else {
            status = "Your scale was not correct. "
            if result.wrongCountAsc > 0 {
                status += "\n⏺ You played \(result.wrongCountAsc) wrong \(result.wrongCountAsc > 1 ? "notes" : "note") ascending. "
            }
            else {
                ///Only show this if there were no wrong notes
                if result.missedCountAsc > 0 {
                    status += "\n⏺ You missed \(result.missedCountAsc) \(result.missedCountAsc > 1 ? "notes" : "note") ascending. "
                }
            }
            if result.wrongCountDesc > 0 {
                status += "\n⏺ You played \(result.wrongCountDesc) wrong \(result.wrongCountDesc > 1 ? "notes" : "note") descending. "
            }
            else {
                if result.missedCountDesc > 0 {
                    status += "\n⏺ You missed \(result.missedCountDesc) \(result.missedCountDesc > 1 ? "notes" : "note") descending. "
                }
            }
        }
        if getaAllCorrect() {
            if let tempo = ScalesModel.shared.scale.setNoteNormalizedValues() {
                let appTempo = Int(ScalesModel.shared.tempoSettings[ScalesModel.shared.selectedTempoIndex])
                if let appTempo = appTempo {
                    let metronome = MetronomeModel.shared
                    status += "\nYour tempo was \(metronome.getTempoString(tempo)) and the setting was \(metronome.getTempoString(appTempo))."
                }
            }
        }
        //ScalesModel.shared.scale.debug1("====Post Build, get tempo")
        return (getaAllCorrect(), status)
    }

    func getResultStatus() -> (Bool, String)? {
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
                //Text("  \(scalesModel.scale.getScaleName())  ").hilighted()
                if let status = getResultStatus() {
                    if status.0 {
                        Text("😊").font(.system(size: 45))
                    }
                    else {
                        Text("😔").font(.system(size: 45))
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
        if let a = key.keyWasPlayedState.tappedAmplitudeAscending {
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

            if let tapEventSet = scalesModel.tapHandlerEventSet {
                ScrollView {
                    ForEach(tapEventSet.events, id: \.self) { event in
                        Text(event.tapData()).foregroundColor(getColor(event))
                    }
                }
            }
            if let eventSet = scalesModel.tapHandlerEventSet {
                Text("Stats: \(eventSet.minMax())").foregroundColor(Color .blue).font(.title3)
            }
            Text("AmplFilter: \(String(format: "%.4f", ScalesModel.shared.amplitudeFilter))").foregroundColor(Color .blue).font(.title3)
        }
    }
}
