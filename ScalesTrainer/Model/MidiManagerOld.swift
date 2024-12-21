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

///// Define 'midiNotifyProc' as a global function outside the class.
///// This function processes an incoming MIDI message.
///// 
//func midiNotifyProc1(packetList: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) {
//    let midiManager = Unmanaged<MIDIManager>.fromOpaque(readProcRefCon!).takeUnretainedValue()
//    
//    let packetList = packetList.pointee
//    var packet = packetList.packet
//    
//    for _ in 0..<packetList.numPackets {
//        let packetLength = Int(packet.length)
//        let data = withUnsafeBytes(of: packet.data) { rawBufferPointer -> [UInt8] in
//            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
//            return Array(bufferPointer.prefix(packetLength))
//        }
//        
//        var index = 0
//        while index < data.count {
//            let statusByte = data[index]
//            if statusByte >= 0xF0 {
//                // System Messages
//                index += 1
//            } else if statusByte & 0x80 != 0 {
//                // Status byte found
//                let messageType = statusByte & 0xF0
//                let channel = statusByte & 0x0F
//                var messageLength = 0
//                switch messageType {
//                case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
//                    messageLength = 3
//                case 0xC0, 0xD0:
//                    messageLength = 2
//                default:
//                    messageLength = 1
//                }
//                
//                if index + messageLength <= data.count {
//                    let messageBytes = Array(data[index..<(index + messageLength)])
//                    if let message:MIDIMessage = midiManager.parseMIDIMessage(messageBytes) {
//                        //print("Received MIDI message: \(message)")
//                        midiManager.processMidiMessage(MIDImessage: message)
//                    }
//                    index += messageLength
//                } else {
//                    // Incomplete message
//                    index = data.count
//                }
//            } else {
//                // Running status not handled in this example
//                index += 1
//            }
//        }
//        packet = MIDIPacketNext(&packet).pointee
//    }
//}
//

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

