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
    @State var backingPresetNumber = 0

    @State private var defaultOctaves = 2
    @State private var tapBufferSize = 4096
    @State private var keyColor: Color = .white

    let width = UIScreen.main.bounds.width * 0.25
    
    struct ColourView: View {
        @Binding var parentColor: Color
        @State private var selectedColor: Color = .white
        
        var body: some View {
            VStack {
                VStack {
                    HStack {
                        Spacer()
                        Text("Choose your keyboard colour ")
                        ColorPicker("Choose your keyboard colour", selection: $selectedColor)
                            .padding()
                            .onChange(of: selectedColor) { oldColor, newColor in
                                PianoKeyboardModel.shared2.redraw()
                                parentColor = newColor
                            }
                            .labelsHidden()
                        Spacer()
                    }
                    PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: PianoKeyboardModel.shared2, keyColor: selectedColor).padding()
                }
            }
            .onAppear() {
                self.selectedColor = parentColor
            }
        }
    }

    func backingSoundName(_ n:Int) -> String {
        var str:String
        switch n {
        case 1: str = "Cello"
        case 2: str = "Synthesiser"
        case 3: str = "Guitar"
        case 4: str = "Saxophone"
        case 5: str = "Moog Synthesiser"
        case 6: str = "Steel Guitar"
        case 7: str = "Choir"
        case 8: str = "Melody Bell"
        default:
            str = "Piano"
        }
        return str
    }
    
    var body: some View {
        VStack {
            Text("Settings").font(.title)
            VStack {
                Spacer()
                HStack() {
                    Text("Please enter your first name").padding()
                    TextField("First name", text: $firstName)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.gray)
                        .frame(width: width)
                        .padding()
                }
                .onChange(of: firstName, {
                    settings.firstName = firstName
                })
                .commonFrameStyle(backgroundColor: .white).padding()
                
                ColourView(parentColor: $keyColor).commonFrameStyle(backgroundColor: .white).padding()
                
                ///default octaves
                HStack {
                    Text("Default Octaves").padding(0)
                    Picker("Select", selection: $defaultOctaves) {
                        ForEach(1..<5) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
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
                
                ///Backing sampler
                Spacer()
                HStack {
                    Text(LocalizedStringResource("Backing Sound")).padding(0)
                    Picker("Select Value", selection: $backingPresetNumber) {
                        ForEach(0..<9) { number in
                            Text("\(backingSoundName(number))")
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: backingPresetNumber, {
                        settings.backingSamplerPreset = backingPresetNumber
                        AudioManager.shared.resetAudioKit()
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
                        Settings.shared.setKeyColor(keyColor)
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
            PianoKeyboardModel.shared2.configureKeyboardForScaleStartView(start: 36, numberOfKeys: 20, scaleStartMidi: ScalesModel.shared.scale.getMinMax().0)
            self.keyColor = Settings.shared.getKeyColor()
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

