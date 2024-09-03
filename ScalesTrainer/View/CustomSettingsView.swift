import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct CustomSettingsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var recordDataMode = Settings.shared.developerModeOn 
    @State var firstName = Settings.shared.firstName
    @State var leadInBarCount = 0
    @State var scaleNoteValue = 0
    @State var backingPresetNumber = 0
    @State var badgeStyleNumber = 0
    @State var metronomeOn = false
    @State var developerModeOn = false

    @State private var defaultOctaves = 2
    @State private var tapBufferSize = 4096
    @State private var keyColor: Color = .white
    @State private var navigateToSelectBoard = false
    let background = UIGlobals.shared.getBackground()
    
    func DetailedCustomSettingsView() -> some View {
        VStack {
            Spacer()
            HStack {
                Text("Default Octaves").font(.title2).padding(0)
                Picker("Select", selection: $defaultOctaves) {
                    ForEach(1..<3) { number in
                        Text("\(number)").tag(number)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: defaultOctaves) { oldValue, newValue in
                    settings.defaultOctaves = newValue
                }
            }
            
            ///Metronome on
            Spacer()
            HStack {
                Spacer()
                Toggle(isOn: $metronomeOn) {
                    Text("Metronome On").font(.title2).padding(0)
                }
                .onChange(of: metronomeOn, {
                    settings.metronomeOn = metronomeOn
                })
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.30)
        
            ///Lead in count
            Spacer()
            HStack {
                Text(LocalizedStringResource("Scale Lead in Count")).font(.title2).padding(0)
                Picker("Select Value", selection: $leadInBarCount) {
                    ForEach(scalesModel.scaleLeadInCounts.indices, id: \.self) { index in
                        Text("\(scalesModel.scaleLeadInCounts[index])")
                    }
                }
                .disabled(!self.metronomeOn)
                .pickerStyle(.menu)
                .onChange(of: leadInBarCount, {
                    settings.scaleLeadInBarCount = leadInBarCount
                })
            }
            
            ///Backing sampler
            Spacer()
            HStack {
                Text(LocalizedStringResource("Backing Sound")).font(.title2).padding(0)
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
            
            ///Backing sampler
            Spacer()
            HStack {
                Text(LocalizedStringResource("Badge Styles")).font(.title2).padding(0)
                Picker("Select Value", selection: $badgeStyleNumber) {
                    ForEach(0..<2) { number in
                        Text("\(badgeStyle(number))")
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: badgeStyleNumber, {
                    settings.badgeStyle = badgeStyleNumber
                })
            }

            ///Score values
            Spacer()
            HStack {
                Text(LocalizedStringResource("Scale Note Value")).font(.title2).padding(0)
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
            
            ///Developer
            Spacer()
            HStack {
                Spacer()
                Toggle(isOn: $developerModeOn) {
                    Text("Developer Mode On").font(.title2).padding(0)
                }
                .onChange(of: developerModeOn, {
                    settings.developerModeOn = developerModeOn
                })
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.30)
            
            
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    settings.save()
                }) {
                    HStack {
                        Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
                Spacer()
            }

            
//            Spacer()
//            Button(action: {
//                CoinBank.shared.setTotalCoinsInBank(CoinBank.initialCoins)
//                
//            }) {
//                HStack {
//                    Text("Reset Coin Count").padding()//.font(.title2).hilighted(backgroundColor: .blue)
//                }
//            }
            
//            Spacer()
//            Text("---------- TEST ONLY ----------")
//            HStack() {
//                Toggle("Record Data Mode", isOn: $recordDataMode)
//            }
//            //.frame(width: width)
//            .onChange(of: recordDataMode, {
//                settings.recordDataMode = recordDataMode
//            })
//            .padding()
            
            Spacer()
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
    
    func badgeStyle(_ n:Int) -> String {
        var str:String
        switch n {
        case 1: str = "Cute Pets"
        default:
            str = "Star"
        }
        return str
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Image(background)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.top)
                        .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
                }
                VStack {
                    TitleView(screenName: "Custom Settings")
                    VStack {
                        DetailedCustomSettingsView()
                    }
                    .commonFrameStyle()
                    .padding()
                }
                
                .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.8)
                .onAppear() {
                    leadInBarCount = settings.scaleLeadInBarCount
                    self.defaultOctaves = settings.defaultOctaves
                    self.scaleNoteValue = settings.scaleNoteValue==4 ? 0 : 1
                    PianoKeyboardModel.sharedForSettings.configureKeyboardForScaleStartView(start: 36, numberOfKeys: 20, scaleStartMidi: ScalesModel.shared.scale.getMinMax(handIndex: 0).0)
                    self.keyColor = Settings.shared.getKeyColor()
                    self.backingPresetNumber = settings.backingSamplerPreset
                    self.metronomeOn = settings.metronomeOn
                    self.developerModeOn = settings.developerModeOn
                    self.badgeStyleNumber = settings.badgeStyle
                }
            }
        }
    }
}

