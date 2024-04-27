import Foundation
import SwiftUI

struct ResultView: View {
    @ObservedObject var result:Result
    
    func toStr(_ unmatch:UnMatchedType) -> String {
        let amp = String(format: "%.4f", unmatch.amplitude)
        return "Index:\(unmatch.notePlayedSequence) Midi:\(unmatch.midi) Ampl:\(amp)"
    }
    
    var body: some View {
        VStack {
            Text("Result \(result.scale.key.getName())").font(.title)
            Text("Missing from Scale").foregroundColor(Color .blue).padding()
            ForEach(result.scale.scaleNoteStates, id: \.self) { state in
                if state.matchedTime == nil {
                    Text("\(state.sequence) \(state.midi)")
                }
            }
            Text("Not in Scale").foregroundColor(Color .blue).padding()
            ForEach(result.notInScale, id: \.self) { unmatch in
                Text(toStr(unmatch))
            }

        }
    }
}
