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
    let onConfirm: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(board.name) Grade Selection").font(.title2)
                Spacer()
                Button("Confirm") {
                    onConfirm(selectedGrade)
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
    }
}

public struct UserEditView: View {
    public let addingFirstUser: Bool
    @State var user: User
    @Environment(\.dismiss) private var dismiss
    
    @FocusState var nameFieldFocused: Bool
    @State private var userName: String = ""
    @State private var selectedGrade = 0
    @State private var selectedBoard:MusicBoard? = nil
    @State private var errorMessage: String = ""
    @State private var showErrorAlert = false
    let screenWidth = UIScreen.main.bounds.width
    let settings = Settings.shared
    @State private var saveEnabled = false
    @State private var sheetNonce = UUID()
    @State private var showDeleteAlert = false
    
    func getSelectedGrade(_ ctx:String, board:MusicBoard) -> Int {
        var grade = 0
        if board.name == user.boardAndGrade.board.name {
            grade = user.boardAndGrade.grade
        }
        return grade
    }
    
    func isSaveEnabled(user:User) -> Bool {
        if user.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return user.boardAndGrade.grade > 0
    }

    public var body: some View {
        HStack {
            Text("  ")
            VStack(alignment: .leading) {
                ///Header area
                VStack {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        if addingFirstUser {
                            HStack {
                                Text("Let’s set up your account").font(.title2)
                                Spacer()
                            }
                        }
                    }
                    HStack {
                        if saveEnabled {
                            if user.boardAndGrade.grade > 0 {
                                FigmaButton(
                                    label: {
                                        HStack {
                                            Image("figma_tickmark")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: UIFont.preferredFont(forTextStyle: .body).pointSize)
                                            Text("Save")
                                        }
                                    },
                                    action: {
                                        if user.boardAndGrade.grade > 0 {
                                            settings.setUser(user: user)
                                            user.setColor()
                                            dismiss()
                                            if addingFirstUser {
                                                ViewManager.shared.setTab(tab: ViewManager.TAB_ACTIVITES)
                                            }
                                        } else {
                                            errorMessage = "▶️ Please select a grade before saving"
                                            showErrorAlert = true
                                        }
                                    }
                                )
                                .padding()
                            }
                        }
                        
                        if settings.hasUser(name: user.name) {
                            let enabled = user.id != settings.getCurrentUser("UserEditView- is remove enabled").id
                            if enabled  {
                                FigmaButton(
                                    label: {
                                        Text("Remove User").foregroundColor(.red)
                                    },
                                    action: {
                                        showDeleteAlert = true
                                    }
                                )
                                .padding()
                                .alert("Are you sure you want to delete \(user.name)?",
                                       isPresented: $showDeleteAlert) {
                                    Button("Delete", role: .destructive) {
                                        user.name = userName
                                        settings.deleteUser(user: user)
                                        dismiss()
                                    }
                                    Button("Cancel", role: .cancel) { }
                                } message: {
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding()

                Text("")
                VStack(alignment: .leading) {
                    TextField("Please enter your name", text: $userName)
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
                .onChange(of: userName) {_, name in
                    user.name = name
                    self.saveEnabled = isSaveEnabled(user: user)
                }

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
                                Text("")
                                FigmaButton(label: {
                                    Text("Select Grade")
                                }, action: {
                                    print("")
                                    self.selectedBoard = board
                                    self.selectedGrade = self.getSelectedGrade("Button Action to Show POPUP", board: board)
                                    sheetNonce = UUID()
                                })
                                .padding()
                                ///Make the full name last else the buttons dont line up horizontally
                                if UIDevice.current.userInterfaceIdiom != .phone {
                                    Text(board.fullName)//.font(.caption)
                                        .lineLimit(nil)                 // allow unlimited lines
                                        .multilineTextAlignment(.leading) // left-align
                                        .fixedSize(horizontal: false, vertical: true) // allows wrapping
                                }
                                Spacer()
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.2)
                        }
                    }
                }
            }
            Text("  ")
        }
        .onAppear {
            if !self.addingFirstUser {
                self.selectedGrade = user.boardAndGrade.grade
            }
            userName = user.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                nameFieldFocused = true
            }
            self.saveEnabled = self.isSaveEnabled(user: user)
        }
        .sheet(item: $selectedBoard, onDismiss: {
            }) { board in
                SelectGradeView(board: board, selectedGrade: $selectedGrade, onConfirm: {grade in
                    let boardAndGrade = MusicBoardAndGrade(board: board, grade: grade)
                    user.selectedMinorType = boardAndGrade.getDefaultMinorType()
                    user.boardAndGrade = boardAndGrade
                    self.saveEnabled = self.isSaveEnabled(user: user)
                })
            }
        .commonToolbar(
            title: "User Edit",
            onBack: { dismiss() }
        )
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

}
