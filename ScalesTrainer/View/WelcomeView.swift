import Foundation
import SwiftUI
import Combine
import SwiftUI

struct WelcomeView: View {
    @State private var isEditingUser = false
    @State var screenWidth = UIScreen.main.bounds.width
    @State var screenHeight = UIScreen.main.bounds.height

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
                        HStack {
                            Image("figma_icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: UIFont.preferredFont(
                                    forTextStyle: .title1).pointSize)
                            Text("scales academy").font(.title)
                            Spacer()
                        }
                        Text("").padding()
                        Text("").padding()
                        Text("Welcome to ")
                        Text("Scales Academy")
                            .font(.custom("AvenirNext-DemiBold", size: 33.0))
                        Text("")
                        Text("We hope you enjoy your experience using Scales Academy.")
                        Text("To get started please enter your name, Music Board and Grade.")
                        Text("").padding()
                        
                        let defaultBoard = MusicBoard.getSupportedBoards()[0]
                        FigmaNavLink(destination: UserEditView(
                            addingFirstUser: true,
                            user: User(boardAndGrade: MusicBoardAndGrade(board: defaultBoard, grade: 0))),
                                    font: .title2) {
                            Text("Get Started")//.bold()
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
            }
        }
        .navigationTitle("Welcome")
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
    }
}

