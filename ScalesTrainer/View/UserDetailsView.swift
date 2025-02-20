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
    @State private var firstUseForUserStep1 = false
    @State private var firstUseForUserStep2 = false
    @State private var firstUseForUser = false
    @State private var firstUserGrade = ""

    let width = UIScreen.main.bounds.width * 0.7
    
    func setGradeCallback(grade:Int) {
        guard self.firstName.count > 0 else {
            return
        }
        switch grade {
        case 1 : self.firstUserGrade = "One"
        case 2 : self.firstUserGrade = "Two"
        case 3 : self.firstUserGrade = "Three"
        case 4 : self.firstUserGrade = "Four"
        case 5 : self.firstUserGrade = "Five"
        default: self.firstUserGrade = ""
        }
        print("=========== SETXX", grade, self.firstUserGrade)
        firstUseForUserStep2 = true
    }
    
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
                SelectBoardGradesView(user:user, inBoard: MusicBoard(name: "Trinity"), setGradeCallback: setGradeCallback)
                Spacer()
            }
            .commonFrameStyle()
        }
        .sheet(isPresented: $firstUseForUserStep1) {
            VStack(spacing: 20) {
                let imageSize = UIScreen.main.bounds.width * 0.6
                Image("GrandPiano")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageSize )
                        .cornerRadius(imageSize * 0.1)
                
                Text("😊 Welcome 😊").font(.title).fontWeight(.bold)
                Text("We hope you enjoy your experience using Scales Academy.").multilineTextAlignment(.center)
                Text("To get started please enter your name and Grade.").multilineTextAlignment(.center)
                Button("Get Started") {
                    firstUseForUserStep1 = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $firstUseForUserStep2) {
            VStack(spacing: 20) {
                Text("😊 Thanks, Your Grade Is Set 😊").font(.title).fontWeight(.bold)
                Text("Next, let's go to your Activities for Grade \(self.firstUserGrade)").multilineTextAlignment(.center)
                HStack {
                    Button("Cancel") {
                        firstUseForUserStep2 = false
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                    Button("Activites") {
                        firstUseForUserStep2 = false
                        ViewManager.shared.setTab(tab: 20)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }                
                .padding()
            }
            .padding()
        }
        .onChange(of: firstUseForUserStep1) { newValue in
            // Focus only when the sheet is dismissed
            if !newValue {
                self.isNameFieldFocused = true
            }
        }
        .onAppear() {
            self.firstName = user.name
            self.emailAddress = user.email
            firstUseForUserStep1 = false
            if settings.users.count == 1 && user.name.count == 0 {
                firstUseForUserStep1 = true
                firstUseForUser = true
            }
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

