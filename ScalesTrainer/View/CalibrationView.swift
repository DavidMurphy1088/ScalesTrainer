import SwiftUI

public struct CalibrationView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.sharedRightHand
    
    let audioManager = AudioManager.shared
    @State private var amplitudeFilter:Double = 0
    @State var playingScale = false
    @State var analysingResults = false
    @State private var selectedOctaves = 1
    @State private var selectedHand = 0
    @State private var helpShowing = false
    @State var showSaveQuestion = false
    @State var showingTapData = false
    @State var info:String? = nil
    
    func setScale(octaves:Int, hand:Int) {
        let scaleRoot = ScaleRoot(name: "C")
        //self.scalesModel.selectedOctavesIndex = octaves-1
        self.scalesModel.selectedHandIndex = hand
        scalesModel.setScaleByRootAndType(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand, ctx: "Callibration")
        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand,
                                                                 minTempo: 90, dynamicType: .mf, articulationType: .legato))
        PianoKeyboardModel.sharedRightHand.redraw()
        //self.amplitudeFilter = Settings.shared.amplitudeFilter
    }
    
    func getScaleName() -> String {
        let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: false, dynamic:false, articulation:false)
        return name
    }
    public var body1: some View {
        VStack {
            Text("asddasd")
        }
    }
    
    func getStartAmplitudeAndInfo(tapEventSet:TapEventSet) -> (Double, String) {
        var trailingAmplitudes:[Float] = []
        var recent:[Float] = []
        var allAmplitudes:[Float] = []
        let bufferFactor =  Double(4096) / Double(tapEventSet.bufferSize)
        let recentMaxSize = Int(4 * bufferFactor)
        let trailingMaxSize = Int(32 * bufferFactor)
        var foundStart = false
        var maxAmplitude:Float = 0
        
        func calculateAverage(_ array:[Float]) -> Float {
            guard !array.isEmpty else { return 0.0 } // Return 0.0 if the array is empty
            let sum = array.reduce(0, +)
            return sum / Float(array.count)
        }
        
        var trailingAvg:Float = 0.0
        
        for i in 0..<tapEventSet.events.count {
            let event = tapEventSet.events[i]
            allAmplitudes.append(event.amplitude)
            if event.amplitude > maxAmplitude {
                maxAmplitude = event.amplitude
            }
            if foundStart {
                continue
            }
            
            trailingAmplitudes.append(event.amplitude)
            if trailingAmplitudes.count > trailingMaxSize {
                trailingAmplitudes.remove(at: 0)
            }

            recent.append(event.amplitude)
            if recent.count > recentMaxSize {
                recent.remove(at: 0)
            }
            trailingAvg = calculateAverage(trailingAmplitudes)
            let recentAvg = calculateAverage(recent)
            let delta = trailingAvg == 0 ? 0 : (recentAvg - trailingAvg) / trailingAvg

            if delta > 1 {
                foundStart = true
            }
        }
        let avg = calculateAverage(allAmplitudes)
        let info = "maxAmpl:\(String(format: "%.2f", maxAmplitude)) avgAmpl:\(String(format: "%.2f", avg)) taps:\(tapEventSet.events.count) bufferSize:\(tapEventSet.bufferSize)"
        return (Double(trailingAvg), info)
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
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel, keyColor: .white)
                .frame(height: UIScreen.main.bounds.size.height / 6)
                .commonFrameStyle(backgroundColor: .clear).padding()

            if let score = scalesModel.score {
                ScoreView(score: score, widthPadding: false).padding()
            }
            
            if !playingScale {
                VStack {
                    Spacer()
                    if let result = scalesModel.resultPublished {
                        Text("Correct Notes:\(result.correctNotes) Errors:\(result.getTotalErrors())").font(.title3).padding().font(.title3).padding()
                    }
                    Text("Current Amplitude Filter:\(String(format: "%.4f", Settings.shared.amplitudeFilter))").font(.title3).padding()
                    Text("New Amplitude Filter:\(String(format: "%.4f", self.amplitudeFilter))").font(.title3).padding()
                    if let info = self.info {
                        Text(info).font(.title3).padding()
                    }
                    Spacer()
                }
                HStack {
                    Text("Adjust:").padding()
                    Slider(
                        value: $amplitudeFilter,
                        in: 0...0.1,
                        step: 0.01
                    )
                    .padding()
                }
            }

            HStack {
                if self.analysingResults {
                    Spacer()
                    if let results = ScalesModel.shared.resultPublished {
                        Spacer()
                        Text("Status: \(results.getTotalErrors())")
                    }
                }
//                if !analysingResults {
//                    Spacer()
//                    Button(action: {
//                        playingScale.toggle()
//                        analysingResults = false
//                        if playingScale {
//                            scalesModel.setRunningProcess(.recordingScale)
//                        }
//                        else {
//                            for handler in scalesModel.tapHandlers {
//                                if handler.getBufferSize() == 4096 {
//                                    let eventSet = handler.stopTappingProcess()
//                                    (self.amplitudeFilter, self.info) = self.getStartAmplitudeAndInfo(tapEventSet: eventSet)
//                                    //Settings.shared.amplitudeFilter = self.amplitudeFilter
//                                }
//                            }
//                            scalesModel.setRunningProcess(.none)
//                        }
//                        
//                    }) {
//                        Text(playingScale ? "Stop Playing Scale" : "Start Playing Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
//                    }
//                }
                
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
                    tabSelectionManager.selectedTab = 1
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
            PianoKeyboardModel.sharedRightHand.resetKeysWerePlayedState()
            ScalesModel.shared.selectedHandIndex = 0
            self.amplitudeFilter = Settings.shared.amplitudeFilter
        }
        .onDisappear() {
            self.audioManager.stopRecording()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRightHand)
        }
    }
}

