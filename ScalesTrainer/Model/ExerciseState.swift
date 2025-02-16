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
        case exerciseNotStarted
        case exerciseStarted
        case lost
        case won
        case wonAndFinished
    }
    
    func pointsNeededToWin() -> Int {
        return numberToWin - totalCorrect
    }
    
    @Published private(set) var statePublished:State = .exerciseNotStarted
    private var state:State = .exerciseNotStarted
    func setExerciseState(ctx:String, _ value:ExerciseState.State) {
        if value != self.state {
            self.state = value
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
        if totalCorrect < self.numberToWin {
            self.totalCorrect += 1
            if self.totalCorrect == self.numberToWin {
                if ![.won, .wonAndFinished].contains(self.state) {
                    if self.totalCorrect >= self.numberToWin {
                        self.setExerciseState(ctx:"ExerciseState - SetTotalCorrect after points update \(self.totalCorrect),\(self.numberToWin)", .won)
                    }
                }
            }

            DispatchQueue.main.async {
                self.totalCorrectPublished = self.totalCorrect
            }
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
