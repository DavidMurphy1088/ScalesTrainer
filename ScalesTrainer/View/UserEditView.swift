import Foundation
import Foundation
import SwiftUI
import Combine
import SwiftUI
import AVFoundation
import AudioKit

// ---------------------- Edit details of a single user -------------------

struct SelectGradeView: View {
    let board: MusicBoard
    @Binding var selectedGrade: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(board.name) Grade Selection").font(.title2)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .padding()
            }
            HStack {
                Text("Please select yout grade").padding()
                Spacer()
            }
            List(board.gradesOffered, id: \.self) { grade in
                HStack {
                    Text("Grade \(grade)")
                    Spacer()
                    if selectedGrade == grade {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedGrade = grade
                }
            }
        }
        .onAppear() {
            if !board.gradesOffered.contains(selectedGrade)  {
                selectedGrade = 1
            }
        }
    }
}

struct UserEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedGrade: Int = 1
    @State private var showGradesBoard: MusicBoard? = nil
    @State var user: User
    let settings = Settings.shared

    func getBoard(_ name: String) -> MusicBoard {
        return MusicBoard.getSupportedBoards().first { $0.name == name }!
    }

    var body: some View {
        HStack {
            Text("  ")
            VStack(alignment: .leading) {
                HStack {
                    Text("Welcome, let’s set up your account").font(.title2)
                    Spacer()
                    Button("Save") {
                        user.name = name
                        user.isCurrentUser = true
                        settings.saveUser(user: user)
                        dismiss()
                        ViewManager.shared.setTab(tab: ViewManager.TAB_ACTIVITES)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }

                Text("")
                Text("")
                Text("Please enter your name:")

                TextField("name", text: $name)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .foregroundColor(.black)
                    .font(.body)
                    .frame(width: UIScreen.main.bounds.width * 0.2)

                Text("")
                Text("Your Grade")
                Text("Note: Only one grade can be active at one time.").font(.caption)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MusicBoard.getSupportedBoards(), id: \.id) { board in
                            VStack {
                                Image(board.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Text(board.name).font(.footnote)
                                Text(board.fullName).font(.caption)

                                FigmaButton(label: {
                                    Text("Select Grade")
                                }, action: {
                                    user.board = board.name
                                    DispatchQueue.main.async {
                                        self.showGradesBoard = board
                                    }
                                })

                                Text("")
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.2,
                                   height: UIScreen.main.bounds.height * 0.3)
                        }
                    }
                }
            }
            Text("  ")
        }
        .sheet(item: $showGradesBoard, onDismiss: {
            user.grade = selectedGrade
            user.debug()
        }) { board in
            SelectGradeView(board: board, selectedGrade: $selectedGrade)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                FigmaButton(label: {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }, action: {
                    dismiss()
                })
            }
        }
        .onAppear {
            name = user.name
        }
    }
}
