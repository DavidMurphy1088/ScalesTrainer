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
        
//        for note in result.scale.scaleNoteStates {
//            if note.matchedTimeAscending == nil {
//                unmatched += 1
//            }
//            else {
//                if let amplitudeAscending = note.matchedAmplitudeAscending {
//                    if amplitudeAscending > max {
//                        max = amplitudeAscending
//                        maxMidi = note.midi
//                    }
//                    if amplitudeAscending > 0 {
//                        if amplitudeAscending < min {
//                            min = amplitudeAscending
//                            minMidi = note.midi
//                        }
//                    }
//                }
//            }
//        }
        return "Unmatched:\(unmatched)  [min:\(minMidi), \(String(format: "%.4f", min))]    [max:\(maxMidi), \(String(format: "%.4f", max))]"
    }
    
    var body: some View {
        VStack {
            Text("Result \(result.scale.key.getName())").font(.title3)

            Text("Scale Notes").foregroundColor(Color .blue).font(.title3)//.padding()
//            ScrollView {
//                VStack {
//                    ForEach(result.scale.scaleNoteStates, id: \.self) { state in
//                        let status = (state.matchedTimeAscending == nil && state.matchedTimeDescending == nil) ? "--- Not found ---" : "Found \(String(format: "%.4f", state.matchedAmplitudeAscending ?? ""))"
//                        Text("Seq:\(state.sequence) midi:\(state.midi) \(status)")
//                    }
//                }
//                .background(
//                    // Gradient overlay to indicate more content below
//                    LinearGradient(gradient: Gradient(colors: [.clear, .white]), startPoint: .center, endPoint: .bottom)
//                        .frame(height: 60)
//                        .offset(y: 50)
//                )
//            }
            Text("Stats: \(minMax())").foregroundColor(Color .blue).font(.title3).padding()
            Text("Config filter:\(result.amplitudeFilter) start:\(result.startAmplitude)").font(.title3).padding()
            
            Text("Not in Scale").foregroundColor(Color .blue).font(.title3).padding()
            ScrollView {
                ForEach(result.notInScale, id: \.self) { unmatch in
                    Text(toStr(unmatch))
                }
            }
        }
    }
}
