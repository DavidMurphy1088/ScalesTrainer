import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject {
    public static var shared = PianoKeyboardModel()
    
    let scalesModel = ScalesModel.shared
    
    @Published public var scale:Scale = ScalesModel.shared.scale
    @Published public var pianoKeyModel: [PianoKeyModel] = []
    @Published public var forceRepaint1 = 0 ///Without this the key view does not update when pressed
    @Published public var firstKeyMidi = 60
    @Published public var showLabels = true
    
    @Published public var latch = false {
        didSet { reset() }
    }
    var lastKeyPlayed:PianoKeyModel?
    
    public var keyRects: [CGRect] = []

    weak var keyboardAudioManager: AudioManager?
    
    public init() {
        //configureKeys(direction: ScalesModel.shared.selectedDirection)
    }
    
    func redraw() {
        DispatchQueue.main.async {
            self.forceRepaint1 += 1
        }
    }
    
    public var numberOfKeys = 18
//    {
//        didSet { configureKeysToScaleNotes(direction: ScalesModel.shared.selectedDirection) }
//    }
    
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
        if self.scale.scaleNoteStates[0].midi < 60 {
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
        self.showLabels = true
        //self.keys = Array(repeating: ExampleClass(value: 0), count: 10)
        self.createPianoKeys()
        self.mapPianoKeysToScaleNotes(direction: self.scalesModel.selectedDirection)
        //self.scalesModel.forceRepaint()
    }
    
    ///Create each piano key and map to each note in the scale. Some piano keys dont have notes.
    ///Mapping may be different for descending - e.g. melodic minor
    private func createPianoKeys() {
        self.pianoKeyModel = []
        let scale = ScalesModel.shared.scale
        let startMidi = self.firstKeyMidi
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        
        for i in 0..<numberOfKeys {
//            let midi = startMidi + i
//            var scaleNote:ScaleNoteState? = nil
//            if let seq = scale.getMidiIndex(midi: midi, direction: scalesModel.selectedDirection) {
//                scaleNote = scale.scaleNoteStates[seq]
//            }
//            scaleNote = ScaleNoteState(sequence: 0, midi: 62)
//            scaleNote?.finger = 7
//            let keyIndex = i
            let pianoKeyModel = PianoKeyModel(keyboardModel: self,
                                    scale: scale,
                                    keyIndex: i)
            self.pianoKeyModel.append(pianoKeyModel)
        }
    }
    
    public func mapPianoKeysToScaleNotes(direction: Int) {
        //print("====== mapPianoKeysToScaleNotes dir:\(direction)")
        for i in 0..<self.pianoKeyModel.count {
            var key = self.pianoKeyModel[i]
            if let seq = scale.getMidiIndex(midi: key.id, direction: direction) {
                let scaleNote = scale.scaleNoteStates[seq]
                key.scaleNote = scaleNote
                scaleNote.pianoKey = key
                //print("=== mapped keyboard note:", i, key.id, "==> scaleNote:", seq, scaleNote.midi, "finger:", scaleNote.finger, scaleNote.fingerSequenceBreak)
            }
            else {
                key.scaleNote = nil
            }
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
                    pianoKeyModel[index].setPlayingMidi("key pressed down")
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
    
    public func getKeyIndexForMidi(_ midi: Int) -> Int? {
        for i in 0..<self.pianoKeyModel.count {
            if self.pianoKeyModel[i].id == midi {
                return i
            }
        }
        return nil
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

    private func reset() {
        for i in 0..<numberOfKeys {
            pianoKeyModel[i].touchDown = false
            pianoKeyModel[i].latched = false
            keyboardAudioManager?.pianoKeyUp(pianoKeyModel[i].noteMidiNumber)
        }
    }
}
