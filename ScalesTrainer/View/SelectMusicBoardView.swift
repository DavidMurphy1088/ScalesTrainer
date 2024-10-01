import Foundation
import SwiftUI

struct BoardGradesView: View {
    let board:String
    let width = 0.7
    //let background = UIGlobals.shared.getBackground()
    let grades = Array(1...9)
    
    @State private var isOn = [Bool](repeating: false, count: 9)
    @State var index = 0
        
    var body: some View {
        VStack {
            VStack {
                //Text("\(self.board), Select Your Grade").font(.title)//.foregroundColor(.blue)
                Text("Trinity").font(.title)//.foregroundColor(.blue)
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
            .padding()
            Spacer()
            List {
                ForEach(0..<grades.count, id: \.self) { i in
                    HStack {
                        Text(i == 0 ? "Initial Piano" : "Grade \(i) Piano").background(Color.clear).padding()
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
            .commonFrameStyle()
            .padding()

            .onAppear() {
                isOn[1] = true
            }
            .onDisappear() {
                if let grade = isOn.firstIndex(where: { $0 == true }) {
                    Settings.shared.musicBoardGrade = MusicBoardGrade(grade: String(grade))
                }
            }
        }
        .commonFrameStyle()
    }
}

struct SelectMusicBoardView: View {
    let width = 0.7
    
    var body: some View {

            VStack {
                VStack {
                    Text("Select Music Board").font(.title)
                }
                .commonFrameStyle()
                .padding()
                Spacer()
                List {
                    ForEach(Array(MusicBoard.options.enumerated()), id: \.element.id) { index, board in
                        NavigationLink(destination: BoardGradesView(board: board.name)) {
                            HStack {
                                Text(board.name).background(Color.clear).padding()
                                Text(board.fullName).background(Color.clear).padding()
                                Spacer()

                                HStack {
                                    GeometryReader { geometry in
                                        Image(board.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: geometry.size.height)
                                    }
                                }
                            }
                        }
                    }
                }
                .commonFrameStyle()
                .padding()
            //}
            //.frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
            .onDisappear() {
                //if let board = MusicBoard.options.firstIndex(where: { $0.name == true }) {
                Settings.shared.musicBoard = MusicBoard.init(name: "Trinity")
                //}
            }

        }
    }
}
