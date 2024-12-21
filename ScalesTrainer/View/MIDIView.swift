import SwiftUI
import CoreAudioKit

struct BluetoothMIDIView: View {
    var body: some View {
        VStack {
            //let btViewController = CABTMIDICentralViewController()
        }
    }
}

//struct BTMIDIPanelViewControllerWrapper: UIViewControllerRepresentable {
//    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
//        let btMidiViewController = CABTMIDICentralViewController()
//        return btMidiViewController
//    }
//    
//    func updateUIViewController(_ uiViewController: CABTMIDICentralViewController, context: Context) {
//        // No updates needed for this view controller
//    }
//}

struct BTMIDIPanelViewControllerWrapper: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> CABTMIDICentralViewController {
        let btMidiViewController = CABTMIDICentralViewController()
        //btMidiViewController.delegate = context.coordinator
        return btMidiViewController
    }
    
    func updateUIViewController(_ uiViewController: CABTMIDICentralViewController, context: Context) {
        // No updates needed
    }
    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, CABTMIDICentralViewControllerDelegate {
//        var parent: BTMIDIPanelViewControllerWrapper
//        
//        init(_ parent: BTMIDIPanelViewControllerWrapper) {
//            self.parent = parent
//        }
//        
//        func midiCentralViewControllerDidFinish(_ controller: CABTMIDICentralViewController) {
//            parent.presentationMode.wrappedValue.dismiss()
//        }
//    }
}


struct MIDIView: View {
    @ObservedObject var midiManager = MIDIManager.shared
    @State private var showingBTMIDIPanel = false
    
    var body: some View {
        VStack {
            
            Text("Connected MIDI Sources")
                .font(.title)
                .padding()
            List(midiManager.connectionsPublished, id: \.self) { string in
                Text(string)
            }
            
            Button(action: {
                showingBTMIDIPanel = true
            }) {
                Text("Bluetooth MIDI Devices")
                    
            }
            .padding()
            .sheet(isPresented: $showingBTMIDIPanel) {
                BTMIDIPanelViewControllerWrapper()
            }
            
            Button(action: {
                midiManager.scanMIDISources()
            }) {
                Text("Scan MIDI Devices")
            }
            .padding()
            .sheet(isPresented: $showingBTMIDIPanel) {
                BTMIDIPanelViewControllerWrapper()
            }
            
            Button(action: {
                midiManager.disconnectAll()
            }) {
                Text("Disconnect All")
            }
            .padding()

        }
    }
}
