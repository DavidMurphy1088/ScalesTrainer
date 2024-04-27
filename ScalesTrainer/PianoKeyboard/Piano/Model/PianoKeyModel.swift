
import SwiftUI

public protocol PianoKeyViewModelDelegateProtocol {
    var firstKeyMidi: Int { get }
    var scale:Scale {get}
}
                
public struct PianoKeyModel: Identifiable {
    let scalesModel = ScalesModel.shared
    let scale:Scale
    
    ///A key in the scale is associated with a scale note state based on if the scale is ascending or descending
    //@ObservedObject
    var midiState:ScaleNoteState? = nil
    
    let keyIndex: Int
    let delegate: PianoKeyViewModelDelegateProtocol
    
    public var touchDown = false
    public var latched = false

    public var id: Int {
        noteMidiNumber
    }

    public var noteMidiNumber: Int {
        keyIndex + delegate.firstKeyMidi
    }

    public var name: String {
        Note.name(for: noteMidiNumber, preferSharps: !(delegate.scale.key.flats > 0))
    }
    
    func sequence(midi:Int) -> Int {
        for i in 0..<scale.scaleNoteStates.count {
            if scale.scaleNoteStates[i].midi == midi {
                return i
            }
        }
        return 0
    }
    
    public var finger: String {
        let midi = noteMidiNumber
        let inScale = scale.getMidiIndex(midi: midi, direction: scalesModel.selectedDirection) != nil

        if inScale {
            //let off = scaleOffset == nil ? "X" : String(scaleOffset!)
            //return "\(noteMidiNumber) \(fingerName)"
            let seq = sequence(midi: midi)
            let fingerName = String(scale.scaleNoteStates[seq].finger)
            return "\(fingerName)"
        }
        else {
            return ""
        }
    }
    
    public var fingerSequenceBreak: Bool {
        //let scale = delegate.scale
        let midi = noteMidiNumber
        var seq = sequence(midi: midi)
        if scalesModel.selectedDirection == 1 {
            ///Finger breaks are at one note below the ascending break
            seq = seq + 1
        }
        if seq < 0 {
            return false
        }
        else {
            return scale.scaleNoteStates[seq].fingerSequenceBreak
        }
    }
    
//    public var isPlayingMidi: Bool {
////        let scale = delegate.scale
////        let midi = noteMidiNumber
////        //var seq = sequence(midi: midi)
////        print("====", noteMidiNumber, "State", midiState.midi, midiState.isPlayingMidi)
//        return midiState.isPlayingMidi
//    }

    public var isNatural: Bool {
        let k = noteMidiNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    static func == (lhs: PianoKeyModel, rhs: PianoKeyModel) -> Bool {
        lhs.id == rhs.id
    }
}
