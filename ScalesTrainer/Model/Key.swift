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
        if flats == 0 {
            switch sharps {
            case 1:
                name = "G"
            case 2:
                name = "D"
            default:
                name = "C"
            }
        }
        else {
            switch sharps {
            case 2:
                name = "E♭"
            default:
                name = "B♭"
            }
        }
    }
    
    init(name:String, keyType:KeyType) {
        self.keyType = keyType
        self.name = name
        switch name {
        case "G":
            self.flats = 0
            self.sharps = 1
        case "D":
            self.flats = 0
            self.sharps = 2
        case "B♭":
            self.flats = 1
            self.sharps = 0
        case "E♭":
            self.flats = 2
            self.sharps = 0
        case "A♭":
            self.flats = 3
            self.sharps = 0
        case "D♭":
            self.flats = 4
            self.sharps = 0
        default:
            self.flats = 0
            self.sharps = 0
        }
    }
}
