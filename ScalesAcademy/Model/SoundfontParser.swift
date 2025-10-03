//import Foundation
//
//struct SF2Instrument {
//    let program: Int
//    let bank: Int
//    let name: String
//}
//
//func getInstrumentNamesFromSF2(filePath: String) -> [SF2Instrument] {
//    guard let data = NSData(contentsOfFile: filePath) else {
//        print("Could not read SF2 file")
//        return []
//    }
//    
//    var instruments: [SF2Instrument] = []
//    let bytes = data.bytes.bindMemory(to: UInt8.self, capacity: data.length)
//    
//    // Find the "phdr" chunk (preset header)
//    if let phdrOffset = findChunk(bytes: bytes, length: data.length, chunkID: "phdr") {
//        let phdrSize = readUInt32(bytes: bytes, offset: phdrOffset + 4)
//        let numPresets = Int(phdrSize) / 38 // Each preset header is 38 bytes
//        
//        for i in 0..<numPresets {
//            let presetOffset = phdrOffset + 8 + (i * 38)
//            
//            // Read preset name (20 bytes, null-terminated)
//            let nameData = Data(bytes: bytes + presetOffset, count: 20)
//            let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
//            
//            // Skip if it's the end-of-preset marker
//            if name == "EOP" { break }
//            
//            // Read preset number and bank (bytes 20-21 and 22-23)
//            let preset = Int(readUInt16(bytes: bytes, offset: presetOffset + 20))
//            let bank = Int(readUInt16(bytes: bytes, offset: presetOffset + 22))
//            if bank == 0 {
//                instruments.append(SF2Instrument(program: preset, bank: bank, name: name))
//            }
//        }
//    }
//    
//    return instruments.sorted { $0.program < $1.program }
//}
//
//// Helper function to find a chunk in the SF2 file
//func findChunk(bytes: UnsafePointer<UInt8>, length: Int, chunkID: String) -> Int? {
//    let id = chunkID.data(using: .ascii)!
//    let idBytes = [UInt8](id)
//    
//    for i in 0..<(length - 4) {
//        if bytes[i] == idBytes[0] &&
//           bytes[i+1] == idBytes[1] &&
//           bytes[i+2] == idBytes[2] &&
//           bytes[i+3] == idBytes[3] {
//            return i
//        }
//    }
//    return nil
//}
//
//// Helper to read little-endian UInt32
//func readUInt32(bytes: UnsafePointer<UInt8>, offset: Int) -> UInt32 {
//    return UInt32(bytes[offset]) |
//           (UInt32(bytes[offset+1]) << 8) |
//           (UInt32(bytes[offset+2]) << 16) |
//           (UInt32(bytes[offset+3]) << 24)
//}
//
//// Helper to read little-endian UInt16
//func readUInt16(bytes: UnsafePointer<UInt8>, offset: Int) -> UInt16 {
//    return UInt16(bytes[offset]) | (UInt16(bytes[offset+1]) << 8)
//}
//
