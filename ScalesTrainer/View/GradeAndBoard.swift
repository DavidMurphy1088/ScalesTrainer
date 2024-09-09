import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct GradeAndBoard: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var recordDataMode = Settings.shared.developerModeOn 
    @State var firstName = Settings.shared.firstName
    
    @State private var tapBufferSize = 4096
    @State private var keyColor: Color = .white
    @State private var navigateToSelectBoard = false
    @State private var navigateToGrade = false
    let background = UIGlobals.shared.getBackground()
    
    let width = UIScreen.main.bounds.width * 0.7
    
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
                    //TitleView(screenName: "Music Board and Grade").commonFrameStyle()
                    TitleView(screenName: "Trinity Grade").commonFrameStyle()

                    VStack {
                        Spacer()
                        VStack() {
                            Text("Please enter your first name").padding()
                            TextField("First name", text: $firstName)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: UIScreen.main.bounds.width * 0.5)
                            //.border(Color.gray)
                            //.padding()
                        }
                        .onChange(of: firstName, {
                            settings.firstName = firstName
                            SettingsPublished.shared.firstName = firstName
                        })
                        
                        //Spacer()
                        //Button("Select Your Music Board and Grade") {
                        Button("Select Your Grade") {
                            //navigateToSelectBoard = true
                            navigateToGrade = true
                        }
                        .padding()
                        .navigationDestination(isPresented: $navigateToSelectBoard) {
                            SelectMusicBoardView()
                        }
                        .navigationDestination(isPresented: $navigateToGrade) {
                            BoardGradesView(board: "trinity")
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

