import SwiftUI

public struct CalibrationView: View {
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    @ObservedObject var calibrationResults = ScalesModel.shared.calibrationResults
    
    let audioManager = AudioManager.shared
    @State private var amplitudeFilterAdjust:Double = 0
    @State var playingScale = false
    @State var analysingResults = false
    @State private var selectedOctaves = 1
    @State private var selectedHand = 0
    @State private var helpShowing = false
        
    func setScale(octaves:Int, hand:Int) {
        let scaleRoot = ScaleRoot(name: "C")
        self.scalesModel.selectedOctavesIndex = octaves-1
        self.scalesModel.selectedHandIndex = hand
        scalesModel.setKeyAndScale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand)
        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand))
        PianoKeyboardModel.shared.redraw()
        self.amplitudeFilterAdjust = scalesModel.amplitudeFilter
    }
    
    func getScaleName() -> String {
        let name = scalesModel.scale.getScaleName()
        return name
    }
    
    public var body: some View {
        VStack() {
            HStack {
                Text("Piano Calibration").font(.title)
                Button(action: {
                    self.helpShowing = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                        .font(.title2)//.bold()
                        .foregroundColor(.green)
                }
            }
            Text(getScaleName()).padding()
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
                    setScale(octaves: scalesModel.selectedOctavesIndex+1, hand: selectedHand)
                }

                Spacer()
                Button(playingScale ? "Stop Playing Scale" : "Start Playing Scale") {
                    playingScale.toggle()
                    analysingResults = false
                    if playingScale {
                        scalesModel.calibrationResults.reset()
                        scalesModel.setRunningProcess(.callibrating)
                    }
                    else {
                        scalesModel.calibrationResults.calculateCallibration()
                        scalesModel.setRunningProcess(.none)
                        amplitudeFilterAdjust = scalesModel.amplitudeFilter
                    }
                }
                
                if calibrationResults.calibrationEvents != nil {
                    Spacer()
                    let results = ScalesModel.shared.calibrationResults
                    if !analysingResults {
                        Button("Analyse Best Settings") {
                            analysingResults = true
                            results.analyseBestSettings(onDone: {
                                self.analysingResults = false
                            })
                        }
                    }
                }
                if self.analysingResults {
                    let results = ScalesModel.shared.calibrationResults
                    if let status = results.status {
                        Spacer()
                        Text("Status: \(status)")
                    }
                }
                Spacer()
            }
            
            if let results = calibrationResults.calibrationResults {
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
                            Text("Best:").foregroundColor(result.lowestErrors ? Color.green : Color.black)
                            Text(String(result.lowestErrors))
                            Button(action: {
                                calibrationResults.run(amplitudeFilter: result.amplFilter)
                            }) {
                                Text("View This Result")
                            }
                        }
                    }
                }
                .navigationTitle("Test runs")
            }
            
            if !playingScale {
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
                    if calibrationResults.calibrationEvents != nil {
                        Button(action: {
                            calibrationResults.run(amplitudeFilter: amplitudeFilterAdjust)
                        }) {
                            Text("View At\nThis Setting")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $helpShowing) {
            HelpView(topic: "Calibration")
        }
        .onAppear() {
            let octaves = ScalesTrainerApp().runningInXcode() ? 1 : 2
            setScale(octaves: octaves, hand: 0)
            PianoKeyboardModel.shared.resetKeysWerePlayedState()
            ScalesModel.shared.selectedOctavesIndex = octaves == 1 ? 0 : 1
            ScalesModel.shared.selectedHandIndex = 0
        }
        .onDisappear() {
            //Settings.shared.save()
            self.audioManager.stopRecording()
        }
    }
}
