
import SwiftUI

public protocol PianoKeyViewModelDelegateProtocol {
    var firstKeyMidi: Int { get }
    var scale:Scale {get}
}
                
public class PianoKeyModel: Identifiable {
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let scale:Scale
    
    ///A key on the piano is associated with a scale note state based on if the scale is ascending or descending
    var scaleNote:ScaleNoteState?
    
    var keyIndex: Int = 0
    let delegate: PianoKeyViewModelDelegateProtocol
    
    public var touchDown = false
    public var latched = false

    init(scale:Scale, scaleNote:ScaleNoteState?, keyIndex:Int, delegate: PianoKeyViewModelDelegateProtocol) {
        self.scale = scale
        self.scaleNote = scaleNote
        self.delegate = delegate
        self.keyIndex = keyIndex
    }
    
    public var id: Int {
        noteMidiNumber
    }

    public var noteMidiNumber: Int {
        keyIndex + delegate.firstKeyMidi
    }

    public var name: String {
        Note.name(for: noteMidiNumber, preferSharps: !(delegate.scale.key.flats > 0))
    }
    
    public var finger: String {
        let midi = noteMidiNumber
        var fingerName = ""
        if let scaleNote = self.scaleNote {
            //let off = scaleOffset == nil ? "X" : String(scaleOffset!)
            //return "\(noteMidiNumber) \(fingerName)"
            //let seq = sequence(midi: midi)
            
            //let fingerName = String(scale.scaleNoteStates[seq].finger)
            fingerName = String(scaleNote.finger)
        }
        return fingerName
    }
    
    public var isNatural: Bool {
        let k = noteMidiNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    static func == (lhs: PianoKeyModel, rhs: PianoKeyModel) -> Bool {
        lhs.id == rhs.id
    }
}
