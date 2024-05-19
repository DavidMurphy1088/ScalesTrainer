import SwiftUI

struct ScalesView: View {
    @ObservedObject private var scalesModel = ScalesModel.shared
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
    @State private var tempoIndex = 4

    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    let fftMode = false
    @State var stateSetup = true
    @State var amplitudeFilter: Double = 0.00
    @State var asynchHandle = true

    @State var playingSampleFile = false
    @State var hearingGivenScale = false
    @State var hearingUserScale = false
    @State var practicing = false
    @State var showingTapData = false
    @State var recordingScale = false

    @State var speechAudioStarted = false
    @State var showResultPopup = false
    @State var notesHidden = false
    @State var staffHidden = false
    @State var askKeepTapsFile = false
    
    init() {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
    }
    
    func width() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    func fingerChangeName() -> String {
        var name:String
        if scalesModel.selectedHandIndex == 0 {
            if scalesModel.selectedDirection == 0 {
                name = "Thumb Under"
            }
            else {
                name = "Finger Over"
            }
        }
        else {
            if scalesModel.selectedDirection == 0 {
                name = "Finger Over Note"
            }
            else {
                name = "Thumb Under Note"
            }
        }
        return name
    }
    
    func LegendView() -> some View {
        HStack {
            if scalesModel.appMode == .none || scalesModel.appMode == .practicingMode {
                Spacer()
                Text("1").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                Text("Finger Number")
                
                Spacer()
                Text("-1-").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).font(.title2).bold()
                Text(fingerChangeName())
                
                Spacer()
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: width())
                Text("Note is Playing")
                Spacer()
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: width())
                Text("Playing But Not in Scale")

                Spacer()
            }
            
            if scalesModel.appMode == .playingWithScale {
                Spacer()
                if scalesModel.appMode == .playingWithScale {
                    Text("  Listening to your scale  ")
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white) // Change the text color to white for better contrast
                }
                Spacer()
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: width())
                Text("Correctly Played")
                Spacer()
                Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: width())
                Text("Played But Not in Scale")
                Spacer()
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: width())
                Text("In Scale But Not Played")

                Spacer()
            }
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
                scalesModel.setKeyAndScale()
                scalesModel.setAppMode(.none)
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
                scalesModel.setKeyAndScale()
                scalesModel.setAppMode(.none)
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
                scalesModel.setKeyAndScale()
                scalesModel.setAppMode(.none)
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
                scalesModel.setKeyAndScale()
                scalesModel.setAppMode(.none)
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
                scalesModel.scale.resetMatchedData() ///in listen mode clear wrong notes
            })
            .onChange(of: scalesModel.selectedDirection, {
                self.directionIndex = scalesModel.selectedDirection
            })
            
            Spacer()
            Text(LocalizedStringResource("Tempo"))
            Picker("Select Value", selection: $tempoIndex) {
                ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
                    //if scalesModel.selectedDirection >= 0 {
                        Text("\(scalesModel.tempoSettings[index])")
                    //}
                }
            }
            .pickerStyle(.menu)
            .onChange(of: tempoIndex, {
                scalesModel.setTempo(self.tempoIndex)
                //scalesModel.scale.resetMatchedData() ///in listen mode clear wrong notes
            })

            Spacer()
        }
    }
    
    func PracticeView() -> some View {
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
            
            Spacer()
            Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear Scale") {
                hearingGivenScale.toggle()
                //scalesModel.stopPracticeHandler()
                if hearingGivenScale {
                    metronome.startTimer(notified: PianoKeyboardModel.shared, userScale: false, onDone: {
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
                scalesModel.setAppMode(practicing ? .practicingMode : .none)
            }.padding()
            
            Spacer()
        }
    }
    
    func RecordingView() -> some View {
        HStack {
            if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                Spacer()
                
                Button("TEST_DATA") {
                    scalesModel.result = nil
                    recordingScale = true
                    scalesModel.setAppMode(.playingWithScale)
                    scalesModel.startRecordingScale(testData: true, onDone: {
                        recordingScale = false
                        scalesModel.result = Result()
                        scalesModel.result?.makeResult()
                    })
                }.padding()
                
                Spacer()
                Button(recordingScale ? "Stop Playing Your Scale" : "Play Your Scale") {
                    recordingScale.toggle()
                    if recordingScale {
                        scalesModel.result = nil
                        scalesModel.setAppMode(.playingWithScale)
                        scalesModel.startRecordingScale(testData: false, onDone: {
                            askKeepTapsFile = true
                        })
                        self.practicing = false
                        
                    }
                    else {
                        scalesModel.stopRecordingScale("Stop Button")
                        showResultPopup = false
                        scalesModel.result = Result()
                        scalesModel.result?.makeResult()
                        scalesModel.setAppMode(.none)
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
                                print("Failed to delete file: \(error)")
                            }
                        }
                    )
                }
                
                if scalesModel.recordingAvailable {
                    Spacer()
                    Button(scalesModel.appMode == .playingWithScale ? "Show Given Scale" : "Show Your Scale") {
                        //scalesModel.setAppMode(.recordingMode)
                        if scalesModel.appMode == .practicingMode {
                            scalesModel.setAppMode(.playingWithScale)
                        }
                        else {
                            scalesModel.setAppMode(.none)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    Button(hearingUserScale ? "Stop Hearing Your Scale" : "Hear Your Scale") {
                        hearingUserScale.toggle()
                        if hearingUserScale {
                            metronome.startTimer(notified: PianoKeyboardModel.shared, userScale: true, 
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
        VStack() {
            Text("Scales Trainer").font(.title).bold()

            SelectScaleView().commonFrameStyle(backgroundColor: .clear).padding()
            
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                .frame(height: UIScreen.main.bounds.size.height / 4)
                .commonFrameStyle(backgroundColor: .clear).padding()    
            
            LegendView()
            
            if !self.staffHidden {
                VStack {
                    if let score = scalesModel.score {
                        ScoreView(score: score, widthPadding: false)
                    }
                }.commonFrameStyle(backgroundColor: .clear).padding()
            }
            
            if scalesModel.recordingAvailable {
                if let result = scalesModel.result {
                    ResultView(keyboardModel: PianoKeyboardModel.shared, result: result).commonFrameStyle(backgroundColor: .clear).padding()
                }
            }
            
            PracticeView().commonFrameStyle(backgroundColor: .clear).padding()
            
            RecordingView().commonFrameStyle(backgroundColor: .clear).padding()
            
            Spacer()
        }
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
        }
        .onAppear {
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            scalesModel.setAppMode(.none)
            scalesModel.setKeyAndScale()
        }
        .onDisappear {
        }
    }
}

