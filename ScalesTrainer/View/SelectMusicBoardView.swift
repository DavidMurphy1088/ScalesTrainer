import Foundation
import SwiftUI

struct SelectGradeView: View {
    let user: User
    let board: MusicBoard
    let settings = Settings.shared
    @State private var selectedGrade: Int? = nil
    
    func getGrades() -> [Int] {
        board.gradesOffered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScreenTitleView(screenName: "\(board.name) Grades").padding(.vertical, 0)
            List {
                ForEach(getGrades(), id: \.self) { grade in
                    HStack {
                        Spacer()
                        HStack {
                            Text("Grade \(grade)")
                            Spacer()
                            if selectedGrade == grade {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.size.width * 0.30)
                        .contentShape(Rectangle()) // Make entire row tappable
                        
                        .onTapGesture {
                            selectedGrade = grade
                            let user = settings.getCurrentUser()
                            user.board = board.name
                            user.grade = grade
                            ViewManager.shared.updatePublishedUser()
                            ViewManager.shared.isPracticeChartActive = false
                            ViewManager.shared.isSpinWheelActive = false
                            settings.save()
                        }
                        Spacer()
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear() {
            let user = Settings.shared.getCurrentUser()
            if user.board == board.name {
                selectedGrade = user.grade
            }
        }
        
    }
}

struct SelectBoardView: View {
    let user:User
    let boards = MusicBoard.getSupportedBoards()
    
    var body: some View {
            VStack {
                List(boards) { board in
                    HStack {
                        Spacer()
                        NavigationLink(destination: SelectGradeView(user:user, board: board)) {
                            HStack {
                                Image(board.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading) {
                                    Text(board.name)
                                        .font(.headline)
                                    Text(board.fullName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(width: UIScreen.main.bounds.size.width * 0.40)
                        Spacer()
                    }
                }
//                .navigationDestination(for: MusicBoard.self) 👹 NIGHTMARE { board in
//                    // Pass the board to your detail view if needed.
//                    //Text("Selected board: \(board.name)")
//                    SelectGradeView(user:user, board: board) //, selectedGrade: $grade)
//                }
                .listStyle(PlainListStyle())
             }
    }
}

