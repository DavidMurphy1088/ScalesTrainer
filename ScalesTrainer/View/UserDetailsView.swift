import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct NewUserPopup: View {
    @Binding var showPopup: Bool
    @Binding var userName: String
    @State private var tempUserName = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("New User Profile")
                .font(.headline)
            Text("Please enter the first name")
            TextField("first name", text: $tempUserName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    showPopup = false
                }
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)

                Button("OK") {
                    userName = tempUserName // Update parent view's userName
                    showPopup = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 300)
        .padding()
    }
}

struct GradeTitleView: View {
    @ObservedObject var settingsPublished = SettingsPublished.shared
    let user = Settings.shared.getCurrentUser()

    var body: some View {
        VStack {
            Text("Name and Grade").font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            HStack {
                if user.name.count > 0 {
                    let name = user.name + (user.grade == nil ? "" : ",")
                    Text(name).font(.title2)
                    if let grade = user.grade {
                        Text("Grade \(grade)").font(.title2)
                    }
                }
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
    }
}

struct UserDetailsView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    @ObservedObject var publishedSettings = SettingsPublished.shared
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var firstName = Settings.shared.getCurrentUser().name
    @State var emailAddress = Settings.shared.getCurrentUser().email

    @State private var tapBufferSize = 4096
    @State private var navigateToSelectBoard = false
    @State private var navigateToSelectGrade = false
    @State private var selectedGrade:Int?
    @State private var userName = ""
    @State private var showNewUser = false
    @State private var oneUserMode = true
    let width = UIScreen.main.bounds.width * 0.7
    //@FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        //NavigationStack {
        VStack {
            GradeTitleView().commonFrameStyle()

            VStack {
                Spacer()
                ///If no users exist yet let the user create one. But if one exists add the ability to add more.
                if oneUserMode {
                    VStack() {
                        Text("Please enter your first name").padding()
                        TextField("First name", text: $firstName)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                            //.focused($isNameFieldFocused)
                            .onChange(of: firstName) { oldValue, newValue in
                                let user:User
                                if settings.users.count == 0 {
                                    user = User()
                                    settings.addUser(user: user)
                                }
                                else {
                                    user = settings.getCurrentUser()
                                }
                                settings.setUserName(newValue)
                            }
                    }
                }
                
                Spacer()
                VStack() {
                    Text("Optional Email").padding()
                    TextField("Email", text: $emailAddress)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: UIScreen.main.bounds.width * 0.5)
                }
                .onChange(of: emailAddress, {
                    settings.getCurrentUser().email = emailAddress
                })
                
                Spacer()
                SelectBoardGradesView(inBoard: MusicBoard(name: "Trinity"))
                Spacer()
            }
            .overlay(
                Group {
                    if showNewUser {
                        NewUserPopup(showPopup: $showNewUser, userName: $userName)
                            .background(Color.black.opacity(0.2)) // Dim the background
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            )

            .commonFrameStyle()
//            .padding()
//            Spacer()
            //.frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.8)
        }
        .onAppear() {
            self.oneUserMode = settings.users.count <= 1
            if !oneUserMode {
                self.showNewUser = true
            }
        }
        .onDisappear() {
            ///Called on downward navigation from this view as well as view exit
            Settings.shared.save() //User name (above) is in settings
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

