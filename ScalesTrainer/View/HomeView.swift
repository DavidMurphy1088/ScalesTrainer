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

class Option : Identifiable {
    let name:String
    let imageName:String
    init(name:String, imageName:String) {
        self.name = name
        self.imageName = imageName
    }
}

struct ScaleModeView: View {
    var selectedSyllabus: Option
    let options = [
        Option(name: "Instruction", imageName: ""),
        Option(name: "Practice", imageName: ""),
        Option(name: "Practice Meter", imageName: ""),
        Option(name: "Test", imageName: ""),
        Option(name: "Theory", imageName: "")
    ]
    
    var body: some View {
        VStack {
            //Text(selectedSyllabus.name).font(.largeTitle).padding()
            VStack {
                NavigationView {
                    List(options) { item in
                        NavigationLink(destination: ScalesView().border(Color.red)) {
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
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarTitle("\(selectedSyllabus.name) - Select Scales Topic", displayMode: .inline)
                //.navigationBarBackButtonHidden(true)
                //.navigationBarItems(leading: CustomBackButton(label: "FROM TOPIC"))
            }
            Spacer()
        }
        //.navigationBarBackButtonHidden(true)
//        .navigationBarItems(leading: CustomBackButton())
    }
}

struct HomeView: View {
    let options = [
        Option(name: "David's Practice Journal", imageName: ""),
        Option(name: "Full Scale Set", imageName: ""),
        Option(name: "ABRSM Grade 1", imageName: "abrsm"),
        Option(name: "ABRSM Grade 2", imageName: "abrsm"),
        Option(name: "ABRSM Grade 3", imageName: "abrsm"),
        Option(name: "NZMEB Grade 1", imageName: "nzmeb"),
        Option(name: "NZMEB Grade 2", imageName: "nzmeb"),
        Option(name: "NZMEB Grade 3", imageName: "nzmeb"),
        Option(name: "한국음악교육서비스 1급", imageName: "Korea_SJAlogo"),
        Option(name: "한국음악교육서비스 2급", imageName: "Korea_SJAlogo"),
        Option(name: "한국음악교육서비스 3급", imageName: "Korea_SJAlogo"),
        Option(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Option(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Option(name: "中央音乐学院一级", imageName: "Central_Conservatory_of_Music_logo"),
        Option(name: "Trinity Grade 1", imageName: "trinity"),
        Option(name: "Trinity Grade 2", imageName: "trinity"),
        Option(name: "Trinity Grade 3", imageName: "trinity")
    ]
    
    var body: some View {
        VStack {
            //Text("Scales Trainer").font(.title).padding()
            NavigationView {
                List(options) { item in
                    NavigationLink(destination: ScaleModeView(selectedSyllabus: item)) {
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
                .navigationBarTitle("Select a Scale Set1", displayMode: .inline)
            }
            .navigationBarTitle("Select a Scale Set2", displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        //This causes all views navigated to to have the same dimensions
        //.frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height * 0.8)
        .navigationBarTitle("Select a Scale Set3", displayMode: .inline)
        .padding()
    }
}
