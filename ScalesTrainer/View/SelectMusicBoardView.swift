import Foundation
import SwiftUI

struct SelectBoardGradesView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let inBoard:MusicBoard
    @State private var isOn = [Bool](repeating: false, count: 12)
    let width = 0.7
    
    func updateBoardGrade(gradeIndex:Int) {
        ///Force all views dependendent on grade to close since they show the previous grade
        tabSelectionManager.isSpinWheelActive = false
        tabSelectionManager.isPracticeChartActive = false
        Settings.shared.musicBoardGrade = gradeIndex
        Settings.shared.musicBoardName = inBoard.name
        MusicBoardAndGrade.shared = MusicBoardAndGrade(board: MusicBoard(name: self.inBoard.name), grade: gradeIndex)
        Settings.shared.save()
        MusicBoardAndGrade.shared?.savePracticeChartToFile()
        SettingsPublished.shared.setBoardAndGrade(boardAndGrade: MusicBoardAndGrade.shared!)
    }
    
    var body: some View {
        VStack {
            VStack {
                Text(inBoard.name).font(.title)
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
            .padding()
            Spacer()
            List {
                ForEach(inBoard.gradesOffered, id: \.self) { number in
                    HStack {
                        let name = "Grade " + String(number) + " Piano"
                        Text(name).background(Color.clear).padding()
                        Spacer()
                        Toggle("", isOn: $isOn[number])
                        .onChange(of: isOn[number]) { oldWasOn, newWasOn in
                            if newWasOn {
                                for j in 0..<isOn.count {
                                    if j != number {
                                        isOn[j] = false
                                    }
                                }
                                self.updateBoardGrade(gradeIndex: number)
                            }
                        }
                    }
                }
            }
            .commonFrameStyle()
            .padding()
        }
        .commonFrameStyle()
        .onAppear() {
            for i in 0..<isOn.count {
                isOn[i] = false
            }
            if let grade = MusicBoardAndGrade.shared?.grade {
                isOn[grade] = true
            }
        }
        .onDisappear() {
//            if let gradeIndex = isOn.firstIndex(where: { $0 == true }) {
//                ///Force all views dependendent on grade to close since they show the previous grade
//                tabSelectionManager.isSpinWheelActive = false
//                tabSelectionManager.isPracticeChartActive = false
//                Settings.shared.musicBoardGrade = gradeIndex
//                Settings.shared.musicBoardName = inBoard.name
//                MusicBoardAndGrade.shared = MusicBoardAndGrade(board: MusicBoard(name: self.inBoard.name), grade: gradeIndex)
//                Settings.shared.save()
//                MusicBoardAndGrade.shared?.savePracticeChartToFile()
//                SettingsPublished.shared.setBoardAndGrade(boardAndGrade: MusicBoardAndGrade.shared!)
//            }
        }
    }
}

struct SelectMusicBoardView: View {
    let width = 0.7
    let inBoard: MusicBoard?
    @State private var outBoardAndGrade: MusicBoardAndGrade?
    ///All set nil except for the grade assocoated with any settings board and grade
    //@State var alreadySetGradeForBoard:[MusicBoard:Int] = [:]

    var body: some View {
        VStack {
            VStack {
                TitleView(screenName: "Scales Academy", showGrade: true)
                    .commonFrameStyle()
            }
            .commonFrameStyle()
            .padding()
            
            Spacer()
            
            List {
                ForEach(Array(MusicBoard.getSupportedBoards().enumerated()), id: \.element.id) { index, board in
                    ///Send in the board chosen in the navigation. If that board is the same board already set in the setting boardAndGrade also send in the grade so that the grade selection preslects it.
                    NavigationLink(destination: SelectBoardGradesView(inBoard: board)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(board.name)
                                    .font(.title2)
                                //.padding()
                                    .padding(.bottom, 2)
                                Text(board.fullName)
                                    .background(Color.clear)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Image(board.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:UIScreen.main.bounds.width * 0.1, height: UIScreen.main.bounds.width * 0.1)
                            }
                            Text("     ")
                        }
                        .padding(.vertical, 8) // Add padding between list items
                    }
                }
            }
            .commonFrameStyle()
            .padding()
        }
        //.frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
        .onAppear() {
        }
        .onDisappear {
        }
    }
}
