import Foundation
import SwiftUI
import Combine

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

struct SettingsView: View {
    let scalesModel = ScalesModel.shared
    var body: some View {
        VStack {
            HStack {
                SpeechView()
                Spacer()
                TestDataModeView()
                Spacer()
                MetronomeView()
            }
            if let req = scalesModel.requiredStartAmplitude {
                Text("Required Start Amplitude:\(String(format: "%.4f",req))    ampFilter:\(String(format: "%.4f",scalesModel.amplitudeFilter))")
            }

        }
    }
}
