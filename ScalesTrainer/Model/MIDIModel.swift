import Foundation
import CoreMIDI

class MIDIModel {
    static let shared = MIDIModel()
    var midiClient = MIDIClientRef()
    var midiInPort = MIDIPortRef()
    var midiMessNum = 0
    
    init() {
        // Create a MIDI client
        MIDIClientCreate("MIDI Client" as CFString, nil, nil, &midiClient)
        
        // Create an input port

        let midiInputCallback: MIDIReadProc = { packetList, srcConnRefCon, connRefCon in
            let packets = packetList.pointee
            print("DataIN", Date())
            for packet in packets {
                let midiData = packet.data
                //print( "\(self.midiMessNum)  MIDIData", midiData)
            }
        }
        
        MIDIInputPortCreate(midiClient, "Input Port" as CFString, midiInputCallback, nil, &midiInPort)
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            print("MIDI Port", src.description)
            MIDIPortConnectSource(midiInPort, src, nil)
        }
    }
    

}
