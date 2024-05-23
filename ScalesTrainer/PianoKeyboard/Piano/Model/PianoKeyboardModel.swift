import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject, MetronomeTimerNotificationProtocol {
    public static var shared = PianoKeyboardModel()
    let scalesModel = ScalesModel.shared
    @Published public var pianoKeyModel: [PianoKeyModel] = []
    @Published public var forceRepaint1 = 0 ///Without this the key view does not update when pressed

    public var scale:Scale = ScalesModel.shared.scale
    public var firstKeyMidi = 60
    private var nextKeyToPlayIndex:Int?
    private var ascending = true
    
    @Published public var latch = false {
        didSet { resetKeyDownKeyUpState() }
    }
    
    public var keyRects: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    
    public init() {
    }
    
    ///MetronomeTimerNotificationProtocol
    func metronomeStart() {
        resetKeyDownKeyUpState()
        scalesModel.setDirection(0)
        ascending = true
        nextKeyToPlayIndex = nil
        //self.debug2("start")
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        let audioManager = AudioManager.shared
        let sampler = audioManager.midiSampler

        ///Playing the app's scale
        if timerTickerNumber < ScalesModel.shared.scale.scaleNoteState.count {
            let scaleNote = ScalesModel.shared.scale.scaleNoteState[timerTickerNumber]
            if let keyIndex = getKeyIndexForMidi(midi:scaleNote.midi, direction:0) {
                self.pianoKeyModel[keyIndex].setPlayingMidi(ascending: scalesModel.selectedDirection)
            }
            sampler.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
            //scalesModel.setPianoKeyPlayed(midi: scaleNote.midi)
            ///Scale turnaround
            if timerTickerNumber == ScalesModel.shared.scale.scaleNoteState.count / 2 {
                scalesModel.setDirection(1)
                //scalesModel.forceRepaint()
                //setFingers(direction: 1)
            }
        }
        return timerTickerNumber >= ScalesModel.shared.scale.scaleNoteState.count - 1
    }
    
    func metronomeStop() {
        scalesModel.setDirection(0)
    }
        
    func clearAllPlayingKey(besidesID:UUID? = nil) {
        if let last = self.pianoKeyModel.first(where: { $0.keyClickedState.tappedTimeAscending != nil || $0.keyClickedState.tappedTimeDescending != nil}) {
            if besidesID == nil || last.id != besidesID! {
                DispatchQueue.global(qos: .background).async { [self] in
                    usleep(1000000 * UInt32(0.7))
                    last.keyClickedState.tappedTimeAscending = nil
                    last.keyClickedState.tappedTimeDescending = nil
                    self.redraw()
                }
            }
        }
    }
    
    func redraw() {
        DispatchQueue.main.async {
            self.forceRepaint1 += 1
        }
    }
    
    public var numberOfKeys = 18
    
    public var naturalKeyCount: Int {
        pianoKeyModel.filter { $0.isNatural }.count
    }

    var touches: [CGPoint] = [] {
        didSet { updateKeysForUpDown() }
    }

    func naturalKeyWidth(_ width: CGFloat, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }
    
    func configureKeyboardSize() {
        self.scale = self.scalesModel.scale
        self.firstKeyMidi = scale.scaleNoteState[0].midi
        
        ///Decide first key to show on the keyboard - either the F key or the C key
        switch self.scalesModel.scale.key.name {
        case "D♭":
            self.firstKeyMidi -= 1
        case "D":
            self.firstKeyMidi -= 2
        case "E♭":
            self.firstKeyMidi -= 3
        case "E":
            self.firstKeyMidi -= 4
            
        case "G":
            self.firstKeyMidi -= 2
        case "A♭":
            self.firstKeyMidi -= 3
        case "A":
            self.firstKeyMidi -= 4
        case "B♭":
            self.firstKeyMidi -= 5
        case "B":
            self.firstKeyMidi -= 6

        default:
            self.firstKeyMidi -= 0
        }
                
        var numKeys = (self.scalesModel.octaveNumberValues[self.scalesModel.selectedOctavesIndex] * 12) + 1
        numKeys += 2
        if ["E", "G", "A", "A♭", "E♭"].contains(self.scalesModel.scale.key.name) {
            numKeys += 4
        }
        if ["B", "B♭"].contains(self.scalesModel.scale.key.name) {
            numKeys += 6
        }
        self.numberOfKeys = numKeys
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
        }
        self.mapScaleFingersToKeyboard(direction: ScalesModel.shared.selectedDirection)
    }
    
    ///Create the map for each piano key to a scale note, if there is one.
    ///Mapping may be different for descending - e.g. melodic minor needs different mapping of scale notes for descending
    public func mapScaleFingersToKeyboard(direction:Int) {
        for i in 0..<numberOfKeys {
            let key = self.pianoKeyModel[i]
            key.scaleNoteState = scale.getStateForMidi(midi: key.midi, direction: direction)
        }
    }
    
