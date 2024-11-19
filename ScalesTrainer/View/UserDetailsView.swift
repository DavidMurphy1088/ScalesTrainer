import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct UserDetailsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    @ObservedObject var publishedSettings = SettingsPublished.shared
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var firstName = Settings.shared.firstName
    @State var emailAddress = Settings.shared.emailAddress

    @State private var tapBufferSize = 4096
    @State private var navigateToSelectBoard = false
    @State private var navigateToSelectGrade = false
    @State private var selectedGrade:Int?

    let width = UIScreen.main.bounds.width * 0.7
    
    func setSelectedGrade() -> Int? {
        if let boardAndGrade = Settings.shared.getBoardAndGrade() {
            return boardAndGrade.grade
        }
        else {
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TitleView(screenName: "Name and Grade", showGrade: true).commonFrameStyle()

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
                    
                    Spacer()
                    VStack() {
                        Text("Optional Email").padding()
                        TextField("Email", text: $emailAddress)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                    }
                    .onChange(of: emailAddress, {
                        settings.emailAddress = emailAddress
                        //SettingsPublished.shared = firstName
                    })
                    
                    Spacer()
                    if MusicBoard.getSupportedBoards().count == 1 {
                        Button(action: {
                            navigateToSelectGrade = true
                        }) {
                            HStack {
                                Text("Select Your Piano Grade").padding().font(.title2).hilighted(backgroundColor: .blue)
                            }
                        }
                        .navigationDestination(isPresented: $navigateToSelectGrade) {
                            SelectBoardGradesView(inBoard: MusicBoard(name: MusicBoard.getSupportedBoards()[0].name), inGrade: publishedSettings.grade)
                        }
                    }
                    else {
                        Button(action: {
                            navigateToSelectBoard = true
                        }) {
                            HStack {
                                Text("Select Your Music Board").padding().font(.title2).hilighted(backgroundColor: .blue)
                            }
                        }
                        .navigationDestination(isPresented: $navigateToSelectBoard) {
                            SelectMusicBoardView(inBoard: Settings.shared.getBoardAndGrade()?.board)
                        }
                    }

//                    Spacer()
//                    Button(action: {
//                        settings.save()
//                        tabSelectionManager.selectedTab = 10
//                    }) {
//                        HStack {
//                            Text("Save Settings").padding().font(.title2).hilighted(backgroundColor: .blue)
//                        }
//                    }
                    
                    Spacer()
                }
                .commonFrameStyle()
                .padding()
                Spacer()

                //.frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.8)
                .onAppear() {

                }
                .onDisappear() {
                    settings.save()
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

