import Foundation
import AVFoundation
import Combine
import SwiftUI

class ExerciseState : ObservableObject {
    static let shared = ExerciseState()
    var numberToWin = 0
    
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
    
    @Published private(set) var state: State = .exerciseNotStarted
    func setExerciseState(_ ctx:String, _ value:ExerciseState.State) {
        DispatchQueue.main.async {
            print("==== state change ctx:", ctx, self.state, "-->", value)
            self.state = value
        }
    }
    
    @Published private(set) var totalCorrectPublished: Int = 0
    var totalCorrect: Int = 0
    func setTotalCorrect(_ value:Int) {
        self.totalCorrect = value
        DispatchQueue.main.async {
            self.totalCorrectPublished = self.totalCorrect
            if self.state != .won {
                if self.totalCorrect >= self.numberToWin {
                    self.setExerciseState("ExerciseState - setTotalCorrect", .won)
                }
            }
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
