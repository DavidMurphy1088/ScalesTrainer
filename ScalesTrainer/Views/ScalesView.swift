import SwiftUI

struct SpeechView : View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    @State var setSpeechListenMode = false
    var body: some View {
        HStack {
            HStack() {
                //Text("Speech Listen")
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

struct DataModeView : View {
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
    
    @State var speechAudioStarted = false
    @State var showResultPopup = false
    
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
            })
            
            Spacer()
            Text("Hand:")
            Picker("Select Value", selection: $handIndex) {
                ForEach(scalesModel.handTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.handTypes[index])")
                }
            }
            .pickerStyle(.menu)

            Spacer()
            Text("Direction")
            Picker("Select Value", selection: $directionIndex) {
                ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.directionTypes[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: directionIndex, {
                
                scalesModel.setDirection(self.directionIndex)
                keyboardModel.mapPianoKeysToScaleNotes(direction: self.directionIndex)
                scalesModel.forceRepaint()
            })

            Spacer()
        }
    }
    
//    var body1: some View {
//        VStack {
//            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
//                .frame(height: 320)
//                .padding()
//        }
//    }
    
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()
            
            HStack {
                SpeechView()
                Spacer()
                DataModeView()
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
            
            HStack {
//                Spacer()
//                Button(metronome.isTiming ? "Stop Metronome" : "Start Metronome") {
//                    //metronome.setTimer(!metronome.isTiming)
//                }.padding()
                
                Spacer()
                Button(scalesModel.listening ? "Stop Listening" : "Listen") {
                    if scalesModel.listening {
                        scalesModel.stopListening()
                    }
                    else {
                        //reset()
                        scalesModel.startListening()
                    }
                    
                }.padding()
                
                Spacer()
                Button(metronome.isTiming ? "Stop Hearing Scale" : "Hear Scale") {
                    if metronome.isTiming {
                        metronome.stop()
                    }
                    else {
                        //reset()
                        metronome.startTimer(notified: scalesModel.scale)
                    }
                }.padding()
                Spacer()
            }
            .commonFrameStyle(backgroundColor: .clear).padding()
            
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button("READ_TEST_DATA") {
                        audioManager.readTestData(tapHandler: PitchTapHandler(requiredStartAmplitude:
                                                                                scalesModel.requiredStartAmplitude ?? 0,
                                                                              recordData: false,
                                                                              scaleMatcher: nil,
                                                                              scale: scalesModel.scale))
                        scalesModel.setMode(.displayMode)
                    }.padding()
                    
                    Button(scalesModel.recordingScale ? "Stop Recording Scale" : "Record Your Scale") {
                        if scalesModel.recordingScale {
                            scalesModel.stopRecordingScale("Stop Button")
                            showResultPopup = false
                        }
                        else {
                            ///😡 reset here causes the recording to stop just after its started - no idea why....
                            //reset()
                            scalesModel.setMode(.displayMode)
                            scalesModel.startRecordingScale(readTestData: false)
                        }
                    }.padding()
                    
                    Spacer()
                    if scalesModel.result != nil {
                        Spacer()
                        VStack {
                            Button("Show Result") {
                                if let result = scalesModel.result {
                                    //showResultPopup = true
                                    scalesModel.processScaleResult(result: result, soundScale: false)
                                    scalesModel.setMode(.resultMode)
                                }
                            }
                            Button("Show Scale") {
                                scalesModel.setMode(.displayMode)
                            }
                        }.padding()
                    }

                    Spacer()
                    if scalesModel.recordingAvailable {
                        if let result = scalesModel.result {
                            Spacer()
                            Button("Play Recording") {
                                //scalesModel.setMode(.resultMode)
                                //audioManager.playRecordedFile()
                                scalesModel.processScaleResult(result: result, soundScale: true)
                            }.padding()
                        }
                    }
                    Spacer()
                }
                else {
                    Text("Calibration is required in Settings").padding()
                }
            }
            .commonFrameStyle(backgroundColor: .clear).padding()

            //StaveView()//.commonFrameStyle(backgroundColor: .clear, borderColor: .red)
            Spacer()
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))    ampFilter:\(String(format: "%.4f",scalesModel.amplitudeFilter))")
            }
        }
        .sheet(isPresented: $showResultPopup) {
            if let result  = scalesModel.result {
                ResultView(result: result)//4.commonFrameStyle(backgroundColor: .clear, borderColor: .red)
            }
        }
        .onAppear {
            pianoKeyboardViewModel.keyboardAudioManager = audioManager //keyboardAudioEngine
        }
        .onDisappear {
            //audioManager.stopPlaySampleFile()
        }
    }
}

