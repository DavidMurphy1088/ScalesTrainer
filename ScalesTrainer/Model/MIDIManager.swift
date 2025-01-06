import Foundation
import CoreMIDI

// MARK: - MIDIObjectType Enumeration

class MIDIMessage {
    let messageType:Int
    let midi:Int
    init(messageType:Int, midi:Int) {
        self.messageType = messageType
        self.midi = midi
    }
}

//enum MIDIObjectType: UInt32 {
//    case other = 0
//    case device = 1
//    case entity = 2
//    case source = 3
//    // case destination = 4 // Not needed since we're only handling sources
//}
enum MIDIObjectType: Int32 {
    case other = 0
    case device = 1
    case entity = 2
    case source = 3
    case destination = 4
    case externalDevice = 5

    var description: String {
        switch self {
        case .other:
            return "Other"
        case .device:
            return "Device"
        case .entity:
            return "Entity"
        case .source:
            return "Source"
        case .destination:
            return "Destination"
        case .externalDevice:
            return "External Device"
        }
    }
}

///Define 'midiNotifyProc' as a global function outside the class.
///This function processes an incoming MIDI message.
func midiNotifyProc(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) {
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
                    if let message:MIDIMessage = midiManager.parseMIDIMessage(messageBytes) {
                        //print("Received MIDI message: \(message)")
                        midiManager.processMidiMessage(MIDImessage: message)
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

// MARK: - MIDIManager Class

class MIDIManager : ObservableObject {
    static let shared = MIDIManager()
    //@Published var devicesPublished:[String] = []
    @Published var connectionsPublished:[String] = []

    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private var connectedSources: Set<MIDIEndpointRef> = []
    private let log = Logger.shared
    var lastNoteOn:Date? = nil
    
    var testMidiNotes:TestMidiNotes?
    private var installedNotificationTarget: ((MIDIMessage) -> Void)?

    init() {
    }
    
    func processMidiMessage(MIDImessage:MIDIMessage) {
        //print("============= MidiManger Received MIDI", MIDImessage.midi)
        if let target = self.installedNotificationTarget {
            target(MIDImessage)
        }
    }
    
    ///Tell the manager where to send MIDI notifcations
    func installNotificationTarget(target:((MIDIMessage) -> Void)?) {
        self.installedNotificationTarget = target
    }

    func setupMIDI() {
        // Create MIDI Client
        let clientName = "Scales Academy" as CFString
        let result = MIDIClientCreate(clientName, midiSetupNotifyProc, Unmanaged.passUnretained(self).toOpaque(), &midiClient)
        if result != noErr {
            log.reportError(self, "Error creating MIDI client: \(result)")
            return
        }
        
        // Create Input Port
        let portName = "Input Port" as CFString
        let inputResult = MIDIInputPortCreate(midiClient, portName, midiNotifyProc, Unmanaged.passUnretained(self).toOpaque(), &inputPort)
        if inputResult != noErr {
            log.reportError(self, "Error creating MIDI input port: \(inputResult)")
            return
        }
        
        scanMIDISources()
    }
    
    func scanMIDISources() {
        self.disconnectAll()

        let numSources = MIDIGetNumberOfSources()
        for i in 0..<numSources {
            let source = MIDIGetSource(i)
            if !connectedSources.contains(source) {
                connectToSource(source)
            }
        }
    }
    
    private func connectToSource(_ source: MIDIEndpointRef) {
        let name = getDeviceName(from: source)
        let result = MIDIPortConnectSource(inputPort, source, nil)
        if result != noErr {
            log.reportError(self, "Failed to connect to source \(name): \(result)")
            notifyUser(ofError: "Failed to connect to MIDI Source: \(name)")
            return
        }
        connectedSources.insert(source)
        log.log(self, "🥶 Connected to source: \(name)")
        DispatchQueue.main.async {
            self.connectionsPublished.append(name)
        }

        // Notify UI about device change
        NotificationCenter.default.post(name: .midiDeviceChanged, object: nil)
    }
    
    private func disconnectFromSource(_ source: MIDIEndpointRef) {
        let name = getDeviceName(from: source)
        let result = MIDIPortDisconnectSource(inputPort, source)
        if result != noErr {
            log.reportError(self, "Failed to disconnect from source \(name): \(result)")
            return
        }
        connectedSources.remove(source)
        log.log(self, "Disconnected from source: \(name)")
        
        // Notify UI about device change
        NotificationCenter.default.post(name: .midiDeviceChanged, object: nil)
    }
    
    private func getDeviceName(from endpoint: MIDIEndpointRef) -> String {
        var paramName: Unmanaged<CFString>?
        let result = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &paramName)
        if result == noErr, let name = paramName?.takeUnretainedValue() {
            return name as String
        }
        return "Unknown"
    }
    
    func handleDeviceAdded(_ endpoint: MIDIObjectRef) {
        //let type = getMIDIObjectType(endpoint)
        //if type == .source {
            let source = MIDIEndpointRef(endpoint)
            if !connectedSources.contains(source) {
                connectToSource(source)
            }
        //}
    }
    
    func handleDeviceRemoved(_ endpoint: MIDIObjectRef) {
        //let type = getMIDIObjectType(endpoint)
        //if type == .source { // Direct comparison without rawValue
            let source = MIDIEndpointRef(endpoint)
            if connectedSources.contains(source) {
                disconnectFromSource(source)
            }
        //}
    }
    
    private func getMIDIObjectType(_ midiObject: MIDIObjectRef) -> MIDIObjectType? {
        var objectType: Int32 = 0
        let kMIDIPropertyType = "type" as CFString
        let result = MIDIObjectGetIntegerProperty(midiObject, kMIDIPropertyType, &objectType)
        if result == noErr {
            return MIDIObjectType(rawValue: objectType)
        } else {
            log.reportError(self, "Error retrieving MIDI object type: \(result)")
            return nil
        }
    }
    
    func disconnectAll() {
        for source in connectedSources {
            disconnectFromSource(source)
        }
        self.connectedSources = []
        DispatchQueue.main.async {
            self.connectionsPublished = []
        }
    }
    
    private func notifyUser(ofError message: String) {
        // Implement user notification, e.g., using NotificationCenter
        NotificationCenter.default.post(name: .midiConnectionError, object: nil, userInfo: ["message": message])
    }
    
    func timeDifference(startDate: Date, endDate: Date) -> String {
        let timeInterval = endDate.timeIntervalSince(startDate)
        let hundredthsOfSeconds = timeInterval * 1 //00
        let diff = String(format: "%.2f", hundredthsOfSeconds)
        return diff
    }
    
    func parseMIDIMessage(_ bytes: [UInt8]) -> MIDIMessage? {
        guard !bytes.isEmpty else {
            return nil
        }
        let statusByte = bytes[0]

        if statusByte >= 0xF0 {
            // System Common or System Real-Time Message
            //return "System Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
            return nil
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
                    return MIDIMessage(messageType: Int(messageType), midi: Int(note))
                }
            case 0xA0:
                // Polyphonic Key Pressure (Aftertouch)
                if bytes.count >= 3 {
                    //let note = bytes[1]
                    //let pressure = bytes[2]
                    //return "Polyphonic Key Pressure - Channel \(channel + 1), Note \(note), Pressure \(pressure)"
                    return nil
                }
            case 0xB0:
                // Control Change
                if bytes.count >= 3 {
                    //let controller = bytes[1]
                    //let value = bytes[2]
                    //return "Control Change - Channel \(channel + 1), Controller \(controller), Value \(value)"
                    return nil
                }
            case 0xC0:
                // Program Change
                if bytes.count >= 2 {
                    //let program = bytes[1]
                    //return "Program Change - Channel \(channel + 1), Program \(program)"
                    return nil
                }
            case 0xD0:
                // Channel Pressure (Aftertouch)
                if bytes.count >= 2 {
                    //let pressure = bytes[1]
                    //return "Channel Pressure - Channel \(channel + 1), Pressure \(pressure)"
                    return nil
                }
            case 0xE0:
                // Pitch Bend Change
                if bytes.count >= 3 {
                    //let lsb = bytes[1]
                    //let msb = bytes[2]
                    //let value = (Int(msb) << 7) | Int(lsb)
                    //return "Pitch Bend Change - Channel \(channel + 1), Value \(value)"
                    return nil
                }
            default:
                //return "Unknown MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
                return nil
            }
        }
        //return "Incomplete MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
        return nil
    }

}

