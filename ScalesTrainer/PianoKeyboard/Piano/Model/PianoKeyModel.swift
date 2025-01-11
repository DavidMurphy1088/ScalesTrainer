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

public enum KeyboardType {
    case left
    case right
    case combined
}

public enum HandType {
    case left
    case right
}

public class PianoKeyModel: Identifiable, Hashable {
    public let id = UUID()
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale
    let score:Score
    
    ///Tracks keyboard key presses as a process like recording a scale is underway
    var keyWasPlayedState:PianoKeyPlayedState
    
    /// The note in the scale to which the key currently maps. The mapping changes between ascending and descending
    //private(set) var scaleNoteState:ScaleNoteState?
    private(set) var scaleNoteState:ScaleNoteState?

    /// The key was just played and its note is sounding
    var keyIsSounding = false
    /// How long the key stays hilighed when played
    static let keySoundingSeconds:Double = 0.5 //MetronomeModel.shared.notesPerClick == 1 ? 1.0 :
    
    var keyOffsetFromLowestKey: Int = 0
    var midi: Int
    
    var hilightKeyToFollow:PianoKeyHilightType = .none
    
    var hilightCallbackNotUSed: () -> Void = {}

    //private var playedCallback:(()->Void)?
    ///Sometimes the single key needs to call more than one callback. e.g. the key for the first note in a contrary motion scale starting on the same note.
    ///The key will need to generate a press for the LH and RH separately. 
    private var playedCallbacks:[(()->Void)?] = []
    func addCallbackFunction(fn:(()->Void)?) {
        self.playedCallbacks.append(fn)
    }
//    func getCallbackFunction() -> (()->Void)? {
//        return self.playedCallback
//    }

    public var touchDown = false
    public var latched = false
    ///A keyboard may have keys played by both LH and RH - e.g. a contray motion keyboard
    let handType:HandType

    init(scale:Scale, score:Score, keyboardModel:PianoKeyboardModel, keyIndex:Int, midi:Int, handType:HandType) {
        self.scale = scale
        self.score = score
        self.keyboardModel = keyboardModel
        self.keyOffsetFromLowestKey = keyIndex
        self.keyWasPlayedState = PianoKeyPlayedState()
        self.midi = midi
        self.handType = handType
    }

    public func setState(state: ScaleNoteState?) {
        self.scaleNoteState = state
    }
    
    ///Set a keyboard key as playing.
    ///Also hilight the associated score note.
    public func setKeyPlaying() {
        if true {
            //print("============= Set KEY Playing", "midi:", self.scaleNoteState?.midi, "keyhand:", self.hand)
            self.keyIsSounding = true
            DispatchQueue.global(qos: .background).async {
                usleep(UInt32(1000000 * PianoKeyModel.keySoundingSeconds))
                DispatchQueue.main.async {
                    self.keyIsSounding = false
                    self.keyboardModel.redraw()
                }
            }
            ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
            self.keyboardModel.redraw()
            
            if self.playedCallbacks.count > 0 {
                if let callback = self.playedCallbacks[0] {
                    callback()
                    self.playedCallbacks.removeFirst()
                }
            }
        }
    }

    public var noteMidiNumber: Int {
        keyOffsetFromLowestKey + self.keyboardModel.firstKeyMidi
    }

    func getNameDefault() -> String {
            ///Use the keysignature to determine whether the black notes are shown as sharps or flats
            ///Chromatic - use the above rule - e.g. D chromatic shows black notes as sharps (since D Maj KeySig has sharps), F chromatic shows black notes as flats
            let major = [.major, .arpeggioDominantSeventh, .arpeggioMajor, .arpeggioMajorSeventh, .brokenChordMajor].contains(scale.scaleType)
            let ks = KeySignature(keyName: scale.scaleRoot.name, keyType: major ? .major : .minor) //KeySignature(scalesModel.scale.scaleType.)
            var showSharps = ks.accidentalType == .sharp
//            if [.melodicMinor, .harmonicMinor].contains(scale.scaleType) {
//
//                ///A black note for a raised 7th or 6th should be shown as a sharp or flat based on how the corresponding staff note is displayed. (with a sharp or with a flat)
//                //if ScalesModel.shared.scores.count > 0 {
//                    //let scoreIndex = self.keyboardModel == PianoKeyboardModel.sharedRH ? 0 : 1
//                    if let score = ScalesModel.shared.getScore() {
//                        if let ts = score.getTimeSliceForMidi(midi: self.midi, occurence: 0) {
//                            let note:StaffNote = ts.entries[0] as! StaffNote
//                            //if note.noteStaffPlacements.count > 0 {
//                            if note.noteStaffPlacement.accidental == 1 {
//                                showSharps = true
//                            }
//                            //}
//                        }
//                    }
//                //}
//            }
            return NoteName.name(for: noteMidiNumber, showSharps: showSharps)
        }
    
    func getName() -> String {
        var handType = self.handType
        var (staffNote, staffClef) = score.getNoteAndClefForMidi(midi: self.midi, handType: handType, occurence: 0)
        var name = ""

        if let staffNote = staffNote {
            if staffNote.noteStaffPlacement.placementSetByKeySignature == true {
                name = getNameDefault()
            }
            else {
                name = getNameCustom(staffNote: staffNote, staffClef: staffClef, handType: handType)
            }
        }
        return name
    }
    
    ///Get the key name and accidentals from the staff note that it represents.
    ///The staff notation is the canonical representation since it contains any customisations for note name and accidental display.
    ///The notes name is derived from the note's offset on the stave.
    ///A staff may have had a clef switch in that applies to the key's note.
    func getNameCustom(staffNote:StaffNote, staffClef:StaffClef?, handType:HandType) -> String {
        var name = ""
        let handIndex:Int
        
        ///Check if the bass staff has a treble clef switched in
        let clefType:ClefType
        if let staffClef = staffClef {
            clefType = staffClef.clefType
        }
        else {
            clefType = handType == .left ? ClefType.bass : .treble
        }
    
        let placement = staffNote.noteStaffPlacement
        var offset = (abs(placement.offsetFromStaffMidline) % 7)
        offset = offset * (placement.offsetFromStaffMidline >= 0 ? 1 : -1)
        var noteNameUnicode = 0
        var base = ""

        if clefType == .treble {
            base = "B"
            if offset > 5 {
                offset = offset - 7
            }
            if offset < -1 {
                offset = offset + 7
            }
        }
        else {
            base = "D"
            if offset > 3 {
                offset = offset - 7
            }
            if offset < -3 {
                offset = offset + 7
            }
        }
        if let asciiValue = base.first?.asciiValue {
            noteNameUnicode = Int(asciiValue) + offset
            if let scalar = UnicodeScalar(noteNameUnicode) {
                name = String(Character(scalar))
            }
        }
        if placement.accidental == 1 {
            name += "#"
        }
        if placement.accidental == 2 {
            name += "\u{1D12A}" //double sharp
        }
        if placement.accidental == -1 {
            name += "♭"
        }
        return name
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
