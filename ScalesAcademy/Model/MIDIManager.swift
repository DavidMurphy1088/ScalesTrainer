import Foundation
import CoreMIDI

class MIDIMessage {
    enum MIDIStatus: UInt8 {
        case noteOff        = 0x80
        case noteOn         = 0x90
        case polyAftertouch = 0xA0
        case controlChange  = 0xB0
        case programChange  = 0xC0
        case channelPressure = 0xD0
        case pitchBend      = 0xE0
    }
    let messageType:MIDIStatus
    let midi:Int
    let velocity:Int
    init(messageType:MIDIStatus, midi:Int, velocity:Int) {
        self.messageType = messageType
        self.midi = midi
        self.velocity = velocity
    }
}

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

///The notes matched in a scale
class MatchedNotes {
    ///A note that was matched to the scale
    class Note {
        let sequenceNum: Int
        let timestamp:Date
        let midi:Int
        let handType:HandType
        let velocity:Int
        var duration:Double?
        
        init(midi:Int, handType:HandType, velocity:Int) {
            self.timestamp = Date()
            self.sequenceNum = 0
            self.midi = midi
            self.handType = handType
            self.velocity = velocity
        }
    }
    var hands:[HandType] = []
    var notes:[Note] = []
    var startTimestamp:Date?
    
    init () {
    }
    
    func start(hands:[HandType]) {
        startTimestamp = nil
        self.notes = []
        self.hands = hands
    }
    
    func applyToScore(score:Score) {
        debug1("ResultView OnAppear")
        for ts in score.getAllTimeSlices() {
            for note in ts.getTimeSliceNotes(handType: .right) {
                let status = StaffNoteResultStatus()
                note.staffNoteResultStatus = status
            }
        }
    }
    func resetScore(score:Score) {
        debug1("ResultView OnAppear")
        for ts in score.getAllTimeSlices() {
            for note in ts.getTimeSliceNotes(handType: .right) {
                note.staffNoteResultStatus = nil
            }
        }
    }
    
    func debug1(_ msg:String) {
        print("======== Matched Notes \(msg) =======")
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss.SSS"
        for note in self.notes {
            var timeFromStart = 0.0
            if let startTimestamp = self.startTimestamp {
                timeFromStart = note.timestamp.timeIntervalSince(startTimestamp)
            }
            var dur = ""
            if let duration = note.duration {
                dur = String(format: "%.2f", duration)
            }
            print("   ", String(format: "%.2f", timeFromStart),
                  "Hand:\(note.handType) \tMidi:\(note.midi) \tVel:\(note.velocity) \tDuration:\(dur)")
        }
    }
    
    func processNoteOn(midi: Int, handType: HandType, velocity: Int) {
        let note = Note(midi: midi, handType: handType, velocity: velocity)
        self.notes.append(note)
        if self.startTimestamp == nil {
            self.startTimestamp = note.timestamp
        }
        //debug("NoteOn")
    }
    func processNoteOff(midi: Int) {
        for n in self.notes.reversed() {
            if n.midi == midi {
                let diff = Date().timeIntervalSince(n.timestamp)
                n.duration = diff
                break
            }
        }
        //debug("NoteOff")
    }

}

class MIDIManager : ObservableObject {
    static let shared = MIDIManager()
    
    @Published var connectionSourcesPublished:[String] = []
    private var connectedSources: Set<MIDIEndpointRef> = []

    private var midiClient: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0
    private let log = AppLogger.shared
    
    var testMidiNotes:TestMidiNotes?
    var testMidiNotesStopPlaying = false
    var matchedNotes:MatchedNotes
    
    private var installedNotificationTarget: ((MIDIMessage) -> Void)?

    init() {
        matchedNotes = MatchedNotes()
    }
    
