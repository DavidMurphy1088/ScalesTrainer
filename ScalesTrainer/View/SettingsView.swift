import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

//struct SpeechView : View {
//    @ObservedObject private var scalesModel = ScalesModel.shared
//    @State var setSpeechListenMode = false
////    var body: some View {
////        HStack {
////            HStack() {
////                Toggle("Speech Listen", isOn: $setSpeechListenMode)
////            }
////            .frame(width: UIScreen.main.bounds.width * 0.15)
////            .padding()
////            .background(Color.gray.opacity(0.3)) // Just to see the size of the HStack
////            //.onChange(of: setSpeechListenMode, {scalesModel.setSpeechListenMode(setSpeechListenMode)})
////            .padding()
////            if scalesModel.speechListenMode {
////                let c = String(scalesModel.speechCommandsReceived)
////                Text("Last Word Number:\(c) Word:\(scalesModel.speechLastWord)")
////            }
////        }
////    }
//}

struct SettingsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager

    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var recordDataMode = Settings.shared.recordDataMode
    @State var firstName = Settings.shared.firstName
    @State var leadInBarCount = 0
    let width = UIScreen.main.bounds.width * 0.25
    
    var body: some View {
        VStack {
            Text("Settings").font(.title)
            VStack {
                Spacer()
                HStack() {
                    Text("Please enter your first name")
                    TextField("First name", text: $firstName)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.gray)
                        
                        .frame(width: width)
                        .padding()
//
//                    Text("You entered: \(inputText)")
//                        .padding()
                }
                .onChange(of: firstName, {
                    settings.firstName = firstName
                    //settings.save(amplitudeFilter: scalesModel.amplitudeFilter)
                })
                .padding()
                
                Spacer()
                HStack {
                    Text(LocalizedStringResource("Recording Scale Lead in Count")).padding(0)
                    Picker("Select Value", selection: $leadInBarCount) {
                        ForEach(scalesModel.scaleLeadInCounts.indices, id: \.self) { index in
                            Text("\(scalesModel.scaleLeadInCounts[index])")
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: leadInBarCount, {
                        settings.scaleLeadInBarCount = leadInBarCount
                        //settings.save(amplitudeFilter: scalesModel.amplitudeFilter)
                    })
                }
                
                Spacer()
                Button(action: {
                    CoinBank.shared.setTotalCoinsInBank(CoinBank.initialCoins)
                    CoinBank.shared.save()
                }) {
                    HStack {
                        Text("Reset Coin Count").padding()//.font(.title2).hilighted(backgroundColor: .blue)
                    }
                }

                Spacer()
                HStack() {
                    Toggle("(TEST ONLY Record Data Mode)", isOn: $recordDataMode)
                }
                .frame(width: width)
                .onChange(of: recordDataMode, {
                    settings.recordDataMode = recordDataMode
                })
                .padding()
                
                Spacer()
                HStack {
                    Spacer()

                    Button(action: {
                        settings.save(amplitudeFilter: scalesModel.amplitudeFilter1)
                    }) {
                        HStack {
                            Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
//                    Spacer()
//                    Button(action: {
//                        settings.load()
//                    }) {
//                        HStack {
//                            Text("Load").padding().font(.title2).hilighted(backgroundColor: .blue)
//                        }
//                    }
                    Spacer()
                    Button(action: {
                        tabSelectionManager.nextNavigationTab()
                    }) {
                        HStack {
                            Text("Exit").padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            //let req = settings.requiredScaleRecordStartAmplitude
            Text(Settings.shared.toString())
        }
        .onAppear() {
            leadInBarCount = settings.scaleLeadInBarCount
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
        //print("Selected Microphone: \(microphone.portName)")
    } catch {
        //Logger.shared.reportError(self, "Failed to set preferred input: \(error)")
    }
}

