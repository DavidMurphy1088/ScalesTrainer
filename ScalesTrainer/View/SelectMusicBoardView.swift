import Foundation
import SwiftUI

struct BoardGradesView: View {
    let inBoard:MusicBoard
    let inGrade:Int?
    @Binding var outBoardGrade:BoardGrade?
    
    @State private var isOn:[Bool] = [Bool](repeating: false, count: 12)
    let width = 0.7

    var body: some View {
        VStack {
            VStack {
                Text(inBoard.name).font(.title)
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
            .padding()
            Spacer()
            List {
                ForEach(inBoard.grades) { grade in
                    HStack {
                        Text("\(grade.getGradeName())").background(Color.clear).padding()
                        Spacer()
                        Toggle("", isOn: $isOn[grade.grade])
                        .onChange(of: isOn[grade.grade]) { old, value in
                            if value {
                                for j in 0..<isOn.count {
                                    if j != grade.grade {
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
        }
        .commonFrameStyle()
        .onAppear() {
            for i in 0..<isOn.count {
                isOn[i] = false
            }
            if let grade = self.inGrade {
                isOn[grade] = true
            }
            print("==================== GradeView Appear", self.inBoard.name, "Grade", self.inGrade)
        }
        .onDisappear() {
            if let gradeIndex = isOn.firstIndex(where: { $0 == true }) {
                self.outBoardGrade = BoardGrade(board: MusicBoard(name: self.inBoard.name), grade: gradeIndex)
                print("==================== GradeView Disapper", self.outBoardGrade?.getFullName())
            }
        }
    }
}

struct SelectMusicBoardView: View {
    let width = 0.7
    let inBoard: MusicBoard?
    @State private var outBoardAndGrade: BoardGrade?
    ///All set nil except for the grade assocoated with any settings board and grade
    @State var alreadySetGradeForBoard:[MusicBoard:Int] = [:]
    
//    init(inBoard: MusicBoard?) {
//        _inBoard = State(initialValue: inBoard)
//        //_outBoardAndGrade = State(initialValue: outBoardAndGrade)
//    }
//    
//    func setOutGrade(board:MusicBoard) -> Bool {
//        if let settingsBoardGrade = Settings.shared.getBoardGrade() {
//            print("=============setOutGrade", board.name, settingsBoardGrade.board.name, board.name == settingsBoardGrade.board.name)
//            if board.name == settingsBoardGrade.board.name {
//                outBoardAndGrade = BoardGrade(board: MusicBoard(name: board.name), grade: settingsBoardGrade.grade)
//            }
//        }
//        return true
//    }
    
    var body: some View {
        VStack {
            // Title Section
            VStack {
                Text("Select Music Board")
                    .font(.title)
            }
            .commonFrameStyle()
            .padding()
            
            Spacer()
            
            List {
                ForEach(Array(MusicBoard.boards.enumerated()), id: \.element.id) { index, board in
                    ///Send in the board chosen in the navigation. If that board is the same board already set in the setting boardAndGrade also send in the grade so that the grade selectedion preslects it.
                    NavigationLink(destination: BoardGradesView(inBoard: board, inGrade: alreadySetGradeForBoard[board], outBoardGrade: $outBoardAndGrade)) {
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
            if let boardAndGrade = Settings.shared.getBoardGrade() {
                self.alreadySetGradeForBoard[boardAndGrade.board] = boardAndGrade.grade
            }
        }
        .onDisappear {
            if let outBoardAndGrade = self.outBoardAndGrade {
                Settings.shared.boardName = outBoardAndGrade.board.name
                Settings.shared.boardGrade = outBoardAndGrade.grade
                SettingsPublished.shared.setBoardAndGrade(boardAndGrade: outBoardAndGrade)
                print("==================== BoardView Disappear SETTINGS UPDATED", outBoardAndGrade.getFullName())
            }
        }
    }
}
