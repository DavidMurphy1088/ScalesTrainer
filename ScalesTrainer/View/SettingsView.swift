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
    case 7: str = "Melody Bell"
    default:
        str = "Piano"
    }
    return str
}

struct SettingsView: View {
    var user:User?
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var leadInBarCount = 0
    @State var backingPresetNumber = 0
    @State var badgeStyleNumber = 0
    @State var developerMode = false
    @State var useMidiSources = false
    @State var practiceChartGamificationOn = false

    @State private var defaultOctaves = 2
    @State private var tapBufferSize = 4096
    @State private var keyboardColor: Color = .white
    @State private var backgroundColor: Color = .white
    @State private var navigateToSelectBoard = false
    @State private var selectedBackgroundColor: Color = .white
    @State var backgroundChange = 0
    
    struct SetKeyboardColourView: View {
        let scalesModel: ScalesModel
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
                PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: PianoKeyboardModel.sharedForSettings, keyColor: selectedColor)
                    .frame(height: UIScreen.main.bounds.size.height * 0.15)
                    .padding()
            }
            //.background(UIGlobals.shared.purpleHeading)
            .onAppear() {
                self.selectedColor = parentColor
            }
        }
    }

    func DetailedCustomSettingsView(user:User) -> some View {
        VStack(alignment: .leading) {
            ///Backing sampler
            Spacer()
            HStack {
                Text(LocalizedStringResource("Backing Track Sound")).font(.title2).padding(0)
                Picker("Select Value", selection: $backingPresetNumber) {
                    ForEach(0..<8) { number in
                        Text("\(backingSoundName(number))")
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: backingPresetNumber, {
                    user.settings.backingSamplerPreset = backingPresetNumber
                    //AudioManager.shared.resetAudioKit()
                })
            }
            .padding()
            
            ///Badges
            //Spacer()
            HStack {
                Text(LocalizedStringResource("Badge Styles")).font(.title2).padding(0)
                Picker("Select Value", selection: $badgeStyleNumber) {
                    ForEach(0..<5) { number in
                        Text("\(badgeStyle(number))")
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: badgeStyleNumber, {
                    user.settings.badgeStyle = badgeStyleNumber
                })
            }
            .padding()
            
            //Spacer()
//            HStack {
//                Spacer()
//                Toggle(isOn: $practiceChartGamificationOn) {
//                    Text("Gamification").font(.title2).padding(0)
//                }
//                .frame(width: UIScreen.main.bounds.width * (UIDevice.current.userInterfaceIdiom == .phone ? 0.60 : 0.3))
//                .onChange(of: practiceChartGamificationOn, {
//                    user.settings.practiceChartGamificationOn = practiceChartGamificationOn
//                })
//                Spacer()
//            }
//            .padding()
            
            ///Only show the enable MIDI if some MIDI endpoints are connected. Even if they are, below lets the user not use them.
//            if MIDIManager.shared.connectionSourcesPublished.count > 0  {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Toggle(isOn: $useMidiSources) {
//                        Text("Use MIDI Connections").font(.title2).padding(0)
//                    }
//                    .onChange(of: useMidiSources, {
//                        user.settings.useMidiSources = useMidiSources
//                    })
//                    Spacer()
//                }
//                //.frame(width: UIScreen.main.bounds.width * (UIDevice.current.userInterfaceIdiom == .phone ? 0.60 : 0.3))
//                .padding()
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
        case 7: str = "Melody Bell"
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
        case 3: str = "Dinosaurs"
        case 4: str = "Sea Creatures"
        default:
            str = "Star"
        }
        return str
    }

    var body: some View {
        NavigationStack {
            HStack() {
                if let user = user {
                    DetailedCustomSettingsView(user:user)
                }
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Settings",
                helpMsg: "",
                onBack: {}
            )
        }
        .onAppear() {
            let user = settings.getCurrentUser("Settings view")
            ///The keyboard model must be configured to something (if not already) to display the keyboard
            if scalesModel.getScore() == nil {
                scalesModel.setKeyboardAndScore(scale: Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, scaleMotion: .similarMotion, octaves: 1, hands: [0], minTempo: 60, dynamicTypes: [], articulationTypes: []), callback: nil)
            }
            self.defaultOctaves = settings.defaultOctaves
            self.backingPresetNumber = user.settings.backingSamplerPreset
            self.practiceChartGamificationOn = user.settings.practiceChartGamificationOn
            self.badgeStyleNumber = user.settings.badgeStyle
            self.useMidiSources = user.settings.useMidiSources
        }
        .onDisappear() {
            settings.save()
        }
    }
}

