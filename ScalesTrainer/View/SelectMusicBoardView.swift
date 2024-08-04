import Foundation
import SwiftUI

struct BoardGradesView: View {
    let board:String
    let width = 0.7
    let background = UIGlobals.shared.getBackground()
    let grades = Array(1...8)
    
    @State private var isOn = [Bool](repeating: false, count: 8)
    @State var index = 0
    
//    func setOn(index:Int)  {
//        isOn = [Bool](repeating: false, count: grades.count )
//        for i in 0..<isOn.count {
//            isOn[i] = i == index
//        }
//    }
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                VStack {
                    Text("Select Your Grade for \(self.board)").font(.title)//.foregroundColor(.blue)
                }
                .commonTitleStyle()
                .padding()
                Spacer()
                List {
                    ForEach(0..<grades.count, id: \.self) { i in
                        HStack {
                            Text(i == 0 ? "Preliminary" : "Grade \(i) Piano").background(Color.clear).padding()
                            Spacer()
                            Toggle("", isOn: $isOn[i])
                                .onChange(of: isOn[i]) { old, value in
                                    if value {
                                        for j in 0..<isOn.count {
                                            if j != i {
                                                isOn[j] = false
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
                .commonFrameStyle(backgroundColor: .white)
                .padding()
            }
            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
            .onAppear() {
                isOn[3] = true
            }
        }
    }
}



struct SelectMusicBoardView: View {
    let width = 0.7
    let background = UIGlobals.shared.getBackground()
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                VStack {
                    Text("Select Music Board").font(.title)//.foregroundColor(.blue)
                }
                .commonTitleStyle()
                .padding()
                Spacer()
                List {
                    ForEach(Array(MusicBoard.options.enumerated()), id: \.element.id) { index, scaleGroup in
                        NavigationLink(destination: BoardGradesView(board: scaleGroup.name)) {
                            HStack {
                                Text(scaleGroup.name).background(Color.clear).padding()
                                Text(scaleGroup.fullName).background(Color.clear).padding()
                                Spacer()

                                HStack {
                                    GeometryReader { geometry in
                                        Image(scaleGroup.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: geometry.size.height)
                                    }
                                }
                                //.padding()
                                //                            Spacer()
                                //                            Toggle(isOn: Binding<Bool>(
                                //                                get: { self.isOn[index] },
                                //                                set: { newValue in
                                //                                    if newValue {
                                //                                        self.setOn(index: index)
                                //                                    }
                                //                                }
                                //                            )) {
                                //                                EmptyView()
                                //                            }
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
