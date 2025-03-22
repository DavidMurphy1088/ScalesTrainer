//import XCTest
//import CoreMIDI
//
//final class ScalesStarUITests: XCTestCase {
//    let app = XCUIApplication()
//    
//    override func setUpWithError() throws {
//        // Create a MIDI client for the UI test
//        //try XCTUnwrap(MIDIClientCreate("UITestClient" as CFString, nil, nil, &midiClient), "Failed to create MIDI client")
//        
//        // Create a virtual source for sending MIDI messages
//        //try XCTUnwrap(MIDISourceCreate(midiClient, "UITestSource" as CFString, &virtualSource), "Failed to create MIDI source")
//        
//        ///If app.launch() is called in setUpWithError(), the app will launch again after the automatic launch by XCTest, causing it to appear as if it's being launched twice.
//        //////🥵🥵🥵🥵🥵🥵🥵🥵🥵 not clear where this supposed to be. But changed xCode scheme Run, Wait for Executable to be launched to true
//        ///Tests are invoked by Command-U (🥵 not run command)
//        //app.launch()
//        app.launchArguments = ["--UITestMode", "--EnableFeatureX"]
//        app.launchEnvironment = ["TestKey": "TestValue"]
//    }
//    
//    override func tearDownWithError() throws {
////        if midiClient != 0 {
////            MIDIClientDispose(midiClient)
////        }
//    }
//    
//    func testExample() throws {
//        continueAfterFailure = false
//        app.launch()
//
//        var tapMeButton = app.buttons["button_lead"]
//        XCTAssertTrue(tapMeButton.exists, "The 'Tap Me' button should exist.")
//        tapMeButton.tap()
//        
//        //let logTab = app.buttons["app_log"]
//        //XCTAssertTrue(logTab.exists, "log tab should exist")
//        //logTab.tap()
//        
////        tapMeButton = app.buttons["app_log"]
////        tapMeButton.tap()
//        
//        let chartView = app.otherElements["chart_title"]
//        //XCTAssert(chartView.exists, "ChartView does not exist")
//        // Wait for view to exist
//        XCTAssertTrue(chartView.waitForExistence(timeout: 15), "View did not appear within 15 seconds")
//
//        print("=========== END UI TEST")
//    }
//
//}
//
////private func listDestinationEndpoints() {
////    // Iterate through available MIDI destinations
////    for index in 0..<MIDIGetNumberOfDestinations() {
////        let destination = MIDIGetDestination(index)
////        // Get the destination's name
////        var name: Unmanaged<CFString>?
////        let nameResult = MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &name)
////
////        if nameResult == noErr {
////            if let name = name {
////                let endpointName = name.takeRetainedValue() as String
////            }
////        }
////    }
////}
//
////    func sendMIDINotification(_ note:Int) throws {
////        // Build a simple MIDI message (e.g., Note On for Middle C, velocity 64)
////        let noteOnMessage: [UInt8] = [0x90, UInt8(note), 64] // MIDI channel 1, middle C, velocity 64
////        let packet = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
////        var packetList = MIDIPacketList(numPackets: 1, packet: packet.pointee)
////
////        withUnsafeMutablePointer(to: &packetList) { packetListPtr in
////            let packet = MIDIPacketListInit(packetListPtr)
////            _ = MIDIPacketListAdd(packetListPtr, 1024, packet, 0, noteOnMessage.count, noteOnMessage)
////            for i in 0..<MIDIGetNumberOfDestinations() {
////                // Send the packet to the main app's input port
////                let destination = MIDIGetDestination(i) // Assuming the main app is listening on the first destination
////                XCTAssertNotEqual(destination, 0, "No valid MIDI destination found")
////                MIDISend(virtualSource, destination, packetListPtr)
////                print("============ sentMIDINotification to ", note, destination.description)
////            }
////        }
////    }
//    
////    func sendMIDINotificationBAD(_ note:Int) throws {
//////        guard let destinationEndpoint = findDestinationEndpoint() else {
//////            XCTFail("Could not find destination MIDI endpoint")
//////            return
//////        }
////        // Define the MIDI message: Note On (0x90) for middle C (60) with velocity 127
////        let noteOnMessage: [UInt8] = [0x90, UInt8(note), 127]
////
////        // Define the MIDI message: Note Off (0x80) for middle C (60) with velocity 0
////        let noteOffMessage: [UInt8] = [0x80, UInt8(note), 0]
////
////        // Convert messages to MIDIPacketList
////        func createPacketList(from message: [UInt8]) -> MIDIPacketList {
////            var packetList = MIDIPacketList()
////            var packet = MIDIPacketListInit(&packetList)
////            packet = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size, packet, 0, message.count, message)
////            return packetList
////        }
////
////        // Get the list of MIDI destinations
////        let destinationCount = MIDIGetNumberOfDestinations()
////        if destinationCount == 0 {
////            XCTFail("No MIDI destinations found. Ensure the app is ready to receive MIDI.")
////            return
////        }
////        print("========== SENDING MIDI", note, "destination Count:", destinationCount)
////
////        for d in 0..<destinationCount {
////            // For simplicity, use the first available destination
////            //let destination:MIDIEndpointRef = MIDIGetDestination(d)
////            let destination:MIDIEndpointRef = MIDIGetSource(d)
////            print("============ DESTINATION", d)
////
////            // Create and send Note On message
////            var noteOnPacketList = createPacketList(from: noteOnMessage)
////            let sendStatusOn = MIDISend(midiOutPort, destination, &noteOnPacketList)
////            if sendStatusOn != noErr {
////                XCTFail("Failed to send Note On message: \(sendStatusOn)")
////            }
////
////            // Optionally, add a short delay to simulate the duration of the note
////    //        sleep(1) // Sleep for 1 second
////
////            // Create and send Note Off message
////    //        var noteOffPacketList = createPacketList(from: noteOffMessage)
////    //        let sendStatusOff = MIDISend(midiOutPort, destination, &noteOffPacketList)
////    //        if sendStatusOff != noErr {
////    //            XCTFail("Failed to send Note Off message: \(sendStatusOff)")
////    //        }
////        }
////    }
