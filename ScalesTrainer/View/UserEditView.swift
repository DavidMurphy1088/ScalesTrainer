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
                Button("Confirm") {
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
    let addingFirstUser: Bool
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFieldFocused: Bool
    @State private var name: String = ""
    @State private var selectedGrade: Int = 1
    @State private var showGradesBoard: MusicBoard? = nil
    @State var user: User
    @State private var errorMessage: String = ""
    @State private var showErrorAlert = false
    let screenWidth = UIScreen.main.bounds.width
    let settings = Settings.shared

    var body: some View {
        HStack {
            Text("  ")
            VStack(alignment: .leading) {
                ///Header area
                HStack {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        if addingFirstUser {
                            HStack {
                                Spacer()
                                Text("Let’s set up your account").font(.title2)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            FigmaButton(
                                label: {
                                    HStack {
                                        Image("figma_tickmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: UIFont.preferredFont(forTextStyle: .body).pointSize)
                                        Text("Confirm")
                                    }
                                },
                                action: {
                                    if user.grade > 0 {
                                        errorMessage = ""
                                        user.name = name
                                        settings.setUser(user: user)
                                        dismiss()
                                        ViewManager.shared.setTab(tab: ViewManager.TAB_ACTIVITES)
                                    } else {
                                        errorMessage = "Please select a grade before saving"
                                        showErrorAlert = true
                                    }
                                }
                            )
                            .padding()
                        }
                        
                        if user.grade > 0 {
                            Button(action: {
                                user.name = name
                                settings.deleteUser(user: user)
                                dismiss()
                                ViewManager.shared.setTab(tab: ViewManager.TAB_ACTIVITES)
                            }) {
                                Text("Remove User").foregroundColor(.red)
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }

                Text("")
                //Text("Please add your name:")
                VStack(alignment: .leading) {
                    TextField("Please add your name", text: $name)
                        .focused($nameFieldFocused)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .font(.body)
                        .frame(width: UIScreen.main.bounds.width * 0.2)
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Text("")
                        Text("Your Grade").font(.title2)
                        Text("Note: Only one grade can be active at one time.")
                    }
                }
                .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MusicBoard.getSupportedBoards(), id: \.id) { board in
                            VStack {
                                let boxWidth = screenWidth * (UIDevice.current.userInterfaceIdiom == .phone ? 0.05 : 0.08)
                                Image(board.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: boxWidth, height: boxWidth)
                                    .clipShape(RoundedRectangle(cornerRadius: boxWidth * 0.1))
                                Text("")
                                Text(board.name).font(.title2)
                                if UIDevice.current.userInterfaceIdiom != .phone {
                                    Text(board.fullName)//.font(.caption)
                                }
                                Text("")
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
                            .frame(width: UIScreen.main.bounds.width * 0.2)
                                   //,height: UIScreen.main.bounds.height * 0.3)
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
        .commonToolbar(
            title: "User Edit",
            onBack: { dismiss() }
        )
        .onAppear {
            name = user.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                nameFieldFocused = true
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
