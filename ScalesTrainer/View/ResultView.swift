import SwiftUI

struct ResultView: View {
    var keyboardModel:PianoKeyboardModel
    let result:Result
    let scalesModel = ScalesModel.shared
    
    func getAllCorrect() -> Bool {
        return result.missedFromScaleCountAsc == 0 && result.missedFromScaleCountDesc == 0 && result.playedAndWrongCountAsc == 0 && result.playedAndWrongCountDesc == 0
    }
    
    func recordStatus() -> (Bool, String) {
        var status = ""
        if getAllCorrect() {
            status = "Good job, your scale was correct."
        }
        else {
            status = "Your scale was not correct. "
            if result.playedAndWrongCountAsc > 0 {
                status += "\n⏺ You played \(result.playedAndWrongCountAsc) wrong \(result.playedAndWrongCountAsc > 1 ? "notes" : "note") ascending. "
            }
            else {
                ///Only show this if there were no wrong notes
                if result.missedFromScaleCountAsc > 0 {
                    status += "\n⏺ You missed \(result.missedFromScaleCountAsc) \(result.missedFromScaleCountAsc > 1 ? "notes" : "note") ascending. "
                }
            }
            if result.playedAndWrongCountDesc > 0 {
                status += "\n⏺ You played \(result.playedAndWrongCountDesc) wrong \(result.playedAndWrongCountDesc > 1 ? "notes" : "note") descending. "
            }
            else {
                if result.missedFromScaleCountDesc > 0 {
                    status += "\n⏺ You missed \(result.missedFromScaleCountDesc) \(result.missedFromScaleCountDesc > 1 ? "notes" : "note") descending. "
                }
            }
        }
        if getAllCorrect() {
            if let tempo = ScalesModel.shared.scale.setNoteNormalizedValues() {
                let metronome = MetronomeModel.shared
                let useQuaverTempo = tempo >= 120
                status += "\n⏺ Your tempo was \(metronome.getTempoString(tempo, useQuavers: useQuaverTempo)) "
                var appTempoString = ScalesModel.shared.tempoSettings[ScalesModel.shared.selectedTempoIndex]
                if appTempoString.count >= 2 {
                    ///Remove to noteType = prefix in tempo setting
                    let index = appTempoString.index(appTempoString.startIndex, offsetBy: 2)
                    appTempoString = String(appTempoString[index...])
                    let appTempo = Int(appTempoString)
                    if let appTempo = appTempo {
                        status += "and the metronome setting was \(metronome.getTempoString(appTempo, useQuavers: useQuaverTempo))."
                    }
                }
            }
        }
        return (getAllCorrect(), status)
    }

    func getResultStatus() -> (Bool, String)? {
        if [.recordingScale, .recordScaleWithFileData].contains(self.result.fromProcess) {
            return recordStatus()
        }
        if self.result.fromProcess == .followingScale {
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
        //var color = event.ascending ? Color.gray : Color.green
        var color = Color.gray
//        if event.status == .pressNextScaleMatch {
//            color = event.ascending ? .blue : .green
//        }
//        if event.status == .pressFollowingScaleMatch {
//            color = .purple
//        }
//        if event.status  == .wrongButWaitForNext {
//            color = .purple
//        }
//        if event.status == .pressWithoutScaleMatch {
//            color = .red
//        }
//        if event.status == .farFromExpected {
//            color = .orange
//        }
        if event.status == .belowAmplitudeFilter {
            color = .brown
        }
        if event.status == .keyPressed {
            color = event.ascending ? .purple : .green
        }
        if event.status == .discardedSingleton {
            color = .cyan
        }
        return color
    }
    
    var body: some View {
        VStack {
            Text("Taps").foregroundColor(Color .blue).font(.title3)//.padding()

            if let tapEventSet = scalesModel.tapHandlerEventSet {
                Text("AmplFilter: \(String(format: "%.4f", tapEventSet.amplitudeFilter)) \(tapEventSet.description)").foregroundColor(Color .blue).font(.title3)

                ScrollView {
                    ForEach(tapEventSet.events, id: \.self) { event in
                        if getColor(event) == .black {
                            Text(event.tapData()).foregroundColor(getColor(event))
                        }
                        else {
                            Text(event.tapData()).foregroundColor(getColor(event)).bold()
                        }
                    }
                }
            }
            if let eventSet = scalesModel.tapHandlerEventSet {
                Text("Stats: \(eventSet.minMax())").foregroundColor(Color .blue).font(.title3)
            }
        }
    }
}
