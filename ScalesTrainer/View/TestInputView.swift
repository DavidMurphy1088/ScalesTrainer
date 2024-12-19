import SwiftUI

struct TestInputView: View {
    let midiManager = MIDIManager.shared
    let octaves = 2 //UIDevice.current.userInterfaceIdiom == .phone ? 1 : 2
    
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
    
    func getNumbers() -> [Int] {
        let b = octaves > 1 ? 48 : 60
        var numbers = [b+0, b+2, b+4, b+5, b+7, b+9, b+11, b+12]
        if octaves > 1 {
            numbers.append(contentsOf: [b+14, b+16, b+17, b+19, b+21, b+23, b+24])
        }
        return numbers
    }
    
    var body: some View {
        let b = 48
        let accidentals = true
        let showOctaveLower = UIDevice.current.userInterfaceIdiom == .phone ? false : true
        
        VStack {
            Text("Base \(b)")
            HStack {
                if accidentals {
                    Text("......")
                    ForEach(getNumbers(), id: \.self) { midi in
                        Button(action: {
                            noteTapped(midi+1)
                            if ScalesModel.shared.scale.hands.count > 1 {
                                if showOctaveLower {
                                    noteTapped(midi-12+1)
                                }
                            }
                        }) {
                            Text("\(noteName(midi))").font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .padding(UIDevice.current.userInterfaceIdiom == .phone ? 3 : 10)
                        .border(Color.black)
                    }
                }
            }
            HStack {
                ForEach(getNumbers(), id: \.self) { midi in
                    Button(action: {
                        noteTapped(midi)
                        if ScalesModel.shared.scale.hands.count > 1 {
                            if showOctaveLower {
                                noteTapped(midi-12)
                            }
                        }
                    }) {
                        Text("\(noteName(midi))").font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    .padding(UIDevice.current.userInterfaceIdiom == .phone ? 3 : 10)
                    .border(Color.black)
                }
            }
        }
        .padding()
    }
}
