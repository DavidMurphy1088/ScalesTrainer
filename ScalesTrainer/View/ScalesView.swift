import SwiftUI

struct ScalesView: View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    @StateObject private var orientationObserver = DeviceOrientationObserver()

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
    
    let fftMode = false
    @State var stateSetup = true
    @State var amplitudeFilter: Double = 0.00
    @State var asynchHandle = true

    @State var playingSampleFile = false
    @State var hearingGivenScale = false
    @State var hearingUserScale = false
    @State var hearingBacking = false
    @State var practicing = false
    @State var showingTapData = false
    @State var recordingScale = false

    @State var speechAudioStarted = false
    @State var showResultPopup = false
    @State var notesHidden = false
    @State var staffHidden = false
    @State var askKeepTapsFile = false

    //@State var scaleFollow = false
    @State var scaleFollowWithSound = false

    init() {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
    }
    
    ///Set state of the model and the view
    func setState(_ ctx:String) {
        scalesModel.setKeyAndScale()
        scalesModel.setAppMode(.none, ctx)
        self.hearingGivenScale = false
        self.hearingUserScale = false
        //self.scaleFollow = false
        self.practicing = false
        self.directionIndex = 0
    }
    func ConfigView() -> some View {
        HStack {
            Spacer()
            Button(action: {
                staffHidden.toggle()
                scalesModel.scoreHidden = staffHidden
                scalesModel.forceRepaint()
            }) {
                if staffHidden {
                    HStack {
                        Text("Show Staff")
                        Image("eye_closed_trans")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                    }
                }
                else {
                    HStack {
                        Text("Hide Staff")
                        Image("eye_open_trans")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            
            Spacer()
            Button(action: {
                notesHidden.toggle()
                scalesModel.staffHidden = notesHidden
                scalesModel.forceRepaint()
            }) {
                if notesHidden {
                    HStack {
                        Text("Show Notes")
                        Image("eye_closed_trans")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                    }
                }
                else {
                    HStack {
                        Text("Hide Notes")
                        Image("eye_open_trans")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
    }
    
    func SelectScaleView() -> some View {
        HStack {
            Spacer()
            Text(LocalizedStringResource("Key"))
            Picker("Select Value", selection: $keyNameIndex) {
                ForEach(scalesModel.keyNameValues.indices, id: \.self) { index in
                    Text("\(scalesModel.keyNameValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: keyNameIndex, {
                scalesModel.selectedKeyNameIndex = keyNameIndex
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
    
    func PracticeView() -> some View {
        HStack {
            ConfigView().padding()
            
            Spacer()
            Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear Scale") {
                hearingGivenScale.toggle()
                if hearingGivenScale {
                    metronome.startTimer(notified: PianoKeyboardModel.shared, onDone: {
                        self.hearingGivenScale = false
                        //scalesModel.startPracticeHandler()
                    })
                }
                else {
                    metronome.stop()
                }
            }.padding()
            
            Button(hearingBacking ? "Stop Backing" : "Hear Backing") {
                hearingBacking.toggle()
                if hearingBacking {
                    metronome.startTimer(notified: Backer(), onDone: {
                        self.hearingGivenScale = false
                        //scalesModel.startPracticeHandler()
                    })
                }
                else {
                    metronome.stop()
                }
            }.padding()
            
            Spacer()
            Button(practicing ? "Stop Practicing" : "Practice") {
                practicing.toggle()
                scalesModel.setAppMode(practicing ? .practiceMode : .none, "practiceMode")
            }.padding()
            
            Spacer()
            Button("READ_TEST_DATA") {
                scalesModel.result = nil
                recordingScale = true
                scalesModel.setAppMode(.assessWithScale, "readTestData")
                scalesModel.startRecordingScale(testData: true, onDone: {
                    recordingScale = false
                })
            }.padding()
            
            Spacer()
        }
    }
    
    func RecordingView() -> some View {
        HStack {
            Spacer()
            Button(scalesModel.appMode == .scaleFollow ? "Stop Following" : "Follow Scale") {
                //scaleFollow.toggle()
                scalesModel.setAppMode(scalesModel.appMode == .none ? .scaleFollow : .none, "followMode")
            }.padding()

            if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                Spacer()
                let label = "Record Your Scale" + (scalesModel.appMode == .assessWithScale ? " Again" : "")
                Button(recordingScale ? "Stop Playing Your Scale" : label) {
                    recordingScale.toggle()
                    if recordingScale {
                        DispatchQueue.main.async {
                            scalesModel.result = nil
                        }
                        scalesModel.setAppMode(.assessWithScale, "scaleMode")
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
                            scalesModel.result = Result(type: .practiceMode)
                            scalesModel.result?.buildResult(feedbackType: .assessWithScale)
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
                
                if scalesModel.appMode == .assessWithScale {
//                    Spacer()
//                    Button(scalesModel.appMode == .assessWithScale ? "Show Given Scale" : "Show Your Scale") {
//                        //scalesModel.setAppMode(.recordingMode)
//                        if scalesModel.appMode == .practiceMode {
//                            
//                        }
//                        else {
//                            
//                        }
//                    }
//                    .padding()
                    
                    Spacer()
                    Button(hearingUserScale ? "Stop Hearing Your Scale" : "Hear Your Scale") {
                        hearingUserScale.toggle()
                        if hearingUserScale {
                            metronome.startTimer(notified: PianoKeyboardModel.shared,
                                                 onDone: {self.hearingUserScale = false})
                        }
                        else {
                            metronome.stop()
                        }
                    }
                    .padding()
                    
                    Spacer()
                    Button(showingTapData ? "Close Tap Data" : "Show Tap Data") {
                        showingTapData.toggle()
                    }
                    .padding()

                }

                Spacer()
            }
            else {
                Text("Calibration is required in Settings").padding()
            }
        }
    }
    
    var body: some View {
        //NavigationView {
            VStack() {
                //CustomBackButton()
                //Text("Scales Trainer").font(.title).bold()
                
                SelectScaleView().commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                
                PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                    .frame(height: UIScreen.main.bounds.size.height / 4)
                    .commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                
                if !orientationObserver.orientation.isAnyLandscape {
                    LegendView()
                }
                
                if !self.staffHidden {
                    VStack {
                        if let score = scalesModel.score {
                            ScoreView(score: score, widthPadding: false)
                        }
                    }.commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                
                if scalesModel.appMode == .scaleFollow {
                    HStack {
                        //                    Spacer()
                        //                    Toggle("With Sound", isOn: $scaleFollowWithSound)
                        Spacer()
                        ConfigView().padding()
                        Button("Stop Following") {
                            //                        scaleFollow = false
                            scalesModel.setAppMode(.none, "followMode")
                        }.padding()
                        Spacer()
                    }
                }
                else {
                    if let result = scalesModel.result {
                        ResultView(keyboardModel: PianoKeyboardModel.shared, result: result).commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    }
                    
                    PracticeView().commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    
                    RecordingView().commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                }
                
                Spacer()
            }
            .sheet(isPresented: $showingTapData) {
                TapDataView(keyboardModel: PianoKeyboardModel.shared)
            }
            ///Every time the view appears, not just the first.
            .onAppear {
                ///Required to get the score to paint on entry
                scalesModel.setKeyAndScale()
                pianoKeyboardViewModel.keyboardAudioManager = audioManager
                scalesModel.setAppMode(.none, "onAppear")
            }
            .onDisappear {
            }
        //}
        .navigationBarBackButtonHidden(true)
        //.navigationBarItems(leading: CustomBackButton(label: "In scales View"))
    }
}

