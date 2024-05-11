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

    //@Published
    public var scale:Scale = ScalesModel.shared.scale
    public var firstKeyMidi = 60
    private var nextKeyToPlayIndex:Int?
    private var ascending = true
    
    @Published public var latch = false {
        didSet { resetDisplayState() }
    }
    
    public var keyRects: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    
    public init() {
    }
    
    ///MetronomeTimerNotificationProtocol
    func metronomeStart() {
        resetDisplayState()
        scalesModel.setDirection(0)
        ascending = true
        nextKeyToPlayIndex = nil
        //self.debug2("start")
    }
    
    func metronomeTicked(timerTickerNumber: Int, userScale:Bool) -> Bool {
        let audioManager = AudioManager.shared
        let sampler = audioManager.midiSampler

        if !userScale {
            ///Playing the app's scale
            if timerTickerNumber < ScalesModel.shared.scale.scaleNoteState.count {
                let scaleNote = ScalesModel.shared.scale.scaleNoteState[timerTickerNumber]
                if let keyIndex = getKeyIndexForMidi(midi:scaleNote.midi, direction:0) {
                    self.pianoKeyModel[keyIndex].setPlayingMidi()
                }
                sampler.play(noteNumber: UInt8(scaleNote.midi), velocity: 64, channel: 0)
                scalesModel.setPianoKeyPlayed(midi: scaleNote.midi)
                ///Scale turnaround
                if timerTickerNumber == ScalesModel.shared.scale.scaleNoteState.count / 2 {
                    scalesModel.setDirection(1)
                    //scalesModel.forceRepaint()
                    //setFingers(direction: 1)
                }
            }
            return timerTickerNumber >= ScalesModel.shared.scale.scaleNoteState.count - 1
        } else {
            ///Playing the users recorded scale
            var keyToPlay:Int = nextKeyToPlayIndex == nil ? 0 : nextKeyToPlayIndex!
            var hitTurnaround = false
            if nextKeyToPlayIndex ?? 0 < 0 {
                return true
            }
            while true {
                let key = self.pianoKeyModel[keyToPlay]
                ///Find the next key to play
                var matches = (ascending && key.keyState.matchedTimeAscending != nil) || (!ascending && key.keyState.matchedTimeDescending != nil)
                if matches {
                    if hitTurnaround {
                        hitTurnaround = false
                    }
                    else {
                        key.setPlayingMidi()
                        sampler.play(noteNumber: UInt8(key.midi), velocity: 64, channel: 0)
                        scalesModel.setPianoKeyPlayed(midi: key.midi)
                        if ascending {
                            nextKeyToPlayIndex = keyToPlay + 1
                        }
                        else {
                            nextKeyToPlayIndex = keyToPlay - 1
                        }
                        
                        return false
                    }
                }
                keyToPlay = ascending ? keyToPlay + 1 : keyToPlay - 1
                
                if ascending {
                    if keyToPlay >= self.pianoKeyModel.count-1 {
                        setFingers(direction: 1)
                        ///Dont play the top note twice
                        hitTurnaround = true
                        scalesModel.setDirection(1)
                        ascending = false
                    }
                }
           }
        }
    }
    
    func metronomeStop() {
        clearAllPlayingMidi()
        scalesModel.setDirection(0)
    }
    
    func clearAllPlayingMidi(besidesID:UUID? = nil) {
        if let last = self.pianoKeyModel.first(where: { $0.isPlayingMidi}) {
            if besidesID == nil || last.id != besidesID! {
                DispatchQueue.global(qos: .background).async { [self] in
                    usleep(1000000 * UInt32(0.5))
                    last.isPlayingMidi = false
                    self.redraw()
                }
            }
        }
    }
    
    func clearAllPlayingKey(besidesID:UUID? = nil) {
        if let last = self.pianoKeyModel.first(where: { $0.keyState.matchedTimeAscending != nil || $0.keyState.matchedTimeDescending != nil}) {
            if besidesID == nil || last.id != besidesID! {
                DispatchQueue.global(qos: .background).async { [self] in
                    usleep(1000000 * UInt32(0.5))
                    last.keyState.matchedTimeAscending = nil
                    last.keyState.matchedTimeDescending = nil
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
        didSet { updateKeys() }
    }

    func naturalKeyWidth(_ width: CGFloat, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }
    
    func configureKeyboardSize() {
        self.scale = self.scalesModel.scale
        self.firstKeyMidi = 60
        if self.scale.scaleNoteState[0].midi < 60 {
            self.firstKeyMidi -= 12
        }
        if ["G", "A", "F", "B♭", "A♭"].contains(self.scalesModel.selectedKey.name) {
            self.firstKeyMidi = 65
            if ["A", "B♭", "A♭"].contains(self.scalesModel.selectedKey.name) {
                self.firstKeyMidi -= 12
            }
        }
        var numKeys = (self.scalesModel.octaveNumberValues[self.scalesModel.selectedOctavesIndex] * 12) + 1
        numKeys += 2
        if ["E", "G", "A", "A♭", "E♭"].contains(self.scalesModel.selectedKey.name) {
            numKeys += 4
        }
        if ["B", "B♭"].contains(self.scalesModel.selectedKey.name) {
            numKeys += 6
        }
        self.numberOfKeys = numKeys
        self.pianoKeyModel = []
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        for i in 0..<numberOfKeys {
            let pianoKeyModel = PianoKeyModel(keyboardModel: self, keyIndex: i, midi: self.firstKeyMidi + i)
            self.pianoKeyModel.append(pianoKeyModel)
        }
        self.setFingers(direction: ScalesModel.shared.selectedDirection)
    }
    
    ///Create map each piano key to a scale note, if there is one.
    ///Mapping may be different for descending - e.g. melodic minor needs different mapping of scale notes for descending
    public func setFingers(direction:Int) {
        for i in 0..<numberOfKeys {
            let key = self.pianoKeyModel[i]
            key.scaleNoteState = scale.getStateForMidi(midi: key.midi, direction: direction)
        }
        //debug("set fingers")
    }
    
    func debug22(_ ctx:String) {
        print("=== Keyboard status === \(ctx)")
        for i in 0..<numberOfKeys {
            let key = self.pianoKeyModel[i]
            print(key.keyIndex, "midi:", key.midi, "finger:", key.scaleNoteState?.finger ?? "_____",
                  key.scaleNoteState?.fingerSequenceBreak ?? "", terminator: "")
            print("\tascMatch", key.keyState.matchedTimeAscending != nil, "\tdescMatch", key.keyState.matchedTimeDescending != nil)
        }
    }
    
    private func updateKeys() {
        var keyDownAt = Array(repeating: false, count: numberOfKeys)

        for touch in touches {
            if let index = getKeyContaining(touch) {
                keyDownAt[index] = true
            }
        }
        //print("======= KeyboardModel::UpdateKeys \(self.keyChangeNum)")
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
                    pianoKeyModel[index].setPlayingMidi()
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

    public func resetDisplayState() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].touchDown = false
            pianoKeyModel[i].latched = false
            keyboardAudioManager?.pianoKeyUp(pianoKeyModel[i].noteMidiNumber)
            pianoKeyModel[i].isPlayingMidi = false
        }
    }
    
    public func resetScaleMatchState() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].keyState.matchedTimeAscending = nil
            pianoKeyModel[i].keyState.matchedTimeDescending = nil
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
