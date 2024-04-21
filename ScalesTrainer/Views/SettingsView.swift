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
                Text("The app needs to hear you play a mezzo-forte (mf) note on your piano before listening to your scales.\n\n•Tap Start Calibrating\n\n•Play Middle C on your piano\n\n•Wait a a few seconds\n\n•Tap Stop Calibrating.")
                Spacer()
            }
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
            
            let tapHandler = CallibrationTapHandler()
            HStack {
                Spacer()
                Button(calibrating ? "Stop Calibrating" : "Start Calibrating") {
                    calibrating.toggle()
                    if calibrating {
                        audioManager.startRecordingMicrophone(tapHandler: tapHandler)
                    }
                    else {
                        audioManager.stopRecording()
                    }
                }.padding()


                Spacer()
                Button(calibratingFromFile ? "Stop Calibrating" : "Start Calibrating from Recording") {
                    calibratingFromFile.toggle()
                    
                    if calibratingFromFile {
                        //let fileName = "one_note_60"
                        let fileName = "1_octave_slow"
                        audioManager.playSampleFile(fileName: fileName, tapHandler: tapHandler)
                    }
                    else {
                        audioManager.stopPlaySampleFile()
                    }
                }.padding()
                Spacer()
            }
            Spacer()
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f", req))")
            }
            Spacer()
        }
        .sheet(isPresented: $showingHelpPopup) {
            HelpView()
        }
    }
}
