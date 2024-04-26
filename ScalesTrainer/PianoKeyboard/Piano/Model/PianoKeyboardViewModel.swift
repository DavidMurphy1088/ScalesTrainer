import SwiftUI

public protocol PianoKeyboardDelegate: AnyObject {
    func pianoKeyUp(_ keyNumber: Int)
    func pianoKeyDown(_ keyNumber: Int)
}

public class PianoKeyboardViewModel: ObservableObject, PianoKeyViewModelDelegateProtocol {
    let scalesModel = ScalesModel.shared
    @Published public var scale:Scale = ScalesModel.shared.scale
    @Published public var keys: [PianoKeyViewModel] = []
    @Published public var noteMidi = 60
    @Published public var showLabels = true
    @Published public var latch = false {
        didSet { reset() }
    }
    
    public var keyRects: [CGRect] = []

    weak var delegate: AudioManager?
    
    public init() {
        configureKeys(direction: ScalesModel.shared.selectedDirection)
    }
    public func setScale(scale:Scale) {
        DispatchQueue.main.async { [self] in
            self.scale = scale
        }
    }
    public var numberOfKeys = 18 {
        didSet { configureKeys(direction: ScalesModel.shared.selectedDirection) }
    }
    public var naturalKeyCount: Int {
        keys.filter { $0.isNatural }.count
    }

    var touches: [CGPoint] = [] {
        didSet { updateKeys() }
    }

    func naturalKeyWidth(_ width: CGFloat, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }

    private func configureKeys(direction: Int) {
        self.keys = []
        let scale = ScalesModel.shared.scale
        let startMidi = self.noteMidi
        self.keyRects = Array(repeating: .zero, count: numberOfKeys)
        
        for i in 0..<numberOfKeys {
            var state = scale.scaleNoteStates[0]
            let midi = startMidi + i
            if let seq = scale.getMidiIndex(midi: midi, direction: scalesModel.selectedDirection) {
                state = scale.scaleNoteStates[seq]
            }
            let keyIndex = i// (direction == 0 ? 0 : 8) + i
            let model = PianoKeyViewModel(scale: scale,
                                          midiState: state,
                                          keyIndex: keyIndex,
                                          delegate: self)
            self.keys.append(model)
        }
    }

    private func updateKeys() {
        var keyDownAt = Array(repeating: false, count: numberOfKeys)

        for touch in touches {
            if let index = getKeyContaining(touch) {
                keyDownAt[index] = true
            }
        }

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
