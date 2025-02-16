import Foundation
import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

// ---------------------- Edit details of a single user -------------------

struct GradeTitleView: View {
    //@ObservedObject var settingsPublished = SettingsPublished.shared
    let user = Settings.shared.getCurrentUser()

    var body: some View {
        VStack {
            Text("Name and Grade").font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            HStack {
                if let user = Settings.shared.getCurrentUser() {
                    Text(user.getTitle()).font(.title2)
                }
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading)
    }
}

struct UserDetailsView: View {
    //@ObservedObject var publishedSettings = SettingsPublished.shared
    let user:User
    @Binding var listUpdated:Bool
    @FocusState private var isNameFieldFocused: Bool
    
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var firstName = "" //Settings.shared.getCurrentUser().name
    @State var emailAddress  = "" //= Settings.shared.getCurrentUser().email
    
    @State private var tapBufferSize = 4096
    @State private var navigateToSelectBoard = false
    @State private var navigateToSelectGrade = false
    @State private var selectedGrade:Int?
    @State private var userName = ""
    @State private var welcomeNotification = false

    let width = UIScreen.main.bounds.width * 0.7
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                VStack() {
                    HStack {
                        Text("First Name")
                        TextField("First name", text: $firstName)
                            .focused($isNameFieldFocused)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                            .onChange(of: firstName) { oldName, name in
                                settings.setUserName(user, name)
                            }
                    }
                    
                    HStack {
                        Text("Optional Email")
                        TextField("Email", text: $emailAddress)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                    }
                }
                .onChange(of: emailAddress, {
                    if let user = settings.getCurrentUser() {
                        user.email = emailAddress
                    }
                })
                
                Spacer()
                SelectBoardGradesView(user:user, inBoard: MusicBoard(name: "Trinity"))
                Spacer()
            }
            .commonFrameStyle()
        }
        .sheet(isPresented: $welcomeNotification) {
            VStack(spacing: 20) {
                Image("PianoKeyboard2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        //.frame(width: geo.size.width * 0.60)
                        .cornerRadius(20)

                Text("😊 Welcome 😊")
                    .font(.title).fontWeight(.bold)
                Text("We hope you enjoy your experience using Scales Academy.").multilineTextAlignment(.center)
                Text("To get started please enter your name and Grade.").multilineTextAlignment(.center)
                Button("Get Started") {
                    welcomeNotification = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .onChange(of: welcomeNotification) { newValue in
            // Focus only when the sheet is dismissed
            if !newValue {
                self.isNameFieldFocused = true
            }
        }
    
        .onAppear() {
            //if let user = user { //Settings.shared.getCurrentUser() {
                self.firstName = user.name
                self.emailAddress = user.email
                welcomeNotification = false
                if settings.users.count == 1 && user.name.count == 0 {
                    welcomeNotification = true
                }
            //}
            //self.isNameFieldFocused = true
            listUpdated = false
        }
        .onDisappear() {
            ///Called on downward navigation from this view as well as view exit
            if let user = settings.getUser(id: user.id) {
                user.name = self.firstName
                user.email = self.emailAddress
                settings.save()
                listUpdated = true
            }
        }
    }
}

