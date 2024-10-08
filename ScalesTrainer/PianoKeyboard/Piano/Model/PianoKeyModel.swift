import SwiftUI
  
public class PianoKeyPlayedState { 
    let id = UUID()
    var tappedTimeAscending:Date? = nil
    var tappedTimeDescending:Date? = nil
    var tappedAmplitudeAscending:Double? = nil
    var tappedAmplitudeDescending:Double? = nil
    
    public init() {
    }
}

public enum PianoKeyHilightType {
    case none
    case followThisNote
    case middleOfKeyboard
}

public class PianoKeyModel: Identifiable, Hashable {
    public let id = UUID()
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale = ScalesModel.shared.scale
    
    ///Tracks keyboard key presses as a process like recording a scale is underway
    var keyWasPlayedState:PianoKeyPlayedState
    
    /// The note in the scale to which the key currently maps. The mapping changes between ascending and descending
    //private(set) var scaleNoteState:ScaleNoteState?
    private(set) var scaleNoteState:ScaleNoteState?

    /// The key was just played and its note is sounding
    var keyIsSounding = false
    /// How long the key stays hilighed when played
    let keySoundingSeconds:Double = 0.5 //MetronomeModel.shared.notesPerClick == 1 ? 1.0 : 
    
    var keyOffsetFromLowestKey: Int = 0
    var midi: Int
    
    var hilightKeyToFollow:PianoKeyHilightType = .none
    var hilightCallbackNotUSed: () -> Void = {}

    var wasPlayedCallback:(()->Void)?
    
    public var touchDown = false
    public var latched = false
    ///A keyboard may have keys played by both LH and RH - e.g. a contray motion keyboard
    var hand:Int

    init(keyboardModel:PianoKeyboardModel, keyIndex:Int, midi:Int) {
        self.keyboardModel = keyboardModel
        self.keyOffsetFromLowestKey = keyIndex
        self.keyWasPlayedState = PianoKeyPlayedState()
        self.midi = midi
        self.hand = keyboardModel.keyboardNumber - 1
    }

    public func setState(state: ScaleNoteState?) {
        self.scaleNoteState = state
    }
    
    //public func setKeyPlaying(ascending:Int, hilight:Bool) {
    public func setKeyPlaying(hilight:Bool) {
        if hilight {
            self.keyIsSounding = true
            DispatchQueue.global(qos: .background).async {
                usleep(UInt32(1000000 * self.keySoundingSeconds))
                DispatchQueue.main.async {
                    self.keyIsSounding = false
                    self.keyboardModel.redraw()
                }
            }
            ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
            self.keyboardModel.redraw()

            ///Update the stave(s) if its showing
            ///The MIDI might be in both staves. e.g. first note of a contrary scale.
            for i in 0..<scalesModel.scores.count {
                //if let score = scalesModel.scores[self.hand] {
                if let score = scalesModel.scores[i] {
                    let segment = self.scaleNoteState?.segments[0]
                    if let segment = segment {
                        if let staffNote = score.setScoreNotePlayed(midi: self.midi, segment:segment) {
                            DispatchQueue.global(qos: .background).async {
                                usleep(UInt32(1000000 * self.keySoundingSeconds))
                                DispatchQueue.main.async {
                                    staffNote.setShowIsPlaying(false)
                                }
                            }
                        }
                    }
                }
            }
        }
        if let callback = self.wasPlayedCallback {
            callback()
        }
    }

    public var noteMidiNumber: Int {
        keyOffsetFromLowestKey + self.keyboardModel.firstKeyMidi
    }

    public var name: String {
        ///Use the keysignature to determine whether the black notes are shown as sharps or flats
        ///Chromatic - use the above rule - e.g. D chromatic shows black notes as sharps (since D Maj KeySig has sharps), F chromatic shows black notes as flats
        let major = [.major, .arpeggioDominantSeventh, .arpeggioMajor, .arpeggioMajorSeventh, .brokenChordMajor].contains(scale.scaleType)
        let ks = KeySignature(keyName: scale.scaleRoot.name, keyType: major ? .major : .minor) //KeySignature(scalesModel.scale.scaleType.)
        var showSharps = ks.accidentalType == .sharp
        if [.melodicMinor, .harmonicMinor].contains(scale.scaleType) {

            ///A black note for a raised 7th or 6th should be shown as a sharp or flat based on how the corresponding staff note is displayed. (with a sharp or with a flat)
            if ScalesModel.shared.scores.count > 0 {
                let scoreIndex = self.keyboardModel == PianoKeyboardModel.sharedRH ? 0 : 1
                if let score = ScalesModel.shared.scores[scoreIndex] {
                    if let ts = score.getTimeSliceForMidi(midi: self.midi, occurence: 0) {
                        let note:StaffNote = ts.entries[0] as! StaffNote
                        if note.noteStaffPlacements.count > 0 {
                            let notePlacement = note.noteStaffPlacements[0]
                            if let notePlacement = notePlacement {
                                if notePlacement.accidental == 1 {
                                    showSharps = true
                                }
                            }
                        }
                    }
                }
            }
        }
        return NoteName.name(for: noteMidiNumber, showSharps: showSharps)
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
