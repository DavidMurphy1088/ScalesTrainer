import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

// --------------------------- List of all Users ------------------------------

struct UserListView: View {
    @EnvironmentObject var tabSelectionManager: ViewManager
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State var listUpdated = false
    @State private var selectedUserForDetailing: User?
    @State private var userToDelete: User?
    @State private var showDeleteAlert:Bool = false
    
    func getUsersList(listUpdated:Bool) -> [String] {
        var list:[String] = []
        for user in settings.users {
            list.append(user.id.uuidString)
        }
        return list
    }
    
    func createAndAddUser() -> User {
        let boards = MusicBoard.getSupportedBoards()
        if boards.count > 0 {
            let user = User(board: boards[0].name)
            settings.addUser(user: user)
            settings.setCurrentUser(id: user.id)
            return user
            //listUpdated.toggle()
        }
        fatalError("No boards for default user")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenTitleView(screenName: "Scales Academy Users").padding(.vertical, 0)
                VStack {
                    //Text("User List").font(.title2).padding()
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
                                //if let grade = user.grade {
                                Text("\(user.board) Grade-\(String(user.grade))").font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                //}
                                //else {
                                    //Text("Grade-0").opacity(0.0).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                //}
                                
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
                                        ZStack {
                                            Image(systemName: "checkmark.circle").opacity(user.isCurrentUser ? 1.0 : 0.0).bold().foregroundColor(.green)
                                                .opacity(user.isCurrentUser ? 1.0 : 0.0)
                                            Text("Make Current User").foregroundColor(.blue).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                                .opacity(user.isCurrentUser ? 0.0 : 1.0)
                                        }
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())

                                Spacer()
                                Button(action: {
                                    //self.creatingNewUser = false
                                    selectedUserForDetailing = user
                                }) {
                                    HStack {
                                        if UIDevice.current.userInterfaceIdiom != .phone {
                                            Image(systemName: "graduationcap.fill").foregroundColor(.green)
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
                    
                    Button(action: {
                        let user = createAndAddUser()
                        selectedUserForDetailing = user
                    }) {
                        Text("Add New User")
                    }
                    .appButtonStyle(trim: false)
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.70)
                .outlinedStyleView()
//                .navigationDestination(item: $selectedUserForDetailing) { user in
//                    UserDetailsView(user: user, listUpdated: $listUpdated)
//                }
                Spacer()
            }
            .padding()
            .screenBackgroundStyle()
        }
        
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

        .onAppear() {
            ///Create a user if we dont have one already and go straight to editing that user
            if settings.users.count == 0 {
                let user = createAndAddUser() 
                selectedUserForDetailing = user
            }
        }
    }
}
