import Foundation
import SwiftUI

struct ResultView: View {
    @ObservedObject var result:Result
    
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
                Text("Index:\(unmatch.notePlayedSequence) Midi:\(unmatch.midi)")
            }

        }
    }
}
