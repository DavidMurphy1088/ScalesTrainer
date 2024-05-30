import SwiftUI

struct ScalesView: View {
    let activityMode:ActivityMode

    @ObservedObject private var scalesModel = ScalesModel.shared
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared
    
    private var keyboardModel = PianoKeyboardModel.shared
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardModel
    @ObservedObject private var speech = SpeechManager.shared
    private var metronome = MetronomeModel.shared
    private let audioManager = AudioManager.shared

    @State private var octaveNumberIndex = 0
    @State private var handIndex = 0
    @State private var keyNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 2

    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    @State var amplitudeFilter: Double = 0.00

    @State var hearingGivenScale = false
    @State var hearingUserScale = false
    @State var hearingBacking = false
    @State var practicing = false
    @State var showingTapData = false
    @State var recordingScale = false

    @State var showResultPopup = false
    @State var notesHidden = false
    @State var askKeepTapsFile = false

    @State var scaleFollowWithSound = false
    @State var showingFeedback = false
    
    init(activityMode:ActivityMode) {
        //self.staffHidden = staffHidden
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
        self.activityMode = activityMode
    }
    
    ///Set state of the model and the view
    func setState(_ ctx:String) {
        scalesModel.setKeyAndScale()
        audioManager.stopRecording()
        self.hearingGivenScale = false
        self.hearingUserScale = false
        //self.scaleFollow = false
        self.practicing = false
        self.directionIndex = 0
    }
    
