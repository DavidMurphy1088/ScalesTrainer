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

    init(name:String, view:AnyView) {
        self.name = name
        self.view = view
    }
}

struct SelectScaleGroupView: View {
    @State var isOn:[Bool] = [false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true]
    @State var index = 0
    let width = 0.7
    
    var body: some View {
        ZStack {
            Image(UIGlobals.shared.getBackground())
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                VStack {
                    Text("Select Exam Scales").font(.title)//.foregroundColor(.blue)
                }
                .commonTitleStyle()
                .padding()
                Spacer()
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
                .commonFrameStyle(backgroundColor: .white)
                .padding()
            }
            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
        }
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
        //.navigationBarTitle("Famous Quotes")
    }
}



struct ActivityModeView: View {
    @State var menuOptions:[ActivityMode] = []
    @State var helpShowing = false
    
    func getView(activityMode: ActivityMode) -> some View {
        return activityMode.view
    }
    
    var body: some View {
        VStack {
            List(menuOptions) { activityMode in
                HStack {
                    NavigationLink(destination: getView(activityMode: activityMode)) {
                        HStack {
                            VStack {
                                ///The usual amount of padding in SwiftUI is 16 points, so half of that would be 8 points.
                                Text(activityMode.name).background(Color.clear).padding(.vertical, 8)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle()) // Ensure the link only covers the text and spacer
                    }
                    Spacer()
                    Text("    ")
                    Button(action: {
                        self.helpShowing = true
                        ScalesModel.shared.helpTopic = activityMode.name

                    }) {
                        VStack {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure button styling doesn't affect layout
                }
            }
            //.navigationBarTitle("\(selectedSyllabus.name) Activities", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            Spacer()
        }
        .sheet(isPresented: $helpShowing) {
            if let topic = ScalesModel.shared.helpTopic {
                HelpView(topic: topic)
           }
        }
    
        .onAppear() {
            if menuOptions.count == 0 {
                menuOptions.append(ActivityMode(name: "Select Exam Scales", view: AnyView(SelectScaleGroupView())))
                if let practiceJournal = PracticeJournal.shared {
                    let name = "Practice Journal" // for " + practiceJournal.title
                    menuOptions.append(ActivityMode(name: name, view: AnyView(PracticeJournalView(practiceJournal: practiceJournal))))
                    menuOptions.append(ActivityMode(name: "Your Coin Bank", view: AnyView(CoinBankView(practiceJournal: practiceJournal, scalingSize: 100))))
                    menuOptions.append(ActivityMode(name: "Spin The Scale Wheel", view: AnyView(SpinWheelView(practiceJournal: practiceJournal, mode: .pickRandomScale))))
                    //menuOptions.append(ActivityMode(name: "Identify The Scale", view: AnyView(SpinWheelView(practiceJournal: practiceJournal, mode: .identifyTheScale))))
                }
                menuOptions.append(ActivityMode(name: "Pick Any Scale", view: AnyView(PickAnyScaleView())))
                
                //            menuOptions.append(ActivityMode(name: "Practice Scales", view: AnyView(ScalesView(practiceJournalScale: PracticeJournal.shared)), showStaff: true, showFingers: true))
                
                //ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
                //        ActivityMode(name: "Hear and Identify A Scale", implemented: true, imageName: "", showStaff: false, showFingers: false),
                //ActivityMode(name: "Scales Exam", view: AnyView(UnderConstructionView()), imageName: "", showStaff: false, showFingers: false),
                
                menuOptions.append(ActivityMode(name: "Scales Technique Instruction Videos", view: AnyView(UnderConstructionView())))
                
                menuOptions.append(ActivityMode(name: "Scales Theory and Quizzes", view: AnyView(UnderConstructionView())))
                menuOptions.append(ActivityMode(name: "Why Practice Scales", view: AnyView(FamousQuotesView())))
                menuOptions.append(ActivityMode(name: "Practice Hanon Exercises", view: AnyView(UnderConstructionView())))
            }
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    let width = 0.7
    
    func getTitle() -> String {
        let name = Settings.shared.firstName
        var title = "Scales Trainer"
        if name.count > 0 {
            title = name+"'s " + title
        }
        return title
    }
    
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
                        VStack {
                            Text(getTitle()).font(.title)//.padding()
                        }
                        .commonTitleStyle()
                        .frame(width: UIScreen.main.bounds.width * width)
                        .padding()

                        ActivityModeView()
                            .commonFrameStyle(backgroundColor: .white)
                            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.6)

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
            PracticeJournal.shared = PracticeJournal(scaleGroup: ScaleGroup.options[2])
        }
    }
}


