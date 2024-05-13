import SwiftUI
  
//public enum PianoKeyResultStatus {
//    case none
//    case correctAscending
//    case correctDescending
//    case incorrectAscending
//    case incorrectDescending
//}

public class PianoKeyMatchedState { 
    let id = UUID()
    var matchedTimeAscending:Date? = nil
    var matchedTimeDescending:Date? = nil
    var matchedAmplitudeAscending:Double? = nil
    var matchedAmplitudeDescending:Double? = nil
    
    public init() {
    }
}

public class PianoKeyModel: Identifiable, Hashable {
    public let id = UUID()
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale = ScalesModel.shared.scale
    var keyMatchedState:PianoKeyMatchedState
    var scaleNoteState:ScaleNoteState?
    
    var isPlayingMidi = false
    var keyIndex: Int = 0
    var midi: Int

    public var touchDown = false
    public var latched = false

    init(keyboardModel:PianoKeyboardModel, keyIndex:Int, midi:Int) {
        self.keyboardModel = keyboardModel
        self.keyIndex = keyIndex
        self.keyMatchedState = PianoKeyMatchedState()
        self.midi = midi
    }
    
    public func setPlayingMidi() {
        self.keyboardModel.clearAllPlayingMidi(besidesID: self.id)
        self.isPlayingMidi = true
        if let score  = scalesModel.score {
            score.setScoreNotePlayed(midi: self.midi, direction: scalesModel.selectedDirection)
            score.clearAllPlayingNotes(besidesMidi: self.midi)
        }
        ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
        self.keyboardModel.redraw()
    }
    
    public func setPlayingKey() {
        self.keyboardModel.clearAllPlayingKey(besidesID: self.id)
        self.keyMatchedState.matchedTimeAscending = Date()
        self.keyMatchedState.matchedTimeDescending = Date()
        self.keyboardModel.redraw()
    }
    
    public var noteMidiNumber: Int {
        keyIndex + self.keyboardModel.firstKeyMidi
    }

    public var name: String {
        NoteName.name(for: noteMidiNumber, preferSharps: !(keyboardModel.scale.key.flats > 0))
    }
    
    public var finger: String {
        var fingerName = ""
        if let scaleNote = self.scaleNoteState {
            fingerName = String(scaleNote.finger)
        }
        return fingerName
    }
    
    public var isNatural: Bool {
        let k = noteMidiNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    public static func == (lhs: PianoKeyModel, rhs: PianoKeyModel) -> Bool {
        return lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
