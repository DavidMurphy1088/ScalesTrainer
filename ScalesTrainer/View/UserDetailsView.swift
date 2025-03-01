import Foundation
import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

// ---------------------- Edit details of a single user -------------------

struct UserDetailsView: View {
    @Environment(\.dismiss) var dismiss  // Access the dismiss function
    let user:User
    let creatingNewUser:Bool
    @Binding var listUpdated:Bool
    @FocusState private var isNameFieldFocused: Bool
    
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var firstName = ""
    @State var emailAddress  = ""
    
    @State private var tapBufferSize = 4096
    @State private var navigateToSelectBoard = false
    @State private var navigateToSelectGrade = false
    @State private var userName = ""
    @State private var showWelcomeToFirstUser = false
    @State private var isFirstUser = false
    @State private var firstUseForUserStep2 = false
    @State private var selectedGrade = 0

    let width = UIScreen.main.bounds.width * 0.7
    
    func getGradeName(grade:Int) -> String {
        var gradeStr = ""
        switch grade {
        case 1 : gradeStr = "One"
        case 2 : gradeStr = "Two"
        case 3 : gradeStr = "Three"
        case 4 : gradeStr = "Four"
        case 5 : gradeStr = "Five"
        default: gradeStr = ""
        }
        return gradeStr
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
                SelectBoardGradesView(user:user, inBoard: MusicBoard(name: "Trinity"), selectedGrade: $selectedGrade)
                if self.creatingNewUser && user.name.count > 0 && selectedGrade > 0 {
                    Spacer()
                    Button(action: {
                        settings.addUser(user: user)
                        settings.setCurrentUser(id: user.id)
                        listUpdated.toggle()
                        dismiss()
                    }) {
                        Text("Add User")
                    }
                    .blueButtonStyle()
                }
                Spacer()
            }
            //.commonFrameStyle()
            //.screenBackgroundStyle()
        }
        .onChange(of: selectedGrade, {
            if isFirstUser {
                if self.firstName.count > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        firstUseForUserStep2 = true
                    }
                }
            }
        })
        .sheet(isPresented: $showWelcomeToFirstUser) {
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
                    showWelcomeToFirstUser = false
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
                Text("😊 Thanks \(self.firstName), Your Grade Is Set 😊").font(.title).fontWeight(.bold)
                Text("Next, let's go to your Activities for Grade \(getGradeName(grade: self.selectedGrade))").multilineTextAlignment(.center)
                HStack {
                    Button("Cancel") {
                        firstUseForUserStep2 = false
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)

                    Button("Activites") {
                        firstUseForUserStep2 = false
                        settings.addUser(user: user)
                        settings.setCurrentUser(id: user.id)
                        ViewManager.shared.setTab(tab: MainContentView.TAB_ACTIVITES)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }                
            }
            .presentationDetents([.fraction(0.3)])
        }
        .onChange(of: showWelcomeToFirstUser) { newValue in
            // Focus only when the sheet is dismissed
            if !newValue {
                self.isNameFieldFocused = true
            }
        }
        .onAppear() {
            self.firstName = user.name
            self.emailAddress = user.email
            showWelcomeToFirstUser = false
            if settings.users.count == 0 {
                showWelcomeToFirstUser = true
                isFirstUser = true
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

