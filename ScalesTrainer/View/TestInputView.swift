import SwiftUI

struct TestInputView: View {
    let midi = MIDIManager.shared
    
    func noteTapped(_ midiNumber:Int) {
        let msg = MIDIMessage(messageType: 0, midi: midiNumber)
        midi.processMidiMessage(MIDImessage: msg)
        if let midi = ScalesModel.shared.midiTestHander {
            let noteSet = TestMidiNotes.NoteSet([midiNumber])
            let notes:TestMidiNotes = TestMidiNotes([noteSet], noteWait: 2)
            midi.sendTestMidiNotes(notes: notes)
        }
    }
    
    var body: some View {
        let numbers = [60, 62, 64, 65, 67, 69, 71, 72, 74]
        VStack {
            HStack {
                Text(".....")
                ForEach(numbers, id: \.self) { midi in
                    Button("\(midi+1)") {
                        noteTapped(midi+1)
                        if ScalesModel.shared.scale.hands.count > 1 {
                            noteTapped(midi-12+1)
                        }
                    }
                    .padding()
                    .border(Color.black)
                }
            }
            HStack {
                ForEach(numbers, id: \.self) { midi in
                    Button("\(midi)") {
                        noteTapped(midi)
                        if ScalesModel.shared.scale.hands.count > 1 {
                            noteTapped(midi-12)
                        }
                    }
                    .padding()
                    .border(Color.black)
                }
            }
        }
        .padding()
    }
}
