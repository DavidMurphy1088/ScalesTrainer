import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation

struct UserListView: View {
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State private var users: [User] = []
    @State private var currentUser: User = Settings.shared.getCurrentUser()
    
    func getUsers() -> [User] {
        var users:[User] = []
        users.append(contentsOf: settings.users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        users.append(User(board: ""))
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
                            ZStack {
                                let boxSize = 0.1
                                if user.grade == 0 {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: UIScreen.main.bounds.width * boxSize,
                                               height: UIScreen.main.bounds.width * boxSize)
                                    Text("+").font(.headline)
                                }
                                else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(User.color(from: user.color).opacity(0.5))
                                        .frame(width: UIScreen.main.bounds.width * boxSize,
                                               height: UIScreen.main.bounds.width * boxSize)
                                    Text(user.name)
                                        .font(.headline)
                                }
                            }
                            Text("")
                            Text(user.board).font(.headline).opacity(user.grade == 0 ? 0.0 : 0.5)
                            Text("Grade \(user.grade)").font(.subheadline).opacity(user.grade == 0 ? 0.0 : 0.5)
                            Text("")
                            let butLabel = user.board == "" ? "Add User" : "Edit User"
                            FigmaNavLink(destination: UserEditView(addingFirstUser:false, user: user), font: .title2) {Text(butLabel)}
                        }
                        .padding()
                        .frame(width: UIScreen.main.bounds.width * 0.2)
                    }
                }
                //.border(.green)
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
