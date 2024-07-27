import SwiftUI

public struct CalibrationView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.shared
    //@ObservedObject var calibrationResults = ScalesModel.shared.calibrationResults
    
    let audioManager = AudioManager.shared
    @State private var amplitudeFilter:Double = 0
    @State var playingScale = false
    @State var analysingResults = false
    @State private var selectedOctaves = 1
    @State private var selectedHand = 0
    @State private var helpShowing = false
    @State var showSaveQuestion = false
    @State var showingTapData = false
    
    func setScale(octaves:Int, hand:Int) {
        let scaleRoot = ScaleRoot(name: "C")
        //self.scalesModel.selectedOctavesIndex = octaves-1
        self.scalesModel.selectedHandIndex = hand
        scalesModel.setScaleByRootAndType(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand, ctx: "Callibration")
        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand))
        PianoKeyboardModel.shared.redraw()
        self.amplitudeFilter = Settings.shared.amplitudeFilter
    }
    
    func getScaleName() -> String {
        let name = scalesModel.scale.getScaleName()
        return name
    }
    public var body1: some View {
        VStack {
            Text("asddasd")
        }
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
            
            if !playingScale {
                HStack {
                    Spacer()
                    if let result = scalesModel.resultPublished {
                        Text("Correct:\(result.correctNotes) Errors:\(result.getTotalErrors())").font(.title3).padding().font(.title3).padding()
                    }
                    Spacer()
                    Text("Current Amplitude Filter:\(String(format: "%.4f", amplitudeFilter))").font(.title3).padding()
                    Spacer()
                }
                HStack {
                    Text("Adjust:").padding()
                    Slider(
                        value: $amplitudeFilter,
                        in: 0...0.2,
                        step: 0.01
                    )
                    .padding()
                }
            }

            HStack {
                if self.analysingResults {
                    Spacer()
                    if let results = ScalesModel.shared.resultPublished {
                        //let status = results.getInfo() {
                            Spacer()
                            Text("Status: \(results.getTotalErrors())")
                        //}
                    }
                }
                if !analysingResults {
                    Spacer()
                    Button(action: {
                        playingScale.toggle()
                        analysingResults = false
                        if playingScale {
                            //scalesModel.calibrationResults.reset()
                            //scalesModel.setRunningProcess(.calibrating)
                            scalesModel.setRunningProcess(.recordingScale)
                        }
                        else {
                            Settings.shared.amplitudeFilter = self.amplitudeFilter
                            scalesModel.setRunningProcess(.none)
//                            if let result = scalesModel.resultPublished {
//                                userMessage = "Calibration as scale average " + String(format:"%.4f", result)
//                                //self.amplitudeCalibrationValue = result
//                            }
                        }
                        
                    }) {
                        Text(playingScale ? "Stop Playing Scale" : "Start Playing Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
                
                ///This section tries different amplitude Filters to find the best.
                ///For the moment just go with the average calculated after the scale was recorded
//                if calibrationResults.calibrationEvents != nil {
//                    Spacer()
//                    let results = ScalesModel.shared.calibrationResults
//                    if !analysingResults {
//                        Button(action: {
//                            analysingResults = true
//                            results.analyseBestSettings(onNext: {amp in
//                                self.userMessage = "Analysing with " + String(format: "%.4f", amp) + ", please wait..."
//                            }, onDone: {best in
//                                var msg = "Finished analysing."
//                                self.analysingResults = false
//                                if let best = best {
//                                    msg += " Result:"+String(format:"%.4f", best)
//                                    self.amplitudeCalibrationValue = best
//                                }
//                                self.userMessage = msg
//                            },
//                                                        tapBufferSize: Settings.shared.defaultTapBufferSize)
//                        })
//                        {
//                            Text("Analyse Best Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
//                        }
//                    }
//                }
                Spacer()
                Button(action: {
                    Settings.shared.amplitudeFilter = self.amplitudeFilter
                    Settings.shared.save()
                }) {
                    HStack {
                        Text("Save Configuration").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
                Spacer()
            }
            if scalesModel.tapHandlerEventSetPublished  {
                Spacer()
                Button(action: {
                    showingTapData = true
                }) {
                    HStack {
                        Text("Show Tap Data").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
            Spacer()
        }
        .sheet(isPresented: $helpShowing) {
            HelpView(topic: "Calibration")
        }
//        .alert(isPresented: $showSaveQuestion) {
//            Alert(
//                title: Text("Save"),
//                message: Text("Save calibration " + String(format:"%.4f", self.amplitudeFilter) + " as the App's setting?"),
//                primaryButton: .default(Text("Yes")) {
//                    //scalesModel.setAmplitudeFilter1(self.amplitudeCalibrationValue)
//                },
//                secondaryButton: .default(Text("No")) {
//                }
//            )
//        }
        .onAppear() {
            let octaves = ScalesTrainerApp.runningInXcode() ? 1 : 2
            setScale(octaves: octaves, hand: 0)
            PianoKeyboardModel.shared.resetKeysWerePlayedState()
            ScalesModel.shared.selectedHandIndex = 0
            self.amplitudeFilter = Settings.shared.amplitudeFilter
        }
        .onDisappear() {
            self.audioManager.stopRecording()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
        }
    }
}

