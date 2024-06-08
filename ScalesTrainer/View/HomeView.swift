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
    let imageName:String
    //let showStaff:Bool
    //let showFingers:Bool
    let view:AnyView
    
    init(name:String, view:AnyView, imageName:String) {
        self.name = name
        self.imageName = imageName
        //self.showStaff = showStaff
        //self.showFingers = showFingers
        self.view = view
    }
}

struct SelectScaleGroupView: View {
    @State var isOn:[Bool] = [false, false, true, false, false, false, false, false, false, false, false, false, false, true]
    @State var index = 0

    var body: some View {
        ZStack {
            Image(UIGlobals.shared.screenImageBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                List {
                    ForEach(Array(ScaleGroup.options.enumerated()), id: \.element.id) { index, scaleGroup in
                        HStack {
                            Text(scaleGroup.name).background(Color.clear)
                            Spacer()
                            HStack {
                                GeometryReader { geometry in
                                    Image(scaleGroup.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: geometry.size.height)
                                }
                            }
                            .padding()
                            Spacer()
                            Toggle(isOn: $isOn[index]) {
                                
                            }
                        }
                    }
                }
                .padding()
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.8)
        }
        .navigationBarTitle("Scale Sets")
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
        ZStack {
            Image(UIGlobals.shared.screenImageBackground)
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
        //.navigationBarTitle("Famous Quotes")
    }
}

struct ActivityModeView: View {
    @State var menuOptions:[ActivityMode] = []

    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        VStack {
            List(menuOptions) { activityMode in
                NavigationLink(destination: getView(activityMode: activityMode)) {
                    HStack {
                        Text(activityMode.name).background(Color.clear)
                        Spacer()
                        HStack {
                            GeometryReader { geometry in
                                Image(activityMode.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: geometry.size.height)
                            }
                        }
                        .padding()
                    }
                }
            }
            //.navigationBarTitle("\(selectedSyllabus.name) Activities", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            Spacer()
        }
        .onAppear() {
            menuOptions.append(ActivityMode(name: "Select Scales", view: AnyView(SelectScaleGroupView()), imageName: ""))
            if let practiceJournal = PracticeJournal.shared {
                menuOptions.append(ActivityMode(name: "Practice Journal", view: AnyView(PracticeJournalView(practiceJournal: practiceJournal)), imageName: ""))
                menuOptions.append(ActivityMode(name: "Practice a Random Journal Scale", view: AnyView(ScalesView(practiceJournalScale: practiceJournal.getRandomScale())), imageName: ""))
            }
//            menuOptions.append(ActivityMode(name: "Practice Scales", view: AnyView(ScalesView(practiceJournalScale: PracticeJournal.shared)), imageName: "", showStaff: true, showFingers: true))

            //ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
    //        ActivityMode(name: "Hear and Identify A Scale", implemented: true, imageName: "", showStaff: false, showFingers: false),
            //ActivityMode(name: "Scales Exam", view: AnyView(UnderConstructionView()), imageName: "", showStaff: false, showFingers: false),
            
            menuOptions.append(ActivityMode(name: "Scales Technique Instruction Videos", view: AnyView(UnderConstructionView()), imageName: ""))
            
            menuOptions.append(ActivityMode(name: "Scales Theory and Quizzes", view: AnyView(UnderConstructionView()), imageName: ""))
            menuOptions.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView()), imageName: ""))
            menuOptions.append(ActivityMode(name: "Practice Hanon Exercises", view: AnyView(UnderConstructionView()), imageName: ""))

        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    
    var body: some View {
            VStack {
                NavigationView {
                    ZStack {
                        Image(UIGlobals.shared.screenImageBackground)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.top)
                            .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
                        VStack {
                            Spacer()
                            VStack {
                                Text("Scales Trainer").font(.title).padding()
                            }
                            .commonFrameStyle(backgroundColor: .white)
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                            .padding()

                            ActivityModeView()
                                //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
                                .commonFrameStyle(backgroundColor: .white)
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.5)

                            Spacer()
                        }
                   }
                }


            //.frame(width: UIScreen.main.bounds.width * 0.80)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        //This causes all views navigated to to have the same dimensions
        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
        .padding(.horizontal, 0)
        .onAppear() {
            PracticeJournal.shared = PracticeJournal(scaleGroup: ScaleGroup.options[2])
        }
    }
}


