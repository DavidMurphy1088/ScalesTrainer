import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

// ---------------------- Edit details of a single user -------------------

struct GradeTitleView: View {
    @ObservedObject var settingsPublished = SettingsPublished.shared
    let user = Settings.shared.getCurrentUser()

    var body: some View {
        VStack {
            Text("Name and Grade").font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            HStack {
                if user.name.count > 0 {
                    Text(user.getTitle()).font(.title2)
                }
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading)
    }
}

struct UserDetailsView: View {
    @ObservedObject var publishedSettings = SettingsPublished.shared
    let user:User
    @Binding var listUpdated:Bool
    
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var firstName = Settings.shared.getCurrentUser().name
    @State var emailAddress = Settings.shared.getCurrentUser().email
    
    @State private var tapBufferSize = 4096
    @State private var navigateToSelectBoard = false
    @State private var navigateToSelectGrade = false
    @State private var selectedGrade:Int?
    @State private var userName = ""
    let width = UIScreen.main.bounds.width * 0.7
    
    var body: some View {
        VStack {
            //GradeTitleView().commonFrameStyle()

            VStack {
                Spacer()
                VStack() {
                    let x = String(user.id.uuidString.suffix(4))
                    Text(x)
                    Text("Please enter your first name").padding()
                    TextField("First name", text: $firstName)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: UIScreen.main.bounds.width * 0.5)
                
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
                SelectBoardGradesView(userForGrade:user, inBoard: MusicBoard(name: "Trinity"))
                Spacer()
            }
            .commonFrameStyle()
        }
        .onAppear() {
            self.firstName = user.name
            self.emailAddress = user.email
            listUpdated = false
        }
        .onDisappear() {
            ///Called on downward navigation from this view as well as view exit
            if let user = settings.getUser(id: user.id) {
                user.name = self.firstName
                user.email = self.emailAddress
                settings.setCurrentUser(id: user.id)
                settings.save()
                listUpdated = true
            }
        }
    }
}

// --------------------------- List of all Users ------------------------------

struct UsersTitleView: View {
    var body: some View {
        VStack {
            Text("Scales Academy Users").font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading)
    }
}

struct UserListView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var listUpdated = false
    @State private var selectedUser: User?
    @State private var userToDelete: User?
    @State private var showDeleteAlert:Bool = false
    
    func getUsersList(listUpdated:Bool) -> [String] {
        var list:[String] = []
        for user in settings.users {
            list.append(user.id.uuidString)
        }
        return list
    }

    var body: some View {
        VStack {
            UsersTitleView()
            Spacer()
            VStack {
                NavigationStack {
                    Text("Users").font(.title2).padding()
                    List(getUsersList(listUpdated: listUpdated), id: \.self) { userId in
                        if let id = UUID(uuidString: userId), let user = settings.getUser(id: id) {
                            HStack {
                                Text("\(user.name)")
                                    .font(UIDevice.current.userInterfaceIdiom != .phone ? .title2 : .callout)
                                    .lineLimit(1) // Prevent text from wrapping
                                    .truncationMode(.tail) // Add "..." if text is too long
                                    .frame(width: UIScreen.main.bounds.width * 0.20, alignment: .leading) // Fixed width for username
                                    .foregroundColor(user.isCurrentUser ? /*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/ : .black)
                                
                                Spacer()
                                if let grade = user.grade {
                                    Text("Grade-\(String(grade))").font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                }
                                else {
                                    Text("Grade-0").opacity(0.0).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                }
                                
                                Spacer()
                                Button(action: {
                                    settings.setCurrentUser(id: id)
                                    settings.save()
                                    tabSelectionManager.isSpinWheelActive = false
                                    tabSelectionManager.isPracticeChartActive = false
                                    Settings.shared.save()

                                    listUpdated.toggle()
                                }) {
                                    HStack {
                                        if UIDevice.current.userInterfaceIdiom != .phone {
                                            Image(systemName: "checkmark.circle").opacity(user.isCurrentUser ? 1.0 : 0.0).bold()
                                            //.resizable()
                                                .foregroundColor(.green)
                                        }
                                        Text("Make Current User").foregroundColor(.blue).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())

                                Spacer()
                                Button(action: {
                                    selectedUser = user
                                }) {
                                    HStack {
                                        if UIDevice.current.userInterfaceIdiom != .phone {
                                            Image(systemName: "graduationcap.fill")
                                            //.resizable()
                                                .foregroundColor(.green)
                                        }
                                        Text("Set Grade").foregroundColor(.blue).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Spacer()
                                Button(action: {
                                    showDeleteAlert = true
                                    userToDelete = user
                                }) {      
                                    HStack {
                                        if UIDevice.current.userInterfaceIdiom != .phone {
                                            Image(systemName: "trash")
                                            //.resizable()
                                                .foregroundColor(.red)
                                        }
                                        Text("Remove").foregroundColor(.blue).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle()) // AI says needed - otherwise any click on the the line anywhere triggers delete 🥵
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .navigationDestination(item: $selectedUser) { user in
                        UserDetailsView(user: user, listUpdated: $listUpdated)
                    }
                    Button(action: {
                        let user = User(board: "Trinity")
                        user.name = ""
                        settings.addUser(user: user)
                        selectedUser = user
                        listUpdated.toggle()
                    }) {
                        Text("Add New User")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.75)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 2)
                )
                .padding()
            }
            Spacer()
        }
        .commonFrameStyle()
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Confirm Remove User?"),
                message: Text("Are you sure you want remove \(userToDelete!.name)"),
                primaryButton: .destructive(Text("Remove")) {
                    settings.deleteUser(by: userToDelete!.id)
                    settings.save()
                    listUpdated.toggle()
                },
                secondaryButton: .cancel()
            )
        }

        .onDisappear() {
            //Settings.shared.save()
        }
        .onAppear() {
            if settings.users.count == 0 {
                let user = User(board: "Trinity")
                user.name = ""
                settings.addUser(user: user)
                selectedUser = user
                listUpdated.toggle()
            }
        }

    }
}

