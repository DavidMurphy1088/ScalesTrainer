
import SwiftUI

public protocol PianoKeyViewModelDelegateProtocol {
    var noteMidi: Int { get }
    var scale:Scale {get}
}
                
public struct PianoKeyViewModel: Identifiable {
    let scalesModel = ScalesModel.shared
    //@ObservedObject
    let scale:Scale
    @ObservedObject var midiState:ScaleNoteState
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
    
    func sequence(midi:Int) -> Int {
        //let scale = delegate.scale
        for i in 0..<scale.scaleNoteStates.count {
            if scale.scaleNoteStates[i].midi == midi {
                //fingerName = String(scale.fingers[i])
                //scaleOffset = i
                return i
            }
        }
        return 0
    }
    
    public var finger: String {
        //let scale = delegate.scale
        let midi = noteMidiNumber
        let inScale = scale.containsMidi(midi: midi) //? 1 : 0
        
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

    static func == (lhs: PianoKeyViewModel, rhs: PianoKeyViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
