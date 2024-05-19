import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

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

func getAvailableMicrophones() -> [AVAudioSessionPortDescription] {
    var availableMicrophones: [AVAudioSessionPortDescription] = []
    //var selectedMicrophone: AVAudioSessionPortDescription? = nil
    let audioSession = AVAudioSession.sharedInstance()
    availableMicrophones = audioSession.availableInputs ?? []
    return availableMicrophones
}

func selectMicrophone(_ microphone: AVAudioSessionPortDescription) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setPreferredInput(microphone)
        //selectedMicrophone = microphone
        print("Selected Microphone: \(microphone.portName)")
    } catch {
        print("Failed to set preferred input: \(error)")
    }
}

//class MicAudioManager: ObservableObject {
//    private var engine = AudioEngine()
//    private var mic: AudioEngine.InputNode!
//    private var mixer: Mixer!
//    
//    @Published var availableMicrophones: [AVAudioSessionPortDescription] = []
//    @Published var selectedMicrophone: AVAudioSessionPortDescription? = nil
//
//    init() {
//        setupAudioSession()
//        setupAudioKit()
//        fetchAvailableMicrophones()
//    }
//    
//    private func setupAudioSession() {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
//            try audioSession.setActive(true)
//        } catch {
//            print("Failed to set up audio session: \(error)")
//        }
//    }
//    
//    private func setupAudioKit() {
//        mic = engine.input
//        mixer = Mixer(mic)
//        engine.output = mixer
//        do {
//            try engine.start()
//        } catch {
//            print("AudioKit did not start: \(error)")
//        }
//    }
//    
//    func fetchAvailableMicrophones() {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
//        }
//        catch {
//            print(error.localizedDescription)
//        }
//        availableMicrophones = audioSession.availableInputs ?? []
//        for m in availableMicrophones {
//            let mic:AVAudioSessionPortDescription = m
//            print("====MIC", mic.portName, mic.portType, mic.selectedDataSource)
//        }
//    }
//    
//    func selectMicrophone(_ microphone: AVAudioSessionPortDescription) {
//        let audioSession = AVAudioSession.sharedInstance()
//        do {
//            try audioSession.setPreferredInput(microphone)
//            selectedMicrophone = microphone
//            print("Selected Microphone: \(microphone.portName)")
//        } catch {
//            print("Failed to set preferred input: \(error)")
//        }
//    }
//}
//
//struct MicrophoneView: View {
//    @StateObject var audioManager = MicAudioManager()
//    
//    var body: some View {
//        VStack {
//            List(audioManager.availableMicrophones, id: \.uid) { mic in
//                HStack {
//                    Text(mic.portName)
//                    Spacer()
//                    if mic == audioManager.selectedMicrophone {
//                        Image(systemName: "checkmark")
//                    }
//                }
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    audioManager.selectMicrophone(mic)
//                }
//            }
//            .navigationTitle("Select Microphone")
//        }
//        .onAppear {
//            audioManager.fetchAvailableMicrophones()
//        }
//    }
//}

struct SettingsView: View {
    let scalesModel = ScalesModel.shared
    var body: some View {
        VStack {
            VStack {
                //Spacer()
                //MicrophoneView()
                SpeechView()
                Spacer()
                TestDataModeView()
                Spacer()
                //MetronomeView()
            }
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))    ampFilter:\(String(format: "%.4f",scalesModel.amplitudeFilter))")
            }

        }
    }
}