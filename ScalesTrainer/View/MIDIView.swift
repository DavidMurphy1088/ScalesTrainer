import SwiftUI

struct MIDIView: View {
    @StateObject var midiManager = MIDIManager.shared
    
    var body: some View {
        VStack {
            Text("Received MIDI Messages")
                .font(.title)
                .padding()

            List(midiManager.receivedMessages, id: \.self) { message in
                Text(message)
                    .font(.system(.body, design: .monospaced))
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: .infinity) // Expand the list to fill available space

            Button(action: {
                midiManager.clear()
            }) {
                Text("Clear MIDI")
            }
            .padding()
        }
    }
}
