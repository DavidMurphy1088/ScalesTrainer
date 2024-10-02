import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

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

struct SettingsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    //@State var recordDataMode = Settings.shared.developerModeOn
    @State var firstName = Settings.shared.firstName
    @State var leadInBarCount = 0
    @State var backingPresetNumber = 0
    @State var badgeStyleNumber = 0
    @State var developerMode = false
    @State var metronomeSilent = false

    @State private var defaultOctaves = 2
    @State private var tapBufferSize = 4096
    @State private var keyboardColor: Color = .white
    @State private var backgroundColor: Color = .white
    @State private var navigateToSelectBoard = false
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    @State private var selectedBackgroundColor: Color = .white
    @State var backgroundChange = 0
    
    struct SetKeyboardColourView: View {
        @Binding var parentColor: Color
        @State private var selectedColor: Color = .white
        
        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Text("Choose your keyboard colour ")
                    ColorPicker("Choose your keyboard colour", selection: $selectedColor)
                        .padding()
                        .onChange(of: selectedColor) { oldColor, newColor in
                            PianoKeyboardModel.sharedForSettings.redraw()
                            parentColor = newColor
                        }
                        .labelsHidden()
                        
                    Spacer()
                }
                PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: PianoKeyboardModel.sharedForSettings, keyColor: selectedColor).padding()
            }
            .background(UIGlobals.shared.purpleDark)
            .onAppear() {
                self.selectedColor = parentColor
            }
        }
    }
    
    func DetailedCustomSettingsView() -> some View {
        VStack {
            //ZStack {
//                if self.backgroundChange >= 0 {
//                    VStack {
//                        Settings.shared.getBackgroundColor()
//                    }
//                }
                VStack {
                    HStack {
                        //Spacer()
                        Text("Choose your background colour ").font(.title2).padding(0)
                        ///Force a repaint on color change with published self.backgroundChange
                        ColorPicker("Choose your background colour \(self.backgroundChange)", selection: $selectedBackgroundColor)
                            .padding()
                            .onChange(of: selectedBackgroundColor) { oldColor, newColor in
                                Settings.shared.setBackgroundColor(newColor)
                                self.backgroundChange += 1
                            }
                            .labelsHidden()
                        //Spacer()
                    }
                    HStack {
                        //Spacer()
                        VStack {
                            SetKeyboardColourView(parentColor: $keyboardColor)
                        }
                        //.padding()
                        .onChange(of: keyboardColor, {
                            Settings.shared.setKeyboardColor(keyboardColor)
                        })
                        .hilighted(backgroundColor: .gray)
                        .frame(width: UIScreen.main.bounds.size.width * 0.9,
                               height: orientationObserver.orientation.isAnyLandscape ? UIScreen.main.bounds.size.height * 0.4 : UIScreen.main.bounds.size.height * 0.25)
                        //Spacer()
                    }
                }
                .padding(.vertical, 0)
                .border(Color.green, width: 3)
            //}
            .padding(.vertical, 0)
            .border(Color.red)
            
//            ///Metronome on
//            Spacer()
//            HStack {
//                Spacer()
//                Toggle(isOn: $metronomeOn) {
//                    Text("Metronome On").font(.title2).padding(0)
//                }
//                .onChange(of: metronomeOn, {
//                    settings.metronomeOn = metronomeOn
//                })
//                Spacer()
//            }
//            .frame(width: UIScreen.main.bounds.width * 0.30)
        
            ///Lead in count
            Spacer()
            HStack {
                Text(LocalizedStringResource("Lead in Count")).font(.title2).padding(0)
                Picker("Select Value", selection: $leadInBarCount) {
                    ForEach(scalesModel.scaleLeadInCounts.indices, id: \.self) { index in
                        Text("\(scalesModel.scaleLeadInCounts[index])")
                    }
                }
                //.disabled(!self.metronomeOn)
                .pickerStyle(.menu)
                .onChange(of: leadInBarCount, {
                    
                    settings.scaleLeadInBearCountIndex = leadInBarCount
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
            
            ///Badges
            Spacer()
            HStack {
                Text(LocalizedStringResource("Badge Styles")).font(.title2).padding(0)
                Picker("Select Value", selection: $badgeStyleNumber) {
                    ForEach(0..<3) { number in
                        Text("\(badgeStyle(number))")
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: badgeStyleNumber, {
                    settings.badgeStyle = badgeStyleNumber
                })
            }

//            ///Score values
//            Spacer()
//            HStack {
//                Text(LocalizedStringResource("Scale Note Value")).font(.title2).padding(0)
//                Picker("Select Value", selection: $scaleNoteValue) {
//                    ForEach(0..<2) { number in
//                        let valueStr = number == 0 ? "Crotchet" : "Quaver"
//                        Text("\(valueStr)")
//                    }
//                }
//                .pickerStyle(.menu)
//                .onChange(of: scaleNoteValue, {
//                    settings.scaleNoteValue = scaleNoteValue == 0 ? 4 : 8
//                })
//            }
            
            ///Developer
            if Settings.shared.isDeveloperMode() {
                Spacer()
                HStack {
                    Spacer()
                    Toggle(isOn: $developerMode) {
                        Text("Developer Mode On").font(.title2).padding(0)
                    }
                    .onChange(of: developerMode, {
                        settings.developerMode = developerMode
                    })
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.30)
            }
            
            if Settings.shared.isDeveloperMode() {
                Spacer()
                HStack {
                    Spacer()
                    Toggle(isOn: $metronomeSilent) {
                        Text("Metronome Silent").font(.title2).padding(0)
                    }
                    .onChange(of: metronomeSilent, {
                        settings.metronomeSilent = metronomeSilent
                    })
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * 0.30)
            }

//            Spacer()
//            HStack {
//                Spacer()
//                Button(action: {
//                    settings.save()
//                }) {
//                    HStack {
//                        Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
//                    }
//                }
//                Spacer()
//            }
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
        case 1: str = "Pets"
        case 2: str = "Bugs"
        default:
            str = "Star"
        }
        return str
    }

    var body: some View {
        NavigationStack {
            
            VStack {
                TitleView(screenName: "Settings").commonFrameStyle()
                DetailedCustomSettingsView()
                    .commonFrameStyle()
                    .padding()
            }
            
            .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.9)
            .onAppear() {
                leadInBarCount = settings.scaleLeadInBearCountIndex
                self.defaultOctaves = settings.defaultOctaves
                //self.scaleNoteValue = settings.scaleNoteValue==4 ? 0 : 1
                PianoKeyboardModel.sharedForSettings.configureKeyboardForScaleStartView(start: 36, numberOfKeys: 20, scaleStartMidi: ScalesModel.shared.scale.getMinMax(handIndex: 0).0)
                self.keyboardColor = Settings.shared.getKeyboardColor1()
                self.backgroundColor = Settings.shared.getBackgroundColor()
                self.backingPresetNumber = settings.backingSamplerPreset
                self.metronomeSilent = settings.metronomeSilent
                self.developerMode = settings.developerMode
                self.badgeStyleNumber = settings.badgeStyle
            }
            .onDisappear() {
                settings.save()
            }
        }
        
    }
}

