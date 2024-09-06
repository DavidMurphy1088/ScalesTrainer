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
        .commonFrameStyle()
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
    @State var menuOptionsRight:[ActivityMode] = []
    @State var helpShowing = false
    
    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        VStack {
            HStack {
                GeometryReader { geo in
                    List(menuOptionsLeft) { activityMode in
                        NavigationLink(destination: getView(activityMode: activityMode)) {
                            HStack {
                                Image(activityMode.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.30) //, height: geo.size.height * 0.25)
                                    .border(Color.gray)
                                    .clipShape(Circle()) // Clips the image to a circular shape
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 4)) // Optional: Add a circular border
                                    .shadow(radius: 10) // Optional: Add a shadow for depth
                                Text(activityMode.name).font(.title2)
                            }
                            //.border(.red)
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
                GeometryReader { geo in
                    List(menuOptionsRight) { activityMode in
                        NavigationLink(destination: getView(activityMode: activityMode)) {
                            HStack {
                                Image(activityMode.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width * 0.30)
                                    .border(Color.gray)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 4))
                                    .shadow(radius: 10)
                                Text(activityMode.name).font(.title2)
                            }
                            //.contentShape(Rectangle()) // Ensure the link only covers the text and spacer
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            Spacer()
        }
        .commonFrameStyle(backgroundColor: .white)
        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
           }
        }
    
        .onAppear() {
            //if let boardAndGrade = Settings.shared.getMusicBoardAndGrade() {
                if menuOptionsLeft.count == 0 {
                    var practiceChart:PracticeChart
                    if let savedChart = PracticeChart.loadPracticeChartFromFile() {
                        practiceChart = savedChart
                        print("Loaded PracticeChart with \(savedChart.rows) rows and \(savedChart.columns) columns.")
                    }
                    else {
                        practiceChart = PracticeChart(musicBoard: Settings.shared.musicBoard, musicBoardGrade: Settings.shared.musicBoardGrade)
                    }
                    menuOptionsLeft.append(ActivityMode(name: "Practice Chart",
                                                        view: AnyView(PracticeChartView(practiceChart: practiceChart)),
                                                        imageName: "practice_chart"))
                    
                    //menuOptions.append(ActivityMode(name: "Practice Journal", view: AnyView(PracticeJournalView(musicBoardGrade: ScalesModel.shared.musicBoardGrade))))
                    //menuOptions.append(ActivityMode(name: "Your Coin Bank", view: AnyView(CoinBankView())))
                    menuOptionsLeft.append(ActivityMode(name: "Spin The Scale Wheel",
                                                        view: AnyView(SpinWheelView(board: Settings.shared.musicBoard, boardGrade: Settings.shared.musicBoardGrade)),
                                                        imageName: "scales_wheel"))
                    
                    menuOptionsLeft.append(ActivityMode(name: "Pick Any Scale",
                                                        view: AnyView(PickAnyScaleView()),
                                                        imageName: "pick_any_scale"))
                    
                    //ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
                    //        ActivityMode(name: "Hear and Identify A Scale", implemented: true, imageName: "", showStaff: false, showFingers: false),
                    //ActivityMode(name: "Scales Exam", view: AnyView(UnderConstructionView()), imageName: "", showStaff: false, showFingers: false),
                    menuOptionsRight.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView()), imageName: "WhyLearnScales"))
                    menuOptionsRight.append(ActivityMode(name: "Understanding Scales", view: AnyView(UnderstandingScalesView()), imageName: "UnderstandingScales"))
                    //                menuOptions.append(ActivityMode(name: "Scales Technique Instruction Videos", view: AnyView(UnderConstructionView())))
                    //                menuOptions.append(ActivityMode(name: "Scales Theory and Quizzes", view: AnyView(UnderConstructionView())))
                    //                menuOptions.append(ActivityMode(name: "Practice Hanon Exercises", view: AnyView(UnderConstructionView())))
                }
            //}
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                NavigationView {
                    ZStack {
                        Image(UIGlobals.shared.getBackground())
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.top)
                            .opacity(UIGlobals.shared.screenImageBackgroundOpacity)

                        VStack {
                            Spacer()
                            TitleView(screenName: "")
                            ActivityModeView()
                            Spacer()
                        }
                        .frame(width: geometry.size.width * UIGlobals.shared.screenWidth, height: geometry.size.height)
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
}
