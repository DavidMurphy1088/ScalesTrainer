
import SwiftUI

public protocol PianoKeyViewModelDelegateProtocol {
    var noteMidi: Int { get }
    var scale:Scale {get}
}
                
public struct PianoKeyViewModel: Identifiable {
    let keyIndex: Int
    let delegate: PianoKeyViewModelDelegateProtocol
    public var touchDown = false
    public var latched = false

    public var id: Int {
        noteMidiNumber
    }

    public var noteMidiNumber: Int {
        keyIndex + delegate.noteMidi
    }

    public var name: String {
        Note.name(for: noteMidiNumber, preferSharps: !(delegate.scale.key.flats > 0))
    }
    
    public var finger: String {
        //var s = delegate.scale.key.name
        let scale = delegate.scale
        let midi = noteMidiNumber
        let inScale = scale.containsMidi(midi: midi) //? 1 : 0
        var fingerName = "F"
        var scaleOffset:Int? = nil
        
        if inScale {
            for i in 0..<scale.notes.count {
                if scale.notes[i] == midi {
                    fingerName = String(scale.fingers[i])
                    scaleOffset = i
                    break
                }
            }
            let off = scaleOffset == nil ? "X" : String(scaleOffset!)
            //return "\(noteMidiNumber) \(fingerName)"
            return "\(fingerName)"
        }
        else {
            return ""
        }
    }

    public var isNatural: Bool {
        let k = noteMidiNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    static func == (lhs: PianoKeyViewModel, rhs: PianoKeyViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
