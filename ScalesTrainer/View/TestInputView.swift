import SwiftUI

struct TestInputView: View {
    let midiManager = MIDIManager.shared
    
    func noteTapped(_ midiNumber:Int) {
        let msg = MIDIMessage(messageType: 0, midi: midiNumber)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            midiManager.processMidiMessage(MIDImessage: msg)
        }
//        if let midiTestHandler = ScalesModel.shared.midiTestHander {
//            let noteSet = TestMidiNotes.NoteSet([midiNumber])
//            let notes:TestMidiNotes = TestMidiNotes([noteSet], noteWait: 2)
//            midiTestHandler .sendTestMidiNotes(notes: notes)
//        }
    }
    
    func noteName(_ midi:Int) -> String {
        return StaffNote.getNoteName(midiNum: midi)
    }
    
    var body: some View {
        let b = 48
        let accidentals = false
        let octaves = false
        let numbers = [b+0, b+2, b+4, b+5, b+7, b+9, b+11,   b+12, b+14, b+16, b+17, b+19, b+21, b+23, b+24]
        
        VStack {
            Text("Base \(b)")
            HStack {
                if accidentals {
                    Text("......")
                    ForEach(numbers, id: \.self) { midi in
                        //Button("\(midi+1)") {
                        Button("\(noteName(midi))") {
                            noteTapped(midi+1)
                            if ScalesModel.shared.scale.hands.count > 1 {
                                if octaves {
                                    noteTapped(midi-12+1)
                                }
                            }
                        }
                        .padding()
                        .border(Color.black)
                    }
                }
            }
            HStack {
                ForEach(numbers, id: \.self) { midi in
                    Button("\(noteName(midi))") {
                    //Button("\(names[midi-60])") {
                        noteTapped(midi)
                        if ScalesModel.shared.scale.hands.count > 1 {
                            if octaves {
                                noteTapped(midi-12)
                            }
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
