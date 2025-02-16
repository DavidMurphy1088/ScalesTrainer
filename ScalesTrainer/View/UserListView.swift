import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

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
                                        //if UIDevice.current.userInterfaceIdiom != .phone {
                                        if user.isCurrentUser {
                                            Image(systemName: "checkmark.circle").opacity(user.isCurrentUser ? 1.0 : 0.0).bold()
                                                //.resizable()
                                                .foregroundColor(.green)
                                        }
                                        else {
                                            Text("Make Current User").foregroundColor(.blue).font(UIDevice.current.userInterfaceIdiom != .phone ? .body : .caption)
                                        }
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
                        settings.setCurrentUser(id: user.id)
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
            ///Create a user if we dont have one already
            if settings.users.count == 0 {
                let user = User(board: "Trinity")
                user.name = ""
                settings.addUser(user: user)
                settings.setCurrentUser(id: user.id)
                selectedUser = user
                listUpdated.toggle()
            }
        }
    }
}

