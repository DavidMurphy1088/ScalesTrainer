import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject {
    public static var sharedRightHand = PianoKeyboardModel()
    public static var sharedLeftHand = PianoKeyboardModel()
    public static var sharedForSettings = PianoKeyboardModel()

    @Published public var forceRepaint1 = 0 ///Without this the key view does not update when pressed
    let scalesModel = ScalesModel.shared
    public var pianoKeyModel: [PianoKeyModel] = []

    public var firstKeyMidi = 60
    private var nextKeyToPlayIndex:Int?
    private var ascending = true
    
    @Published public var latch = false {
        didSet { resetKeyDownKeyUpState() }
    }
    
    public var keyRects: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    
    public init() {
        self.pianoKeyModel = []
        self.keyRects = []
    }
    
    func clearAllKeyWasPlayedState(besidesID:UUID? = nil) {
        if let last = self.pianoKeyModel.first(where: { $0.keyWasPlayedState.tappedTimeAscending != nil || $0.keyWasPlayedState.tappedTimeDescending != nil}) {
            if besidesID == nil || last.id != besidesID! {
                DispatchQueue.global(qos: .background).async { [self] in
                    usleep(1000000 * UInt32(0.7))
                    last.keyWasPlayedState.tappedTimeAscending = nil
                    last.keyWasPlayedState.tappedTimeDescending = nil
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
    
    func getKeyBoardSize(scale:Scale) -> (first:Int, numberKeys:Int) {
        var firstKeyMidi = scale.scaleNoteState[0].midi
        
        ///Decide first key to show on the keyboard - either the F key or the C key
        switch self.scalesModel.scale.scaleRoot.name {
        case "C#":
            firstKeyMidi -= 1
        case "D♭":
            firstKeyMidi -= 1
        case "D":
            firstKeyMidi -= 2
        case "E♭":
            firstKeyMidi -= 3
        case "E":
            firstKeyMidi -= 4
            
        case "G♭":
            firstKeyMidi -= 1
        case "F#":
            firstKeyMidi -= 1
        case "G":
            firstKeyMidi -= 2
        case "A♭":
            firstKeyMidi -= 3
        case "A":
            firstKeyMidi -= 4
        case "B♭":
            firstKeyMidi -= 5
        case "B":
            firstKeyMidi -= 6

        default:
            firstKeyMidi -= 0
        }
                
        //var numKeys = (self.scalesModel.octaveNumberValues[self.scalesModel.selectedOctavesIndex] * 12) + 1
        //let octaves = scale.octaves
        var numKeys = (scale.octaves * 12) + 1
        numKeys += 2
        if ["E", "G", "A", "A♭", "E♭"].contains(self.scalesModel.scale.scaleRoot.name) {
            numKeys += 4
        }
        if ["B", "B♭"].contains(self.scalesModel.scale.scaleRoot.name) {
            numKeys += 6
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(self.scalesModel.scale.scaleType) {
            numKeys += 4
        }
        return (firstKeyMidi, numKeys)
    }
    
    func configureKeyboardForScale(scale:Scale) {
        (self.firstKeyMidi, self.numberOfKeys) = getKeyBoardSize(scale: scale)
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
        }
        self.linkScaleFingersToKeyboardKeys(scale: scale, direction: ScalesModel.shared.selectedDirection)
    }
    
    func configureKeyboardForScaleStartView(start:Int, numberOfKeys:Int, scaleStartMidi:Int) {
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        self.firstKeyMidi = start
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
            if pianoKeyModel.midi == scaleStartMidi {
                let keyState = ScaleNoteState(sequence: 0, midi: scaleStartMidi, value: 1)
                ///Mark the start of scale
                keyState.finger = 9
                pianoKeyModel.scaleNoteState = keyState
            }
        }
        //let key = self.pianoKeyModel[i]
        //key[10].scaleNoteState = ScaleNoteState()
        //self.linkScaleFingersToKeyboardKeys(scale: scale, direction: ScalesModel.shared.selectedDirection)
    }

    ///Create the link for each piano key to a scale note, if there is one.
    ///Mapping may be different for descending - e.g. melodic minor needs different mapping of scale notes for descending
    public func linkScaleFingersToKeyboardKeys(scale:Scale, direction:Int) {
        for i in 0..<numberOfKeys {
            if i < self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                key.scaleNoteState = scale.getStateForMidi(midi: key.midi, direction: direction)
            }
        }
    }
    
    func debugSize11(_ ctx:String) {
        print("========================= Keyboard Size === \(ctx)", "lowMidi", self.pianoKeyModel[0].midi, "hiMidi", self.pianoKeyModel[self.pianoKeyModel.count-1].midi)
    }
    
    func debug111(_ ctx:String) {
        print("=== Keyboard status === \(ctx)")
        for i in 0..<numberOfKeys {
            let key = self.pianoKeyModel[i]
            print(String(format: "%02d",i), "keyOffset:", String(format: "%02d",key.keyOffsetFromLowestKey), "midi:", key.midi, terminator: "")
            print("   ascMatch:", key.keyWasPlayedState.tappedTimeAscending != nil, "descMatch:", key.keyWasPlayedState.tappedTimeDescending != nil, terminator: "")
            if let state = key.scaleNoteState {
                print("  finger:", state.finger, "fingerBreak:", state.fingerSequenceBreak, terminator: "")
            }
            print("")
        }
    }
    
    public func updateKeysForUpDown() {
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
                    pianoKeyModel[index].setKeyPlaying(ascending: scalesModel.selectedDirection, hilight: true)
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
            pianoKeyModel[i].keyIsSounding = false
        }
    }
    
    public func resetKeysWerePlayedState() {
        for i in 0..<numberOfKeys {
            if i < pianoKeyModel.count {
                pianoKeyModel[i].keyWasPlayedState.tappedTimeAscending = nil
                pianoKeyModel[i].keyWasPlayedState.tappedTimeDescending = nil
            }
        }
    }
    
    public func clearAllFollowingKeyHilights(except:Int?) {
        for i in 0..<numberOfKeys {
            if except == nil || i != except {
                pianoKeyModel[i].hilightFollowingKey = false
            }
        }
    }
    
    public func unmapScaleFingersToKeyboard() {
        for i in 0..<numberOfKeys {
            let key = self.pianoKeyModel[i]
            key.scaleNoteState = nil
        }
    }
    
    ///Get the offset in the keyboard for the given midi
    ///For ascending C 1-octave returns C 60 to C 72 inclusive = 8 notes
    ///For descending C 1-octave returns same 8 notes
    public func getKeyIndexForMidi(midi:Int, direction:Int) -> Int? {
        let x = self.pianoKeyModel.first(where: { $0.midi == midi })
        return x == nil ? nil : x?.keyOffsetFromLowestKey
    }
}