struct MIDIObjectAddRemoveNotification {
    var messageID: MIDINotificationMessageID
    var messageSize: Int
    var object: MIDIObjectRef
    var child: MIDIObjectRef
    var parent: MIDIObjectRef
}

private let midiSetupNotifyProc: MIDINotifyProc = { (message, refCon) in
    guard let refCon = refCon else {
        return
    }
    let midiManager = Unmanaged<MIDIManager>.fromOpaque(refCon).takeUnretainedValue()
    switch message.pointee.messageID {
    case .msgObjectAdded:
        Logger.shared.log(MIDIManager.shared, "MIDI Object Added")
        // Cast the message to MIDIObjectAddRemoveNotification to access 'child'
        let notification = message.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) { $0.pointee }
        //what is this 👹- it causes connection fails...
        midiManager.handleDeviceAdded(notification.child)
        
    case .msgObjectRemoved:
        Logger.shared.log(MIDIManager.shared, "MIDI Object Removed")
        // Cast the message to MIDIObjectAddRemoveNotification to access 'child'
        let notification = message.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) { $0.pointee }
        midiManager.handleDeviceRemoved(notification.child)
        
    default:
        break
    }
}

extension Notification.Name {
    static let midiDeviceChanged = Notification.Name("midiDeviceChanged")
    static let midiConnectionError = Notification.Name("midiConnectionError")
}

