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
    let implemented:Bool
    let imageName:String
    let showStaff:Bool
    let showFingers:Bool
    
    init(name:String, implemented:Bool, imageName:String, showStaff:Bool, showFingers:Bool) {
        self.name = name
        self.imageName = imageName
        self.showStaff = showStaff
        self.showFingers = showFingers
        self.implemented = implemented
    }
}

class PracticeScale : Identifiable {
    let name:String
    let score:Int
    static var dayNum = 0
    init(name:String, score:Int) {
        self.name = name
        self.score = score
    }
    
    func getGradient() -> LinearGradient {
//        let gradient = LinearGradient(
//            gradient: Gradient(colors: [Color.yellow, Color.green]),
//            startPoint: .leading,
//            endPoint: .trailing
//        )
        if score < 5 {
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.red, location: 0.0),
                    //.init(color: Color.red, location: 0.15),
                    .init(color: Color.blue, location: 0.50),
                    .init(color: Color.blue, location: 0.55),
                    .init(color: Color.green, location: 0.65),
                    .init(color: Color.red, location: 0.95)
                ]),
                startPoint: .leading,
                endPoint: .trailing
                )
        }
        else {
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.red, location: 0.0),
                    .init(color: Color.red, location: 0.10),
                    .init(color: Color.blue, location: 0.55),
                    .init(color: Color.blue, location: 0.65),
                    .init(color: Color.green, location: 0.95)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

struct PracticeJournalView: View {
    let scales:[PracticeScale] = [PracticeScale(name: "D Major", score: 10),
                                  PracticeScale(name: "A♭ Major", score: 10),
                                  PracticeScale(name: "F Minor", score: 10),
                                  PracticeScale(name: "F MelodicMinor", score: 2),
                                  PracticeScale(name: "D Major Arpeggio", score: 10),
                                  PracticeScale(name: "A♭ Major Arpeggio", score: 2)

    ]
    let days = ["Mon","Tue","Wed ","Thu","Fri","Sat", "Sun"]
    let color = Color(red: 0.1, green: 0.7, blue: 0.2)
    
    func getColor(day:String) -> Color {
        PracticeScale.dayNum += 1
        if PracticeScale.dayNum % 3 == 0 {
            return Color.gray
        }
        return Color.blue
    }
    
    func WeekDaysView() -> some View {
        HStack {
            ForEach(days, id: \.self) { day in
                Text(" "+day+" ")
                    //.padding()
                    .background(getColor(day: day))
                    .foregroundColor(.white)
                    .cornerRadius(3)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Image("app_background_0_11")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(0.5)
            VStack {
                Text("Your Journal Scales").padding().commonFrameStyle(backgroundColor: .white)
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                List(scales) { scale in
                    VStack {
                        HStack {
                            Text(scale.name).padding()
                            Text("Practice Days")
                        }
                        HStack {
                            WeekDaysView().padding()
                        }
                        HStack {
                            Text("Progress")
                            Text("                                                                             ")
                            .background(GeometryReader { geo in
                                Color.clear
                                    .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                                    .overlay(
                                        Rectangle()
                                            .fill(scale.getGradient())
                                            .frame(height: geo.size.height * 0.8)
                                            .border(Color.black, width: 1)
                                            .opacity(0.4),
                                        alignment: .center
                                    )
                            })
                        }
                        //.border(.red)
                        .padding()
                    }
                }
                .padding()
                .commonFrameStyle(backgroundColor: .white)
                .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.8)
            }
        }
    }
}

