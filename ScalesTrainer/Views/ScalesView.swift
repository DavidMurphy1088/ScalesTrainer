import SwiftUI

struct ScalesView: View {
    let scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardViewModel
    
    @State private var octaveNumberIndex = 0
    @State private var keyIndex = 0
    @State private var scaleTypeIndex = 0
    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    let fftMode = false
    @State var stateSetup = true
    @State var amplitudeFilter: Double = 0.00
    @State var asynchHandle = true
    @State var recordingScale = false
    @State var playingSampleFile = false
    @State var calibrating = false

    init() {
        self.pianoKeyboardViewModel = PianoKeyboardViewModel()
        //configureKeyboard(key: Key(sharps: 0, flats: 0, type: .major))
        configureKeyboard(key: "C", octaves: 1)
    }
    
    func configureKeyboard(key:String, octaves:Int) {
        DispatchQueue.main.async {
            if ["C", "D", "E"].contains(key) {
                pianoKeyboardViewModel.noteMidi = 60
            }
            else {
                pianoKeyboardViewModel.noteMidi = 65
            }
            pianoKeyboardViewModel.numberOfKeys = (scalesModel.octaveNumberValues[octaveNumberIndex] * 12) + 1
            pianoKeyboardViewModel.showLabels = true
            let keyName = scalesModel.keyValues[keyIndex]
            pianoKeyboardViewModel.setScale(scale: Scale(key: Key(name: keyName, keyType:.major), scaleType: .major, octaves: 1))
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
                self.configureKeyboard(key: scalesModel.keyValues[keyIndex], octaves: 1)
            })
            
            Text("Scale")
            Picker("Select Value", selection: $scaleTypeIndex) {
                ForEach(scalesModel.scaleTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.scaleTypes[index])")
                }
            }
            .pickerStyle(.menu)

            Text("Octaves:")
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(scalesModel.octaveNumberValues.indices, id: \.self) { index in
                    Text("\(scalesModel.octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: octaveNumberIndex, {
                self.configureKeyboard(key: scalesModel.keyValues[keyIndex], octaves: 1)
            })
            Spacer()
        }
    }
    
    func getScale() -> Scale {
        let scale = Scale(key: Key(), scaleType: .major, octaves: scalesModel.octaveNumberValues[self.octaveNumberIndex])
        return scale
    }
    
    func getScaleMatcher() -> ScaleMatcher  {        
        return ScaleMatcher(scale: getScale(), mismatchesAllowed: 8)
    }
    
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()
            
            SelectScaleView()
            
            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle())
                .frame(height: 320)
                .padding()
//            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle(scale: getScale()))
//                .frame(height: 320)
//                .padding()

            HStack {
                Spacer()
                Button(calibrating ? "Stop Calibrating" : "Start Calibrating") {
                    calibrating.toggle()
                    let t = CallibrationTapHandler()
                    if calibrating {
                        //let fileName = "one_note_60"
                        let fileName = "1_octave_slow"
                        audioManager.playSampleFile(fileName: fileName, tapHandler: t)
                    }
                    else {
                        audioManager.stopPlaySampleFile()
                    }
                }.padding()
                Text("Required Start Amplitude:\(scalesModel.getRequiredStartAmplitude())")
                Spacer()
            }
             
            Button("Play Scale") {
            }.padding()
            
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button(recordingScale ? "Stop Recording Scale" : "Record Scale") {
                        recordingScale.toggle()
                        if recordingScale {
                            let scale = Scale(key: Key(), scaleType: .major, octaves: 1)
                            let scaleMatcher = ScaleMatcher(scale: scale, mismatchesAllowed: 8)
                            let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: requiredAmplitude, scaleMatcher: scaleMatcher)
                            audioManager.startRecording(tapHandler: pitchTapHandler)
                        }
                        else {
                            audioManager.stopRecording()
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
                            audioManager.playSampleFile(fileName: fileName, 
                                                        tapHandler: PitchTapHandler(requiredStartAmplitude: requiredAmplitude, 
                                                                                    scaleMatcher: getScaleMatcher()))
                        }
                        else {
                            audioManager.stopPlaySampleFile()
                        }
                    }.padding()
                    Spacer()
                    Button("Play Recording") {
                        audioManager.playRecordedFile()
                    }.padding()
                    Spacer()
                }
            }
            if scalesModel.statusMessage.count > 0 {
                Text(scalesModel.statusMessage)
            }
            StaveView()
        }

        .onAppear {
            pianoKeyboardViewModel.delegate = audioManager //keyboardAudioEngine
            //keyboardAudioEngine.start()
            //audio_kit_audioManager.setupAudioFile()
        }
        .onDisappear {
            audioManager.stopPlaySampleFile()
        }

    }

}

