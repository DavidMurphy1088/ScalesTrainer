import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct SettingsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager

    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var recordDataMode = Settings.shared.recordDataMode
    @State var firstName = Settings.shared.firstName
    @State var leadInBarCount = 0
    @State var scaleNoteValue = 0
    
    @State private var defaultOctaves = 2
    @State private var tapBufferSize = 4096
    
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
                
                ///default octaves
                HStack {
                    Text("Default Octaves").padding(0)
                    Picker("Select", selection: $defaultOctaves) {
                        ForEach(1..<5) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .onChange(of: defaultOctaves) { oldValue, newValue in
                        settings.defaultOctaves = newValue
                    }
                }
                
                ///Score values
                Spacer()
                HStack {
                    Text(LocalizedStringResource("Scale Note Value")).padding(0)
                    Picker("Select Value", selection: $scaleNoteValue) {
                        ForEach(0..<2) { number in
                            let valueStr = number == 0 ? "Crotchet" : "Quaver"
                            Text("\(valueStr)")
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: scaleNoteValue, {
                        settings.scaleNoteValue = scaleNoteValue == 0 ? 4 : 8
                    })
                }
                
                ///Lead in
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
                    
                }) {
                    HStack {
                        Text("Reset Coin Count").padding()//.font(.title2).hilighted(backgroundColor: .blue)
                    }
                }

                Spacer()
                Text("---------- TEST ONLY ----------")
                HStack() {
                    Toggle("Record Data Mode", isOn: $recordDataMode)
                }
                .frame(width: width)
                .onChange(of: recordDataMode, {
                    settings.recordDataMode = recordDataMode
                })
                .padding()
//                HStack {
//                    Text("TapBufferSize").padding(0)
//                    Picker("Select", selection: $tapBufferSize) {
//                        ForEach(1..<16+1) { number in
//                            Text("\(number * 1024)").tag(number * 1024)
//                        }
//                    }
//                    .pickerStyle(MenuPickerStyle())
//                    .padding()
//                    .onChange(of: tapBufferSize) { oldValue, newValue in
//                        settings.defaultTapBufferSize = tapBufferSize //* 1024
//                    }
//                }

                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        settings.save()
                        if settings.amplitudeFilter == 0 {
                            tabSelectionManager.selectedTab = 3
                        }
                    }) {
                        HStack {
                            Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
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
            self.defaultOctaves = settings.defaultOctaves
            //self.tapBufferSize = settings.defaultTapBufferSize // 1024
            self.scaleNoteValue = settings.scaleNoteValue==4 ? 0 : 1
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

