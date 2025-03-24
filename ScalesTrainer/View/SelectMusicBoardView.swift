import Foundation
import SwiftUI

struct SelectBoardView: View {
    var body: some View {
        VStack(spacing: 0) {
        }
    }
}

struct SelectBoardGradesView: View {
    @EnvironmentObject var tabSelectionManager: ViewManager
    let user:User
    let inBoard:MusicBoard
    @Binding var selectedGrade: Int
    @State private var isOn = [Bool](repeating: false, count: 12)
    let width = 0.7
    
    func updateBoardGrade(gradeNumber:Int) {
        user.grade = gradeNumber
        Settings.shared.setUserGrade(user, gradeNumber)
        ///Force all views dependendent on grade to close since they show the previous grade
        tabSelectionManager.isSpinWheelActive = false
        tabSelectionManager.isPracticeChartActive = false
        Settings.shared.save()
        self.selectedGrade = gradeNumber
    }
    
    var body: some View {
        VStack(spacing: 0) {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    HStack {
                        Text("\(inBoard.name) Grades")
                            .font(.title)
                            .font(.title3)
                    }
                    .padding(.horizontal)
                }
                List {
                    ForEach(inBoard.gradesOffered, id: \.self) { number in
                        HStack {
                            let name = "Grade " + String(number) + " Piano"
                            Text(name)
                                .padding(.vertical, 4)  // Reduced vertical padding
                            Spacer()
                            Toggle("", isOn: $isOn[number])
                                .onChange(of: isOn[number]) { oldWasOn, newWasOn in
                                    if newWasOn {
                                        for j in 0..<isOn.count {
                                            if j != number {
                                                isOn[j] = false
                                            }
                                        }
                                        self.updateBoardGrade(gradeNumber: number)
                                    }
                                }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
                .listStyle(PlainListStyle())
            }
        
        .onAppear() {
            for i in 0..<isOn.count {
                isOn[i] = false
            }
            if let grade = user.grade {
                isOn[grade] = true
            }
        }
        .onDisappear() {
        }
    }
}