    func playTestMidiNotes(soundHandler:SoundEventHandlerProtocol) {
        testMidiNotesStopPlaying = false
        if let notify = soundHandler.getFunctionToNotify() {
            if let testNotes = self.testMidiNotes {
                DispatchQueue.global(qos: .background).async {
                    for noteSet in testNotes.noteSets {
                        if self.testMidiNotesStopPlaying {
                            break
                        }
                        DispatchQueue.main.async {
                            for note in noteSet.notes {
                                //Logger.shared.log(self, "sending note:\(note) notify:\(self.functionToNotify != nil)")
                                notify(MIDIMessage(messageType: MIDIMessage.MIDIStatus.noteOn, midi: note, velocity: 50))
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    notify(MIDIMessage(messageType: MIDIMessage.MIDIStatus.noteOff, midi: note, velocity: 0))
                                }
                            }
                            usleep(UInt32(0.2 * 1000000))
                        }
                        let noteSetDelay = UInt32(1000000 * testNotes.noteSetWait)
                        usleep(noteSetDelay)
                    }
                }
            }
        }
    }
    
    func processMidiMessage(MIDImessage:MIDIMessage) {
        if let target = self.installedNotificationTarget {
            target(MIDImessage)
        }
    }
    
    ///Tell the manager where to send MIDI notifcations
    func installNotificationTarget(target:((MIDIMessage) -> Void)?) {
        self.installedNotificationTarget = target
    }

    func setupMIDIUnused() {
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

    public func scanMIDISources() {
        self.disconnectAll()
        let numSources = MIDIGetNumberOfSources()
        if numSources == 0 {
            return
        }
        log.log(self, "Scanning MIDI sources")
        
        for i in 0..<numSources {
            let endpoint:MIDIEndpointRef = MIDIGetSource(i)
            if let driver = getMIDIProperty(endpoint, kMIDIPropertyDriverOwner) {
                ///Filter out Apple virtual network driver or connections from other Apple devices
                if !Parameters.shared.testMode {
                    if driver.lowercased().contains("apple") {
                        continue
                    }
                }
                if !connectedSources.contains(endpoint) {
                    connectToSource(endpoint)
                }
            }
        }
        log.log(self, "Connected MIDI sources count:\(self.connectedSources.count)")
    }

    private func connectToSource(_ source: MIDIEndpointRef) {
        let endPointDetails = getEndpointDetails(source)
        let result = MIDIPortConnectSource(inputPort, source, nil)
        
        if result != noErr {
            log.log(self, "Failed to connect to source \(endPointDetails): \(result)")
            notifyUser(ofError: "Failed to connect to MIDI Source: \(endPointDetails)")
            return
        }
        connectedSources.insert(source)
        log.log(self, "Connected to MIDI source. \(endPointDetails)")
        DispatchQueue.main.async {
            self.connectionSourcesPublished.append(endPointDetails)
        }

        // Notify UI about device change
        NotificationCenter.default.post(name: .midiDeviceChanged, object: nil)
    }
    
   private func disconnectFromSource(_ source: MIDIEndpointRef) {
       let endPointDetails = getEndpointDetails(source)
       let result = MIDIPortDisconnectSource(inputPort, source)
       if result != noErr {
            log.reportError(self, "Failed to disconnect from source \(endPointDetails): \(result)")
            return
       }
       connectedSources.remove(source)
//       DispatchQueue.main.async {
//           self.connectionSourcesPublished.remove(endPointDetails)
//       }

       log.log(self, "Disconnected from source: \(endPointDetails)")
       // Notify UI about device change
       NotificationCenter.default.post(name: .midiDeviceChanged, object: nil)
    }
    
    func getMIDIProperty(_ endpoint: MIDIEndpointRef, _ property: CFString) -> String? {
        var unmanaged: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, property, &unmanaged)
        if status == noErr, let value = unmanaged?.takeUnretainedValue() {
            return value as String
        }
        return nil
    }
    
    func getEndpointDetails(_ endpoint: MIDIEndpointRef) -> String {
        let name = getMIDIProperty(endpoint, kMIDIPropertyName) ?? "Unknown"
        let model = getMIDIProperty(endpoint, kMIDIPropertyModel) ?? "Unknown"
        let driver = getMIDIProperty(endpoint, kMIDIPropertyDriverOwner) ?? "Unknown"
        //let desc = endpoint.description
        return "Name:\(name) Model:\(model) Driver:\(driver)"
    }
    
