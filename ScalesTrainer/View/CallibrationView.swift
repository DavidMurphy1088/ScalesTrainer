import SwiftUI

public struct CallibrationView: View {
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    let scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    @State private var amplitudeFilterAdjust:Double = 0
    @State var callibrating = false
    
    func getInstructions() -> String {
        var msg = "Calibration is required so Scales Trainer can accurately hear your piano."
        msg += "\n\n👉 Hit Start and then play one or two notes as softly as you can then hit Stop."
        msg += "\n👉 Adjust callibration if the app is not accurately hearing your scale."
        msg += "\n👉 You will need to do callibration again if you change the location of where the app is positioned when it listens."
        return msg
    }
    
    public var body: some View {
        VStack() {
            Text("Piano Calibration").font(.title)
            Text(getInstructions()).padding()
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
                Settings.shared.amplitudeFilter = amplitudeFilterAdjust
                Settings.shared.save(false)
            })
            Button(callibrating ? "Stop" : "Start") {
                callibrating.toggle()
                if callibrating {
                    scalesModel.startMicrophoneWithTapHandler(.onWithCallibration, "Callibration Appear")
                }
                else {
                    self.audioManager.stopRecording()
                    scalesModel.calculateCallibration()
                    amplitudeFilterAdjust = Settings.shared.amplitudeFilter
                }
            }
            .padding()
            .hilighted(backgroundColor: .blue)
        }
        .onAppear() {
            scalesModel.selectedScaleRootIndex = 0
            scalesModel.setKeyAndScale()
            self.amplitudeFilterAdjust = Settings.shared.amplitudeFilter
        }
        .onDisappear() {
            Settings.shared.save()
            self.audioManager.stopRecording()
        }
    }
}

