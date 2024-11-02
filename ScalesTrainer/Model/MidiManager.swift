import Foundation
import CoreMIDI

// Define 'midiReadProc' as a global function outside the class
func midiReadProc(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) {
    let midiManager = Unmanaged<MIDIManager>.fromOpaque(readProcRefCon!).takeUnretainedValue()
    
    let packetList = packetList.pointee
    var packet = packetList.packet
    
    for _ in 0..<packetList.numPackets {
        let packetLength = Int(packet.length)
        let data = withUnsafeBytes(of: packet.data) { rawBufferPointer -> [UInt8] in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return Array(bufferPointer.prefix(packetLength))
        }
        
        var index = 0
        while index < data.count {
            let statusByte = data[index]
            if statusByte >= 0xF0 {
                // System Messages
                index += 1
            } else if statusByte & 0x80 != 0 {
                // Status byte found
                let messageType = statusByte & 0xF0
                let channel = statusByte & 0x0F
                var messageLength = 0
                switch messageType {
                case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
                    messageLength = 3
                case 0xC0, 0xD0:
                    messageLength = 2
                default:
                    messageLength = 1
                }
                
                if index + messageLength <= data.count {
                    let messageBytes = Array(data[index..<(index + messageLength)])
                    let message = midiManager.parseMIDIMessage(messageBytes)
                    if let message = message {
                        print("Received MIDI message: \(message)")
                        DispatchQueue.main.async {
                            if midiManager.receivedMessages.count > 15 {
                                midiManager.receivedMessages = []
                            }
                            midiManager.receivedMessages.append(message)
                        }
                    }
                    index += messageLength
                } else {
                    // Incomplete message
                    index = data.count
                }
            } else {
                // Running status not handled in this example
                index += 1
            }
        }
        
        packet = MIDIPacketNext(&packet).pointee
    }
}

class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    @Published var receivedMessages: [String] = []
    var lastNoteOn:Date? = nil
    
    init() {
        MIDIClientCreate("Scales Academy" as CFString, nil, nil, &midiClient)
        MIDIInputPortCreate(midiClient, "Input Port" as CFString, midiReadProc, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &inputPort)
        
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, src, nil)
        }
        let names = self.getMIDISources()
        Logger.shared.log(self, "Connected Sources : \(self.getMIDISources())")
    }
    
    func getMIDISources() -> [String] {
        var sources: [String] = []
        let sourceCount = MIDIGetNumberOfSources()
        let propertyKeys: [CFString] = [
            kMIDIPropertyDisplayName,
//            kMIDIPropertyName,
//            kMIDIPropertyManufacturer,
            //kMIDIPropertyModel
//            kMIDIPropertyDriverOwner,
            
        ]
        
        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            //var endpointName: Unmanaged<CFString>?
            for key in propertyKeys {
                var propertyValue: Unmanaged<CFString>?
                let result = MIDIObjectGetStringProperty(src, key, &propertyValue)
                if result == noErr, let value = propertyValue?.takeUnretainedValue() as String? {
                    //let midiDesc = "Key:\(key as String)  Value:\(value)"
                    let midiDesc = "\(value)"
                    sources.append(midiDesc)
                }
            }
        }
        return sources
    }
    
    func getMidiConections() -> String {
        var midis = self.getMIDISources()
        return midis.joined(separator: ", ")
    }
    
    func timeDifference(startDate: Date, endDate: Date) -> String {
        let timeInterval = endDate.timeIntervalSince(startDate)
        let hundredthsOfSeconds = timeInterval * 1 //00
        let diff = String(format: "%.2f", hundredthsOfSeconds)
        return diff
    }
    
    func parseMIDIMessage(_ bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return "Empty MIDI message" }
        let statusByte = bytes[0]
        
        if statusByte >= 0xF0 {
            // System Common or System Real-Time Message
            return "System Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
        } else {
            let messageType = statusByte & 0xF0
            let channel = statusByte & 0x0F
            switch messageType {
            case 0x80:
                // Note Off
                if bytes.count >= 3 {
                    let note = bytes[1]
                    let velocity = bytes[2]
                    var out = "Note Off - Channel \(channel + 1), Note \(note), Velocity \(velocity)"
                    if let lastOn = self.lastNoteOn {
                        let diff = self.timeDifference(startDate: lastOn, endDate: Date())
                        out += " Value:" + diff
                    }
                    return nil
                }
            case 0x90:
                // Note On
                if bytes.count >= 3 {
                    let note = bytes[1]
                    let velocity = bytes[2]
                    let noteStatus = velocity == 0 ? "Note Off" : "Note On"
                    var out = "\(noteStatus) - Channel \(channel + 1), Note \(note), Velocity \(velocity)"
                    if let lastOn = self.lastNoteOn {
                        let diff = self.timeDifference(startDate: lastOn, endDate: Date())
                        out += " Value:" + diff
                    }
                    if velocity != 0 {
                        self.lastNoteOn = Date()
                    }
                    return out
                }
            case 0xA0:
                // Polyphonic Key Pressure (Aftertouch)
                if bytes.count >= 3 {
                    let note = bytes[1]
                    let pressure = bytes[2]
                    return "Polyphonic Key Pressure - Channel \(channel + 1), Note \(note), Pressure \(pressure)"
                }
            case 0xB0:
                // Control Change
                if bytes.count >= 3 {
                    let controller = bytes[1]
                    let value = bytes[2]
                    return "Control Change - Channel \(channel + 1), Controller \(controller), Value \(value)"
                }
            case 0xC0:
                // Program Change
                if bytes.count >= 2 {
                    let program = bytes[1]
                    return "Program Change - Channel \(channel + 1), Program \(program)"
                }
            case 0xD0:
                // Channel Pressure (Aftertouch)
                if bytes.count >= 2 {
                    let pressure = bytes[1]
                    return "Channel Pressure - Channel \(channel + 1), Pressure \(pressure)"
                }
            case 0xE0:
                // Pitch Bend Change
                if bytes.count >= 3 {
                    let lsb = bytes[1]
                    let msb = bytes[2]
                    let value = (Int(msb) << 7) | Int(lsb)
                    return "Pitch Bend Change - Channel \(channel + 1), Value \(value)"
                }
            default:
                return "Unknown MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
            }
        }
        return "Incomplete MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
    }

    func clear() {
        DispatchQueue.main.async {
            self.receivedMessages = []
        }
    }
}
