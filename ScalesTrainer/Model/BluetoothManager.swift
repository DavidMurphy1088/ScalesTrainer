import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    var centralManager: CBCentralManager!
    static let shared = BluetoothManager()
    
    var connectedPeripherals: [CBPeripheral] = []
    let midiServiceUUIDs: [CBUUID] = [
        CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700") // Standard MIDI over BLE Service UUID
    ]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Bluetooth is available and ready to use
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        case .poweredOff:
            print("🥶 Bluetooth is off. Please turn it on.")
        case .unauthorized:
            print("🥶 Bluetooth usage is not authorized.")
        case .unsupported:
            print("🥶 Bluetooth is not supported on this device.")
        case .unknown, .resetting:
            print("🥶 Bluetooth state is resetting or unknown.")
        @unknown default:
            print("🥶 A new state has been introduced.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("🥶 Discovered: \(peripheral.name ?? "Unknown Device")")
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
        print("🥶 Connected to: \(peripheral.name ?? "Unknown Device")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🥶 Connected to \(peripheral.name ?? "Unknown Device")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("🥶 Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func startUp() {
//        let session = MIDINetworkSession.default()
//        session.isEnabled = true
//        session.connectionPolicy = .anyone // Adjust as needed
//        print("Bluetooth MIDI Enabled")
        
//        if retrieveConnectedMIDIDevices() == 1000 {
//            print("🥶 Scanning for MIDI devices...")
//            //        guard centralManager.state == .poweredOn else {
//            //            print("🥶 Central Manager is not powered on.")
//            //            return
//            //        }
//            //        print("🥶 Started scanning for peripherals.")
//            ///Scan for any Bluetooth capable devices, not necessarily MIDI capable.
//            centralManager.scanForPeripherals(withServices: nil, options: nil)
//        }
    }
    ///Works only for peripherals that are already connected to the system.
    ///If the MIDI device is not connected (or only advertising), it will not appear in the result.
    ///
    func retrieveConnectedMIDIDevices() -> Int {
        // Retrieve peripherals already connected with the MIDI service UUID
        connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: midiServiceUUIDs)
        
        if connectedPeripherals.isEmpty {
            print("🥶 No connected MIDI devices found.")
        } else {
            for peripheral in connectedPeripherals {
                print("🥶 Connected MIDI Device: \(peripheral.name ?? "Unknown Device")")
                // Optionally, set the delegate and start interacting with the peripheral
                //peripheral.delegate = self.centralManager
                // Discover services if needed
                peripheral.discoverServices(nil)
            }
        }
        return connectedPeripherals.count
    }
}

