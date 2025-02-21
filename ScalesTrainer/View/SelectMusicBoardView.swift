import Foundation
import SwiftUI

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
        VStack {
            if UIDevice.current.userInterfaceIdiom != .phone {
                HStack {
                    Image("trinity")
                        .resizable()
                        .scaledToFit()
                        .frame(height: UIFont.preferredFont(forTextStyle: .title2).lineHeight * 3.0)
                    
                    Text("\(inBoard.name) Grades").font(.title).font(.title3)
                }
                .padding(.horizontal)
            }
            
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
                                    self.updateBoardGrade(gradeNumber: number)
                                }
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .padding()
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