//    private func getDeviceName(from endpoint: MIDIEndpointRef) -> String {
//        var paramName: Unmanaged<CFString>?
//        let result = MIDIObjectGetStringProperty(endpoint, kMIDIPropertyName, &paramName)
//        if result == noErr, let name = paramName?.takeUnretainedValue() {
//            return name as String
//        }
//        return "Unknown"
//    }
    
    ///https://developer.apple.com/documentation/coremidi/midiobjectref
    ///This function disabled 8Jan2025. Cant figure out how to determine type of endpoint and connection attempt always fails.
    func handleDeviceAdded(_ endpoint: MIDIObjectRef) {
        //Logger.shared.log(self, "Device Added. ObjectRef:\(endpoint)")
        //let type = getMIDIObjectType(endpoint)
        //let type = getMIDIObjectType(endpoint)
        //if type == .source {
//            let source = MIDIEndpointRef(endpoint)
//            if !connectedSources.contains(source) {
//                connectToSource(source)
//            }
//        //}
    }
    
    func handleDeviceRemoved(_ endpoint: MIDIObjectRef) {
        //Logger.shared.log(self, "Device Added. ObjectRef:\(endpoint)")
        //let type = getMIDIObjectType(endpoint)
        //if type == .source { // Direct comparison without rawValue
//            let source = MIDIEndpointRef(endpoint)
//            if connectedSources.contains(source) {
//                disconnectFromSource(source)
//            }
        //}
    }

    func disconnectAll() {
        for source in connectedSources {
            disconnectFromSource(source)
        }
        self.connectedSources = []
        DispatchQueue.main.async {
            self.connectionSourcesPublished = []
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
                    return MIDIMessage(messageType: MIDIMessage.MIDIStatus.noteOff, midi: Int(note), velocity: Int(velocity))
                }
            case 0x90:
                // Note On
                if bytes.count >= 3 {
                    let note = bytes[1]
                    let velocity = bytes[2]
                    let noteStatus = velocity == 0 ? "Note Off" : "Note On"
                    var out = "\(noteStatus) - Channel \(channel + 1), Note \(note), Velocity \(velocity)"
//                    if let lastOn = self.lastNoteOn {
//                        let diff = self.timeDifference(startDate: lastOn, endDate: Date())
//                        out += " Value:" + diff
//                    }
//                    if velocity != 0 {
//                        self.lastNoteOn = Date()
//                    }
                    return MIDIMessage(messageType: MIDIMessage.MIDIStatus.noteOn, midi: Int(note), velocity: Int(velocity))
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

///Setup callbacks to handle new and removed MIDI connections while the app is running.
private let midiSetupNotifyProc: MIDINotifyProc = { (message, refCon) in
    guard let refCon = refCon else {
        return
    }
    let midiManager = Unmanaged<MIDIManager>.fromOpaque(refCon).takeUnretainedValue()
    let messageID = message.pointee.messageID

    switch messageID {
    case .msgObjectAdded:
        //AppLogger.shared.log(MIDIManager.shared, "MIDI Object Added")
        let notification = message.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) { $0.pointee }
        midiManager.handleDeviceAdded(notification.child)
        
    case .msgObjectRemoved:
        //AppLogger.shared.log(MIDIManager.shared, "MIDI Object Removed")
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
    
    init(scale:Scale, hands:[Int], noteSetWait:Double, withErrors:Bool) {
        let totalNotes = scale.getScaleNoteCount()
        self.noteSetWait = noteSetWait
        self.noteSets = []
        self.scaleId = UUID() // = was = scale.id 🥵🥵🥵🥵🥵🥵🥵🥵🥵 but having "id" in scale serialisationm wrecks regression tests
        
        for n in 0..<totalNotes {
            var noteSet:[Int] = []
            for hand in hands {
                if let noteState = scale.getScaleNoteState(handType: hand==0 ? .right : .left, index: n) {
                    var midi = noteState.midi
                    if n == 4 && withErrors {
                        midi += 1
                    }
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
}

