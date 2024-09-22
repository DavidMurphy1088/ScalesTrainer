import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject, Equatable {
    
    public static var sharedRH = PianoKeyboardModel(keyboardNumber: 1)
    public static var sharedLH = PianoKeyboardModel(keyboardNumber: 2)
    public static var sharedCombined:PianoKeyboardModel?
    
    public static var sharedForSettings = PianoKeyboardModel(keyboardNumber: 2)

    let id = UUID()
    @Published public var forceRepaint = 0 ///Without this the key view does not update when pressed
    let scalesModel = ScalesModel.shared
    private(set) var pianoKeyModel: [PianoKeyModel] = []

    public var firstKeyMidi = 60
    private var nextKeyToPlayIndex:Int?
    private var ascending = true
    var keyboardNumber:Int ////😡 the lowest value is 1. If changed to 0 remove all the ' -1' in the code that uses it
    
    @Published public var latch = false {
        didSet { resetKeyDownKeyUpState() }
    }
    
    public var keyRects: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    
    private init(keyboardNumber:Int) {
        self.pianoKeyModel = []
        self.keyRects = []
        self.keyboardNumber = keyboardNumber
        self.keyboardAudioManager = AudioManager.shared
    }
    
    public static func == (lhs: PianoKeyboardModel, rhs: PianoKeyboardModel) -> Bool {
        return lhs.keyboardNumber == rhs.keyboardNumber
    }

    public func join(fromKeyboard:PianoKeyboardModel, scale:Scale) -> PianoKeyboardModel {
        let merged = PianoKeyboardModel(keyboardNumber: (self.keyboardNumber + fromKeyboard.keyboardNumber) * 10)
        var offset = 0
        //var keyedMidis:[Int] = []
        var keyCount = 0
        var lowestRHInScaleKey:PianoKeyModel? = nil
        for key in fromKeyboard.pianoKeyModel {
            if key.scaleNoteState != nil {
                lowestRHInScaleKey = key
                break
            }
        }
        guard let lowestRHInScaleKey = lowestRHInScaleKey else {
            return self
        }
        
        for key in self.pianoKeyModel {
            if key.midi >= lowestRHInScaleKey.midi {
                break
            }
            let newModel = PianoKeyModel(keyboardModel: merged, keyIndex: offset, midi: key.midi)
            newModel.hand = 1
            offset += 1
            newModel.setState(state: key.scaleNoteState)
            merged.pianoKeyModel.append(newModel)
            //keyedMidis.append(key.midi)
            keyCount += 1
        }
        //keyedMidis.removeLast()
        //var firstInScaleFound = false
        
        for key in fromKeyboard.pianoKeyModel {
//            if !firstInScaleFound {
//                if key.scaleNoteState != nil {
//                    firstInScaleFound = true
//                }
//            }
            if key.midi < lowestRHInScaleKey.midi {
                continue
            }
            let newModel = PianoKeyModel(keyboardModel: merged, keyIndex: offset, midi: key.midi)
            newModel.hand = 0
            offset += 1
            newModel.setState(state: key.scaleNoteState)
            merged.pianoKeyModel.append(newModel)
            keyCount += 1
        }
        merged.numberOfKeys = keyCount //self.numberOfKeys + fromKeyboard.numberOfKeys
        for rect in self.keyRects {
            let newRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
            merged.keyRects.append(newRect)
        }
        for rect in fromKeyboard.keyRects {
//            if keyedMidis.contains(key.midi) {
//                continue
//            }

            let newRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
            merged.keyRects.append(newRect)
        }
//        for touch in self.touches {
//            let newTouch = CGPoint(x: touch.x, y: touch.y)
//            merged.touches.append(newTouch)
//        }

        merged.firstKeyMidi = self.firstKeyMidi
        merged.keyboardAudioManager = AudioManager.shared
        //merged.debug11("merged")
        return merged
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
            self.forceRepaint += 1
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
    
    func getKeyBoardStartAndSize(scale:Scale, hand:Int) -> (first:Int, numberKeys:Int) {
        let lowestIndex:Int
        if hand == 0 {
            lowestIndex = 0
        }
        else {
            ///For contrary the LH starts high and goes low. The lowest is the middle of the scale
            lowestIndex = scale.scaleMotion == .contraryMotion ? scale.scaleNoteState[hand].count/2 : 0
        }
        var lowestKeyMidi = scale.scaleNoteState[hand][lowestIndex].midi
        
        ///Decide first key to show on the keyboard - either the F key or the C key
        switch self.scalesModel.scale.scaleRoot.name {
        case "C#":
            lowestKeyMidi -= 1
        case "D♭":
            lowestKeyMidi -= 1
        case "D":
            lowestKeyMidi -= 2
        case "E♭":
            lowestKeyMidi -= 3
        case "E":
            lowestKeyMidi -= 4
            
        case "G♭":
            lowestKeyMidi -= 1
        case "F#":
            lowestKeyMidi -= 1
        case "G":
            lowestKeyMidi -= 2
        case "A♭":
            lowestKeyMidi -= 3
        case "A":
            lowestKeyMidi -= 4
        case "B♭":
            lowestKeyMidi -= 5
        case "B":
            lowestKeyMidi -= 6

        default:
            lowestKeyMidi -= 0
        }
               
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

        return (lowestKeyMidi, numKeys)
    }
    
    func configureKeyboardForScale(scale:Scale, hand:Int) {
        (self.firstKeyMidi, self.numberOfKeys) = getKeyBoardStartAndSize(scale: scale, hand: hand)
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
        }
        self.linkScaleFingersToKeyboardKeys(scale: scale, scaleSegment: ScalesModel.shared.selectedScaleSegment, hand: hand)
//        if hand == 1 {
//            self.debug1("LH - After linked to Scale")
//        }
    }
    
    func configureKeyboardForScaleStartView(start:Int, numberOfKeys:Int, scaleStartMidi:Int) {
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        self.firstKeyMidi = start
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
            if pianoKeyModel.midi == scaleStartMidi {
                let keyState = ScaleNoteState(sequence: 0, midi: scaleStartMidi, value: 1, segment: 0)
                ///Mark the start of scale
                keyState.finger = 9

                pianoKeyModel.setState(state: keyState)

            }
        }
        //let key = self.pianoKeyModel[i]
        //key[10].scaleNoteState = ScaleNoteState()
        //self.linkScaleFingersToKeyboardKeys(scale: scale, direction: ScalesModel.shared.selectedDirection)
    }
    
    public func resetLinkScaleFingersToKeyboardKeys() {
        for i in 0..<numberOfKeys {
            if i < self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                key.keyIsSounding = false
                key.setState(state: nil)
            }
        }
    }
    ///Create the link for each piano key to a scale note, if there is one.
    ///Mapping may be different for descending - e.g. melodic minor needs different mapping of scale notes for descending
    public func linkScaleFingersToKeyboardKeys(scale:Scale, scaleSegment:Int, hand:Int) {
        for i in 0..<numberOfKeys {
            if i < self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                let state = scale.getStateForMidi(handIndex: hand, midi: key.midi, scaleSegment: scaleSegment)
                if let state = state {
                    key.setState(state: state)
                }
            }
        }
    }
    
    func debug2(_ ctx:String) {
        let idString = String(self.id.uuidString.suffix(4))
        print("=== Keyboard status ===\(ctx), Number:\(self.keyboardNumber) ID:\(idString))")
        if self.pianoKeyModel.count > 0 {
            for i in 0..<numberOfKeys {
                let key = self.pianoKeyModel[i]
                print(String(format: "%02d",i), "keyOffset:", String(format: "%02d",key.keyOffsetFromLowestKey), "hand:", key.hand, "midi:", key.midi, terminator: "")

//                print("   ascMatch:", key.keyWasPlayedState.tappedTimeAscending != nil, "descMatch:", key.keyWasPlayedState.tappedTimeDescending != nil, terminator: "")
                if let state = key.scaleNoteState {
                    print("  Segment", state.segment, "finger:", state.finger, "fingerBreak:", state.fingerSequenceBreak, terminator: "")
                }
                else {
                    print("  No scale state", terminator: "")
                }
                print(" isSounding:", key.keyIsSounding, key.midi, terminator: "")

                print("")
            }
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
        self.forceRepaint += 1
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
                    pianoKeyModel[index].setKeyPlaying(hilight: true)
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
            if self.keyRects[index].contains(point) {
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
            key.setState(state: nil)
        }
    }
    
    ///Get the offset in the keyboard for the given midi
    ///For ascending C 1-octave returns C 60 to C 72 inclusive = 8 notes
    ///For descending C 1-octave returns same 8 notes
    public func getKeyIndexForMidi(midi:Int, segment:Int?) -> Int? {
        var keyNumber:PianoKeyModel?
        if false { //} let segment = segment{
            keyNumber = self.pianoKeyModel.first(where: { $0.midi == midi && $0.scaleNoteState?.segment == segment })
        }
        else {
            keyNumber = self.pianoKeyModel.first(where: { $0.midi == midi })
        }
        //let x = self.pianoKeyModel.first(where: { $0.midi == midi })
        //let x = self.pianoKeyModel.first(where: { $0.midi == midi && $0.scaleNoteState?.segment == segment })
        return keyNumber == nil ? nil : keyNumber?.keyOffsetFromLowestKey
    }
//    public func getKeyIndexForMidi(midi:Int) -> Int? {
//        //let x = self.pianoKeyModel.first(where: { $0.midi == midi })
//        let x = self.pianoKeyModel.first(where: { $0.midi == midi})
//        return x == nil ? nil : x?.keyOffsetFromLowestKey
//    }

}
