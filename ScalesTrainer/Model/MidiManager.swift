import Foundation
import CoreMIDI

class MIDIMessage {
    let messageType:Int
    let midi:Int
    init(messageType:Int, midi:Int) {
        self.messageType = messageType
        self.midi = midi
    }
}

/// Define 'midiNotifyProc' as a global function outside the class.
/// This function processes an incoming MIDI message.
/// 
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

class MIDIManager: ObservableObject {
    static let shared = MIDIManager()
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    //@Published var receivedMessages: [String] = []
    //var receivedMessages: [String] = []
    var lastNoteOn:Date? = nil
    private var installedNotificationTarget: ((MIDIMessage) -> Void)?
    var testMidiNotes:TestMidiNotes?
    
    init() {
    }
    
    ///Tell the manager where to send MIDI notifcations
    func installNotificationTarget(target:((MIDIMessage) -> Void)?) {
        self.installedNotificationTarget = target
    }
    

    ///Determine which device a MIDI source comes from
    ///
    func getDeviceForSource(source: MIDIEndpointRef) -> String? {
        var entity = MIDIEntityRef()
        var device = MIDIDeviceRef()
        
        // Step 1: Get the parent entity of the source
        let entityStatus = MIDIEndpointGetEntity(source, &entity)
        if entityStatus != noErr {
            //print("Failed to get parent entity. Error: \(entityStatus)")
            return nil
        }
        
        // Step 2: Get the parent device of the entity
        let deviceStatus = MIDIEntityGetDevice(entity, &device)
        if deviceStatus != noErr {
            //print("Failed to get parent device. Error: \(deviceStatus)")
            return nil
        }
        
        // Step 3: Get the device name
        var name: Unmanaged<CFString>?
        let nameStatus = MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
        if nameStatus == noErr, let deviceName = name?.takeRetainedValue() {
            return String(deviceName)
        } else {
            return nil
        }
    }