    func SelectScaleView() -> some View {
        HStack {
            Spacer()
            Text(LocalizedStringResource("Root"))
            Picker("Select Value", selection: $keyNameIndex) {
                ForEach(scalesModel.scaleRootValues.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleRootValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: keyNameIndex, {
                scalesModel.selectedScaleRootIndex = keyNameIndex
                setState("KeyChange")
            })
            
            Spacer()
            Text(LocalizedStringResource("Scale")).padding(0)
            Picker("Select Value", selection: $scaleTypeNameIndex) {
                ForEach(scalesModel.scaleTypeNames.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleTypeNames[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scaleTypeNameIndex, {
                scalesModel.selectedScaleTypeNameIndex = scaleTypeNameIndex
                setState("ScaleTypeChange")
            })
            
            Spacer()
            Text("Hand:")
            Picker("Select Value", selection: $handIndex) {
                ForEach(scalesModel.handTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.handTypes[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: handIndex, {
                scalesModel.selectedHandIndex = handIndex
                setState("HandChange")
            })
            Spacer()
            
            Text("Octaves:").padding(0)
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(scalesModel.octaveNumberValues.indices, id: \.self) { index in
                    Text("\(scalesModel.octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: octaveNumberIndex, {
                scalesModel.selectedOctavesIndex = octaveNumberIndex
                setState("OctavesChange")
            })
            
            Spacer()
            Text(LocalizedStringResource("Viewing\nDirection"))
            Picker("Select Value", selection: $directionIndex) {
                ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
                    if scalesModel.selectedDirection >= 0 {
                        Text("\(scalesModel.directionTypes[index])")
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: directionIndex, {
                scalesModel.setDirection(self.directionIndex)
            })
            
            Spacer()
            Text(LocalizedStringResource("Tempo"))
            Picker("Select Value", selection: $tempoIndex) {
                ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
                    Text("\(scalesModel.tempoSettings[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: tempoIndex, {
                scalesModel.setTempo(self.tempoIndex)
            })

            Spacer()
        }
    }
    
    func ActionView(hearScaleEnabled:Bool, followEnabled:Bool, practiceEnabled:Bool, assessScaleEnabled:Bool, backingEnabled:Bool) -> some View {
        HStack {
            if followEnabled {
                Spacer()
                Button(scalesModel.runningProcess == .followingScale ? "Stop Following" : "Follow The Scale") {
                    if scalesModel.runningProcess == .followingScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.followingScale)
                    }
                }.padding()
            }
            
            if practiceEnabled {
                Spacer()
                Button(practicing ? "Stop Practicing" : "Practice") {
                    practicing.toggle()
                    scalesModel.startMicrophoneWithTapHandler(practicing ? .onWithPractice : .off, "practiceMode")
                }.padding()
            }
                        
            if hearScaleEnabled {
                Spacer()
                Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear The Scale") {
                    hearingGivenScale.toggle()
                    if hearingGivenScale {
                        metronome.startTimer(notified: PianoKeyboardModel.shared, tempoMultiplier: 1.0, onDone: {
                            self.hearingGivenScale = false
                            //scalesModel.startPracticeHandler()
                        })
                    }
                    else {
                        metronome.stop()
                    }
                }.padding()
            }
            
            if assessScaleEnabled {
                Spacer()
                if followEnabled {
                    Spacer()
                    Button(scalesModel.runningProcess == .followingScale ? "Stop Recording" : "Record The Scale") {
                        if scalesModel.runningProcess == .followingScale {
                            scalesModel.setRunningProcess(.none)
                        }
                        else {
                            scalesModel.setRunningProcess(.recordingScale)
                        }
                    }.padding()
                }
            }
                
//                Button(recordingScale ? "Stop Playing Your Scale" : "Record Your Scale") {
//                    recordingScale.toggle()
//                    scalesModel.setMicMode(recordingScale ? .onWithRecordingScale : .off, "practiceMode")
//                    if recordingScale {
//                        DispatchQueue.main.async {
//                            scalesModel.result = nil
//                        }
//                        scalesModel.startRecordingScale(testData: false, onDone: {
//                            askKeepTapsFile = true
//                            recordingScale = false
//                        })
//                        self.practicing = false
//                    }
//                    else {
//                        scalesModel.stopRecordingScale("Stop Button")
//                        showResultPopup = false
//                        DispatchQueue.main.async {
//                            //scalesModel.result = Result(type: .practiceMode)
//                            //scalesModel.result?.buildResult(feedbackType: .assessWithScale)
//                        }
//                        self.practicing = false
//                    }
//                }.padding()
//                .alert(isPresented: $askKeepTapsFile) {
//                    Alert(
//                        title: Text("Keep Taps File?"),
//                        message: Text("Keep Taps File?"),
//                        primaryButton: .default(Text("Yes")) {
//                        },
//                        secondaryButton: .cancel(Text("No")) {
//                            let fileManager = FileManager.default
//                            do {
//                                if let url = scalesModel.recordedTapsFileURL {
//                                    try fileManager.removeItem(at: url)
//                                    print("File deleted successfully.")
//                                }
//                            } catch {
//                                Logger.shared.reportError(scalesModel, "Failed to delete file: \(error)")
//                            }
//                        }
//                    )
//                }
//            }
                
            if backingEnabled {
                Spacer()
                Button(hearingBacking ? "Backing Off" : "Backing On") {
                    hearingBacking.toggle()
                    if hearingBacking {
                        metronome.startTimer(notified: Backer(), tempoMultiplier: 0.5, onDone: {
                            //self.hearingGivenScale = false
                            //scalesModel.startPracticeHandler()
                        })
                    }
                    else {
                        metronome.stop()
                    }
                }.padding()
            }
            Spacer()
        }
    }
        
    var body: some View {
        VStack {
            //            Image("app_background_0_8")
            //                .resizable()
            //                .scaledToFill()
            //                .edgesIgnoringSafeArea(.top)
            //                .opacity(0.2)
            VStack() {
                if scalesModel.runningProcess == .none {
                    SelectScaleView().commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                Text(scalesModel.scale.getScaleName()).font(.title).padding()//.hilighted()
                PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                    .frame(height: UIScreen.main.bounds.size.height / (orientationObserver.orientation.isPortrait ? 4 : 3))
                    .commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                
                if !orientationObserver.orientation.isAnyLandscape {
                    LegendView()
                }
                
                if scalesModel.showStaff {
                    VStack {
                        if let score = scalesModel.score {
                            ScoreView(score: score, widthPadding: false)
                        }
                    }.commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                
                if scalesModel.runningProcess != .none {
                    if scalesModel.runningProcess == .followingScale {
                        HStack {
                            Spacer()
                            Button("Stop Following Scale") {
                                scalesModel.setRunningProcess(.none)
                            }
                            .padding()
                            .hilighted(backgroundColor: .blue)
                            Spacer()
                        }
                    }
                    if scalesModel.runningProcess == .identifyingScale {
                        HStack {
                            Spacer()
                            Button("Stop Hearing Scale") {
                                scalesModel.setRunningProcess(.none)
                            }
                            .padding()
                            .hilighted(backgroundColor: .blue)
                            Spacer()
                        }
                    }
                    if scalesModel.runningProcess == .recordingScale {
                        HStack {
                            Spacer()
                            Button("Stop Recording Scale") {
                                scalesModel.setRunningProcess(.none)
                            }
                            .padding()
                            .hilighted(backgroundColor: .blue)
                            Spacer()
                        }
                    }
                    
                }
                else {
                    if let result = scalesModel.result {
                        ResultView(keyboardModel: PianoKeyboardModel.shared, result: result).commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    
                    if ["All"].contains(activityMode.name) {
                        ActionView(hearScaleEnabled: true, followEnabled: true, practiceEnabled: true, assessScaleEnabled: true, backingEnabled: true)
                            .commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    
                    if ["Learning Mode"].contains(activityMode.name) {
                        ActionView(hearScaleEnabled: true, followEnabled: true, practiceEnabled: true, assessScaleEnabled: false, backingEnabled: true)
                            .commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    
                    if ["Record Scales"].contains(activityMode.name) {
                        ActionView(hearScaleEnabled: false, followEnabled: false, practiceEnabled: false, assessScaleEnabled: true, backingEnabled: false)
                            .commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    if ["Hear and Identify A Scale"].contains(activityMode.name) {
                        ActionView(hearScaleEnabled: true, followEnabled: false, practiceEnabled: false, assessScaleEnabled: false, backingEnabled: false)
                            .commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    
                }
                if settings.recordDataMode {
                    Spacer()
                    Button("READ_TEST_DATA") {
                        scalesModel.result = nil
                        recordingScale = true
                        scalesModel.startMicrophoneWithTapHandler(.onWithRecordingScale, "readTestData")
//                        scalesModel.startRecordingScale(testData: true, onDone: {
//                            recordingScale = false
//                        })
                        scalesModel.setRunningProcess(.recordingScale)
                    }.padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
        }
        
        .alert(isPresented: $showingFeedback) {
            Alert(
                title: Text("Followed \(scalesModel.scale.getScaleName())"),
                message: Text(scalesModel.userFeedback ?? "None"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: scalesModel.userFeedback, {showingFeedback = scalesModel.userFeedback != nil})
        
        ///Every time the view appears, not just the first.
        .onAppear {
            ///Required to get the score to paint on entry
            scalesModel.setKeyAndScale()
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            scalesModel.startMicrophoneWithTapHandler(.off, "onAppear")
            ScalesModel.shared.setShowStaff(activityMode.showStaff)
            ScalesModel.shared.setShowFingers(activityMode.showFingers)
            if ["Hear and Identify A Scale"].contains(activityMode.name) {
                let scaleRoot = Int.random(in: 0...scalesModel.scaleRootValues.count - 1)
                let scaleType = Int.random(in: 0...scalesModel.scaleTypeNames.count - 1)
                let hand = Int.random(in: 0...1)
                scalesModel.selectedHandIndex = hand
                scalesModel.selectedScaleRootIndex = scaleRoot
                scalesModel.selectedScaleTypeNameIndex = scaleType
                setState("ScaleTypeChange")
                scalesModel.setRunningProcess(.identifyingScale)
                metronome.startTimer(notified: IdentifyScalePlayer(), tempoMultiplier: 0.35, onDone: {
                    //self.hearingGivenScale = false
                    //scalesModel.startPracticeHandler()
                })
            }
        }
        .onDisappear {
            metronome.stop()
        }
        .navigationBarTitle("\(activityMode.name)", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


