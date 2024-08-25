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
    
    @State private var tapBufferSize = 4096
    @State private var keyColor: Color = .white
    @State private var navigateToSelectBoard = false
    let background = UIGlobals.shared.getBackground()
    
    let width = UIScreen.main.bounds.width * 0.7
    
    struct SetKeyboardColourView: View {
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
                                PianoKeyboardModel.sharedForSettings.redraw()
                                parentColor = newColor
                            }
                            .labelsHidden()
                        Spacer()
                    }
                    PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: PianoKeyboardModel.sharedForSettings, keyColor: selectedColor).padding()
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
                    TitleView(screenName: "Settings")

                    Spacer()
                    VStack {
                        VStack {
                            HStack() {
                                Text("Please enter your first name").padding()
                                TextField("First name", text: $firstName)
                                    .padding()
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                //.border(Color.gray)
                                //.padding()
                            }
                            .onChange(of: firstName, {
                                settings.firstName = firstName
                                SettingsPublished.shared.firstName = firstName
                            })
                            
                            Button("Select Your Music Board and Grade") {
                                navigateToSelectBoard = true
                            }
                            .padding()
                            .navigationDestination(isPresented: $navigateToSelectBoard) {
                                SelectMusicBoardView()
                            }
                            
                            GeometryReader { geometry in
                                HStack {
                                    Spacer()
                                    VStack {
                                        SetKeyboardColourView(parentColor: $keyColor)
                                    }
                                    .padding()
                                    .hilighted(backgroundColor: .gray)
                                    .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.6)
                                    Spacer()
                                }
                            }
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                Settings.shared.setKeyColor(keyColor)
                                settings.save()
//                                if settings.amplitudeFilter == 0 {
//                                    tabSelectionManager.selectedTab = 3
//                                }
                                tabSelectionManager.selectedTab = 1
                            }) {
                                HStack {
                                    Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
                                }
                            }
                            Spacer()
                        }
                    }
                    .commonFrameStyle()
                    .padding()
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.8)
                .onAppear() {
                    PianoKeyboardModel.sharedForSettings.configureKeyboardForScaleStartView(start: 36, numberOfKeys: 20, scaleStartMidi: ScalesModel.shared.scale.getMinMax(handIndex: 0).0)
                    self.keyColor = Settings.shared.getKeyColor()
                }
            }
        }
    }
}

func getAvailableMicrophones() -> [AVAudioSessionPortDescription] {
    var availableMicrophones: [AVAudioSessionPortDescription] = []
    let audioSession = AVAudioSession.sharedInstance()
    availableMicrophones = audioSession.availableInputs ?? []
    return availableMicrophones
}

func selectMicrophone(_ microphone: AVAudioSessionPortDescription) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try audioSession.setPreferredInput(microphone)

    } catch {
        //Logger.shared.reportError(self, "Failed to set preferred input: \(error)")
    }
}

