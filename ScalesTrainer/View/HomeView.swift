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
    @State var isOn:[Bool] = [false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true]
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

struct RandomView: View {
    let practiceJournal: PracticeJournal
    
    init(practiceJournal: PracticeJournal) {
        self.practiceJournal = practiceJournal
        practiceJournal.makeRandomScale()
    }
    
    var body: some View {
        ZStack {
            Image(UIGlobals.shared.screenImageBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            if let scale = practiceJournal.randomScale {
                VStack {
                    Text(practiceJournal.scaleGroup.name).font(.title).padding().padding()
                    NavigationLink(destination: ScalesView(practiceJournalScale: scale)) {
                        HStack {
                            Text(scale.getName()).padding()
                        }
                    }
                }
                .commonFrameStyle(backgroundColor: .white)
                .frame(width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.3)
                .onAppear() {
                    practiceJournal.makeRandomScale()
                }

            }
        }
    }
}

struct AnyScaleView: View {
    @State var typeIndexMajor:Int = 0
    @State var rootIndexMajor:Int = 0
    @State var typesMajor:[String] = []
    @State var rootsMajor:[String] = ["A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭"]

    @State var typeIndexMinor:Int = 0
    @State var rootIndexMinor:Int = 0
    @State var typesMinor:[String] = []
    @State var rootsMinor:[String] = ["A", "B♭", "B", "C", "C#", "D", "E♭", "E", "F", "F#", "G", "G#"]

    init() {
    }
    
    func getScale(major:Bool) -> PracticeJournalScale {
        let scale:PracticeJournalScale
        let scaleType:ScaleType
        if major {
            switch typeIndexMajor {
            case 0:
                scaleType = .major
            case 1:
                scaleType = .arpeggioMajor
            case 2:
                scaleType = .arpeggioDominantSeventh
            case 3:
                scaleType = .arpeggioMajorSeventh
            case 4:
                scaleType = .chromatic
            default:
                scaleType = .major
            }
            scale = PracticeJournalScale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMajor]), scaleType: scaleType)
        }
        else {
            switch typeIndexMinor {
            case 0:
                scaleType = .naturalMinor
            case 1:
                scaleType = .harmonicMinor
            case 2:
                scaleType = .melodicMinor
            case 3:
                scaleType = .arpeggioMinor
            case 4:
                scaleType = .arpeggioDiminished
            case 5:
                scaleType = .arpeggioMinorSeventh
            case 6:
                scaleType = .arpeggioDiminishedSeventh
            case 7:
                scaleType = .arpeggioHalfDiminished
                
            default:
                scaleType = .major
            }
            scale = PracticeJournalScale(scaleRoot: ScaleRoot(name: rootsMinor[rootIndexMinor]), scaleType: scaleType)
        }
        return scale
    }
    
    var body: some View {
        ZStack {
            Image(UIGlobals.shared.screenImageBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            
            VStack {
                //Spacer()
                Text("Pick A Scale").font(.title).padding()
                VStack {
                    Text("Major Scales").padding()
                     HStack {
                        Text("Scale Root:")//.padding()
                        Picker("Select Value", selection: $rootIndexMajor) {
                            ForEach(rootsMajor.indices, id: \.self) { index in
                                Text("\(rootsMajor[index])")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Scale Type:").padding()
                        Picker("Select Value", selection: $typeIndexMajor) {
                            ForEach(typesMajor.indices, id: \.self) { index in
                                Text("\(typesMajor[index])")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    let scale = getScale(major: true)
                    NavigationLink(destination: ScalesView(practiceJournalScale: scale)) {
                        HStack {
                            Text(" Practice Scale \(scale.getName()) ")
                        }
                        //.padding()
                        .hilighted(backgroundColor: .blue)
                    }
                }
                //.border(Color.gray)
                .commonFrameStyle()
                .padding()
                
                VStack {
                    Text("Minor Scales").padding()
                     HStack {
                        Text("Scale Root:")//.padding()
                        Picker("Select Value", selection: $rootIndexMinor) {
                            ForEach(rootsMinor.indices, id: \.self) { index in
                                Text("\(rootsMinor[index])")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("Scale Type:").padding()
                        Picker("Select Value", selection: $typeIndexMinor) {
                            ForEach(typesMinor.indices, id: \.self) { index in
                                Text("\(typesMinor[index])")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    let scale = getScale(major: false)
                    NavigationLink(destination: ScalesView(practiceJournalScale: scale)) {
                        HStack {
                            Text(" Practice Scale \(scale.getName()) ")
                        }
                        .hilighted(backgroundColor: .blue)
                    }
                }
                .commonFrameStyle()
                .padding()
            }
            .commonFrameStyle(backgroundColor: .white)
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.8)
            .onAppear() {
                if self.typesMinor.count == 0 {
                    for scale in ScaleType.allCases {
                        if scale.isMajor() {
                            self.typesMajor.append(scale.description)
                        }
                        else {
                            self.typesMinor.append(scale.description)
                        }
                    }
                }
            }
        }
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
            menuOptions.append(ActivityMode(name: "Select Exam Scales", view: AnyView(SelectScaleGroupView()), imageName: ""))
            if let practiceJournal = PracticeJournal.shared {
                let name = "Practice Journal" // for " + practiceJournal.title
                //let menuName = "Practice Journal " + (name.count > 0 ? "for \(name)" : "")
                menuOptions.append(ActivityMode(name: name, view: AnyView(PracticeJournalView(practiceJournal: practiceJournal)), imageName: ""))
                menuOptions.append(ActivityMode(name: "Randomly Selected Practice Journal Scale", view: AnyView(RandomView(practiceJournal: practiceJournal)), imageName: ""))
            }
            menuOptions.append(ActivityMode(name: "Pick Any Scale", view: AnyView(AnyScaleView()), imageName: ""))

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
                        Image(UIGlobals.shared.screenImageBackground)
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.top)
                            .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
                        VStack {
                            Spacer()
                            VStack {
                                Text(getTitle()).font(.title).padding()
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