///A package of test notes to replay in automated testing.
///Can be generated from a scale under test
class TestMidiNotes {
    class NoteSet {
        var notes:[Int]
        init(_ notes:[Int]) {
            self.notes = notes
        }
    }
    var noteSets:[NoteSet]
    let noteSetWait:Double
    let scaleId:UUID?
    
    init(_ noteSets:[NoteSet], noteWait:Double) {
        self.noteSets = noteSets
        self.noteSetWait = noteWait
        self.scaleId = nil
    }
    
    func debug(_ ctx:String) {
        var msg = ""
        for noteSet in noteSets {
            for note in noteSet.notes {
                msg += " \(note)"
            }
            msg += ", "
        }
        print("==== NoteSet Debug \(ctx)", msg)
    }
    
    init(scale:Scale, hands:[Int], noteSetWait:Double) {
        let totalNotes = scale.getScaleNoteCount()
        self.noteSetWait = noteSetWait
        self.noteSets = []
        self.scaleId = scale.id
        
        for n in 0..<totalNotes {
            var noteSet:[Int] = []
            for hand in hands {
                let midi = scale.getScaleNoteState(handType: hand==0 ? .right : .left, index: n).midi
                ///When contrary starting and ending LH and RH on same note the student will only play one note. So only generate that note, not one for each hand
                if scale.scaleMotion == .contraryMotion && hands.count > 1 {
                    if hand == 0 {
                        noteSet.append(midi)
                    }
                    else {
                        if n > 0 && n < scale.getScaleNoteCount() - 1 {
                            noteSet.append(midi)
                        }
                    }
                }
                else {
                    noteSet.append(midi)
                }
            }
            self.noteSets.append(NoteSet(noteSet))
        }
    }
}

