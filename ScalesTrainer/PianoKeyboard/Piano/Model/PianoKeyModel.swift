import SwiftUI
  
public enum PianoKeyResultStatus {
    case none
    case correctAscending
    case correctDescending
    case incorrectAscending
    case incorrectDescending
}

public class PianoKeyState { //}: ObservableObject, Hashable {
    let id = UUID()
    var matchedTimeAscending:Date? = nil
    var matchedTimeDescending:Date? = nil
    var matchedAmplitudeAscending:Double? = nil
    var matchedAmplitudeDescending:Double? = nil
    
    public init() {
    }
}

public class PianoKeyModel: Identifiable {
    public let id = UUID()
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale = ScalesModel.shared.scale
    
    var noteFingering:ScaleNoteFinger?
    var isPlayingMidi = false
    var state:PianoKeyState
    var keyIndex: Int = 0
    var midi: Int

    public var touchDown = false
    public var latched = false

    init(keyboardModel:PianoKeyboardModel, keyIndex:Int, midi:Int) {
        self.keyboardModel = keyboardModel
        self.keyIndex = keyIndex
        self.state = PianoKeyState()
        self.midi = midi
    }
    
//    public func setStatusForScalePlay(_ way:PianoKeyResultStatus) {
//        //self.resultStatus = way
//        self.keyboardModel.redraw()
//    }
    
    public func setPlayingMidi(_ ctx:String) {
        self.keyboardModel.clearAllPlayingMidi(besidesID: self.id)
        ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
        self.isPlayingMidi = true
        self.keyboardModel.redraw()
    }
    
//    public var id: Int {
//        noteMidiNumber
//    }

    public var noteMidiNumber: Int {
        keyIndex + self.keyboardModel.firstKeyMidi
    }

    public var name: String {
        Note.name(for: noteMidiNumber, preferSharps: !(keyboardModel.scale.key.flats > 0))
    }
    
    public var finger: String {
        var fingerName = ""
        if let scaleNote = self.noteFingering {
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
