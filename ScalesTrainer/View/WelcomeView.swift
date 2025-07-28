import Foundation
import SwiftUI
import Combine
import SwiftUI

struct WelcomeView: View {
    @State private var isEditingUser = false
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Image("figma_logo_horizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 280.0)
                Text("")
                Text("")
                Text("Welcome to ")
                Text("Scales Academy").font(.largeTitle)
                Text("")
                Text("We hope you enjoy your experience using Scales Academy.")
                Text("To get started please enter your name, Music Board and Grade.")
                Text("")
                Text("")

                FigmaNavLink(destination: UserEditView(user: User(board: "")), font: .title2) {
                    Text("Get Started")
                }

                Text("")
            }
        }
        .navigationTitle("Welcome")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
    }
}

