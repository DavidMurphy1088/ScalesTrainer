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
        var name = self.settingsPublished.firstName
        if self.settingsPublished.firstName.count > 0 {
            name += "'s "
        }
        name += screenName
        return name
    }

    var body: some View {
        let grade = "Trinity, Grade 1"
        VStack {
            Text(getTitle()).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            if showGrade {
                Text("\(grade)").font(.title2)
            }
            //}
//            if let screenName = screenName {
//                Text(screenName).font(.title2)
//            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark) 
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
    @State var menuOptionsLeft:[ActivityMode] = []
    //@State var menuOptionsRight:[ActivityMode] = []
    @State var helpShowing = false
    let shade = 8.0
    
    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        VStack {
            let overlay = Circle().stroke(Color.black, lineWidth: 2)
            
            Spacer()
            if menuOptionsLeft.count > 0 {
                let activityMode = menuOptionsLeft[0]
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                        Image(menuOptionsLeft[0].imageName)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())  // Clips the image to a circular shape
                            .frame(width: UIScreen.main.bounds.size.width * 0.35)
                            .overlay(overlay)
                            //.border(.red)
                            
                        Text(activityMode.name)
                            .font(.custom("Noteworthy-Bold", size: 32)).padding()
                    }
                    .padding()
                }
            }
            
            Spacer()
            if menuOptionsLeft.count > 1 {
                let activityMode = menuOptionsLeft[1]
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                        Image(activityMode.imageName)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: UIScreen.main.bounds.size.width * 0.35)
                            .overlay(overlay)
                            //.border(.red)
                        Text(activityMode.name)
                            .font(.custom("Noteworthy-Bold", size: 32)).padding()
                    }
                    .padding()
                }
            }
            if Settings.shared.useMidiKeyboard {
                let midis = MIDIManager.shared.getMidiConections()
                Text("Connected to MIDI keyboards: \(midis)")
            }

            Spacer()
        }
        //.background()
        .commonFrameStyle()
        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
           }
        }
    
        .onAppear() {
            if menuOptionsLeft.count == 0 {
                var practiceChart:PracticeChart
//                if Settings.shared.isDeveloperMode() {
//                    PracticeChart.shared = PracticeChart(musicBoard: Settings.shared.musicBoard, musicBoardGrade: Settings.shared.musicBoardGrade, minorScaleType: 0)
//                    PracticeChart.shared.adjustForStartDay()
//                }
//                else {
                    if let savedChart = PracticeChart.loadPracticeChartFromFile()  {
                        PracticeChart.shared = savedChart
                        PracticeChart.shared.adjustForStartDay()
                    }
                    else {
                        PracticeChart.shared = PracticeChart(musicBoard: Settings.shared.musicBoard, musicBoardGrade: Settings.shared.musicBoardGrade, minorScaleType: 0)
                    }
//                }
                practiceChart = PracticeChart.shared
                menuOptionsLeft.append(ActivityMode(name: "Practice Chart",
                                                    view: AnyView(PracticeChartView(practiceChart: practiceChart)),
                                                    imageName: "home_practice_chart_1"))
                
                menuOptionsLeft.append(ActivityMode(name: "Spin The Scale Wheel",
                                                    view: AnyView(SpinWheelView()),
                                                    imageName: "home_scales_wheel_1"))
                
                //if Settings.shared.developerModeOn {
//                menuOptionsLeft.append(ActivityMode(name: "Scales Library",
//                                                        view: AnyView(ScalesLibraryView()),
//                                                        imageName: "home_pick_any_scale_1"))
                //}
                
                //menuOptionsRight.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView()), imageName: "home_why_learn_scales_1"))
                //menuOptionsLeft.append(ActivityMode(name: "Understanding Scales", view: AnyView(UnderstandingScalesView()), imageName: "home_understanding_scales_1"))
            }
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    //let midiManager = MIDIManager.shared
    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    Spacer()
                    TitleView(screenName: "Scales Academy", showGrade: true)
                    ActivityModeView()
                    Spacer()
                }
            }
        }

        .navigationViewStyle(StackNavigationViewStyle())
    }
    
}
