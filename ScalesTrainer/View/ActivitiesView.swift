import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    let label:String
    
    var body: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back \(label)")
            }
        }
    }
}

class ActivityMode : Identifiable {
    let name:String
    let view:AnyView
    let imageName:String
    
    init(name:String, view:AnyView, imageName:String) {
        self.name = name
        self.view = view
        self.imageName = imageName
    }
}

struct UnderConstructionView: View {
    var body: some View {
        VStack {
            Text("Under Construction")
        }
    }
}

struct FamousQuotesView: View {
    var body: some View {
        VStack {
            let quotes = FamousQuotes.shared
            let quote = quotes.getQuote()
            VStack {
                Text("Famous Quotes").font(.title).padding()
                VStack {
                    Text(quote.0).italic().padding()
                    Text(quote.1).padding()
                }
                .padding()
                Spacer()
            }
        }
        //.commonFrameStyle()
        .frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.3)
    }
}

struct ActivityEntriesView: View {
    @EnvironmentObject var tabSelectionManager: ViewManager
    let user: User
    let practiceChart: PracticeChart
    @State var helpShowing = false
    let overlay = Circle().stroke(Color.white.opacity(0.8), lineWidth: 3) // Soft stroke effect
    
    var body: some View {
        HStack(spacing:0) {
            Spacer()
            VStack {
                navigationButton(imageName: "home_practice_chart_1",
                    text: "Practice Chart",
                    action: {
                        practiceChart.adjustForStartDay()
                        tabSelectionManager.isPracticeChartActive = true
                    },
                    isActive: $tabSelectionManager.isPracticeChartActive,
                    destination: PracticeChartViewOld(user: user, practiceChart: practiceChart))
            }
            .frame(width: UIScreen.main.bounds.width * 0.3)
            //.border(Color.red)
            
            Spacer()
            VStack {
                navigationButton(imageName: "home_scales_wheel_1",
                                 text: "Spin The Scale Wheel",
                    action: {
                        tabSelectionManager.isSpinWheelActive = true
                    },
                    isActive: $tabSelectionManager.isSpinWheelActive,
                    destination: SpinWheelView(user: user, practiceChart: practiceChart))
            }
            .frame(width: UIScreen.main.bounds.width * 0.3)
            Spacer()
        }
       // .frame(maxWidth: .infinity)
        //.screenBackgroundStyle()

        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
            }
        }
    }

    /// Custom Navigation Button for dynamic UI
    @ViewBuilder
    private func navigationButton<T: View>(imageName: String, text: String, action: @escaping () -> Void, isActive: Binding<Bool>, destination: T) -> some View {
        NavigationLink(destination: destination, isActive: isActive) {
            EmptyView()
        }

        Button(action: {
            action()
        }) {
            VStack(spacing: 10) {
                    Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .clipShape(Circle())
                    //.frame(width: UIScreen.main.bounds.size.width * 0.35)
                    .overlay(overlay)
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: -5, y: -5)
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 5, y: 5)
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 10)
                    .scaleEffect(isActive.wrappedValue ? 1.1 : 1.0) // Slight zoom effect
                    .padding()
                Text(text).fancyTextStyle()
            }
        }
    }
}

struct ActivitiesView: View {
    //@State var user:User
    ///NB 🟢 Reference types (e.g. User) state **don't refresh** the view with onAppear, use userName
    ///Therefore use name and grade changes to force the view to refresh (and therefore load the correct chart)
    @State var userName:String = ""
    @State var userGrade:Int?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    Text("")
                    Text("")
                    Text("How do you want to practise?").padding()
                    HStack {
                        FigmaNavLink(destination: PracticeChartView(), font: .title2) {
                            Text("Practice Chart")
                        }
                        FigmaNavLink(destination: PracticeChartView(), font: .title2) {
                            Text("Spin Wheel")
                        }
                    }
//                        if let user = Settings.shared.getUser(name: self.userName), let grade = self.userGrade {
//                            if let practiceChart = user.getPracticeChart() {
//                                ActivityEntriesView(user: user, practiceChart: practiceChart)
//                                //.background(Color.clear)
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                    .screenBackgroundStyle()
//                            }
//                        }
//                        else {
//                            VStack {
//                                Spacer()
//                                Text("No name or grade has been setup.").font(.title2).padding()
//                                Text("Please setup your name and grade.").font(.title2).padding()
//                            }
//                            .screenBackgroundStyle()
//                        }
                }
                Spacer()
                .navigationTitle("Activities") //Required to use to set as "back" name in child views
                .navigationBarTitleDisplayMode(.inline) //Required to use a custom toolbar .commonToolbar at the top of the nav stack
            }
            .commonToolbar(
                title: "Activities",
                onBack: {}
            )
        }
        .onAppear() {
            ///Force the view to redraw by updating these @State variables
            let user = Settings.shared.getCurrentUser()
            self.userName = user.name
            self.userGrade = user.grade
            
        }
    }
}
