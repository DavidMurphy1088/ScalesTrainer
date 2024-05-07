import Foundation
import SwiftUI

struct ResultView: View {
    let scalesModel = ScalesModel.shared
    //@ObservedObject
    var keyboardModel:PianoKeyboardModel
    
//    func toStr(_ unmatch:UnMatchedType) -> String {
//        let amp = String(format: "%.4f", unmatch.amplitude)
//        return "TapNumber:\(unmatch.notePlayedSequence) Midi:\(unmatch.midi) Ampl:\(amp)"
//    }
    
    func minMax() -> String {
//        var stats = ""
//        var min = Double.infinity
//        var minMidi = 0
//        var max = 0.0
//        var maxMidi = 0
//        var unmatched = 0
        
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
 //       return "Unmatched:\(unmatched)  [min:\(minMidi), \(String(format: "%.4f", min))]    [max:\(maxMidi), \(String(format: "%.4f", max))]"
        return ""
    }
    
    func amplData(key:PianoKeyModel) -> String {
        var asc:String = "______"
        if let a = key.state.matchedAmplitudeAscending {
            asc = String(format: "%.4f", a)
        }
        return asc
    }
        
    var body: some View {
        VStack {
            Text("Result").font(.title3)

            Text("Scale Notes").foregroundColor(Color .blue).font(.title3)//.padding()
//            ForEach(keyboardModel.pianoKeyModel, id: \.self) { key in
//                Text("Key \(key.midi) \(amplData(key: key))")
//            }
            if let tapEvents = scalesModel.recordedEvents {
                ScrollView {
                    ForEach(tapEvents.event, id: \.self) { event in
                        Text(event.tapData())
                    }
                }
            }

            Text("Stats: \(minMax())").foregroundColor(Color .blue).font(.title3).padding()
            //Text("Config filter:\(result.amplitudeFilter) start:\(result.startAmplitude)").font(.title3).padding()
            
//            Text("Not in Scale").foregroundColor(Color .blue).font(.title3).padding()

        }
    }
}
