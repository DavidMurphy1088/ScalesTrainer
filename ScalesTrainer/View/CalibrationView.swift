import SwiftUI

public struct CalibrationView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    @ObservedObject var calibrationResults = ScalesModel.shared.calibrationResults
    
    let audioManager = AudioManager.shared
    @State private var amplitudeCalibrationValue:Double = 0
    @State var playingScale = false
    @State var analysingResults = false
    @State private var selectedOctaves = 1
    @State private var selectedHand = 0
    @State private var helpShowing = false
    @State private var userMessage:String = ""
    @State var showSaveQuestion = false
    
    func setScale(octaves:Int, hand:Int) {
        let scaleRoot = ScaleRoot(name: "C")
        //self.scalesModel.selectedOctavesIndex = octaves-1
        self.scalesModel.selectedHandIndex = hand
        scalesModel.setScaleByRootAndType(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand, ctx: "Callibration")
        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand))
        PianoKeyboardModel.shared.redraw()
        self.amplitudeCalibrationValue = scalesModel.amplitudeFilter
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

            //Spacer()
            
            if let results = calibrationResults.calibrationResults {
                List(results) { result in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(String(result.num))
                            Text("AmplFilter:")
                            Text(String(format: "%.4f", result.amplitudeFilter))
                            Text("MissedKeys[\(result.result.missedFromScaleCountAsc + result.result.missedFromScaleCountDesc)]")
                            //Text(String(result.result.missedCountAsc + result.result.missedCountDesc))
                            Text("WrongKeys[\(result.result.playedAndWrongCountAsc + result.result.playedAndWrongCountDesc)]")
                            //Text(String(result.result.wrongCountAsc + result.result.wrongCountDesc))

                            Text("Errors:").bold()
                            Text(String(result.result.getTotalErrors()))
                            Text("Best:").foregroundColor(result.lowestErrors ? Color.green : Color.black)
                            Text(String(result.lowestErrors))
                            Button(action: {
                                calibrationResults.run(amplitudeFilter: result.amplitudeFilter)
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
                    Spacer()
                    Text(userMessage).font(.title3).padding().font(.title3).padding()
                    Spacer()
                    Text("Current Amplitude Filter:\(String(format: "%.4f", amplitudeCalibrationValue))").font(.title3).padding()
                    Spacer()
                }
                HStack {
                    Text("Adjust:").padding()
                    Slider(
                        value: $amplitudeCalibrationValue,
                        in: 0...0.2,
                        step: 0.001
                    )
                    .padding()
//                    .onChange(of: scalesModel.amplitudeFilterDisplay, {
//                        amplitudeFilterAdjust = scalesModel.amplitudeFilterDisplay
//                    })

//                    .onChange(of: amplitudeFilterAdjust, {
//                        scalesModel.setAmplitudeFilter(amplitudeFilterAdjust)
//                        Settings.shared.save(amplitudeFilter: amplitudeFilterAdjust, false)
//                    })
                    if calibrationResults.calibrationEvents != nil {
                        Button(action: {
                            calibrationResults.run(amplitudeFilter: amplitudeCalibrationValue)
                        }) {
                            Text("View At\nThis Setting")
                        }
                    }
                }
            }
//            Spacer()

            HStack {
                if self.analysingResults {
                    Spacer()
                    let results = ScalesModel.shared.calibrationResults
                    if let status = results.status {
                        Spacer()
                        Text("Status: \(status)")
                    }
                }
                if !analysingResults {
                    Spacer()
                    Button(action: {
                        playingScale.toggle()
                        analysingResults = false
                        if playingScale {
                            scalesModel.calibrationResults.reset()
                            scalesModel.setRunningProcess(.calibrating, tapBufferSize: Settings.shared.tapBufferSize)
                        }
                        else {
                            scalesModel.setRunningProcess(.none, tapBufferSize: Settings.shared.tapBufferSize)
                            if let result = scalesModel.calibrationResults.calculateAverageAmplitude() {
                                userMessage = "Calibration as scale average " + String(format:"%.4f", result)
                                self.amplitudeCalibrationValue = result
                            }
                        }
                        
                    }) {
                        Text(playingScale ? "Stop Playing Scale" : "Start Playing Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }

                if true {
                    ///This section tries different amplitude Filters to find the best.
                    ///For the moment just go with the average calculated after the scale was recorded
                    if calibrationResults.calibrationEvents != nil {
                        Spacer()
                        let results = ScalesModel.shared.calibrationResults
                        if !analysingResults {
                            Button(action: {
                                analysingResults = true
                                results.analyseBestSettings(onNext: {amp in
                                    self.userMessage = "Analysing with " + String(format: "%.4f", amp) + ", please wait..."
                                }, onDone: {best in
                                    var msg = "Finished analysing."
                                    self.analysingResults = false
                                    if let best = best {
                                        msg += " Result:"+String(format:"%.4f", best)
                                        self.amplitudeCalibrationValue = best
                                    }
                                    self.userMessage = msg
                                },
                                                            tapBufferSize: Settings.shared.tapBufferSize)
                            })
                            {
                                Text("Analyse Best Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
                            }
                        }
                    }
                    Spacer()
                    Button(action: {
                        Settings.shared.save(amplitudeFilter: amplitudeCalibrationValue)
                    }) {
                        HStack {
                            Text("Save Configuration").padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
                    Spacer()
                }
            }

        }
        .sheet(isPresented: $helpShowing) {
            HelpView(topic: "Calibration")
        }
        .alert(isPresented: $showSaveQuestion) {
            //let calib =
            Alert(
                title: Text("Save"),
                message: Text("Save calibration " + String(format:"%.4f", self.amplitudeCalibrationValue) + " as the App's setting?"),
                primaryButton: .default(Text("Yes")) {
                    scalesModel.setAmplitudeFilter(self.amplitudeCalibrationValue)
                },
                secondaryButton: .default(Text("No")) {
                }
            )
        }
        .onAppear() {
            let octaves = ScalesTrainerApp.runningInXcode() ? 1 : 2
            setScale(octaves: octaves, hand: 0)
            PianoKeyboardModel.shared.resetKeysWerePlayedState()
            //ScalesModel.shared.selectedOctavesIndex = octaves == 1 ? 0 : 1
            ScalesModel.shared.selectedHandIndex = 0
            self.amplitudeCalibrationValue = Settings.shared.tapMinimunAmplificationFilter
        }
        .onDisappear() {
//            if scalesModel.amplitudeFilter != self.amplitudeCalibrationValue {
//                showSaveQuestion = true
//            }
            self.audioManager.stopRecording()
            self.scalesModel.setAmplitudeFilter(self.amplitudeCalibrationValue)
        }
    }
}

