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
        scalesModel.setMicMode(.off, ctx)
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
    
    func ActionView(followEnabled:Bool, practiceEnabled:Bool, assessScaleEnabled:Bool, backingEnabled:Bool) -> some View {
        HStack {
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
            
            if followEnabled {
                Spacer()
                Button(scalesModel.followScale ? "Stop Following" : "Follow The Scale") {
                    scalesModel.setFollowScale(!scalesModel.followScale)
                    //if scalesModel.followScale
                    //scalesModel.setAppMode(scalesModel.appMode == .none ? .scaleFollow : .none, "followMode")
                }.padding()
            }
            
            if practiceEnabled {
                Spacer()
                Button(practicing ? "Stop Practicing" : "Practice") {
                    practicing.toggle()
                    scalesModel.setMicMode(practicing ? .onWithPractice : .off, "practiceMode")
                }.padding()
            }
            
            if assessScaleEnabled {
                Spacer()
                Button(recordingScale ? "Stop Playing Your Scale" : "Record Your Scale") {
                    recordingScale.toggle()
                    if recordingScale {
                        DispatchQueue.main.async {
                            scalesModel.result = nil
                        }
                        //scalesModel.setMicMode(.assessWithScale, "scaleMode")
                        scalesModel.startRecordingScale(testData: false, onDone: {
                            askKeepTapsFile = true
                            recordingScale = false
                        })
                        self.practicing = false
                    }
                    else {
                        scalesModel.stopRecordingScale("Stop Button")
                        showResultPopup = false
                        DispatchQueue.main.async {
                            //scalesModel.result = Result(type: .practiceMode)
                            //scalesModel.result?.buildResult(feedbackType: .assessWithScale)
                        }
                        self.practicing = false
                    }
                }.padding()
                .alert(isPresented: $askKeepTapsFile) {
                    Alert(
                        title: Text("Keep Taps File?"),
                        message: Text("Keep Taps File?"),
                        primaryButton: .default(Text("Yes")) {
                        },
                        secondaryButton: .cancel(Text("No")) {
                            let fileManager = FileManager.default
                            do {
                                if let url = scalesModel.recordedTapsFileURL {
                                    try fileManager.removeItem(at: url)
                                    print("File deleted successfully.")
                                }
                            } catch {
                                Logger.shared.reportError(scalesModel, "Failed to delete file: \(error)")
                            }
                        }
                    )
                }
            }
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
    
//    func RecordingView() -> some View {
//        HStack {
//
//            
////                if scalesModel.appMode == .assessWithScale {
////
////                    Spacer()
////                    Button(hearingUserScale ? "Stop Hearing Your Scale" : "Hear Your Scale") {
////                        hearingUserScale.toggle()
////                        if hearingUserScale {
////                            metronome.startTimer(notified: PianoKeyboardModel.shared, tempoMultiplier: 1.0,
////                                                 onDone: {self.hearingUserScale = false})
////                        }
////                        else {
////                            metronome.stop()
////                        }
////                    }
////                    .padding()
////
////                    Spacer()
////                    Button(showingTapData ? "Close Tap Data" : "Show Tap Data") {
////                        showingTapData.toggle()
////                    }
////                    .padding()
////
////                }
//            Spacer()
//        }
//    }
    
    var body: some View {
        VStack() {
            SelectScaleView().commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
            Text(scalesModel.scale.getScaleName()).font(.title).padding()//.hilighted()
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                .frame(height: UIScreen.main.bounds.size.height / (orientationObserver.orientation.isPortrait ? 4 : 3))
                .commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
            
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
            
            if scalesModel.followScale {
                HStack {
                    Spacer()
                    Button("Stop Following Scale") {
                        scalesModel.setFollowScale(false)
                     }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    Spacer()
                }
            }
            else {
                if let result = scalesModel.result {
                    ResultView(keyboardModel: PianoKeyboardModel.shared, result: result).commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                
                if ["All"].contains(activityMode.name) {
                    ActionView(followEnabled: true, practiceEnabled: true, assessScaleEnabled: true, backingEnabled: true)
                        .commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }

                if ["Learn The Scale"].contains(activityMode.name) {
                    ActionView(followEnabled: true, practiceEnabled: true, assessScaleEnabled: false, backingEnabled: true)
                        .commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                
                if ["Practice The Scale"].contains(activityMode.name) {
                    ActionView(followEnabled: false, practiceEnabled: false, assessScaleEnabled: true, backingEnabled: false)
                        .commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
            }
            Text(scalesModel.scale.getScaleName())
            if settings.recordDataMode {
                Spacer()
                Button("READ_TEST_DATA") {
                    scalesModel.result = nil
                    recordingScale = true
                    scalesModel.setMicMode(.onWithScale, "readTestData")
                    scalesModel.startRecordingScale(testData: true, onDone: {
                        recordingScale = false
                    })
                }.padding()
            }
            
            Spacer()
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
            scalesModel.setMicMode(.off, "onAppear")
            ScalesModel.shared.setShowStaff(activityMode.showStaff)
            ScalesModel.shared.setShowFingers(activityMode.showFingers)
        }
        .onDisappear {
        }
        .navigationBarTitle("\(activityMode.name)", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

