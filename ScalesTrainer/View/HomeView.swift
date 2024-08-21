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
    let screenName:String
    
    func getTitle() -> String {
        let name = Settings.shared.firstName
        var title = "Scales Academy"
        if name.count > 0 {
            title = name+"'s " + title
        }
        return title
    }
    
    var body: some View {
        VStack {
            Text(getTitle()).font(.title)
            Text("Trinity, Grade 3").font(.title2)
            Text(screenName).font(.title2)
        }
        .commonFrameStyle()
        .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth)
        .padding()
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
                                    .frame(width: geo.size.width * 0.50) //, height: geo.size.height * 0.25)
                                    .border(Color.gray)
                                    .clipShape(Circle()) // Clips the image to a circular shape
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 4)) // Optional: Add a circular border
                                    .shadow(radius: 10) // Optional: Add a shadow for depth
                                    //.border(.blue)
                                Text(activityMode.name).font(.title2)
                            }
                            //.border(.red)
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                
                List(menuOptionsRight) { activityMode in
                    HStack {
                        NavigationLink(destination: getView(activityMode: activityMode)) {
                            HStack {
                                VStack {
                                    Text(activityMode.name).background(Color.clear).padding(.vertical, 8)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle()) // Ensure the link only covers the text and spacer
                        }
                        Spacer()

                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            Spacer()
        }
        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
           }
        }
    
        .onAppear() {
            if menuOptionsLeft.count == 0 {
                let practiceChart = PracticeChart(musicBoardGrade: Settings.shared.getMusicBoardAndGrade())
                menuOptionsLeft.append(ActivityMode(name: "Practice Chart",
                                                    view: AnyView(PracticeChartView(practiceChart: practiceChart)),
                                                    imageName: "practice_chart"))
                
                //menuOptions.append(ActivityMode(name: "Practice Journal", view: AnyView(PracticeJournalView(musicBoardGrade: ScalesModel.shared.musicBoardGrade))))
                //menuOptions.append(ActivityMode(name: "Your Coin Bank", view: AnyView(CoinBankView())))
                menuOptionsLeft.append(ActivityMode(name: "Spin The Scale Wheel", 
                                                    view: AnyView(SpinWheelView(boardGrade: Settings.shared.getMusicBoardAndGrade())),
                                                    imageName: "scales_wheel"))

                menuOptionsLeft.append(ActivityMode(name: "Pick Any Scale", 
                                                    view: AnyView(PickAnyScaleView()),
                                                    imageName: "pick_any_scale"))
                                
                //ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
                //        ActivityMode(name: "Hear and Identify A Scale", implemented: true, imageName: "", showStaff: false, showFingers: false),
                //ActivityMode(name: "Scales Exam", view: AnyView(UnderConstructionView()), imageName: "", showStaff: false, showFingers: false),
                menuOptionsRight.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView()), imageName: ""))
                menuOptionsRight.append(ActivityMode(name: "Understanding Scales", view: AnyView(UnderstandingScalesView()), imageName: ""))
//                menuOptions.append(ActivityMode(name: "Scales Technique Instruction Videos", view: AnyView(UnderConstructionView())))
//                menuOptions.append(ActivityMode(name: "Scales Theory and Quizzes", view: AnyView(UnderConstructionView())))
//                menuOptions.append(ActivityMode(name: "Practice Hanon Exercises", view: AnyView(UnderConstructionView())))
            }
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    //let width = 0.7
    
    var body: some View {
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
                            .commonFrameStyle(backgroundColor: .white)
                            .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.8)
                        Spacer()
                    }
               }
            }

            .navigationViewStyle(StackNavigationViewStyle())
        }
        //This causes all views navigated to to have the same dimensions
        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
        .padding(.horizontal, 0)
        .onAppear() {
           PracticeJournalOld.shared = PracticeJournalOld(scaleGroup: MusicBoard.options[5])
        }
    }
}


