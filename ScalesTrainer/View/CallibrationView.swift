import SwiftUI

public struct CallibrationView: View {
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    let scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    @State private var amplitudeFilterAdjust:Double = 0
    @State var callibrating = false
    
    func getInstructions() -> String {
        var msg = "Calibration is required so Scales Trainer can accurately hear your piano."
        msg += "\n\n- Hit Start and then play one or two notes slowly and very softly then hit Stop."
        msg += "\n- Adjust callibration if the app is not accurately hearing your scale."
        msg += "\n- You will need to perform callibration again if you change the location of where the app is positioned when it listens."
        msg += "\n\n👉 For best recording results your device should be placed near or against your piano"
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

            Button(callibrating ? "Stop" : "Start") {
                callibrating.toggle()
                if callibrating {
                    scalesModel.setRunningProcess(.callibrating)
                }
                else {
                    scalesModel.calculateCallibration()
                    scalesModel.setRunningProcess(.none)
                    amplitudeFilterAdjust = Settings.shared.amplitudeFilter
                }
            }
            .padding()
            .hilighted(backgroundColor: .blue)
            
            if !callibrating {
                Text("Amplitude filter set at:\(String(format: "%.4f", amplitudeFilterAdjust))").font(.title3).padding()

                HStack {
                    Text("Manual adjust:").padding()
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
                }
            }
        }
        .onAppear() {
            //scalesModel.selectedScaleRootIndex = 0
            scalesModel.setKeyAndScale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, octaves: 2, hand: 0)
            self.amplitudeFilterAdjust = Settings.shared.amplitudeFilter
        }
        .onDisappear() {
            Settings.shared.save()
            self.audioManager.stopRecording()
        }
    }
}