//class MIDIManagerOLD: ObservableObject {
//    static let shared = MIDIManagerOLD)
//    @Published var devicesPublished:[String] = []
//    @Published var connectionsPublished:[String] = []
//
//    var midiClient = MIDIClientRef()
//    var inputPort = MIDIPortRef()testMidiNotes
//    var lastNoteOn:Date? = nil
//    private var installedNotificationTarget: ((MIDIMessage) -> Void)?
//    var testMidiNotes:TestMidiNotes?
//    
//    init() {
//        MIDIClientCreate("Scales Academy" as CFString, nil, nil, &midiClient)
//        ///Tell the port which function to call when a MIDI notification arrives
//        _ = MIDIInputPortCreate(midiClient, "Scales Academy" as CFString, midiNotifyProc1, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &inputPort)
//    }
//    
//    ///Tell the manager where to send MIDI notifcations
//    func installNotificationTarget(target:((MIDIMessage) -> Void)?) {
//        self.installedNotificationTarget = target
//    }
//    
//    ///Understanding CoreMIDI Hierarchy - CoreMIDI organizes MIDI objects in a hierarchical structure:
//    ///MIDIDeviceRef: Represents a physical or virtual MIDI device.
//    ///MIDIEntityRef: Represents a logical entity within a device.
//    ///MIDIEndpointRef: Represents a MIDI source or destination endpoint.
//    ///System-managed sessions like "Session 1" and "IDAM MIDI Host" are virtual devices created by CoreMIDI drivers (e.g., RTP-MIDI, IDAM). These do not correspond to physical hardware devices but are essential for network and inter-device MIDI communication.
//
//    /// Retrieves the parent MIDIDeviceRef for a given MIDIEntityRef
//    func getDevice(for entity: MIDIEntityRef) -> MIDIDeviceRef? {
//        var device: MIDIDeviceRef = 0
//        let status = MIDIEntityGetDevice(entity, &device)
//        
//        guard status == noErr, device != 0 else {
//            print("Error: Unable to get device for entity \(entity). Status: \(status)")
//            return nil
//        }
//        return device
//    }
//
//    /// Retrieves the device name for a given MIDIDeviceRef
//    func getDeviceName(for device: MIDIDeviceRef) -> String? {
//        var name: Unmanaged<CFString>?
//        let status = MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name)
//        
//        guard status == noErr, let unmanagedName = name else {
//            print("Error: Unable to get name for device \(device). Status: \(status)")
//            return nil
//        }
//        
//        // Use takeUnretainedValue since CoreMIDI does not transfer ownership
//        let deviceName = unmanagedName.takeUnretainedValue() as String
//        return deviceName
//    }
//
//    /// Retrieves the driver owner for a given MIDIDeviceRef
//    func getDriverOwner(for device: MIDIDeviceRef) -> String? {
//        var driverOwner: Unmanaged<CFString>?
//        let status = MIDIObjectGetStringProperty(device, kMIDIPropertyDriverOwner, &driverOwner)
//        
//        guard status == noErr, let unmanagedDriverOwner = driverOwner else {
//            // Some devices might not have a driver owner
//            return nil
//        }
//        
//        let driverOwnerString = unmanagedDriverOwner.takeUnretainedValue() as String
//        return driverOwnerString
//    }
//
//    /// Determines if a device is virtual based on its driver owner
//    func isVirtualDevice(driverOwner: String?) -> Bool {
//        guard let owner = driverOwner else {
//            // If there's no driver owner, it's likely a virtual device
//            return true
//        }
//        
//        // List of known virtual driver owners
//        let virtualDrivers = [
//            "com.apple.AppleMIDIRTPDriver",    // Network MIDI
//            "com.apple.AppleIDAMDriver",       // IDAM MIDI Host
//            "com.apple.VirtualMIDIDriver",     // Virtual MIDI ports
//            // Add other virtual drivers if necessary
//        ]
//        
//        return virtualDrivers.contains(owner)
//    }
//
//    /// Retrieves the source name for a given MIDIEndpointRef
//    func getSourceName(for source: MIDIEndpointRef) -> String? {
//        var name: Unmanaged<CFString>?
//        let status = MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name)
//        
//        guard status == noErr, let unmanagedName = name else {
//            print("Error: Unable to get name for source \(source). Status: \(status)")
//            return nil
//        }
//        
//        // Use takeUnretainedValue since CoreMIDI does not transfer ownership
//        let sourceName = unmanagedName.takeUnretainedValue() as String
//        return sourceName
//    }
//
//    /// Finds all MIDI sources and their associated devices. Then connect each to our port
//    /// 
//    func connectExistingSources() {
//
//        let numSources = MIDIGetNumberOfSources()
//        var pubList:[String] = []
//        
//        for i in 0..<numSources {
//            let source = MIDIGetSource(i)
//            var sourceDescription = getSourceName(for: source) ?? "unknown source"
//
//            // Retrieve the associated device
//            if let device = getDevice(for: source) {
//                let deviceName = getDeviceName(for: device) ?? "Unknown Device"
//                let driverOwner = getDriverOwner(for: device)
//                let deviceType = isVirtualDevice(driverOwner: driverOwner) ? "Virtual" : "Physical"
//                sourceDescription += " Device:\(deviceName) Type:(\(deviceType)) "
//                if let owner = driverOwner {
//                    sourceDescription += "Driver Owner:\(owner)"
//                } else {
//                    sourceDescription += "Driver Owner: None"
//                }
//                //sourceDevice = device
//            } else {
//                sourceDescription = "Device: Unknown"
//            }
//            
//            ///Connect the source to our port
//            MIDIPortConnectSource(inputPort, source, nil)
//            let desc = getSourceDescription(MIDIGetSource(i))
//            //let device = getDeviceForSource(source: source)
//            Logger.shared.log(self, "Connected to MIDI device:\(sourceDescription), source:\(desc)")
//            pubList.append(sourceDescription)
//        }
//        DispatchQueue.main.async {
//            self.connectionsPublished.append(contentsOf: pubList)
//        }
//    }
//
//    func getAllProperties(ctx:String, _ object: MIDIObjectRef) -> String {
//        var properties: Unmanaged<CFPropertyList>?
//        var desc = ""
//        if MIDIObjectGetProperties(object, &properties, true) == noErr,
//            let dict = properties?.takeRetainedValue() as? [String: Any] {
//            
//            for (key, value) in dict {
//                if ["name", "driver"].contains(key)  {
//                    print("============ \(ctx) key:[\(key)]",  "value:", value)
//                    let midiDesc = " [\(key):\(value)] "
//                    //print("\(key): \(value)")
//                    desc += midiDesc
//                }
//            }
//        } else {
//            print("Failed to retrieve properties")
//        }
//        return desc
//    }
//    
//    func getSourceDescription(_ src:MIDIEndpointRef) -> String {
//        var desc = ""
//        let propertyKeys: [CFString] = [
//            kMIDIPropertyDisplayName,
//            //kMIDIPropertyName,
//            //kMIDIPropertyManufacturer,
//            //kMIDIPropertyModel,
//            kMIDIPropertyDriverOwner
//        ]
//        for key in propertyKeys {
//            var propertyValue: Unmanaged<CFString>?
//            let result = MIDIObjectGetStringProperty(src, key, &propertyValue)
//            if result == noErr, let value = propertyValue?.takeUnretainedValue() as String? {
//                //let midiDesc = " [\(key):\(value)] "
//                let midiDesc = " [\(key):\(value)] "
//                desc += midiDesc
//            }
//        }
//        return desc
//    }
//    
//    ///MIDI Device vs MIDI Source
//    ///MIDI Device: Represents a physical or virtual MIDI device. For example, a connected MIDI keyboard or synthesizer.
//    ///A device can have multiple entities, which are logical subdivisions of the device.
//    ///MIDI Source: Represents a single point where MIDI data can originate (a MIDI endpoint).
//    ///A device can have one or more sources, depending on its capabilities.
//    ///Example: A MIDI keyboard with multiple zones or channels might expose multiple sources.
//    ///This list an optional display to the user, connections are not made from it, but rather from a MIDI source on a device.
//    func getDevicesInSystem() -> [String] {
//        let numberOfDevices = MIDIGetNumberOfDevices()
//        var list:[String] = []
//        for i in 0..<numberOfDevices {
//            let device = MIDIGetDevice(i)
//            var deviceName: Unmanaged<CFString>?
//            MIDIObjectGetStringProperty(device, kMIDIPropertyName, &deviceName)
////            var displayName: Unmanaged<CFString>?
////            MIDIObjectGetStringProperty(device, kMIDIPropertyDisplayName, &displayName)
//            let allProperties:String = self.getAllProperties(ctx: "getDevicesInSystem", device)
//            if let deviceName  = deviceName {
//                let deviceName = deviceName.takeRetainedValue() as String
//                list.append("name:\(deviceName) \(allProperties)")
//            }
//        }
//        DispatchQueue.main.async {
//            self.devicesPublished.append(contentsOf: list)
//        }
//        return list
//    }
//
//    
//    func timeDifference(startDate: Date, endDate: Date) -> String {
//        let timeInterval = endDate.timeIntervalSince(startDate)
//        let hundredthsOfSeconds = timeInterval * 1 //00
//        let diff = String(format: "%.2f", hundredthsOfSeconds)
//        return diff
//    }
//    
//    func parseMIDIMessage(_ bytes: [UInt8]) -> MIDIMessage? {
//        guard !bytes.isEmpty else {
//            return nil
//        }
//        let statusByte = bytes[0]
//        
//        if statusByte >= 0xF0 {
//            // System Common or System Real-Time Message
//            //return "System Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
//            return nil
//        } else {
//            let messageType = statusByte & 0xF0
//            let channel = statusByte & 0x0F
//            switch messageType {
//            case 0x80:
//                // Note Off
//                if bytes.count >= 3 {
//                    let note = bytes[1]
//                    let velocity = bytes[2]
//                    var out = "Note Off - Channel \(channel + 1), Note \(note), Velocity \(velocity)"
//                    if let lastOn = self.lastNoteOn {
//                        let diff = self.timeDifference(startDate: lastOn, endDate: Date())
//                        out += " Value:" + diff
//                    }
//                    return nil
//                }
//            case 0x90:
//                // Note On
//                if bytes.count >= 3 {
//                    let note = bytes[1]
//                    let velocity = bytes[2]
//                    let noteStatus = velocity == 0 ? "Note Off" : "Note On"
//                    var out = "\(noteStatus) - Channel \(channel + 1), Note \(note), Velocity \(velocity)"
//                    if let lastOn = self.lastNoteOn {
//                        let diff = self.timeDifference(startDate: lastOn, endDate: Date())
//                        out += " Value:" + diff
//                    }
//                    if velocity != 0 {
//                        self.lastNoteOn = Date()
//                    }
//                    return MIDIMessage(messageType: Int(messageType), midi: Int(note))
//                }
//            case 0xA0:
//                // Polyphonic Key Pressure (Aftertouch)
//                if bytes.count >= 3 {
//                    //let note = bytes[1]
//                    //let pressure = bytes[2]
//                    //return "Polyphonic Key Pressure - Channel \(channel + 1), Note \(note), Pressure \(pressure)"
//                    return nil
//                }
//            case 0xB0:
//                // Control Change
//                if bytes.count >= 3 {
//                    //let controller = bytes[1]
//                    //let value = bytes[2]
//                    //return "Control Change - Channel \(channel + 1), Controller \(controller), Value \(value)"
//                    return nil
//                }
//            case 0xC0:
//                // Program Change
//                if bytes.count >= 2 {
//                    //let program = bytes[1]
//                    //return "Program Change - Channel \(channel + 1), Program \(program)"
//                    return nil
//                }
//            case 0xD0:
//                // Channel Pressure (Aftertouch)
//                if bytes.count >= 2 {
//                    //let pressure = bytes[1]
//                    //return "Channel Pressure - Channel \(channel + 1), Pressure \(pressure)"
//                    return nil
//                }
//            case 0xE0:
//                // Pitch Bend Change
//                if bytes.count >= 3 {
//                    let lsb = bytes[1]
//                    let msb = bytes[2]
//                    //let value = (Int(msb) << 7) | Int(lsb)
//                    //return "Pitch Bend Change - Channel \(channel + 1), Value \(value)"
//                    return nil
//                }
//            default:
//                //return "Unknown MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
//                return nil
//            }
//        }
//        //return "Incomplete MIDI Message: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))"
//        return nil
//    }
//    
//    func processMidiMessage(MIDImessage:MIDIMessage) {
//        //print("============= MidiManger Received MIDI", MIDImessage.midi)
//        if let target = self.installedNotificationTarget {
//            target(MIDImessage)
//        }
//    }
//    
//    /// ------------- Functions to describe MIDI sources -------------
//
//    /// Describes the properties of a given MIDIEndpointRef by printing its details.
//    ///
//    /// - Parameter endpoint: The MIDIEndpointRef to describe.
//    func describeMIDIEndpoint(_ endpoint: MIDIEndpointRef) -> String {
//        // Helper function to retrieve a string property from a MIDI object
//        func getStringProperty(of object: MIDIObjectRef, property: CFString) -> String {
//            var param: Unmanaged<CFString>?
//            let status = MIDIObjectGetStringProperty(object, property, &param)
//            if status == noErr, let cfString = param?.takeUnretainedValue() {
//                return cfString as String
//            }
//            return "Unknown"
//        }
//        
//        // Helper function to retrieve an integer property from a MIDI object
//        func getIntegerProperty(of object: MIDIObjectRef, property: CFString) -> UInt32 {
//            var value: UInt32 = 0
//            let status = MIDIObjectGetIntegerProperty(object, property, &value)
//            if status == noErr {
//                return value
//            }
//            return 0
//        }
//        
//        // Retrieve MIDI Endpoint Properties
//        let name = getStringProperty(of: endpoint, property: kMIDIPropertyName)
//        let manufacturer = getStringProperty(of: endpoint, property: kMIDIPropertyManufacturer)
//        //let uniqueID = getIntegerProperty(of: endpoint, property: kMIDIPropertyUniqueID)
//        let displayName = getStringProperty(of: endpoint, property: kMIDIPropertyDisplayName)
//        let model = getStringProperty(of: endpoint, property: kMIDIPropertyModel)
//
//        let description = "Name:" + name + " Manufacturer:" + manufacturer + " Display:" + displayName + " Model:" + model
////        print("MIDI Endpoint Properties:")
////        print("  Name: \(name)")
////        print("  Manufacturer: \(manufacturer)")
////        print("  Unique ID: \(uniqueID)")
////        print("  Display Name: \(displayName)")
////        print("  Model: \(model)")
//        return description
//    }
//    
//    func setTestMidiNotesNotes(_ notes:TestMidiNotes) {
//        self.testMidiNotes = notes
//    }
//}
//
////    func getAllProperties(_ endpoint:MIDIEndpointRef) -> String {
////        var desc = ""
////        let propertyKeys: [CFString] = [
////            kMIDIPropertyDisplayName,
////            kMIDIPropertyName,
////            //kMIDIPropertyTransport,
////            //kMIDIPropertyManufacturer,
////            //kMIDIPropertyModel,
////            kMIDIPropertyDriverOwner
////        ]
////        var propertyData: Unmanaged<CFPropertyList>?
////
////
////        for key in propertyKeys {
////            var propertyValue: Unmanaged<CFString>?
////            let result = MIDIObjectGetStringProperty(endpoint, key, &propertyValue)
////            if result == noErr, let value = propertyValue?.takeUnretainedValue() as String? {
////                let midiDesc = " [\(key):\(value)] "
////                desc += midiDesc
////            }
////        }
////        return desc
////    }