    ///Creates a connection hub for the app to send and receive MIDI data to and from MIDI devices.
    ///
    func createMIDIClientAndConnectSources() {
        MIDIClientCreate("Scales Academy" as CFString, nil, nil, &midiClient)
        let status = MIDIInputPortCreate(midiClient, "Scales Academy" as CFString, midiNotifyProc, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &inputPort)
        let name = inputPort.value
        //Logger.shared.log(self, "Connected listening port : \(name)")

        ///Connect to MIDI sources.
        ///A device or entity can have one or more sources, which are the actual objects that transmit MIDI data.
        ///
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source:MIDIEndpointRef = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)
            let desc = getSourceDescription(MIDIGetSource(i))
            let device = getDeviceForSource(source: source)
            Logger.shared.log(self, "Connected to MIDI device:\(device ?? "unknown"), source:\(desc)")
        }
    }
    
    func getConnectedDevices() -> String {
        let numberOfDevices = MIDIGetNumberOfDevices()
        var list = ""
        for i in 0..<numberOfDevices {
            let device = MIDIGetDevice(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
            if let deviceName = name?.takeRetainedValue() {
                //Logger.shared.log(self, "MIDI Device Found: \(deviceName)")
                if list != "" {
                    list += ", "
                }
                list += String(deviceName)
            }
        }
        return list
    }
    
    func getSourceDescription(_ src:MIDIEndpointRef) -> String {
        var desc = ""
        let propertyKeys: [CFString] = [
            kMIDIPropertyDisplayName,
            //kMIDIPropertyName,
            //kMIDIPropertyManufacturer,
            //kMIDIPropertyModel,
            kMIDIPropertyDriverOwner
        ]
        for key in propertyKeys {
            var propertyValue: Unmanaged<CFString>?
            let result = MIDIObjectGetStringProperty(src, key, &propertyValue)
            if result == noErr, let value = propertyValue?.takeUnretainedValue() as String? {
                //let midiDesc = " [\(key):\(value)] "
                let midiDesc = " [\(key):\(value)] "
                desc += midiDesc
            }
        }
        return desc
    }
    
    ///The primary purpose of MIDIGetNumberOfSources() is to retrieve the total number of MIDI sources currently available on the system. MIDI sources are entities that can send MIDI data to the computer. These can include:
    ///Hardware MIDI devices: Such as keyboards, synthesizers, drum machines, and other MIDI-compatible instruments connected via USB, Thunderbolt, or traditional MIDI ports.
    ///Virtual MIDI ports: Software-based MIDI sources like virtual instruments, digital audio workstations (DAWs), or other applications that can generate MIDI data.
//    func getMIDISources() -> [String] {
//        var sources: [String] = []
//        let sourceCount = MIDIGetNumberOfSources()
//        
//        for i in 0..<sourceCount {
//            let src = MIDIGetSource(i)
//            //var endpointName: Unmanaged<CFString>?
//        }
//        return sources
//    }
    
//    func midiNotifyProc(message: UnsafePointer<MIDINotification>, refCon: UnsafeMutableRawPointer?) {
//        Logger.shared.log(self, "Midi Configuration Changed : \(self.getMIDISources())")
//        if let target = self.installedNotificationTarget {
//            target("")
//        }
//    }

//    func getMidiConections() -> String {
//        var midis = self.getMIDISources()
//        return midis.joined(separator: ", ")
//    }
    
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
                    let note = bytes[1]
                    let pressure = bytes[2]
                    //return "Polyphonic Key Pressure - Channel \(channel + 1), Note \(note), Pressure \(pressure)"
                    return nil
                }
            case 0xB0:
                // Control Change
                if bytes.count >= 3 {
                    let controller = bytes[1]
                    let value = bytes[2]
                    //return "Control Change - Channel \(channel + 1), Controller \(controller), Value \(value)"
                    return nil
                }
            case 0xC0:
                // Program Change
                if bytes.count >= 2 {
                    let program = bytes[1]
                    //return "Program Change - Channel \(channel + 1), Program \(program)"
                    return nil
                }
            case 0xD0:
                // Channel Pressure (Aftertouch)
                if bytes.count >= 2 {
                    let pressure = bytes[1]
                    //return "Channel Pressure - Channel \(channel + 1), Pressure \(pressure)"
                    return nil
                }
            case 0xE0:
                // Pitch Bend Change
                if bytes.count >= 3 {
                    let lsb = bytes[1]
                    let msb = bytes[2]
                    let value = (Int(msb) << 7) | Int(lsb)
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
    
    func processMidiMessage(MIDImessage:MIDIMessage) {
        //print("============= MidiManger Received MIDI", MIDImessage.midi)
        if let target = self.installedNotificationTarget {
            target(MIDImessage)
        }
    }
    
    /// ------------- Functions to describe MIDI sources -------------

    /// Describes the properties of a given MIDIEndpointRef by printing its details.
    ///
    /// - Parameter endpoint: The MIDIEndpointRef to describe.
    func describeMIDIEndpoint(_ endpoint: MIDIEndpointRef) -> String {
        // Helper function to retrieve a string property from a MIDI object
        func getStringProperty(of object: MIDIObjectRef, property: CFString) -> String {
            var param: Unmanaged<CFString>?
            let status = MIDIObjectGetStringProperty(object, property, &param)
            if status == noErr, let cfString = param?.takeUnretainedValue() {
                return cfString as String
            }
            return "Unknown"
        }
        
        // Helper function to retrieve an integer property from a MIDI object
        func getIntegerProperty(of object: MIDIObjectRef, property: CFString) -> UInt32 {
            var value: UInt32 = 0
            let status = MIDIObjectGetIntegerProperty(object, property, &value)
            if status == noErr {
                return value
            }
            return 0
        }
        
        // Retrieve MIDI Endpoint Properties
        let name = getStringProperty(of: endpoint, property: kMIDIPropertyName)
        let manufacturer = getStringProperty(of: endpoint, property: kMIDIPropertyManufacturer)
        let uniqueID = getIntegerProperty(of: endpoint, property: kMIDIPropertyUniqueID)
        let displayName = getStringProperty(of: endpoint, property: kMIDIPropertyDisplayName)
        let model = getStringProperty(of: endpoint, property: kMIDIPropertyModel)

        var description = "Name:" + name + " Manufacturer:" + manufacturer + " Display:" + displayName + " Model:" + model
//        print("MIDI Endpoint Properties:")
//        print("  Name: \(name)")
//        print("  Manufacturer: \(manufacturer)")
//        print("  Unique ID: \(uniqueID)")
//        print("  Display Name: \(displayName)")
//        print("  Model: \(model)")
        return description
    }
    
    func setTestMidiNotesNotes(_ notes:TestMidiNotes) {
        self.testMidiNotes = notes
    }
}
