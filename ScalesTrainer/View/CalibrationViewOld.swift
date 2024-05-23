import SwiftUI

public struct CallibrationViewOld: View {
    @ObservedObject var scalesModel = ScalesModel.shared
    let audioManager = AudioManager.shared
    
    @State var calibratingFromFile = false
    @State var calibratingFilter = false
    @State var calibratingStart = false
    @State private var amplitudeFilterAdjust:Double = 0
    
    func AmplitudeFilterCallibrationView() -> some View {
        VStack {
            Spacer()
            Text("Amplitude Filter").font(.title).padding()
            if !calibratingFilter {
                VStack {
                    Text("The app needs to hear you play a very soft (pp) note on your piano to calibrate your piano's sound.\n\n•Make sure your device is close to your piano\n•Tap Start Calibrating\n•Play Middle C very softly on your piano a few times\n•Wait a a few seconds\n•Tap Stop Calibrating.")
                }
            }

            if !calibratingStart {
                Button(action: {
                    calibratingFilter.toggle()
                    if calibratingFilter {
                        let tapHandler = CallibrationTapHandler(type: .amplitudeFilter)
                        audioManager.startRecordingMicrophone(tapHandler: tapHandler, recordAudio: false)
                    }
                    else {
                        audioManager.stopRecording()
                    }
                }) {
                    if calibratingFilter {
                        Text("Stop")
                    }
                    else {
                        Text("Start Calibrating")
                    }
                }
                .padding()
                ///scalesModel.amplitudeFilter is updated after calibration recording
                .onChange(of: scalesModel.amplitudeFilter, {amplitudeFilterAdjust = scalesModel.amplitudeFilter})
            }
            
            Spacer()
            if !calibratingFilter {
                Text("Amplitude filter set at:\(String(format: "%.4f", amplitudeFilterAdjust))").font(.title3).padding()
                if scalesModel.amplitudeFilter > 0 {
                    Slider(
                        value: $amplitudeFilterAdjust,
                        in: 0...2.0 * scalesModel.amplitudeFilter,
                        step: 0.001
                    )
                    .padding()
                }
            }
            Spacer()
        }
    }

    func StartAmplitudeCallibrationView() -> some View {
        VStack {
            Spacer()
            Text("Start Scale Amplitude").font(.title).padding()
            if !calibratingStart {
                VStack {
                    Text("The app needs to hear you play a reglar (mf) note on your piano to calibrate your piano's sound.\n\n•Make sure your device is close to your piano\n•Tap Start Calibrating\n•Play Middle C on your piano a few times\n•Wait a a few seconds\n•Tap Stop Calibrating.")
                }
            }
            if !calibratingFilter {
                Button(action: {
                    calibratingStart.toggle()
                    if calibratingStart {
                        let tapHandler = CallibrationTapHandler(type: .startAmplitude)
                        audioManager.startRecordingMicrophone(tapHandler: tapHandler, recordAudio: false)
                    }
                    else {
                        audioManager.stopRecording()
                    }
                    
                }) {
                    if calibratingStart {
                        Text("Stop")
                    }
                    else {
                        Text("Start Calibrating")
                    }
                }
                .padding()
            }
            
            Spacer()
            if let amplitude = scalesModel.requiredStartAmplitude {
                if !calibratingStart {
                    Text("Scale start filter set at:\(String(format: "%.4f", amplitude))").font(.title3).padding()
                }
                Spacer()
            }
        }
    }

    
    public var body: some View {
        VStack {
            Spacer()
            Text("Calibration").font(.title).bold().padding()
            
//            Button(action: {
//                //showingHelpPopup = true
//            }) {
//                Image(systemName: "questionmark.circle")
//                    .font(.largeTitle)  // Sets the size of the icon
//                    .foregroundColor(.blue)  // Sets the color of the icon
//            }
            Spacer()
            AmplitudeFilterCallibrationView()
            Spacer()
            StartAmplitudeCallibrationView()
            
            Spacer()
        }
        .onAppear() {
            amplitudeFilterAdjust = scalesModel.amplitudeFilter
        }
        .onDisappear() {
            scalesModel.saveSetting(type: .amplitudeFilter, value: amplitudeFilterAdjust)
            scalesModel.amplitudeFilter = amplitudeFilterAdjust 
        }

    }
}

