import SwiftUI

struct ScalesView: View {
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardViewModel
    
    @State private var requiredPitchTapStartAmplitude: Double = 0.00
    @State private var requiredFFTTapStartAmplitude: Double = 0.00
    
    let octaveNumberValues = [1,2,3,4]
    @State private var octaveNumberIndex = 0
    
    let keyValues = ["C","D","E","F","G","A","B"]
    @State private var keyIndex = 0
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    @State private var bufferSizeIndex = 11
    
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    @State private var startMidiIndex = 4
    
    //@StateObject var audioProcessor = AudioProcessor(fileName: "1_octave_slow")
    @StateObject private var audio_kit_audioManager = AudioKit_AudioManager()
    private let keyboardAudioEngine: KeyboardAudioEngine
    
    let fftMode = false
    @State var stateSetup = true
    @State var amplitudeFilter: Double = 0.00
    @State var asynchHandle = true
    
    init() {
        self.pianoKeyboardViewModel = PianoKeyboardViewModel()
        self.keyboardAudioEngine = KeyboardAudioEngine()
        pianoKeyboardViewModel.numberOfKeys = 16
        pianoKeyboardViewModel.showLabels = true
    }
    
    func SelectScaleView() -> some View {
        HStack {
            Spacer()
            Text("Key")
            Picker("Select Value", selection: $keyIndex) {
                ForEach(keyValues.indices, id: \.self) { index in
                    Text("\(keyValues[index])")
                }
            }
            .pickerStyle(.menu)

            Text("Octaves:")
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(octaveNumberValues.indices, id: \.self) { index in
                    Text("\(octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            Spacer()
        }
    }
    
    func getScaleMatcher() -> ScaleMatcher  {
        let scale = Scale(start: self.startMidiValues[self.startMidiIndex], major: true, octaves: self.octaveNumberValues[self.octaveNumberIndex])
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
                Button("Play Scale") {
                    pianoKeyboardViewModel.numberOfKeys = 36
                }.padding()
                
                Spacer()
                Button("Play File") {
                    pianoKeyboardViewModel.numberOfKeys = 18
                    audio_kit_audioManager.playFile()
                }.padding()
                
                Spacer()
                Button("Stop File") {
                    audio_kit_audioManager.stopPlayFile()
                }.padding()
                
                Spacer()
                Button("Record Scale") {
                }.padding()
                Spacer()
            }
            StaveView()
        }
        

        .onAppear {
            pianoKeyboardViewModel.delegate = keyboardAudioEngine
            keyboardAudioEngine.start()
            audio_kit_audioManager.setupAudioSession()
        }
        .onDisappear {
            audio_kit_audioManager.stopPlayFile()
        }

    }

}

