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
    @State private var keyIndex = 0
    @State private var scaleTypeIndex = 0
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
    @State var showingTapData = false
    @State var recordingScale = false

    @State var speechAudioStarted = false
    @State var showResultPopup = false
    @State var notesHidden = false
    @State var staffHidden = false

    init() {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
    }
    
    func width() -> CGFloat {
        return CGFloat(UIScreen.main.bounds.size.width / 50)
    }
    
    func LegendView() -> some View {
        HStack {
            if scalesModel.appMode == .practiceMode {
                Spacer()
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: width())
                Text("Correctly Played")
                Spacer()
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: width())
                Text("Incorrectly Played")
                Spacer()
                
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: width())
                Text("Finger Change")
                Spacer()
            }
            else {
                Spacer()
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: width())
                Text("Correctly Played")
                Spacer()
                Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: width())
                Text("Not in Scale")
                Spacer()
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: width())
                Text("Missing")

                Spacer()
            }
        }
    }
    
    func SelectScaleView() -> some View {
        HStack {
            Spacer()
            //Text("Key")
            Text(LocalizedStringResource("Key"))
            Picker("Select Value", selection: $keyIndex) {
                ForEach(scalesModel.keyValues.indices, id: \.self) { index in
                    Text("\(scalesModel.keyValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: keyIndex, {
                scalesModel.setKey(index: keyIndex)
                scalesModel.setScale()
                scalesModel.setAppMode(.practiceMode, resetRecorded: true)
            })
            
            Spacer()
            Text(LocalizedStringResource("Scale")).padding(0)
            Picker("Select Value", selection: $scaleTypeIndex) {
                ForEach(scalesModel.scaleTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleTypes[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scaleTypeIndex, {
                scalesModel.selectedScaleType = scaleTypeIndex
                scalesModel.setScale()
                scalesModel.setAppMode(.practiceMode, resetRecorded: true)
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
                scalesModel.setScale()
                scalesModel.setAppMode(.practiceMode, resetRecorded: true)
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
                scalesModel.setScale()
                scalesModel.setAppMode(.practiceMode, resetRecorded: true)
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
                scalesModel.notesHidden = notesHidden
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
                scalesModel.stopPracticeHandler()
                if hearingGivenScale {
                    metronome.startTimer(notified: PianoKeyboardModel.shared, userScale: false, onDone: {
                        self.hearingGivenScale = false
                        scalesModel.startPracticeHandler()
                    })
                }
                else {
                    metronome.stop()
                }
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
                    scalesModel.stopPracticeHandler()
                    scalesModel.setAppMode(.resultMode, resetRecorded: true)
                    scalesModel.startRecordingScale(testData: true, onDone: {
                        recordingScale = false
                        scalesModel.setAppMode(.practiceMode, resetRecorded: false)
                        scalesModel.setDirection(0)

                        scalesModel.result = Result()
                        scalesModel.result?.makeResult()
                    })
                }.padding()
                
                Spacer()
                Button(recordingScale ? "Stop Recording Scale" : "Record Your Scale") {
                    if recordingScale {
                        scalesModel.stopRecordingScale("Stop Button")
                        showResultPopup = false
                        scalesModel.result = Result()
                        scalesModel.result?.makeResult()
                        scalesModel.setAppMode(.practiceMode, resetRecorded: false)
                        recordingScale = false
                        //scalesModel.startPracticeHandler()
                    }
                    else {
                        scalesModel.result = nil
                        recordingScale = true
                        scalesModel.stopPracticeHandler()
                        scalesModel.setAppMode(.resultMode, resetRecorded: true)
                        scalesModel.startRecordingScale(testData: false, onDone: {
                            scalesModel.setAppMode(.resultMode, resetRecorded: false)
                            scalesModel.setDirection(0)
                        })
                    }
                }.padding()
                
                if scalesModel.recordingAvailable {
                    Spacer()
                    Button(scalesModel.appMode == .resultMode ? "Show Given Scale" : "Show Your Scale") {
                        if scalesModel.appMode == .practiceMode {
                            scalesModel.setAppMode(.resultMode, resetRecorded: false)
                        }
                        else {
                            scalesModel.setAppMode(.practiceMode, resetRecorded: false)
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
                        //if showingTapData {
                        //}
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
            
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
                .frame(height: UIScreen.main.bounds.size.height / 4)
                .commonFrameStyle(backgroundColor: .clear).padding()    
            
            LegendView()
//            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
//                .frame(height: UIScreen.main.bounds.size.height / 4)
//                .commonFrameStyle(backgroundColor: .clear).padding()
            
            if !self.staffHidden {
                VStack {
                    if let score = scalesModel.score {
                        ScoreView(score: score, widthPadding: false)
                        //ScoreView(score: score, widthPadding: false)
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
            scalesModel.setKey(index: 0)
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            scalesModel.startPracticeHandler()
        }
        .onDisappear {
            //audioManager.stopPlaySampleFile()
        }
    }
}