//    func debug3(_ ctx:String) {
//        print("=== Keyboard status === \(ctx)")
//        for i in 0..<numberOfKeys {
//            let key = self.pianoKeyModel[i]
//            print(key.keyIndex, "midi:", key.midi, "finger:", key.scaleNoteState?.finger ?? "_____",
//                  "fingerBreak:", key.scaleNoteState?.fingerSequenceBreak ?? "", terminator: "")
//            print("\tascMatch", key.keyClickedState.tappedTimeAscending != nil, "\tdescMatch", key.keyClickedState.tappedTimeDescending != nil)
//        }
//    }
    
    private func updateKeysForUpDown() {
        var keyDownAt = Array(repeating: false, count: numberOfKeys)

        for touch in touches {
            if let index = getKeyContaining(touch) {
                keyDownAt[index] = true
            }
        }
        ///👉 😡 Do not remove this repaint. Removing it causes keydowns on the keyboard not to draw the down or up state changes
        self.forceRepaint1 += 1
        for index in 0..<numberOfKeys {
            let noteNumber = pianoKeyModel[index].noteMidiNumber

            if pianoKeyModel[index].touchDown != keyDownAt[index] {
                if latch {
                    let keyLatched = pianoKeyModel[index].latched

                    if keyDownAt[index] && keyLatched {
                        keyboardAudioManager?.pianoKeyUp(noteNumber)
                        pianoKeyModel[index].latched = false
                        pianoKeyModel[index].touchDown = false
                        
                    }
                    if keyDownAt[index] && !keyLatched {
                        keyboardAudioManager?.pianoKeyDown(noteNumber)
                        pianoKeyModel[index].latched = true
                        pianoKeyModel[index].touchDown = true
                    }

                } else {
                    if keyDownAt[index] {
                        keyboardAudioManager?.pianoKeyDown(noteNumber)
                        
                    } else {
                        keyboardAudioManager?.pianoKeyUp(noteNumber)
                    }
                    pianoKeyModel[index].touchDown = keyDownAt[index]
                    pianoKeyModel[index].setPlayingMidi(ascending: scalesModel.selectedDirection)
                }
            } else {
                if pianoKeyModel[index].touchDown && keyDownAt[index] && pianoKeyModel[index].latched {
                    keyboardAudioManager?.pianoKeyUp(noteNumber)
                    pianoKeyModel[index].latched = false
                    pianoKeyModel[index].touchDown = false
                }
            }
        }
    }

    private func getKeyContaining(_ point: CGPoint) -> Int? {
        var keyNum: Int?
        for index in 0..<numberOfKeys {
            if keyRects[index].contains(point) {
                keyNum = index
                if !pianoKeyModel[index].isNatural {
                    break
                }
            }
        }
        return keyNum
    }

    public func resetKeyDownKeyUpState() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].touchDown = false
            pianoKeyModel[i].latched = false
            keyboardAudioManager?.pianoKeyUp(pianoKeyModel[i].noteMidiNumber)
            pianoKeyModel[i].isPlayingMidi = false
        }
    }
    
    public func resetScaleMatchState() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].keyClickedState.tappedTimeAscending = nil
            pianoKeyModel[i].keyClickedState.tappedTimeDescending = nil
        }
    }
    
    public func clearAllKeyHilights() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].hilightKey = false
        }
    }

    ///Get the offset in the keyboard for the given midi
    ///The search is direction specific since melodic minors have different notes in the descending direction
    ///For ascending C 1-octave returns C 60 to C 72 inclusive = 8 notes
    ///For descending C 1-octave returns same 8 notes
    public func getKeyIndexForMidi(midi:Int, direction:Int) -> Int? {
        let x = self.pianoKeyModel.first(where: { $0.midi == midi })
        return x == nil ? nil : x?.keyIndex
    }
}
