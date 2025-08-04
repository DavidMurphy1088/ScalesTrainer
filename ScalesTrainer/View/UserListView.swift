import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation

struct UserListView: View {
    let scalesModel = ScalesModel.shared
    let settings = Settings.shared
    @State private var users: [User] = []
    
    func getUsers() -> [User] {
        var users:[User] = []
        users.append(contentsOf: settings.users)
        users.append(User(board: ""))
        return users
    }

    // Dynamic centering based on content - This version centers when content is small, allows full scrolling when content is large
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(users) { user in
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text("")
                                Text(user.board)
                                    .font(.subheadline)
                                Text("Grade \(user.grade == 0 ? "" : String(user.grade))")
                                    .font(.subheadline)
                                Text("")
                                FigmaNavLink(destination: UserEditView(user: user), font: .title2) {
                                    Text(user.board == "" ? "Add User" : "Edit User")
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(minWidth: geometry.size.width - 40, // Minimum width ensures horizontal centering
                           minHeight: geometry.size.height) // Minimum height ensures vertical centering
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // ScrollView takes full available space
                .clipped() // Prevents content from extending beyond bounds
                .onAppear() {
                    users = getUsers()
                }
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
