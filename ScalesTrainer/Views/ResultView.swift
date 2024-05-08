import Foundation
import SwiftUI

struct ResultView: View {
    var keyboardModel:PianoKeyboardModel
    
    func status() -> (Bool, String) {
        var missedCountAsc = 0
        var missedCountDesc = 0
        var wrongCountAsc = 0
        var wrongCountDesc = 0

        for i in 0..<keyboardModel.pianoKeyModel.count {
            let key = keyboardModel.pianoKeyModel[i]
            if let finger = key.noteFingering {
                if key.state.matchedTimeAscending == nil {
                    missedCountAsc += 1                    
                }
                if key.state.matchedTimeDescending == nil {
                    missedCountDesc += 1
                }
            }
            else {
                if key.state.matchedTimeAscending != nil {
                    wrongCountAsc += 1
                }
                if key.state.matchedTimeDescending != nil {
                    wrongCountAsc += 1
                }
            }
        }
        var status = ""
        if missedCountAsc == 0 && missedCountDesc == 0 && wrongCountAsc == 0 && wrongCountDesc == 0 {
            status = "Good job, your scale was correct."
        }
        else {
            status = "😔 Your scale was not correct. "
            if wrongCountAsc > 0 {
                status += "\nYou played \(wrongCountAsc) wrong \(wrongCountAsc > 1 ? "notes" : "note") ascending. "
            }
            if wrongCountDesc > 0 {
                status += "\nYou played \(wrongCountDesc) wrong \(wrongCountDesc > 1 ? "notes" : "note") descending. "
            }
            if missedCountAsc > 0 {
                status += "\nYou missed \(missedCountAsc) \(missedCountAsc > 1 ? "notes" : "note") ascending. "
            }
            if missedCountDesc > 0 {
                status += "\nYou missed \(missedCountDesc) \(missedCountDesc > 1 ? "notes" : "note") descending. "
            }
        }
        var correct = wrongCountAsc == 0 && wrongCountDesc == 0 && missedCountAsc == 0 && missedCountDesc == 0
        return (correct, status)
    }
    
    var body: some View {
        HStack {
            if status().0 {
                Image(systemName: "face.smiling")
                    .renderingMode(.template)
                    .foregroundColor(.green)
                    .font(.largeTitle)
                    .padding()
            }
            Text(status().1).padding()
        }
    }
}

struct TapDataView: View {
    let scalesModel = ScalesModel.shared
    var keyboardModel:PianoKeyboardModel
    
//    func toStr(_ unmatch:UnMatchedType) -> String {
//        let amp = String(format: "%.4f", unmatch.amplitude)
//        return "TapNumber:\(unmatch.notePlayedSequence) Midi:\(unmatch.midi) Ampl:\(amp)"
//    }
    
    func minMax() -> String {
        var stats = ""
        var min = Double.infinity
        var minMidi = 0
        var max = 0.0
        var maxMidi = 0
        var unmatched = 0
        
        if let taps = scalesModel.recordedEvents {
            for event in taps.event {
                if Double(event.amplitude) > max {
                    max = Double(event.amplitude)
                        maxMidi = event.midi
                    }
                if event.amplitude > 0 {
                    if Double(event.amplitude) < min {
                        min = Double(event.amplitude)
                        minMidi = event.midi
                    }
                }
            }
        }
        return "[min:\(minMidi), \(String(format: "%.4f", min))]    [max:\(maxMidi), \(String(format: "%.4f", max))]"
    }
    
    func amplData(key:PianoKeyModel) -> String {
        var asc:String = "______"
        if let a = key.state.matchedAmplitudeAscending {
            asc = String(format: "%.4f", a)
        }
        return asc
    }
    
    func getColor(_ event:TapEvent) -> Color {
        var color = Color.black
        if event.pressedKey {
            color = .blue
        }
        else {
            if !event.ascending {
                color = .green
            }
        }
        return color
    }
    
    func getStats() ->String {
        var stats = minMax()
        return stats
    }
    
    var body: some View {
        VStack {
            Text("Result").font(.title3)

            Text("Scale Notes").foregroundColor(Color .blue).font(.title3)//.padding()

            if let tapEvents = scalesModel.recordedEvents {
                ScrollView {
                    ForEach(tapEvents.event, id: \.self) { event in
                        Text(event.tapData()).foregroundColor(getColor(event))
                    }
                }
            }

            Text("Stats: \(getStats())").foregroundColor(Color .blue).font(.title3).padding()
            //Text("Config filter:\(result.amplitudeFilter) start:\(result.startAmplitude)").font(.title3).padding()
//            Text("Not in Scale").foregroundColor(Color .blue).font(.title3).padding()
        }
    }
}
