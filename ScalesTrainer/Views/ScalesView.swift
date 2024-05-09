import SwiftUI

struct SpeechView : View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    @State var setSpeechListenMode = false
    var body: some View {
        HStack {
            HStack() {
                Toggle("Speech Listen", isOn: $setSpeechListenMode)
            }
            .frame(width: UIScreen.main.bounds.width * 0.15)
            .padding()
            .background(Color.gray.opacity(0.3)) // Just to see the size of the HStack
            .onChange(of: setSpeechListenMode, {scalesModel.setSpeechListenMode(setSpeechListenMode)})
            .padding()
            if scalesModel.speechListenMode {
                let c = String(scalesModel.speechCommandsReceived)
                Text("Last Word Number:\(c) Word:\(scalesModel.speechLastWord)")
            }
        }
    }
}

struct TestDataModeView : View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    @State var dataMode = false
    var body: some View {
        HStack {
            HStack() {
                Toggle("Record Data Mode", isOn: $dataMode)
            }
            .frame(width: UIScreen.main.bounds.width * 0.15)
            .padding()
            .background(Color.gray.opacity(0.3)) // Just to see the size of the HStack
            .onChange(of: dataMode, {scalesModel.setRecordDataMode(dataMode)})
            .padding()
        }
    }
}

struct ScalesView: View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    private var keyboardModel = PianoKeyboardModel.shared
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardModel
    @ObservedObject private var speech = SpeechManager.shared
    @ObservedObject private var metronome = MetronomeModel.shared

    private let audioManager = AudioManager.shared

    @State private var octaveNumberIndex = 0
    @State private var handIndex = 0
    @State private var keyIndex = 0
    @State private var scaleTypeIndex = 0
    @State private var directionIndex = 0

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
    
    init() {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
    }
    
    func SelectScaleView() -> some View {
        HStack {
            Spacer()
            Text("Key")
            Picker("Select Value", selection: $keyIndex) {
                ForEach(scalesModel.keyValues.indices, id: \.self) { index in
                    Text("\(scalesModel.keyValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: keyIndex, {
                scalesModel.setKey(index: keyIndex)
                scalesModel.setScale()
                scalesModel.setAppMode(.displayMode, resetRecorded: true)
            })
            
            Spacer()
            Text("Scale").padding(0)
            Picker("Select Value", selection: $scaleTypeIndex) {
                ForEach(scalesModel.scaleTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleTypes[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: scaleTypeIndex, {
                scalesModel.selectedScaleType = scaleTypeIndex
                scalesModel.setScale()
                scalesModel.setAppMode(.displayMode, resetRecorded: true)
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
                scalesModel.setAppMode(.displayMode, resetRecorded: true)
            })
            
            Spacer()
            Text("Hand:")
            Picker("Select Value", selection: $handIndex) {
                ForEach(scalesModel.handTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.handTypes[index])")
                }
            }
            .pickerStyle(.menu)
            //scalesModel.setMode(.displayMode)

            Spacer()
            Text("Viewing\nDirection")
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
        }
    }
    
//    var body1: some View {
//        VStack {
//        }
//    }
    
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()

            HStack {
                SpeechView()
                Spacer()
                TestDataModeView()
                Spacer()
                MetronomeView()
            }
            
            SelectScaleView().commonFrameStyle(backgroundColor: .clear).padding()
            
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
                .frame(height: 320)
                .padding()
//            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle(scale: getScale()))
//                .frame(height: 320)
//                .padding()
            
            if scalesModel.recordingAvailable {
                ResultView(keyboardModel: PianoKeyboardModel.shared).commonFrameStyle(backgroundColor: .clear).padding()
            }
            
            HStack {
                Spacer()
                Button(action: {
                    notesHidden.toggle()
                    scalesModel.notesHidden = notesHidden
                    scalesModel.forceRepaint()
                }) {
                    if notesHidden {
                        VStack {
                            Text("Show Notes")
                            Image(systemName: "lock.open")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                    else {
                        VStack {
                            Text("Hide Notes")
                            Image(systemName: "lock")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding()

                Spacer()
                Button(scalesModel.isPracticing ? "Stop Practicing" : "Practice") {
                    if scalesModel.isPracticing {
                        scalesModel.stopListening()
                    }
                    else {
                        scalesModel.startListening()
                    }
                    
                }.padding()
                
                Spacer()
                Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear Scale") {
                    hearingGivenScale.toggle()
                    if hearingGivenScale {
                        metronome.startTimer(notified: PianoKeyboardModel.shared, userScale: false, onDone: {self.hearingGivenScale = false})
                    }
                    else {
                        metronome.stop()
                    }
                }.padding()
                Spacer()
            }
            .commonFrameStyle(backgroundColor: .clear).padding()
            
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button(recordingScale ? "Stop Recording Scale" : "Record Your Scale") {
                        if recordingScale {
                            scalesModel.stopRecordingScale("Stop Button")
                            showResultPopup = false
                            scalesModel.setAppMode(.resultMode, resetRecorded: false)
                            recordingScale = false
                        }
                        else {
                            recordingScale = true
                            scalesModel.setAppMode(.displayMode, resetRecorded: true)
                            scalesModel.startRecordingScale(testData: false, onDone: {
                                scalesModel.setAppMode(.resultMode, resetRecorded: false)
                                scalesModel.setDirection(0)
                            })
                        }
                    }.padding()
                    
                    if scalesModel.recordingAvailable {
                        Spacer()
                        Button(scalesModel.appMode == .resultMode ? "Show Given Scale" : "Show Your Scale") {
                            if scalesModel.appMode == .displayMode {
                                scalesModel.setAppMode(.resultMode, resetRecorded: false)
                            }
                            else {
                                scalesModel.setAppMode(.displayMode, resetRecorded: false)
                            }
                        }
                        .padding()
                        
                        Spacer()
                        Button(hearingUserScale ? "Stop Hearing Your Scale" : "Hear Your Scale") {
                            hearingUserScale.toggle()
                            if hearingUserScale {
                                metronome.startTimer(notified: PianoKeyboardModel.shared, userScale: true, onDone: {self.hearingUserScale = false})
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
            .commonFrameStyle(backgroundColor: .clear).padding()
            
            Spacer()
            Button("READ_TEST_DATA") {
                recordingScale = true
                scalesModel.setAppMode(.displayMode, resetRecorded: true)
                scalesModel.startRecordingScale(testData: true, onDone: {
                    PianoKeyboardModel.shared.debug2("end of test read")
                    //scalesModel.setAppMode(.resultMode, resetRecorded: false)
                    scalesModel.setDirection(0)
                    PianoKeyboardModel.shared.debug2("end of test read")
                    self.recordingScale = false
                })
            }.padding()
            
            //StaveView()//.commonFrameStyle(backgroundColor: .clear, borderColor: .red)
            
            Spacer()
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))    ampFilter:\(String(format: "%.4f",scalesModel.amplitudeFilter))")
            }
        }
        .sheet(isPresented: $showingTapData) {
            //if let result  = scalesModel.result {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
            //}
        }
        .onAppear {
            pianoKeyboardViewModel.keyboardAudioManager = audioManager //keyboardAudioEngine
        }
        .onDisappear {
            //audioManager.stopPlaySampleFile()
        }
    }
}

