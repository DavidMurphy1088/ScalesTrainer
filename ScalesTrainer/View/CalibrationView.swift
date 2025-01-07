import SwiftUI

public struct CalibrationView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    @ObservedObject var pianoKeyboardViewModel = PianoKeyboardModel.sharedRH
    
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
    @State var requiredConsecutiveCount:Int = 0

//    func setScale(octaves:Int, hand:Int) {
//        let scaleRoot = ScaleRoot(name: "C")
//        self.scalesModel.selectedHandIndex = hand
//        scalesModel.setScaleByRootAndType(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand, ctx: "Callibration")
//        scalesModel.score = scalesModel.createScore(scale: Scale(scaleRoot: scaleRoot, scaleType: .major, octaves: octaves, hand: hand,
//                                                                 minTempo: 90, dynamicType: .mf, articulationType: .legato))
//        PianoKeyboardModel.sharedRightHand.redraw()
//    }
    
    func getScaleName() -> String {
        //let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: false, dynamic:false, articulation:false)
        let name = scalesModel.scale.getScaleName(handFull: true, octaves: true)
        return name
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
//            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel, keyColor: .white)
//                .frame(height: UIScreen.main.bounds.size.height / 6)
//                .commonFrameStyle(backgroundColor: .clear).padding()

            if let score = scalesModel.getScore() {
                ScoreView(scale: ScalesModel.shared.scale, score: score, barLayoutPositions: score.barLayoutPositions, widthPadding: false).padding()
            }
            
            if !playingScale {
                VStack {
                    Spacer()
                    if let result = scalesModel.resultPublished {
                        Text("Correct Notes:\(result.correctNotes) Errors:\(result.getTotalErrors())").font(.title3).padding().font(.title3).padding()
                    }
                    Text("Current Amplitude Filter:\(String(format: "%.4f", Settings.shared.amplitudeFilter))").font(.title3).padding()
                    Text("New Amplitude Filter:\(String(format: "%.4f", self.amplitudeFilter))").font(.title3).padding()
                    HStack {
                        Text("Required Consecutive Count").font(.title2).padding(0)
                        Picker("Select", selection: $requiredConsecutiveCount) {
                            ForEach(1..<9) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: requiredConsecutiveCount) { oldValue, newValue in
                            Settings.shared.requiredConsecutiveCount = newValue
                        }
                    }
                }
                HStack {
                    Text("Adjust:").padding()
                    Slider(
                        value: $amplitudeFilter,
                        in: 0...0.1,
                        step: 0.005
                    )
                    .padding()
                    .onChange(of: amplitudeFilter) { oldValue, newValue in
                        Settings.shared.amplitudeFilter = newValue
                    }
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

                Spacer()
                if playingScale {
                    Button(action: {
                        playingScale = false
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Playing").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
                else {
                    Button(action: {
                        playingScale = true
                        scalesModel.setRunningProcess(.leadingTheScale)
                    }) {
                        Text("Play The Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }

                    Spacer()
                    Button(action: {
                        Settings.shared.amplitudeFilter = self.amplitudeFilter
                        Settings.shared.save()
                        //tabSelectionManager.selectedTab = 1
                    }) {
                        HStack {
                            Text("Save Configuration").padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
                }
                Spacer()
            }
            if scalesModel.processedEventSetPublished  {
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
//            let octaves = ScalesTrainerApp.runningInXcode() ? 1 : 2
//            setScale(octaves: octaves, hand: 0)
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            self.amplitudeFilter = Settings.shared.amplitudeFilter
            self.requiredConsecutiveCount = Settings.shared.requiredConsecutiveCount
        }
        .onDisappear() {
            self.audioManager.stopListening()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.sharedRH)
        }
    }
}

