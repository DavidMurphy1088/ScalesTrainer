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

struct TitleView: View {
    @ObservedObject var settingsPublished = SettingsPublished.shared
    let screenName: String
    let showGrade:Bool
    
    func getTitle() -> String {
        var name = self.settingsPublished.name
        if self.settingsPublished.name.count > 0 {
            name += "'s "
        }
        name += screenName
        return name
    }

    var body: some View {
        VStack {
            Text(getTitle()).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            if showGrade {
                HStack {
                    //if let boardAndGrade = settingsPublished.boardAndGrade {
                        Text("FIX").font(.title2)
                        //Text("\(boardAndGrade.getFullName())").font(.title2)
                    //}
                }
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
        .onAppear() {

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
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    @EnvironmentObject var orientationInfo: OrientationInfo
    let musicBoardAndGrade:MusicBoardAndGrade
    @State var menuOptionsLeft:[ActivityMode] = []
    //@State var menuOptionsRight:[ActivityMode] = []
    @State var helpShowing = false
    //@State private var isNavigationActive = false
    let shade = 8.0
    
    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        //NavigationStack {
            VStack {
                let overlay = Circle().stroke(Color.black, lineWidth: 2)
                
                Spacer()
                if let practiceChart = musicBoardAndGrade.practiceChart {
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
                }
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

struct HomeView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    @State var scaleGroupsSheet = false
    
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Spacer()
                    TitleView(screenName: "Scales Academy", showGrade: true)
                    if let musicBoardAndGrade = MusicBoardAndGrade.shared {
                        ActivityModeView(musicBoardAndGrade: musicBoardAndGrade)
                            .environmentObject(orientationInfo)
                    }
                    else {
                        Text("No music grade").padding()
                        Text("Please select your music grade").padding()
                    }
                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}
