import SwiftUI

struct ScalesView: View {
    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardViewModel
    private let audioManager = AudioManager.shared

    @State private var octaveNumberIndex = 0
    @State private var keyIndex = 0
    @State private var scaleTypeIndex = 0
    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    let fftMode = false
    @State var stateSetup = true
    @State var amplitudeFilter: Double = 0.00
    @State var asynchHandle = true

    @State var playingSampleFile = false
    
    @State var speechListening = false
    @State var speechAudioStarted = false
    var speech = SpeechManager.shared
    
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
        configureKeyboard(key: "C", octaves: 1)
        //configureKeyboard(key: "D", octaves: 1)
    }
    
    func configureKeyboard(key:String, octaves:Int) {
        DispatchQueue.main.async {
            let keyName = scalesModel.keyValues[scalesModel.selectedKey]
            let key = Key(name: keyName, keyType:.major)
            if ["C", "D", "E"].contains(keyName) {
                pianoKeyboardViewModel.noteMidi = 60
            }
            else {
                pianoKeyboardViewModel.noteMidi = 65
            }
            let scaleForKey = Scale(key: key, scaleType: .major, octaves: octaves)
            var numKeys = (scalesModel.octaveNumberValues[octaveNumberIndex] * 12) + 1
            numKeys += 2
            pianoKeyboardViewModel.numberOfKeys = numKeys
            pianoKeyboardViewModel.showLabels = true
            pianoKeyboardViewModel.setScale(scale: scaleForKey)
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
                scalesModel.selectedKey = keyIndex
                self.configureKeyboard(key: scalesModel.keyValues[scalesModel.selectedKey], octaves: 1)
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
                
                Button("Play Scale") {
                }.padding()
                Button(speechListening ? "Stop Speech" : "Speech Listen") {
                    speechListening.toggle()
                    if speechListening {
                        if !speechAudioStarted {
                            //speech.installSpeechTap()
                            speechAudioStarted = true
                        }
                        speech.startSpeechRecognition()
                        //AudioManager.shared.startEngine()
                    }
                    else {
                        speech.stopAudioEngine()
                    }
                }.padding()
            }
            
            HStack {
                if let requiredAmplitude = scalesModel.requiredStartAmplitude {
                    Spacer()
                    Button(scalesModel.recordingScale ? "Stop Recording Scale" : "Record Scale") {
                        DispatchQueue.main.async {
                            scalesModel.recordingScale.toggle()
                        }
                        if scalesModel.recordingScale {
                            scalesModel.recordScale()
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
                            //scaleMatcher = getScaleMatcher()
                            audioManager.playSampleFile(fileName: fileName,
                                                        tapHandler: PitchTapHandler(requiredStartAmplitude: requiredAmplitude,
                                                                                    scaleMatcher: scalesModel.getScaleMatcher()))
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

