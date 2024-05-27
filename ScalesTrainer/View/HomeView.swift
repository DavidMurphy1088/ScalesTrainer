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
    let showStaff:Bool
    let showFingers:Bool
    
    init(name:String, imageName:String, showStaff:Bool, showFingers:Bool) {
        self.name = name
        self.imageName = imageName
        self.showStaff = showStaff
        self.showFingers = showFingers
    }
}

struct ActivityModeView: View {
    var selectedSyllabus: Syllabus
    let options = [
        ActivityMode(name: "Learn The Scale", imageName: "", showStaff: false, showFingers: true),
        ActivityMode(name: "Practice The Scale", imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Practice Meter", imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Practice Journal", imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Random Choice", imageName: "", showStaff: true, showFingers: true),
        ActivityMode(name: "Test", imageName: "", showStaff: false, showFingers: false),
        ActivityMode(name: "Theory", imageName: "", showStaff: true, showFingers: true)
    ]
    
//    func getView(activityMode: ActivityMode) -> some View {
//        ScalesModel.shared.setShowStaff(activityMode.showStaff)
//        ScalesModel.shared.setShowFingers(activityMode.showFingers)
//        return ScalesView()
//    }
    
    var body: some View {
        VStack {
            VStack {
                List(options) { activityMode in
                    NavigationLink(destination: ScalesView(activityMode: activityMode)) {
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
                .navigationBarTitle("\(selectedSyllabus.name) Activities", displayMode: .inline)
                .navigationViewStyle(StackNavigationViewStyle())
            }
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

struct HomeView: View {
    let options = [
        //Option(name: "David's Practice Journal", imageName: ""),
        //Option(name: "TEST Full Scale Set", imageName: ""),
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
            //Text("Scales Trainer").font(.title).padding()
            NavigationView {
                List(options) { item in
                    NavigationLink(destination: ActivityModeView(selectedSyllabus: item)) {
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
                    }
                }
                .navigationBarTitle("Select Syllabus", displayMode: .inline)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        //This causes all views navigated to to have the same dimensions
        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
        .padding()
    }
}
