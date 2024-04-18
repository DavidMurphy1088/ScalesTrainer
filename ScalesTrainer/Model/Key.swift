

import Foundation

enum KeyType {
    case major
    case minor
}

class Key {
    let name = ""
    let sharps:Int
    let flats:Int
    var keyType:KeyType
    
    init(sharps:Int, flats:Int, type:KeyType) {
        self.sharps = sharps
        self.flats = flats
        self.keyType = type
        let name = ""
    }
    
    
}
