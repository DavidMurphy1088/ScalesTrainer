import SwiftUI

public struct SettingsView: View {
    let scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    
    @State var calibratingFromFile = false
    @State var calibrating = false
    @State private var showingHelpPopup = false
    
    struct HelpView: View {
        var body: some View {
            VStack {
                Text("Configuration").font(.largeTitle).padding()
                Text("The app needs to hear you play a mezzo-forte (mf) note on your piano before listening to your scales.\n\n•Make sure your device is close to your piano\n\n•Tap Start Calibrating\n\n•Play Middle C on your piano a few times\n\n•Wait a a few seconds\n\n•Tap Stop Calibrating.")
                Spacer()
            }
        }
    }
    
    func CallibrationView(type:CallibrationType, instruction:String) -> some View {
        VStack {
            let tapHandler = CallibrationTapHandler(type: type)
            //let tapHandler = PitchTapHandler(requiredStartAmplitude: 0.0, scaleMatcher: nil, scale: nil)
            let title = type == .amplitudeFilter ? "Amplitude Filter" : "Required Start Amplitude"
            Text(title).font(.title3).padding()
            
            HStack {
                Spacer()
                Button(calibrating ? "Stop" : "Start Calibration") {
                    calibrating.toggle()
                    if calibrating {
                        audioManager.startRecordingMicrophone(tapHandler: tapHandler, recordAudio: false)
                        //ScalesModel.shared.calibrate(type: type)
                    }
                    else {
                        audioManager.stopRecording()
                    }
                }.padding()
                Spacer()
            
                if calibrating {
                    HStack {
                        Spacer()
                        Text(instruction).font(.title3).padding()
                        Spacer()
                    }
                }
                else {
                    if type == .amplitudeFilter {
                        //if let req = scalesModel.amplitudeFilter {
                            Text("Amplitude filter set at:\(String(format: "%.4f", scalesModel.amplitudeFilter))").font(.title3).padding()
                        //}
                    }
                    else {
                        if let req = scalesModel.requiredStartAmplitude {
                            Text("Start Amplitude set at:\(String(format: "%.4f", req))").font(.title3).padding()
                        }
                    }
                }
                Spacer()
            }
            .commonFrameStyle(backgroundColor: .clear).padding()
            Spacer()
        }
    }
    
    public var body: some View {
        VStack {
            Spacer()
            Text("Settings").font(.title).bold().padding()
            
            Button(action: {
                showingHelpPopup = true
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.largeTitle)  // Sets the size of the icon
                    .foregroundColor(.blue)  // Sets the color of the icon
            }
            Spacer()
            CallibrationView(type: .startAmplitude, instruction: "Play Middle C a few times at normal (mf) volume")
            Spacer()
            CallibrationView(type: .amplitudeFilter, instruction: "Play Middle C a few times at a very soft (pp) volume")
            Spacer()
        }
        .sheet(isPresented: $showingHelpPopup) {
            HelpView()
        }
    }
}


//                Spacer()
//                Button(calibratingFromFile ? "Stop Calibrating" : "Start Calibrating from Recording") {
//                    calibratingFromFile.toggle()
//
//                    if calibratingFromFile {
//                        //let fileName = "one_note_60"
//                        let fileName = "1_octave_slow"
//                        audioManager.playSampleFile(fileName: fileName, tapHandler: tapHandler)
//                    }
//                    else {
//                        audioManager.stopPlaySampleFile()
//                    }
//                }.padding()
//                Spacer()