struct ActivityModeView: View {
    let options = [
        ActivityMode(name: "Your Practice Journal", implemented: true, imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Learning Mode", implemented: true, imageName: "", showStaff: false, showFingers: true),
        ActivityMode(name: "Record Scales", implemented: true, imageName: "", showStaff: false, showFingers: true),
        //ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Hear and Identify A Scale", implemented: true, imageName: "", showStaff: false, showFingers: false),
        ActivityMode(name: "Play A Scale Chosen Randomly", implemented: false, imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Scales Exam", implemented: false, imageName: "", showStaff: false, showFingers: false),
        ActivityMode(name: "Practice Hanon Exercises", implemented: false, imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Scales Theory", implemented: false, imageName: "", showStaff: true, showFingers: true)
    ]
    
    func underConstruction(activityMode: ActivityMode) -> some View {
        VStack {
            Text("\(activityMode.name) is under construction")
        }
    }
    
    func getView(activityMode: ActivityMode) -> some View {
        if !activityMode.implemented {
            return AnyView(underConstruction(activityMode: activityMode))
        }

        if activityMode.name == "Your Practice Journal" {
            return AnyView(PracticeJournalView())
        }
        return AnyView(ScalesView(activityMode: activityMode))
    }
    
    var body: some View {
        VStack {
            List(options) { activityMode in
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
    }
}

class Syllabus : Identifiable {
    let name:String
    let imageName:String
    init(name:String, imageName:String) {
        self.name = name
        self.imageName = imageName
    }
}

struct ScaleGroups: View {
    let options = [
        Syllabus(name: "ABRSM Grade 1", imageName: "abrsm"),
        Syllabus(name: "ABRSM Grade 2", imageName: "abrsm"),
        Syllabus(name: "ABRSM Grade 3", imageName: "abrsm"),
        Syllabus(name: "NZMEB Grade 1", imageName: "nzmeb"),
        Syllabus(name: "NZMEB Grade 2", imageName: "nzmeb"),
        Syllabus(name: "NZMEB Grade 3", imageName: "nzmeb"),
        Syllabus(name: "한국음악교육서비스 1급", imageName: "Korea_SJAlogo"),
        Syllabus(name: "한국음악교육서비스 2급", imageName: "Korea_SJAlogo"),
        Syllabus(name: "한국음악교육서비스 3급", imageName: "Korea_SJAlogo"),
        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Syllabus(name: "Trinity Grade 1", imageName: "trinity"),
        Syllabus(name: "Trinity Grade 2", imageName: "trinity"),
        Syllabus(name: "Trinity Grade 3", imageName: "trinity")
    ]
    var body: some View {
        VStack {
            List(options) { item in
                //NavigationLink(destination: ActivityModeView()) {
                    HStack {
                        Text(item.name).background(Color.clear)
                        Spacer()
                        HStack {
                            GeometryReader { geometry in
                                Image(item.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: geometry.size.height)
                            }
                        }
                        .padding()
                    }
                //}
            }
            .padding()
        }
    }
}

struct HomeView: View {
    @State var scaleGroupsSheet = false
    
    var body: some View {
            VStack {
                NavigationView {
                    ZStack {
                        Image("app_background_0_8")
                            .resizable()
                            .scaledToFill()
                            .edgesIgnoringSafeArea(.top)
                            .opacity(0.5)
                        VStack {
                            Spacer()
                            Text("Scales Trainer").font(.title).padding().commonFrameStyle(backgroundColor: .white)
                                .frame(width: UIScreen.main.bounds.width * 0.7)

                            ActivityModeView()
                                //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
                                .commonFrameStyle(backgroundColor: .white)
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.5)
                            Button(action: {
                                scaleGroupsSheet = true
                            }) {
                                Text("Other Scale Groups")
                            }
                            .padding()
                            .commonFrameStyle(backgroundColor: .white)
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                            Spacer()
                        }
                   }
                }
                .sheet(isPresented: $scaleGroupsSheet) {
                    ScaleGroups()
                }

            //.frame(width: UIScreen.main.bounds.width * 0.80)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        //This causes all views navigated to to have the same dimensions
        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
        .padding(.horizontal, 0)
    }
}

//struct HomeViewOld: View {
//    let options = [
//        //Option(name: "David's Practice Journal", imageName: ""),
//        //Option(name: "TEST Full Scale Set", imageName: ""),
//        Syllabus(name: "ABRSM Grade 1", imageName: "abrsm"),
//        Syllabus(name: "ABRSM Grade 2", imageName: "abrsm"),
//        Syllabus(name: "ABRSM Grade 3", imageName: "abrsm"),
//        Syllabus(name: "NZMEB Grade 1", imageName: "nzmeb"),
//        Syllabus(name: "NZMEB Grade 2", imageName: "nzmeb"),
//        Syllabus(name: "NZMEB Grade 3", imageName: "nzmeb"),
//        Syllabus(name: "한국음악교육서비스 1급", imageName: "Korea_SJAlogo"),
//        Syllabus(name: "한국음악교육서비스 2급", imageName: "Korea_SJAlogo"),
//        Syllabus(name: "한국음악교육서비스 3급", imageName: "Korea_SJAlogo"),
//        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
//        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
//        Syllabus(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
//        Syllabus(name: "Trinity Grade 1", imageName: "trinity"),
//        Syllabus(name: "Trinity Grade 2", imageName: "trinity"),
//        Syllabus(name: "Trinity Grade 3", imageName: "trinity")
//    ]
//    
//    var body: some View {
//        ZStack {
//            VStack {
//                Image("app_background_0_8")
//                    .resizable()
//                    .scaledToFill()
//                    .edgesIgnoringSafeArea(.all)
//                    .opacity(0.5)
//            }
//            
//            VStack {
//                Text("Scales Trainer").font(.title).padding()
//                ActivityModeView(selectedSyllabus: options[0])
//                    .padding()
//                    
//                //NavigationView {
//                    List(options) { item in
//                        NavigationLink(destination: ActivityModeView(selectedSyllabus: item)) {
//                            HStack {
//                                Text(item.name).background(Color.clear)
//                                Spacer()
//                                HStack {
//                                    GeometryReader { geometry in
//                                        Image(item.imageName)
//                                            .resizable()
//                                            .aspectRatio(contentMode: .fit)
//                                            .frame(height: geometry.size.height)
//                                    }
//                                }
//                                .padding()
//                            }
//                        }
//                    }
//                    .padding()
//                    .navigationBarTitle("Select Syllabus", displayMode: .inline)
//                //}
//            }
//            .frame(width: UIScreen.main.bounds.width * 0.80)
//            .navigationViewStyle(StackNavigationViewStyle())
//
//        }
//        //This causes all views navigated to to have the same dimensions
//        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
//        .padding()
//    }
//}
