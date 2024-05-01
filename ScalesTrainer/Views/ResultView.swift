import Foundation
import SwiftUI

struct ResultView: View {
    @ObservedObject var result:Result
    
    func toStr(_ unmatch:UnMatchedType) -> String {
        let amp = String(format: "%.4f", unmatch.amplitude)
        return "TapNumber:\(unmatch.notePlayedSequence) Midi:\(unmatch.midi) Ampl:\(amp)"
    }
    
    func minMax() -> String {
        var stats = ""
        var min = Double.infinity
        var minMidi = 0
        var max = 0.0
        var maxMidi = 0
        var unmatched = 0
        
        for note in result.scale.scaleNoteStates {
            if note.matchedTime == nil {
                unmatched += 1
            }
            else {
                if note.matchedAmplitude > max {
                    max = note.matchedAmplitude
                    maxMidi = note.midi
                }
                if note.matchedAmplitude > 0 {
                    if note.matchedAmplitude < min {
                        min = note.matchedAmplitude
                        minMidi = note.midi
                    }
                }
            }
        }
        return "Unmatched:\(unmatched)  [min:\(minMidi), \(String(format: "%.4f", min))]    [max:\(maxMidi), \(String(format: "%.4f", max))]"
    }
    
    var body: some View {
        VStack {
            Text("Result \(result.scale.key.getName())").font(.title)
            Text("Scale Notes").foregroundColor(Color .blue).padding()
            ScrollView {
                ForEach(result.scale.scaleNoteStates, id: \.self) { state in
                    let status = state.matchedTime == nil ? "--- Not found ---" : "Found \(String(format: "%.4f", state.matchedAmplitude ?? ""))"
                    Text("Seq:\(state.sequence) midi:\(state.midi) \(status)")
                }
            }
            Text("In Scale Stats: \(minMax())")

            Text("Not in Scale").foregroundColor(Color .blue).padding()
            ScrollView {
                ForEach(result.notInScale, id: \.self) { unmatch in
                    Text(toStr(unmatch))
                }
            }

        }
    }
}
