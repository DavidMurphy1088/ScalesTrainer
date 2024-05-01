import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardModel: ObservableObject, PianoKeyViewModelDelegateProtocol {
    public static var shared = PianoKeyboardModel()
    
    let scalesModel = ScalesModel.shared
    
    @Published public var scale:Scale = ScalesModel.shared.scale
    @Published public var keys: [PianoKeyModel] = []
    @Published public var forceRepaint = 0 ///Without this the key view does not update when pressed
    @Published public var firstKeyMidi = 60
    @Published public var showLabels = true
    
    @Published public var latch = false {
        didSet { reset() }
    }
     
    public var keyRects: [CGRect] = []

    weak var delegate: AudioManager?
    
    public init() {
        //configureKeys(direction: ScalesModel.shared.selectedDirection)
    }
    
    public var numberOfKeys = 18 
//    {
//        didSet { configureKeysToScaleNotes(direction: ScalesModel.shared.selectedDirection) }
//    }
    
    public var naturalKeyCount: Int {
        keys.filter { $0.isNatural }.count
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
        self.keys = []
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
            let model = PianoKeyModel(scale: scale,
                                          scaleNote: nil,
                                          keyIndex: i,
                                          delegate: self)

            self.keys.append(model)
        }
    }
    
    public func mapPianoKeysToScaleNotes(direction: Int) {
        //print("====== mapPianoKeysToScaleNotes dir:\(direction)")
        for i in 0..<self.keys.count {
            var key = self.keys[i]
            if let seq = scale.getMidiIndex(midi: key.id, direction: direction) {
                let scaleNote = scale.scaleNoteStates[seq]
                key.scaleNote = scaleNote
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
        self.forceRepaint += 1
        for index in 0..<numberOfKeys {
            let noteNumber = keys[index].noteMidiNumber

            if keys[index].touchDown != keyDownAt[index] {
                if latch {
                    let keyLatched = keys[index].latched

                    if keyDownAt[index] && keyLatched {
                        delegate?.pianoKeyUp(noteNumber)
                        keys[index].latched = false
                        keys[index].touchDown = false
                    }
                    if keyDownAt[index] && !keyLatched {
                        delegate?.pianoKeyDown(noteNumber)
                        keys[index].latched = true
                        keys[index].touchDown = true
                    }

                } else {
                    if keyDownAt[index] {
                        delegate?.pianoKeyDown(noteNumber)
                    } else {
                        delegate?.pianoKeyUp(noteNumber)
                    }
                    keys[index].touchDown = keyDownAt[index]
                }
            } else {
                if keys[index].touchDown && keyDownAt[index] && keys[index].latched {
                    delegate?.pianoKeyUp(noteNumber)
                    keys[index].latched = false
                    keys[index].touchDown = false
                }
            }
        }
    }

    private func getKeyContaining(_ point: CGPoint) -> Int? {
        var keyNum: Int?
        for index in 0..<numberOfKeys {
            if keyRects[index].contains(point) {
                keyNum = index
                if !keys[index].isNatural {
                    break
                }
            }
        }
        return keyNum
    }

    private func reset() {
        for i in 0..<numberOfKeys {
            keys[i].touchDown = false
            keys[i].latched = false
            delegate?.pianoKeyUp(keys[i].noteMidiNumber)
        }
    }
}
