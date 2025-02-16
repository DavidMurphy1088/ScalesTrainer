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
        .commonFrameStyle()
        .frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.3)
    }
}

struct ActivityModeView: View {
    @EnvironmentObject var tabSelectionManager: ViewManager
    @EnvironmentObject var orientationInfo: OrientationInfo
    let user:User
    let practiceChart:PracticeChart
    @State var menuOptionsLeft:[ActivityMode] = []
    //@State var menuOptionsRight:[ActivityMode] = []
    @State var helpShowing = false
    let shade = 8.0
    
    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        //NavigationStack {
            VStack {
                let overlay = Circle().stroke(Color.black, lineWidth: 2)
                
                Spacer()
                //if let practiceChart = musicBoardAndGrade.practiceChart {
                    // Invisible NavigationLink that activates when isNavigationActive becomes true.
                    NavigationLink(
                        destination: PracticeChartView(practiceChart: practiceChart),
                        isActive: $tabSelectionManager.isPracticeChartActive
                    ) {
                        EmptyView()
                    }
                    
                    Button(action: {
                        practiceChart.adjustForStartDay()
                        tabSelectionManager.isPracticeChartActive = true
                    }) {
                        VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                            if UIDevice.current.userInterfaceIdiom != .phone || orientationInfo.isPortrait {
                                ///Image wont scale reasonably when too little space
                                Image("home_practice_chart_1")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())  // Clips the image to a circular shape
                                    .frame(width: UIScreen.main.bounds.size.width * 0.35)
                                    .overlay(overlay)
                                //.border(.red)
                            }
                            Text("Practice Chart")
                                .font(.custom("Noteworthy-Bold", size: 32)).padding()
                        }
                        .padding()
                        
                    }
//                    .navigationDestination(isPresented: $tabSelectionManager.isPracticeChartActive) {
//                        PracticeChartView(practiceChart: practiceChart)
//                    }
                    
                    Spacer()
                    NavigationLink(
                        destination: SpinWheelView(practiceChart: practiceChart),
                        isActive: $tabSelectionManager.isSpinWheelActive
                    ) {
                        EmptyView()
                    }
                    Button(action: {
                        tabSelectionManager.isSpinWheelActive = true
                    }) {
                        VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                            if UIDevice.current.userInterfaceIdiom != .phone || orientationInfo.isPortrait {
                                Image("home_scales_wheel_1")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())
                                    .frame(width: UIScreen.main.bounds.size.width * 0.35)
                                    .overlay(overlay)
                                //.border(.red)
                            }
                            Text("Spin The Scale Wheel")
                                .font(.custom("Noteworthy-Bold", size: 32)).padding()
                        }
                        .padding()
                    }
//                    .navigationDestination(isPresented: $tabSelectionManager.isSpinWheelActive) {
//                        SpinWheelView(practiceChart: practiceChart)
//                    }
                //}
                Spacer()
            }
            .commonFrameStyle()
            .sheet(isPresented: $helpShowing) {
                if let topic = ScalesModel.shared.helpTopic {
                    HelpView(topic: topic)
                }
            }
        //}
        .onAppear() {
        }
    }
}

struct ActivitiesView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    //@State var user:User
    ///NB 🟢 Reference types (e.g. User) state **don't refresh** the view with onAppear, use userName
    ///Therefore use name and grade changes to force the view to refresh (and therefore load the correct chart)
    @State var userName:String = ""
    @State var userGrade:Int?

    func loadChart(user:User) -> PracticeChart? {
        var practiceChart:PracticeChart? = nil
        if let grade = user.grade {
            if let loadedChart = PracticeChart.loadPracticeChartFromFile(user: user, board: user.board, grade: grade) {
                practiceChart = loadedChart
            }
            else {
                practiceChart = PracticeChart(user: user, board: user.board, grade: grade)
            }
        }
        return practiceChart
    }
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Spacer()
                    ScreenTitleView(screenName: "Activities")
                    ///A view refresh (and chart load) **must** be triggered by either a change in name or grade
                    if let user = Settings.shared.getUser(name: self.userName), let grade = self.userGrade {
                        if let practiceChart = self.loadChart(user: user) {
                            ActivityModeView(user: user, practiceChart: practiceChart)
                        }
                    }
                    else {
                        Spacer()
//                        if userName.count > 0 {
//                            Text("No music grade has been selected for \(userName).").font(.title2).padding()
//                            Text("Please select your music grade.").font(.title2).padding()
//                        }
//                        else {
                            Text("No name or grade has been setup.").font(.title2).padding()
                            Text("Please setup your name and grade.").font(.title2).padding()
//                        }
                    }
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear() {
            ///Force the view to redraw by updating these @State variables
            if let user = Settings.shared.getCurrentUser() {
                self.userName = user.name
                self.userGrade = user.grade
            }
        }
    }
    
}
