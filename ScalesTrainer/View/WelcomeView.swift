import Foundation
import SwiftUI
import Combine
import SwiftUI

struct WelcomeView: View {
    @State private var isEditingUser = false
    @State var screenWidth = UIScreen.main.bounds.width
    //let systemPadding: CGFloat = 16
    //let heightRatio = UIDevice.current.userInterfaceIdiom == .pad ? 375.0/821.0 : 250.0/821
    //let heightRatio = UIDevice.current.userInterfaceIdiom == .pad ? 320.0/821.0 : 250.0/821
    var body: some View {
        NavigationStack {
            ZStack {
                //Text("").padding(6 * systemPadding)
                HStack {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("").padding()
                        Text("").padding()
                    }
                    
                    VStack(alignment: .leading) {
                        Text("")
                        Text("")
//                        Image("figma_logo_horizontal")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            //.frame(width: 280.0)
                        Text("").padding()
                        Text("").padding()
                        Text("Welcome to ")
                        Text("Scales Academy").font(.largeTitle)
                        Text("")
                        Text("We hope you enjoy your experience using Scales Academy.")
                        Text("To get started please enter your name, Music Board and Grade.")
                        Text("").padding()
                        FigmaNavLink(destination: UserEditView(addingFirstUser: true, user: User(board: "")), font: .title2) {
                            Text("Get Started")
                        }
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Image("welcome_background")
                        .resizable()
                        .scaledToFit() // keeps original aspect ratio
                        .padding(0)
                        //.border(.red)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("").padding()
                    }
                }
                //.border(.blue)
            }
            //.border(.green)
            //.frame(height: screenWidth * heightRatio) ///Based of J's FIGMA rectangle dimensions
            //.border(.red)
        }
        .navigationTitle("Welcome")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
    }
}

