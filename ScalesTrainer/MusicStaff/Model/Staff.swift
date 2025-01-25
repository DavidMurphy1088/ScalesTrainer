import Foundation
import AVKit
import AVFoundation

public class Staff : ObservableObject, Identifiable {
    @Published var publishUpdate = 0
    @Published var notePositionsUpdates = 0
    @Published public var noteLayoutPositions:NoteLayoutPositions
    
    public let id = UUID()
    let score:Score
    public var handType:HandType
    public var linesInStaff:Int

    public init(score:Score, handType:HandType, linesInStaff:Int) {
        self.score = score
        self.handType = handType
        self.linesInStaff = linesInStaff
        self.noteLayoutPositions = NoteLayoutPositions()
        //self.setPlacements()
    }
    
    func update() {
        DispatchQueue.main.async {
            self.publishUpdate += 1
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.publishUpdate = 0
        }
    }

}

