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
            Spacer()
            MetronomeView()
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
    @State var showResult = false
    
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
    
    var body1: some View {
        VStack {
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
                .frame(height: 320)
                .padding()
        }
    }
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()
            
            SpeechView()
            
            SelectScaleView().commonFrameStyle(backgroundColor: .clear).padding()
            
            PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel) //, style: ClassicStyle())
                .frame(height: 320)
                .padding()
//            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle(scale: getScale()))
//                .frame(height: 320)
//                .padding()
            
            HStack {
                Spacer()
                Button(metronome.playingScale ? "Stop Hearing Scale" : "Hear Scale") {
                    if metronome.playingScale {
                        metronome.stop()
                    }
                    else {
                        metronome.playScale(scale: scalesModel.scale)
                    }
                }.padding()
                
                Spacer()
                Button(scalesModel.listening ? "Stop Listening" : "Play for Test Listen") {
                    if scalesModel.listening {
                        scalesModel.stopListening()
                    }
                    else {
                        scalesModel.startListening()
                    }
                    
                }.padding()
                Spacer()
            }
            .commonFrameStyle(backgroundColor: .clear).padding()
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button(scalesModel.recordingScale ? "Stop Playing Scale" : "Play Scale") {
                        if scalesModel.recordingScale {
                            scalesModel.stopRecordingScale()
                            showResult = true
                        }
                        else {
                            scalesModel.startRecordingScale()
                        }
                    }.padding()
                    Spacer()

                    Button(playingSampleFile ? "Stop Recording Sample" : "File Sample Scale") {
                        playingSampleFile.toggle()
                        if playingSampleFile {
                            //let f = "church_4_octave_Cmajor_RH"
                            //let f = "4_octave_fast"
                            //let f = "one_note_60" //1_octave_slow"
                            let fileName = "1_octave_slow"
                            audioManager.playSampleFile(fileName: fileName,
                                                        tapHandler: PitchTapHandler(requiredStartAmplitude: requiredAmplitude,
                                                                                    scaleMatcher: scalesModel.getScaleMatcher(), scale: nil))
                        }
                        else {
                            audioManager.stopPlaySampleFile()
                            showResult = true
                        }
                    }.padding()
                    
                    if scalesModel.result != nil {
                        Spacer()
                        Button("Show Result") {
                            showResult = true
                        }.padding()
                    }

                    if scalesModel.recordingAvailable {
                        Spacer()
                        Button("Play Recording") {
                            audioManager.playRecordedFile()
                        }.padding()
                    }
                    Spacer()
                }
            }
            .commonFrameStyle(backgroundColor: .clear).padding()

            //StaveView()//.commonFrameStyle(backgroundColor: .clear, borderColor: .red)
            Spacer()
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))    ampFilter:\(String(format: "%.4f",scalesModel.amplitudeFilter))")
            }
        }
        .sheet(isPresented: $showResult) {
            if let result  = scalesModel.result {
                ResultView(result: result)//4.commonFrameStyle(backgroundColor: .clear, borderColor: .red)
            }
        }
        .onAppear {
            pianoKeyboardViewModel.delegate = audioManager //keyboardAudioEngine
        }
        .onDisappear {
            //audioManager.stopPlaySampleFile()
        }
    }
}

