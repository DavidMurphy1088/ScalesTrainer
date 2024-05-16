import SwiftUI
  
public class PianoKeyClickedState { 
    let id = UUID()
    var tappedTimeAscending:Date? = nil
    var tappedTimeDescending:Date? = nil
    var tappedAmplitudeAscending:Double? = nil
    var tappedAmplitudeDescending:Double? = nil
    
    public init() {
    }
}

public class PianoKeyModel: Identifiable, Hashable {
    public let id = UUID()
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale = ScalesModel.shared.scale
    var keyClickedState:PianoKeyClickedState
    var scaleNoteState:ScaleNoteState?
    
    var isPlayingMidi = false
    var keyIndex: Int = 0
    var midi: Int

    public var touchDown = false
    public var latched = false

    init(keyboardModel:PianoKeyboardModel, keyIndex:Int, midi:Int) {
        self.keyboardModel = keyboardModel
        self.keyIndex = keyIndex
        self.keyClickedState = PianoKeyClickedState()
        self.midi = midi
    }
    
    public func setPlayingMidi(ascending:Int) {
        //self.keyboardModel.clearAllPlayingMidi(besidesID: self.id)
        self.isPlayingMidi = true
        DispatchQueue.global(qos: .background).async {
            usleep(1000000 * UInt32(1.0))
            DispatchQueue.main.async {
                self.isPlayingMidi = false
                self.keyboardModel.redraw()
            }
        }
        ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
        self.keyboardModel.redraw()

        if let score  = scalesModel.score {
            if let note = score.setScoreNotePlayed(midi: self.midi, direction: ascending) {
                //score.clearAllPlayingNotes(besidesMidi: self.midi)
                DispatchQueue.global(qos: .background).async {
                    usleep(1000000 * UInt32(1.0))
                    DispatchQueue.main.async {
                        note.setStatus(status: .none)
                    }
                }
            }
        }
    }
    
//    public func setPlayingKey() {
//        self.keyboardModel.clearAllPlayingKey(besidesID: self.id)
//        self.keyMatchedState.matchedTimeAscending = Date()
//        self.keyMatchedState.matchedTimeDescending = Date()
//        self.keyboardModel.redraw()
//    }
    
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
