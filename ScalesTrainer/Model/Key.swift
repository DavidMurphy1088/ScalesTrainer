import Foundation

public enum KeyType {
    case major
    case minor
}

public class Key {
    let sharps:Int
    let flats:Int
    var keyType:KeyType
    var name:String

    init(sharps:Int=0, flats:Int=0, type:KeyType = .major) {
        self.sharps = sharps
        self.flats = flats
        self.keyType = type
        name = sharps == 0 ? "C" : "G"
    }
    
    init(name:String, keyType:KeyType) {
        self.keyType = keyType
        self.name = name
        switch name {
        case "G":
            self.flats = 0
            self.sharps = 1
        default:
            self.flats = 0
            self.sharps = 0
        }
    }
}
