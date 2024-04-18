
import SwiftUI

public protocol PianoKeyViewModelDelegateProtocol {
    var noteMidi: Int { get }
}
                
public struct PianoKeyViewModel: Identifiable {
    let keyIndex: Int
    let delegate: PianoKeyViewModelDelegateProtocol
    //let scale:Scale
    public var touchDown = false
    public var latched = false

    public var id: Int {
        noteNumber
    }

    public var noteNumber: Int {
        keyIndex + delegate.noteMidi
    }

    public var name: String {
        Note.name(for: noteNumber)
    }
    
    public var finger: String {
        "\(keyIndex)"
    }

    public var isNatural: Bool {
        let k = noteNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    static func == (lhs: PianoKeyViewModel, rhs: PianoKeyViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
