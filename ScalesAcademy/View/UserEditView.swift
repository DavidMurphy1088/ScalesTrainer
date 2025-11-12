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
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    public var body: some View {
        VStack {
            HStack {
                //Spacer()
                Text(" \(board.name) Grade Selection").font(.title2)
                Text("     ")
                Button("Confirm") {
                    onConfirm(selectedGrade)
                    dismiss()
                }
                .padding()
                Spacer()
            }
            HStack {
                Text(" Please select your grade")//.padding(compact ? 0 : .vertical)
                Spacer()
            }
            .padding(compact ? 0 : 4)
            HStack {
                Text(" ")
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
                .listStyle(.plain)
                .frame(maxWidth: UIScreen.main.bounds.size.width * 0.25) // Set maximum width
                Spacer()
            }
        }
    }
}

struct DisclaimerSheet: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Disclaimer")
                        .font(.title2).bold()

                    Text("""
Scales Academy™ is an independent educational product and is not endorsed by or affiliated with Trinity College London. Trinity College London retains all rights to its syllabuses and trademarks.
""")

                    Divider()

                    Text("Why you’re seeing this")
                        .font(.headline)
                    Text("We show this notice to be transparent about our relationship to examination boards.")

                    Spacer(minLength: 8)
                }
                .padding()
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
    @State private var showDisclaimer = false
    
    let screenWidth = UIScreen.main.bounds.width
    let settings = Settings.shared
    @State private var sheetNonce = UUID()
    @State private var showDeleteAlert = false

    let compact = UIDevice.current.userInterfaceIdiom == .phone
    let colors = FigmaColors.shared
    let boxWidth = UIScreen.main.bounds.width * 0.25
    //let boxHeight = UIScreen.main.bounds.width * (UIDevice.current.userInterfaceIdiom == .phone ? 0.15 : 0.2)
    let boxHeight = UIScreen.main.bounds.height * (UIDevice.current.userInterfaceIdiom == .phone ? 0.40 : 0.40)

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
    
    func getColor(name:String) -> Color {
        if name == "Trinity College" {
            return colors.getColor1("UserEditViewforBoard", "green")
        }
        if name == "ABRSM" {
            return colors.getColor1("UserEditViewforBoard", "blue")
        }
        return colors.getColor1("UserEditViewforBoard", "orange")
    }
    
    func HeaderView() -> some View {
        HStack {
            if isSaveEnabled(user:user) {
                if user.boardAndGrade.grade > 0 {
                    FigmaButtonWithLabel(
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
                                user.setColor()
                                settings.setUser(user: user)
                                dismiss()
                                if addingFirstUser {
                                    settings.setCurrentUser(id: user.id)
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
                    FigmaButtonWithLabel(
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
    
    func showUnderlyingUI() -> Bool {
//        if !compact {
//            return true
//        }
        return !nameFieldFocused
    }
    
    public var body: some View {
        HStack {
            Text("XXX").padding().foregroundColor(.clear)
            VStack(alignment: .leading) {
                ///Header area
                if showUnderlyingUI() {
                    HeaderView()//.padding(.horizontal)
                        //.border(.green)
                        .figmaRoundedBackgroundWithBorder(fillColor: .white)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Your name ").padding()
                        TextField("enter your name here", text: $userName)
                            .focused($nameFieldFocused)
                            .padding()
                            .cornerRadius(8)
                            .foregroundColor(.black)
                            .font(.body)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        nameFieldFocused = false
                                    }
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                                }
                            }
                        Spacer()
                    }
                    .figmaRoundedBackgroundWithBorder(fillColor: .white)
                    //.padding(self.compact ? 0 : .vertical)
                    .padding(self.compact ? 2 : 10.0)
                }
                //.padding(.vertical)
                //.border(.purple)
                
                .onChange(of: userName) {_, name in
                    user.name = name
                }
                
                if showUnderlyingUI() {
                    VStack(alignment: .leading) {
                        if showUnderlyingUI() {
                            if !compact {
                                VStack {
                                    //Text("")//.padding(.horizontal)
                                    Text("Your Grade").font(.title2).padding(.horizontal)
                                    Text("Note: Only one grade can be active at one time.").padding(.horizontal)
                                }
                                .padding(.vertical)
                            }
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(MusicBoard.getSupportedBoards(), id: \.id) { board in
                                    VStack {
                                        Text("") /// Dont remove this - if gone the boxes loose their top lines 👹
                                        Text(board.name).font(compact ? .title3 : .title2).padding()
                                            .figmaRoundedBackgroundWithBorder(fillColor: getColor(name: board.name))
                                        Text("")
                                        FigmaButton("Select Grade", action: {
                                            self.selectedBoard = board
                                            self.selectedGrade = self.getSelectedGrade("Button Action to Show POPUP", board: board)
                                            sheetNonce = UUID()
                                        })
                                        //.padding()
                                       
                                        ///Make the full name last else the buttons dont line up horizontally
                                        //                                        if !compact {
                                        //                                            Text(board.fullName)//.font(.caption)
                                        //                                                .lineLimit(nil)                 // allow unlimited lines
                                        //                                                .multilineTextAlignment(.center) // left-align
                                        //                                                .fixedSize(horizontal: false, vertical: true) // allows wrapping
                                        //                                        }

                                        if compact {
                                            Text("xxx").opacity(0.0)
                                            //Text("xxx").opacity(0.0)
                                            Button("Disclaimer") {
                                                self.showDisclaimer = true
                                            }
                                            .foregroundColor(.blue)
                                            //.padding()
                                        }
                                        else {
                                            VStack {
                                                Text("")
                                                Text(board.copyrightDisclaimer)
                                                    .font(.subheadline)
                                                    .lineLimit(nil)                 // allow unlimited lines
                                                    .multilineTextAlignment(.center) // left-align
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .padding()
                                                Spacer()
                                            }
                                            .frame(height: boxHeight * 0.3)
                                            //.border(.green)
                                        }
                                    }
                                    .frame(width: boxWidth, height: boxHeight)
                                    //.border(.red)
                                }
                            }
                        }
                        //.border(.green)
                        Text("  ")
                    }
                    .figmaRoundedBackgroundWithBorder(fillColor: .white)
                }
            }
            Text("XXXX").padding().foregroundColor(.clear)
        }

        .onAppear {
            if !self.addingFirstUser {
                self.selectedGrade = user.boardAndGrade.grade
            }
            userName = user.name
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                nameFieldFocused = true
//            }
        }
           
        .sheet(item: $selectedBoard, onDismiss: {
            }) { board in
                SelectGradeView(board: board, selectedGrade: $selectedGrade, onConfirm: {grade in
                    let boardAndGrade = MusicBoardAndGrade(board: board, grade: grade)
                    user.selectedMinorType = boardAndGrade.getDefaultMinorType()
                    user.boardAndGrade = boardAndGrade
                    //self.saveEnabled = self.isSaveEnabled(user: user)
                })
            }
            
        .commonToolbar(
            title: settings.isCurrentUserDefined() ? "Edit User" : "Let's set up your account",
            helpMsg: "",
            onBack: { dismiss() }
        )
        .toolbar(.hidden, for: .tabBar) // Hide the TabView
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showDisclaimer, onDismiss: {  }) {
            DisclaimerSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)

        }
    }

}
