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
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardViewModel
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
    
    struct ResultView: View {
        @ObservedObject var result = ScalesModel.shared.result
        
        var body: some View {
            HStack {
                Text("Result")
                Text("Correct: \(result.correctCount)")
                //if result.wrongCount > 0 {
                    Text("Wrong: \(result.wrongCount)").foregroundColor(result.wrongCount > 0  ? Color.red : Color.black)
                    if result.wrongCount > 0 {
                        Text("🤚").font(.title)
                    }
                //}
            }
        }
    }
    
    init() {
        self.pianoKeyboardViewModel = PianoKeyboardViewModel()
        //configureKeyboard(key: Key(sharps: 0, flats: 0, type: .major))
        configureKeyboard()
        //configureKeyboard(key: "D", octaves: 1)
    }
    
    func configureKeyboard() {
        DispatchQueue.main.async {
            //let keyName = scalesModel.keyValues[scalesModel.selectedKey]
            //let key = Key(name: keyName, keyType:.major)
            //if ["C", "D", "E"].contains(keyName) {
            pianoKeyboardViewModel.noteMidi = 60
            //}
            if ["G", "A", "F", "B♭", "A♭"].contains(scalesModel.selectedKey.name) {
                pianoKeyboardViewModel.noteMidi = 65
                if ["A", "B♭", "A♭"].contains(scalesModel.selectedKey.name) {
                    pianoKeyboardViewModel.noteMidi -= 12
                }
            }
            var numKeys = (scalesModel.octaveNumberValues[octaveNumberIndex] * 12) + 1
            numKeys += 2
            if ["E", "G", "A", "A♭", "E♭"].contains(scalesModel.selectedKey.name) {
                numKeys += 4
            }
            if ["B", "B♭"].contains(scalesModel.selectedKey.name) {
                numKeys += 6
            }
            pianoKeyboardViewModel.numberOfKeys = numKeys
            pianoKeyboardViewModel.showLabels = true
            pianoKeyboardViewModel.setScale(scale: scalesModel.scale)
        }
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
                scalesModel.setScale(octaveIndex: self.octaveNumberIndex)
                self.configureKeyboard()
            })
            
            Spacer()
            Text("Scale").padding(0)
            Picker("Select Value", selection: $scaleTypeIndex) {
                ForEach(scalesModel.scaleTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleTypes[index])")
                }
            }
            .pickerStyle(.menu)
            
            Spacer()
            Text("Octaves:").padding(0)
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(scalesModel.octaveNumberValues.indices, id: \.self) { index in
                    Text("\(scalesModel.octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: octaveNumberIndex, {
                scalesModel.setScale(octaveIndex: self.octaveNumberIndex)
                self.configureKeyboard()
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
                self.configureKeyboard()
            })

            Spacer()
        }
    }
    
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()
            
            SpeechView()
            
            SelectScaleView()
            
            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle())
                .frame(height: 320)
                .padding()
//            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle(scale: getScale()))
//                .frame(height: 320)
//                .padding()


            HStack {
                Spacer()
                Button(metronome.playingScale ? "Stop Playing Scale" : "Play Scale") {
                    if !metronome.playingScale {
                        metronome.playScale(scale: scalesModel.scale)
                    }
                    else {
                        metronome.stop()
                    }
                }.padding()
                Spacer()
            }
            
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button(scalesModel.recordingScale ? "Stop Recording Scale" : "Record Scale") {
                        if scalesModel.recordingScale {
                            scalesModel.stopRecordingScale()
                        }
                        else {
                            scalesModel.startRecordingScale()
                        }
                    }.padding()
                    
                    Spacer()

                    Button(playingSampleFile ? "Stop Recording Sample" : "Record Sample File") {
                        playingSampleFile.toggle()
                        if playingSampleFile {
                            //let f = "church_4_octave_Cmajor_RH"
                            //let f = "4_octave_fast"
                            //let f = "one_note_60" //1_octave_slow"
                            let fileName = "1_octave_slow"
                            //scaleMatcher = getScaleMatcher()
                            audioManager.playSampleFile(fileName: fileName,
                                                        tapHandler: PitchTapHandler(requiredStartAmplitude: requiredAmplitude,
                                                                                    scaleMatcher: scalesModel.getScaleMatcher()))
                        }
                        else {
                            audioManager.stopPlaySampleFile()
                        }
                    }.padding()
                    
                    if scalesModel.recordingAvailable {
                        Spacer()
                        Button("Play Recording") {
                            audioManager.playRecordedFile()
                        }.padding()
                    }
                    Spacer()
                }
            }
            //if let scaleMatcher = scaleMatcher {
                ResultView()
            //}
            StaveView()
            Spacer()
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))")
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

