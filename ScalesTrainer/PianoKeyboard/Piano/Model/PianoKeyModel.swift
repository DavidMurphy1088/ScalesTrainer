import SwiftUI
  
public class PianoKeyModel: Identifiable {
    ///ObservableObject - no point since the drawing of all keys is done by a single context struct that cannot listen to @Published
    let scalesModel = ScalesModel.shared
    let keyboardModel:PianoKeyboardModel
    let scale:Scale
    
    ///A key on the piano is associated with a scale note state based on if the scale is ascending or descending
    var scaleNote:ScaleNoteState?
    var isPlayingMidi = false
    
    var keyIndex: Int = 0
    
    public var touchDown = false
    public var latched = false

    init(keyboardModel:PianoKeyboardModel, scale:Scale, keyIndex:Int) {
        self.scale = scale
        self.keyboardModel = keyboardModel
        //self.scaleNote = scaleNote
        //self.delegate = delegate
        self.keyIndex = keyIndex
    }
    
    public func setPlayingMidi(_ ctx:String) {
        //DispatchQueue.main.async {
        ///Canvas is direct draw, not background thread draw)
        //print(" ON=========================>>\(ctx)", self.id, "last", self.keyboardModel.lastKeyPlayed?.id ?? "None")
        self.isPlayingMidi = true
        
        if let last = self.keyboardModel.lastKeyPlayed {
            if last.id != self.id {
                //DispatchQueue.main.async {.
                DispatchQueue.global(qos: .background).async { [self] in
                    usleep(1000000 * UInt32(0.5))
                    //sleep(1)
                    //print("OFF=========================\(ctx)", last.id)
                    last.isPlayingMidi = false
                    self.keyboardModel.redraw()
                }
            }
        }
        ///🤚 keyboard cannot redraw just one key... the key model is not observable so redraw whole keyboard is required
        self.keyboardModel.redraw()
        self.keyboardModel.lastKeyPlayed = self
    }
    
    public var id: Int {
        noteMidiNumber
    }

    public var noteMidiNumber: Int {
        keyIndex + self.keyboardModel.firstKeyMidi
    }

    public var name: String {
        Note.name(for: noteMidiNumber, preferSharps: !(keyboardModel.scale.key.flats > 0))
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
