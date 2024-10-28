import Foundation
import SwiftUI

struct BoardGradesView: View {
    let board:String
    let width = 0.7
    let grades = Array(1...9)
    
    @State private var isOn = [Bool](repeating: true, count: 9)
    @State var index = 0
        
    var body: some View {
        VStack {
            VStack {
                Text("Trinity").font(.title)
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
            .padding()
            Spacer()
            List {
                ForEach(0..<grades.count, id: \.self) { gradeIndex in
                    HStack {
                        Text(gradeIndex == 0 ? "Initial Piano" : "Grade \(gradeIndex) Piano").background(Color.clear).padding()
                        Spacer()
                        if gradeIndex == 1 {
                            Toggle("", isOn: $isOn[gradeIndex])
                                .onChange(of: isOn[gradeIndex]) { old, value in
                                    if value {
                                        for j in 0..<isOn.count {
                                            if j != gradeIndex {
                                                isOn[j] = false
                                            }
                                        }
                                    }
                                }
                        }
                        else {
                            Text("Under construction").foregroundColor(.gray)
                        }
                    }
                }
            }
            .commonFrameStyle()
            .padding()

            .onAppear() {
                //isOn[Settings.shared.musicBoardGrade.gradeIndex] = true
                isOn[1] = true
            }
            .onDisappear() {
                //if let grade = isOn.firstIndex(where: { $0 == true }) {
                let grade = isOn[1]
                Settings.shared.musicBoardGrade = MusicBoardGrade(index: 1, grade: String(grade))
                Settings.shared.save()
                //}
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
