import Foundation
import SwiftUI

struct SelectBoardGradesView: View {
    @EnvironmentObject var tabSelectionManager: TabSelectionManager
    let userForGrade:User
    let inBoard:MusicBoard
    @State private var isOn = [Bool](repeating: false, count: 12)
    let width = 0.7
    
    func updateBoardGrade(gradeNumber:Int) {
        userForGrade.grade = gradeNumber
        Settings.shared.setUserGrade(gradeNumber)
        ///Force all views dependendent on grade to close since they show the previous grade
        tabSelectionManager.isSpinWheelActive = false
        tabSelectionManager.isPracticeChartActive = false
        DispatchQueue.main.async {
            tabSelectionManager.currentUser = userForGrade
        }
        Settings.shared.save()
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
            if let grade = userForGrade.grade {
                isOn[grade] = true
            }
            Settings.shared.debug("appear")
        }
        .onDisappear() {
        }
    }
}

