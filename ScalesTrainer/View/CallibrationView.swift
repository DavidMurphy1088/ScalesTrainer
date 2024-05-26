import SwiftUI

public struct CallibrationView: View {
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    let scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    //var score = Score(key: StaffKey(type: .major, keySig: KeySignature(keyName: "C", keyType: .major)), timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
    //var scale = Scale(key: Key(keyType: KeyType.major), scaleType: .major, octaves: 2, hand: 0)
    @State private var amplitudeFilterAdjust:Double = 0
    
    public var body: some View {
        VStack() {
            
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                .frame(height: UIScreen.main.bounds.size.height / 4)
                .commonFrameStyle(backgroundColor: .clear).padding()
            
            if let score = scalesModel.score {
                ScoreView(score: score, widthPadding: false).padding()
            }
            Text("Amplitude filter set at:\(String(format: "%.4f", amplitudeFilterAdjust))").font(.title3).padding()
            Slider(
                value: $amplitudeFilterAdjust,
                in: 0...0.5,
                step: 0.001
            )
            .padding()
            .onChange(of: amplitudeFilterAdjust, {
                scalesModel.amplitudeFilter = amplitudeFilterAdjust
            })

        }
        .onAppear() {
            scalesModel.selectedKeyNameIndex = 0
            //1scalesModel.selectedOctavesIndex = 1
            scalesModel.setKeyAndScale()
            scalesModel.setMicMode(.onWithPractice, "Callibration Appear")
            self.amplitudeFilterAdjust = scalesModel.amplitudeFilter
        }
        .onDisappear() {
            scalesModel.saveSetting(type: .amplitudeFilter, value: scalesModel.amplitudeFilter)
            scalesModel.setMicMode(.off, "Callibration Disappear")
        }
    }
}

