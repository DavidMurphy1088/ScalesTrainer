import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject, Equatable {
    let name:String
    public static var sharedRH = PianoKeyboardModel(name: "commonRH", keyboardNumber: 1)
    public static var sharedLH = PianoKeyboardModel(name: "commonLH", keyboardNumber: 2)
    public static var sharedCombined:PianoKeyboardModel?
    public static var sharedForSettings = PianoKeyboardModel(name: "forShared", keyboardNumber: 2)

    let id = UUID()
    @Published public var forceRepaint1 = 0 ///Without this the key view does not update when pressed
    let scalesModel = ScalesModel.shared
    private(set) var pianoKeyModel: [PianoKeyModel] = []

    public var firstKeyMidi = 60
    public var hilightNotesOutsideScale = true
    
    //public var scaleDirection = 0
    ///accessQueue1 approach sometimes stillgets data race
    private var _scaleDirection: Int = 0
    private let accessQueue1 = DispatchQueue(label: "com.musicmastereducation.scalesacademy.PianoKBModel.state1")
    var scaleDirection: Int {
        get {
            return accessQueue1.sync { _scaleDirection }
        }
        set {
            accessQueue1.sync { _scaleDirection = newValue }
        }
    }
    
    var keyboardNumber:Int ////😡 the lowest value is 1. If changed to 0 remove all the ' -1' in the code that uses it
    func getKeyboardHandType() -> HandType? {
        switch self.keyboardNumber {
        case 1:
            return .right
        case 2:
            return .left
        default :
            return nil
        }
    }
    @Published public var latch = false {
        didSet { resetKeyDownKeyUpState() }
    }
    
    public var keyRects1: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    public var view:ClassicStyle? = nil
    
    //private
    init(name:String, keyboardNumber:Int) {
        self.name = name
        self.pianoKeyModel = []
        self.keyRects1 = []
        self.keyboardNumber = keyboardNumber
        self.keyboardAudioManager = AudioManager.shared
    }
    
    public static func == (lhs: PianoKeyboardModel, rhs: PianoKeyboardModel) -> Bool {
        return lhs.keyboardNumber == rhs.keyboardNumber
    }

    public func joinKeyboard(score:Score, fromKeyboard:PianoKeyboardModel, scale:Scale) -> PianoKeyboardModel {
        let merged = PianoKeyboardModel(name: "merged", keyboardNumber: (self.keyboardNumber + fromKeyboard.keyboardNumber) * 10)
        var offset = 0
        var keyCount = 0
        var lowestRHInScaleKey:PianoKeyModel? = nil
        for key in fromKeyboard.pianoKeyModel {
            if key.scaleNoteState != nil {
                lowestRHInScaleKey = key
                break
            }
        }
        var highestLHInScaleKey:PianoKeyModel? = nil
        for key in self.pianoKeyModel.reversed() {
            if key.scaleNoteState != nil {
                highestLHInScaleKey = key
                break
            }
        }
        guard let lowestRHInScaleKey = lowestRHInScaleKey else {
            return self
        }
        guard let highestLHInScaleKey = highestLHInScaleKey else {
            return self
        }

        var lastKey:PianoKeyModel?
        for key in self.pianoKeyModel {
            if key.midi >= lowestRHInScaleKey.midi  {
                break
            }
            let newModel = PianoKeyModel(scale:scale, score:score, keyboardModel: merged, keyIndex: offset, midi: key.midi, handType: key.handType)
            offset += 1
            newModel.setState(state: key.scaleNoteState)
            merged.pianoKeyModel.append(newModel)
            lastKey = newModel
            keyCount += 1
        }
        
        ///Need to fill the gap between the LH and RH if the RH scales doesnt exactly follow on from the LH scale. e.g. Gr 5 chromatic LH start C, Rh start E
        if highestLHInScaleKey.midi != lowestRHInScaleKey.midi {
            
            if let lastKey = lastKey {
                let missingKeys = lowestRHInScaleKey.midi - lastKey.midi - 1
                for i in 0..<missingKeys {
                    let fillerKeyModel = PianoKeyModel(scale: scale, score: score, keyboardModel: merged, keyIndex: offset, midi:0, handType: .right)
                    offset += 1
                    merged.pianoKeyModel.append(fillerKeyModel)
                }
                //offset += 1
                //merged.pianoKeyModel.append(fillerKeyModel)
            }
        }
       
        for key in fromKeyboard.pianoKeyModel {
            if key.midi < lowestRHInScaleKey.midi {
                continue
            }
            let newModel = PianoKeyModel(scale:scale, score:score, keyboardModel: merged, keyIndex: offset, midi: key.midi, handType: key.handType)
            offset += 1
            newModel.setState(state: key.scaleNoteState)
            merged.pianoKeyModel.append(newModel)

            keyCount += 1
        }
        
        merged.numberOfKeys = keyCount //self.numberOfKeys + fromKeyboard.numberOfKeys
        for rect in self.keyRects1 {
            let newRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
            merged.keyRects1.append(newRect)
        }
        
        for rect in fromKeyboard.keyRects1 {
            let newRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
            merged.keyRects1.append(newRect)
        }

        merged.firstKeyMidi = self.firstKeyMidi
        merged.keyboardAudioManager = AudioManager.shared
        //merged.debug1("Merged ")
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
    
    func redraw() { //_ ctx:String) {
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
    
    func getKeyBoardStartAndSize(scale:Scale, handType:HandType) -> (first:Int, numberKeys:Int) {
        let lowestIndex:Int
        if handType == .right {
            lowestIndex = 0
        }
        else {
            ///For contrary the LH starts high and goes low. The lowest is the middle of the scale
            //lowestIndex = scale.scaleMotion == .contraryMotion ? scale.scaleNoteState[hand].count/2 : 0
            lowestIndex = scale.scaleMotion == .contraryMotion ? scale.getScaleNoteStates(handType: .left).count/2 : 0
        }
        var lowestKeyMidi = scale.getScaleNoteState(handType: handType, index: lowestIndex)!.midi // [hand][lowestIndex].midi
        
        ///Decide first key to show on the keyboard - either the F key or the C key
        ///Cant go off scaleRoot name - e.g. name F# for the custom chromatic F#A#
        //switch self.scalesModel.scale.scaleRoot.name {
//        switch scale.scaleRoot.name {
//        case "C#":
//            lowestKeyMidi -= 1
//        case "D♭":
//            lowestKeyMidi -= 1
//        case "D":
//            lowestKeyMidi -= 2
//        case "E♭":
//            lowestKeyMidi -= 3
//        case "E":
//            lowestKeyMidi -= 4
//            
//        case "G♭":
//            lowestKeyMidi -= 1
//        case "F#":
//            lowestKeyMidi -= 1
//        case "G":
//            lowestKeyMidi -= 2
//        case "G#":
//            lowestKeyMidi -= 2
//        case "A♭":
//            lowestKeyMidi -= 3
//        case "A":
//            lowestKeyMidi -= 4
//        case "A#":
//            lowestKeyMidi -= 5
//        case "B♭":
//            lowestKeyMidi -= 5
//        case "B":
//            lowestKeyMidi -= 6
//
//        default:
//            lowestKeyMidi -= 0
//        }
        
        var keyDelta = 0
        let startMidi = scale.getStartMidi(handType: handType) % 12
        switch startMidi {
            case 0 : keyDelta = 0
            case 1 : keyDelta = 1
            case 2 : keyDelta = 2
            case 3 : keyDelta = 3
            case 4 : keyDelta = 4
            case 5 : keyDelta = 0
            case 6 : keyDelta = 1
            case 7 : keyDelta = 2
            case 8 : keyDelta = 3
            case 9 : keyDelta = 4
            case 10 : keyDelta = 5
            case 11 : keyDelta = 6
            default: keyDelta = 0
        }
        lowestKeyMidi -= keyDelta
        let notes = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        
        let scaleName = notes[startMidi]
        var numKeys = (scale.octaves * 12) + 1
        numKeys += 2
        
        //if ["E", "G", "A", "A♭", "E♭"].contains(scale.scaleRoot.name) {
        if ["E", "G", "A", "A♭", "E♭"].contains(scaleName) {
            numKeys += 4
        }
//        if ["G#"].contains(scale.scaleRoot.name) {
//            numKeys += 1
//        }
        //if ["B", "B♭"].contains(scale.scaleRoot.name) {
        if ["B", "B♭"].contains(scaleName) {
            numKeys += 6
        }
        if [.brokenChordMajor, .brokenChordMinor].contains(scale.scaleType) {
            numKeys += 4
        }

        return (lowestKeyMidi, numKeys)
    }
    
    func configureKeyboardForScale(scale:Scale, score:Score, handType:HandType) {
        (self.firstKeyMidi, self.numberOfKeys) = getKeyBoardStartAndSize(scale: scale, handType: handType)
        self.pianoKeyModel = []
        self.keyRects1 = Array(repeating: .zero, count: self.numberOfKeys)
        for i in 0..<self.numberOfKeys {
            let midi = self.firstKeyMidi + i
            let pianoKeyModel = PianoKeyModel(scale:scale, score:score, keyboardModel: self, keyIndex: i, midi: midi, handType: handType)
            self.pianoKeyModel.append(pianoKeyModel)
        }
        self.linkScaleFingersToKeyboardKeys(scale: scale, scaleSegment: ScalesModel.shared.selectedScaleSegment, handType: handType, scaleDirection: 0)
        //self.debug11("configureKeyboardForScale hand:\(handType) keys:\(self.numberOfKeys)")
    }
    
    func configureKeyboardForScaleStartView1(scale:Scale, score:Score, start:Int, numberOfKeys:Int, handType:HandType) {
        self.pianoKeyModel = []
        self.keyRects1 = Array(repeating: .zero, count: numberOfKeys)
        self.firstKeyMidi = start
        let handStartMidis = scale.getHandStartMidis()
        
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(scale:scale, score: score, keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i, handType: handType)
            self.pianoKeyModel.append(pianoKeyModel)
            if handStartMidis.contains(pianoKeyModel.midi) {
                let keyState = ScaleNoteState(sequence: 0, midi: pianoKeyModel.midi, value: 1, segment: [0])
                ///Mark the start of scale
                keyState.finger = 9
                pianoKeyModel.setState(state: keyState)
            }
        }
    }
    
    public func resetLinkScaleFingersToKeyboardKeys() {
        for i in 0..<numberOfKeys {
            if i < self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                //key.keyIsSounding = false
                key.setState(state: nil)
            }
        }
    }
    
    ///Create the link for each piano key to a scale note, if there is one.
    ///Mapping may be different for descending - e.g. melodic minor needs different mapping of scale notes for descending
    public func linkScaleFingersToKeyboardKeys(scale:Scale, scaleSegment:Int, handType:HandType, scaleDirection:Int) {
        self.scaleDirection = scaleDirection //thread race, G Maj borken chord play
        for i in 0..<numberOfKeys {
            if i < self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                let state = scale.getStateForMidi(handType: handType, midi: key.midi, scaleSegment: scaleSegment)
                if let state = state {
                    key.setState(state: state)
                }
            }
        }
        //self.debug11("linkScaleFingersToKeyboardKeys")
    }
    
    func debug11(_ ctx:String) {
        let idString = String(self.id.uuidString.suffix(4))
        print("=== Keyboard status ===\(ctx), Number:\(self.keyboardNumber) ID:\(idString)) scale:\(scalesModel.scale.getScaleDescriptionHelpMessage())")
        if self.pianoKeyModel.count > 0 {
            for i in 0..<self.pianoKeyModel.count {
                let key = self.pianoKeyModel[i]
                print(String(format: "%02d",i), "keyOffset:", String(format: "%02d",key.keyOffsetFromLowestKey), "hand:", key.handType, "midi:", key.midi, terminator: "")

//                print("   ascMatch:", key.keyWasPlayedState.tappedTimeAscending != nil, "descMatch:", key.keyWasPlayedState.tappedTimeDescending != nil, terminator: "")
                if let state = key.scaleNoteState {
                    print("  Segment", state.segments, "finger:",
                          state.finger, "breakUp:", state.keyboardFingerColourTypeUp,
                          state.finger, "breakDn:", state.keyboardFingerColourTypeDown,
                          terminator: "")
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
                    pianoKeyModel[index].setKeyPlaying()
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
            if self.keyRects1[index].contains(point) {
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
    
    public func clearAllFollowingKeyHilights(except:[Int]?) {
        for i in 0..<numberOfKeys {
            if let except = except {
                if !except.contains(i) {
                    pianoKeyModel[i].hilightType = .none
                }
            }
            else {
                pianoKeyModel[i].hilightType = .none
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
    public func getKeyIndexForMidi(midi:Int) -> Int? {
        var keyNumber:PianoKeyModel?
        keyNumber = self.pianoKeyModel.first(where: { $0.midi == midi })
        return keyNumber == nil ? nil : keyNumber?.keyOffsetFromLowestKey
    }

}
//    ///Set the
//    static func setKeysHilight(scale:Scale, midi:Int) {
//        class PossibleKeyPlayed {
//            let keyboard:PianoKeyboardModel
//            let keyIndex: Int
//            let inScale:Bool
//            init(keyboard:PianoKeyboardModel, keyIndex:Int, inScale:Bool) {
//                //self.hand = hand
//                self.keyIndex = keyIndex
//                self.inScale = inScale
//                self.keyboard = keyboard
//            }
//        }
//        let scalesModel = ScalesModel.shared
//        var keyboards:[PianoKeyboardModel] = []
//        if scale.getKeyboardCount() == 1 {
//            let keyboard = scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
//            keyboards.append(keyboard)
//        }
//        else {
//            if let combinedKeyboard = PianoKeyboardModel.sharedCombined {
//                keyboards.append(combinedKeyboard)
//            }
//            else {
//                keyboards.append(PianoKeyboardModel.sharedLH)
//                keyboards.append(PianoKeyboardModel.sharedRH)
//            }
//        }
//
//        ///A MIDI heard may be in both the LH and RH keyboards.
//        ///Determine which keyboard the MIDI was played on
//        var possibleKeysPlayed:[PossibleKeyPlayed] = []
//        for i in 0..<keyboards.count {
//            let keyboard = keyboards[i]
//            if let index = keyboard.getKeyIndexForMidi(midi: midi, segment: scalesModel.selectedScaleSegment) {
//                let handType = keyboard.keyboardNumber - 1 == 0 ? HandType.right : HandType.left
//                //let inScale = scale.getStateForMidi(handIndex: keyboard.keyboardNumber - 1, midi: midi, scaleSegment: scalesModel.selectedScaleSegment) != nil
//                let inScale = scale.getStateForMidi(handType: handType, midi: midi, scaleSegment: scalesModel.selectedScaleSegment) != nil
//                possibleKeysPlayed.append(PossibleKeyPlayed(keyboard: keyboard, keyIndex: index, inScale: inScale))
//            }
//        }
//
//        if possibleKeysPlayed.count > 0 {
//            if keyboards.count == 1 {
//                let keyboard = keyboards[0]
//                let keyboardKey = keyboard.pianoKeyModel[possibleKeysPlayed[0].keyIndex]
//                keyboardKey.setKeyPlaying(hilight: true)
//            }
//            else {
//                if possibleKeysPlayed.first(where: { $0.inScale == true})  == nil {
//                    ///Find the keyboard where the key played is not in the scale. If found, hilight it on just that keyboard
//                    if let outOfScale = possibleKeysPlayed.first(where: { $0.inScale == false}) {
//                        let keyboard = outOfScale.keyboard
//                        let keyboardKey = keyboard.pianoKeyModel[outOfScale.keyIndex]
//                        keyboardKey.setKeyPlaying(hilight: true)
//                    }
//                }
//                else {
//                    ///New option for scale Lead in? - For all keys played show the played status only on one keyboard - RH or LH, not both
//                    ///Find the first keyboard where the key played is in the scale. If found, hilight it on just that keyboard
//                    for possibleKey in possibleKeysPlayed {
//                        let keyboard = possibleKey.keyboard
//                        let keyboardKey = keyboard.pianoKeyModel[possibleKey.keyIndex]
//                        keyboardKey.setKeyPlaying(hilight: true)
//                    }
//                }
//            }
//        }
//    }
    
