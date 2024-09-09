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

import SwiftUI

struct TitleView: View {
    @ObservedObject var settingsPublished = SettingsPublished.shared
    let screenName: String?
    
    func getTitle() -> String {
        let name = self.settingsPublished.firstName
        var title = "Scales Academy"
        if name.count > 0 {
            title = name + "'s " + title
        }
        return title
    }

    var body: some View {
        VStack {
            Text(getTitle()).font(.title)
            if Settings.shared.musicBoard.name.count > 0 {
                Text("\(settingsPublished.board), Grade \(settingsPublished.grade)").font(.title2)
            }
            if let screenName = screenName {
                Text(screenName).font(.title2)
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

struct UnderstandingScalesView: View {
    var body: some View {
        ZStack {
        }
    }
}

struct FamousQuotesView: View {
    var body: some View {
        ZStack {
            Image(UIGlobals.shared.getBackground())
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
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
            .commonFrameStyle(backgroundColor: .white)
            .frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.3)
        }
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
            //List(menuOptionsLeft) { activityMode in
            if menuOptionsLeft.count > 0 {
                //Spacer()
                let activityMode = menuOptionsLeft[0]
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                        Image(menuOptionsLeft[0].imageName)
                            .resizable()
                            .scaledToFit()
                            //.frame(width: geo.size.width * 0.50, height: geo.size.height * 0.25)
                            .clipShape(Circle())  // Clips the image to a circular shape
                            .frame(width: UIScreen.main.bounds.size.width * 0.2)
                            .overlay(overlay)
                            //.border(.red)
                            
                        Text(activityMode.name)
                            .font(.title2)
                    }
                    .listRowInsets(EdgeInsets())  // Remove any default padding in the List row
                    //.padding(.vertical, 0)
                    .padding()
                }
            }
            if menuOptionsLeft.count > 1 {
                let activityMode = menuOptionsLeft[1]
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                        Image(activityMode.imageName)
                            .resizable()
                            .scaledToFit()
                            //.frame(width: geo.size.width * 0.50, height: geo.size.height * 0.25)
                            .clipShape(Circle())
                            .frame(width: UIScreen.main.bounds.size.width * 0.2)
                            .overlay(overlay)
                            //.border(.red)
                        Text(activityMode.name)
                            .font(.title2)
                    }
                    .listRowInsets(EdgeInsets())  // Remove any default padding in the List row
                    //.padding(.vertical, 0)
                    .padding()
                }
            }
            if menuOptionsLeft.count > 2 {
                let activityMode = menuOptionsLeft[2]
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    VStack(spacing: 0) {  // Ensure no space between the elements inside VStack
                        Image(activityMode.imageName)
                            .resizable()
                            .scaledToFit()
                            //.frame(width: geo.size.width * 0.50, height: geo.size.height * 0.25)
                            
                            .clipShape(Circle())  // Clips the image to a circular shape
                            .frame(width: UIScreen.main.bounds.size.width * 0.2)
                            .overlay(overlay)
                            //.border(.red)
                        Text(activityMode.name)
                            .font(.title2)
                    }
                    .listRowInsets(EdgeInsets())  // Remove any default padding in the List row
                    //.padding(.vertical, 0)
                    .padding()
                }
            }
            Spacer()
        }
        //.background()
        .commonFrameStyle(backgroundColor:UIGlobals.shared.purple)
        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
           }
        }
    
        .onAppear() {
            if menuOptionsLeft.count == 0 {
                var practiceChart:PracticeChart
                if let savedChart = PracticeChart.loadPracticeChartFromFile() {
                    PracticeChart.shared = savedChart
                    print("Loaded PracticeChart with \(savedChart.rows) rows and \(savedChart.columns) columns.")
                }
                else {
                    PracticeChart.shared = PracticeChart(musicBoard: Settings.shared.musicBoard, musicBoardGrade: Settings.shared.musicBoardGrade)
                }
                practiceChart = PracticeChart.shared
                menuOptionsLeft.append(ActivityMode(name: "Practice Chart",
                                                    view: AnyView(PracticeChartView(practiceChart: practiceChart)),
                                                    imageName: "home_practice_chart_1"))
                
                menuOptionsLeft.append(ActivityMode(name: "Spin The Scale Wheel",
                                                    view: AnyView(SpinWheelView(board: Settings.shared.musicBoard, boardGrade: Settings.shared.musicBoardGrade)),
                                                    imageName: "home_scales_wheel_1"))
                
                if Settings.shared.developerModeOn {
                    menuOptionsLeft.append(ActivityMode(name: "Pick Any Scale",
                                                        view: AnyView(PickAnyScaleView()),
                                                        imageName: "home_pick_any_scale_1"))
                }
                
                //menuOptionsRight.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView()), imageName: "home_why_learn_scales_1"))
                menuOptionsLeft.append(ActivityMode(name: "Understanding Scales", view: AnyView(UnderstandingScalesView()), imageName: "home_understanding_scales_1"))
            }
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                NavigationView {
//                    ZStack {
//                        Image(UIGlobals.shared.getBackground())
//                            .resizable()
//                            .scaledToFill()
//                            .edgesIgnoringSafeArea(.top)
//                            .opacity(UIGlobals.shared.screenImageBackgroundOpacity)

                        VStack {
                            Spacer()
                            TitleView(screenName: "").commonFrameStyle()
                            ActivityModeView()
                            Spacer()
                        }
                        //.frame(width: geometry.size.width * UIGlobals.shared.screenWidth, height: geometry.size.height)
                    }
                //}
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
}
