import Foundation
import AVFoundation
import Combine
import SwiftUI

class ExerciseState : ObservableObject {
    static let shared = ExerciseState()
    private(set) var numberToWin = 0
    func setNumberToWin(_ n:Int) {
        self.numberToWin = n
    }
    
    enum State {
        case exerciseNotStarted1
        case exerciseStarting
        case exerciseRunning
        case exerciseLost
        case exerciseWon
    }
    
    func pointsNeededToWin() -> Int {
        return numberToWin - totalCorrect
    }
    
    @Published private(set) var statePublished:State = .exerciseNotStarted1
    private(set) var state:State = .exerciseNotStarted1
    func setExerciseState(ctx:String, _ value:ExerciseState.State) {
        if value != self.state {
            self.state = value
            print("================= Exercise setState ✅", value)
            DispatchQueue.main.async {
                self.statePublished = value
            }
        }
    }
    func getState() -> State {
        return self.state
    }
    
    @Published private(set) var totalCorrectPublished: Int = 0
    var totalCorrect: Int = 0
    func bumpTotalCorrect() {
        if self.totalCorrect < self.numberToWin {
            self.totalCorrect += 1
            if self.totalCorrect == self.numberToWin {
                if ![.exerciseWon].contains(self.state) {
                    if self.totalCorrect >= self.numberToWin {
                        self.setExerciseState(ctx:"ExerciseState - SetTotalCorrect after points update \(self.totalCorrect),\(self.numberToWin)", .exerciseWon)
                    }
                }
            }
            DispatchQueue.main.async {
                self.totalCorrectPublished = self.totalCorrect
            }
//            if [ExerciseState.State.exerciseWon].contains(exerciseState.statePublished) {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    exerciseState.setExerciseState(ctx: "ExerciseHandler - ExerciseEnded", .exerciseNotStarted1)
//                }
//            }
        }
    }
    func resetTotalCorrect() {
        self.totalCorrect = 0
        DispatchQueue.main.async {
            self.totalCorrectPublished = 0
        }
    }
    
    @Published private(set) var totalIncorrect: Int = 0
    func setTotalIncorrect(_ value:Int) {
        DispatchQueue.main.async {
            self.totalIncorrect = value
        }
    }
    
    @Published private(set) var matches:[Int] = []
    func addMatch(_ value:Int) {
        DispatchQueue.main.async {
            self.matches.append(value)
        }
    }

    func removeMatch() {
        DispatchQueue.main.async {
            if !self.matches.isEmpty {
                self.matches.removeLast()
            }
        }
    }
}
