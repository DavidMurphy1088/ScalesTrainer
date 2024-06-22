import SwiftUI

public struct CallibrationView: View {
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    @ObservedObject var callibrationResults = ScalesModel.shared.callibrationResults
    
    let audioManager = AudioManager.shared
    @State private var amplitudeFilterAdjust:Double = 0
    @State var callibrating = false
    @State private var selectedOctaves = 1
    @State private var selectedHand = 0

    func getInstructions() -> String {
        var msg = "Calibration is required so Scales Trainer can accurately hear your piano."
        msg += "\n\n- Hit Start and then play one or two notes slowly and very softly then hit Stop."
        msg += "\n- Adjust callibration if the app is not accurately hearing your scale."
        msg += "\n- You will need to perform callibration again if you change the location of where the app is positioned when it listens."
        msg += "\n\n👉 For best recording results your device should be placed near or against your piano"
        return msg
    }
    
    func setScale(octaves:Int, hand:Int) {
        let scaleRoot = ScaleRoot(name: "C")
        self.scalesModel.selectedOctavesIndex = octaves-1
        self.scalesModel.selectedHandIndex = hand
        scalesModel.setKeyAndScale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand)
        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand))
        PianoKeyboardModel.shared.redraw()
        self.amplitudeFilterAdjust = scalesModel.amplitudeFilter
    }
    
    public var body: some View {
        VStack() {
            Text("Piano Calibration").font(.title)
            //Text(getInstructions()).padding()
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                .frame(height: UIScreen.main.bounds.size.height / 6)
                .commonFrameStyle(backgroundColor: .clear).padding()
            
            if let score = scalesModel.score {
                ScoreView(score: score, widthPadding: false).padding()
            }
            HStack {
                Spacer()
                Text("Octaves")
                Picker("", selection: $selectedOctaves) {
                    ForEach(1..<5) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .onChange(of: selectedOctaves) { oldValue, newValue in
                    setScale(octaves: newValue, hand: selectedHand)
                }
                
                Spacer()
                Text("Hand")
                Picker("", selection: $selectedHand) {
                    ForEach(0..<2) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .onChange(of: selectedHand) { oldValue, newValue in
                    setScale(octaves: newValue, hand: selectedHand)
                }

                Spacer()
                Button(callibrating ? "Stop Playing Scale" : "Start Playing Scale") {
                    callibrating.toggle()
                    if callibrating {
                        scalesModel.callibrationResults.reset()
                        scalesModel.setRunningProcess(.callibrating)
                    }
                    else {
                        scalesModel.callibrationResults.calculateCallibration()
                        scalesModel.setRunningProcess(.none)
                        amplitudeFilterAdjust = scalesModel.amplitudeFilter
                    }
                }
                
                if callibrationResults.callibrationEvents != nil {
                    Spacer()
                    Button("Analyse Best Settings") {
                        ScalesModel.shared.callibrationResults.analyseBestSettings()
                    }
                }
                Spacer()
            }
            
            if let results = callibrationResults.results {
                List(results) { result in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(result.num))
                            Text("AmplFilter:")
                            Text(String(format: "%.4f", result.amplFilter))
                            Text("MissedKeys[\(result.result.missedCountAsc + result.result.missedCountDesc)]")
                            //Text(String(result.result.missedCountAsc + result.result.missedCountDesc))
                            Text("WrongKeys[\(result.result.wrongCountAsc + result.result.wrongCountDesc)]")
                            //Text(String(result.result.wrongCountAsc + result.result.wrongCountDesc))

                            Text("Errors:").bold()
                            Text(String(result.result.totalErrors()))
                            Text("Best:").foregroundColor(result.best ? Color.green : Color.black)
                            Text(String(result.best))
                            Button(action: {
                                callibrationResults.run(amplitudeFilter: result.amplFilter)
                            }) {
                                Text("View This Result")
                            }
                        }
                    }
                }
                .navigationTitle("Test runs")
            }
            
            if !callibrating {
                HStack {
                    //Text("Amplitude1:\(String(format: "%.4f", scalesModel.amplitudeFilterDisplay))").font(.title3).padding()
                    Text("Amplitude filter:\(String(format: "%.4f", amplitudeFilterAdjust))").font(.title3).padding()
                    Text("Adjust:").padding()
                    Slider(
                        value: $amplitudeFilterAdjust,
                        in: 0...0.3,
                        step: 0.001
                    )
                    .padding()
                    .onChange(of: scalesModel.amplitudeFilterDisplay, {
                        amplitudeFilterAdjust = scalesModel.amplitudeFilterDisplay
                    })

                    .onChange(of: amplitudeFilterAdjust, {
                        scalesModel.setAmplitudeFilter(amplitudeFilterAdjust)
                        Settings.shared.save(amplitudeFilter: amplitudeFilterAdjust, false)
                    })
                    if callibrationResults.callibrationEvents != nil {
                        Button(action: {
                            callibrationResults.run(amplitudeFilter: amplitudeFilterAdjust)
                        }) {
                            Text("View At\nThis Setting")
                        }
                    }
                }
            }
        }
        .onAppear() {
            //scalesModel.selectedScaleRootIndex = 0
            setScale(octaves: 1, hand: 0)
        }
        .onDisappear() {
            //Settings.shared.save()
            self.audioManager.stopRecording()
        }
    }
}

