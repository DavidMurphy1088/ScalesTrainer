import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation

struct UserListView: View {
    @ObservedObject var titledUser:UserPublished = ScalesModel.shared.userPublished
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State private var users: [User] = []
    @State private var currentUser: User = Settings.shared.getCurrentUser()
    //@State private var isChecked = false
    let screenWidth = UIScreen.main.bounds.width
    
    func getUsers() -> [User] {
        var users:[User] = []
        users.append(contentsOf: settings.users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        let addUser = User()
        addUser.boardAndGrade.grade = 0
        addUser.color = "gray"
        users.append(addUser)
        return users
    }
    
    func randomPrimaryColor() -> Color {
        let primaryColors: [Color] = [
            .red,.green,.blue,.orange,.purple,.pink,.yellow,.teal
        ]
        return primaryColors.randomElement()!
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(users) { user in
                        VStack(alignment: .leading) {
                            let boxSize = 0.1
                            RoundedRectangle(cornerRadius: 12)
                                .fill(User.color(from: user.color).opacity(0.5))
                                .frame(width: UIScreen.main.bounds.width * boxSize,
                                       height: UIScreen.main.bounds.width * boxSize)
                                .overlay(alignment: .topTrailing) {
                                    if user.boardAndGrade.grade > 0 {
                                        //let titledUser = ScalesModel.shared.userPublished
                                        Button {
                                            let checked = settings.getCurrentUser().id == user.id
                                            if checked {
                                                if settings.users.count > 0 {
                                                    settings.setCurrentUser(id: settings.users[0].id)
                                                    ScalesModel.shared.updateUserPublished(user: settings.users[0])
                                                }
                                            }
                                            else {
                                                settings.setCurrentUser(id: user.id)
                                                ScalesModel.shared.updateUserPublished(user: user)
                                            }
                                            
                                        } label: {
                                            let checked = titledUser.name == user.name
                                            Image(systemName: checked ? "checkmark.circle" : "circle")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .background(Color.gray)
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                                .overlay {
                                    Text(user.name).font(.headline)
                                }

                            Text("")
                            let grade = user.boardAndGrade.grade
                            Text(user.boardAndGrade.board.name).font(.headline).opacity(grade == 0 ? 0.0 : 0.5)
                            Text("Grade \(grade)").font(.subheadline).opacity(grade == 0 ? 0.0 : 0.5)
                            Text("")
                            let butLabel = user.boardAndGrade.grade == 0 ? "Add User" : "Edit User"
                            FigmaNavLink(destination: UserEditView(addingFirstUser:false, user: user), font: .title2) {Text(butLabel)}
                        }
                        .padding()
                        .frame(width: UIScreen.main.bounds.width * 0.2)
                    }
                    //.border(.green)
                }
            }
            //.border(.red)
            .onAppear() {
                users = getUsers()
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Users",
                onBack: {}
            )
        }
    }
}
