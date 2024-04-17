import SwiftUI

struct ScalesView: View {
    let scalesModel = ScalesModel()
    let audioManager = AudioManager.shared
    
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardViewModel
    
    @State private var octaveNumberIndex = 0
    @State private var keyIndex = 0
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
        pianoKeyboardViewModel.numberOfKeys = 16
        pianoKeyboardViewModel.showLabels = true
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

            Text("Octaves:")
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(scalesModel.octaveNumberValues.indices, id: \.self) { index in
                    Text("\(scalesModel.octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: octaveNumberIndex, {
                pianoKeyboardViewModel.numberOfKeys = (scalesModel.octaveNumberValues[octaveNumberIndex] * 12) + 1
            })
            Spacer()
        }
    }
    
    func getScaleMatcher() -> ScaleMatcher  {
        let scale = Scale(start: scalesModel.startMidiValues[self.startMidiIndex], major: true, octaves: scalesModel.octaveNumberValues[self.octaveNumberIndex])
        return ScaleMatcher(scale: scale, mismatchesAllowed: 8)
    }
    
    var body: some View {
        VStack() {
            Text("Scales Trainer").font(.title).bold()
            
            SelectScaleView()
            
            PianoKeyboardView(viewModel: pianoKeyboardViewModel, style: ClassicStyle(sfKeyWidthMultiplier: 0.55))
                .frame(height: 320)
                .padding()
            HStack {
                Spacer()
                Button(calibrating ? "Stop Calibrating" : "Start Calibrating") {
                    calibrating.toggle()
                    if calibrating {
                        audioManager.playSampleFile()
                    }
                    else {
                        audioManager.stopPlaySampleFile()
                    }
                }.padding()
                Spacer()
            }
            HStack {
                Spacer()
                Button("Play Scale") {
                    
                }.padding()
                
                Spacer()
                Button(recordingScale ? "Stop Recording Scale" : "Record Scale") {
                    recordingScale.toggle()
                    if recordingScale {
                        let scale = Scale(start: 60, major: true, octaves: 1)
                        let scaleMatcher = ScaleMatcher(scale: scale, mismatchesAllowed: 8)
                        let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: 0, scaleMatcher: scaleMatcher)
                        audioManager.startRecording(tapHandler: pitchTapHandler)
                    }
                    else {
                        audioManager.stopRecording()
                    }
                }.padding()
                Spacer()
//                Button("Stop Record") {
//                    audio_kit_audioManager.stopRecording()
//                }.padding()
                Button("Play Recording") {
                    audioManager.playRecordedFile()
                }.padding()
                Spacer()
            }
            HStack {
                Spacer()
                Button(playingSampleFile ? "Stop Playing Sample" : "Play Sample File") {
                    playingSampleFile.toggle()
                    if playingSampleFile {
                        audioManager.playSampleFile()
                    }
                    else {
                        audioManager.stopPlaySampleFile()
                    }
                }.padding()
                Spacer()
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

