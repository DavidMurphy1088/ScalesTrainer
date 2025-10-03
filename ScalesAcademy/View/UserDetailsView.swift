//import Foundation
//import Foundation
//import SwiftUI
//import Combine
//import SwiftUI
//import AVFoundation
//import AudioKit
//
//// ---------------------- Edit details of a single user -------------------
//
//struct UserDetailsView: View {
//    @State var user:User
//    @Binding var listUpdated:Bool
//    @FocusState private var isNameFieldFocused: Bool
//    
//    let scalesModel = ScalesModel.shared
//    let settings = Settings.shared
//    @State var firstName = ""
//    @State var emailAddress  = ""
//    
//    @State private var tapBufferSize = 4096
//    @State private var navigateToSelectBoard = false
//    @State private var navigateToSelectGrade = false
//    @State private var userName = ""
//    @State private var showWelcomeToFirstUser = false
//    @State private var isFirstUser = false
//    //@State private var firstUseForUserStep2 = false
//    //@State private var selectedGrade = 0
//
//    let width = UIScreen.main.bounds.width * 0.7
//    
//    func getGradeName(grade:Int) -> String {
//        var gradeStr = ""
//        switch grade {
//        case 1 : gradeStr = "One"
//        case 2 : gradeStr = "Two"
//        case 3 : gradeStr = "Three"
//        case 4 : gradeStr = "Four"
//        case 5 : gradeStr = "Five"
//        default: gradeStr = ""
//        }
//        return gradeStr
//    }
//    
//    var body: some View {
//        VStack {
//            ScreenTitleView(screenName: "User Details").padding(.vertical, 0)
//            VStack(spacing:0) {
//                VStack(spacing: 0) {
//                    HStack {
//                        Text("First Name")
//                        TextField("First name", text: $firstName)
//                            .focused($isNameFieldFocused)
//                            .padding()
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .frame(width: UIScreen.main.bounds.width * 0.5)
//                            .onChange(of: firstName) { oldName, newName in
//                                if !newName.isEmpty {
//                                    let user = settings.getCurrentUser()
//                                    user.name = newName
//                                }
//                            }
//                    }
//                    
//                    HStack {
//                        Text("Optional Email")
//                        TextField("Email", text: $emailAddress)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .frame(width: UIScreen.main.bounds.width * 0.5)
//                            .onChange(of: emailAddress, {
//                                let user = settings.getCurrentUser()
//                                user.email = emailAddress
//                            })
//                    }
//                }
//
//                SelectBoardView(user: user)
//                    
//            }
//            //.commonFrameStyle()
//            //.screenBackgroundStyle()
//        }
//
////        .onChange(of: selectedGrade, {
////            if isFirstUser {
////                if self.firstName.count > 0 {
////                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
////                        firstUseForUserStep2 = true
////                    }
////                }
////            }
////        })
//        

//
//        .onChange(of: showWelcomeToFirstUser) { newValue in
//            // Focus only when the sheet is dismissed
//            if !newValue {
//                self.isNameFieldFocused = true
//            }
//        }
//        .onAppear() {
//            self.firstName = user.name
//            self.emailAddress = user.email
//            showWelcomeToFirstUser = false
//            if !settings.aValidUserIsDefined() {
//                showWelcomeToFirstUser = true
//                isFirstUser = true
//            }
//            listUpdated = false
//        }
//        .onDisappear() {
//            ///Called on downward navigation from this view as well as view exit
//            if let user = settings.getUser(id: user.id) {
//                user.name = self.firstName
//                user.email = self.emailAddress
//                settings.save()
//                listUpdated = true
//            }
//        }
//    }
//}
//
