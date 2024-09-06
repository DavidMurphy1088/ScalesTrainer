import Foundation

public class ScaleRoot : Codable{
    let sharps:Int
    let flats:Int
    var name:String

    init(name:String) {
        //self.keyType = keyType
        self.name = name
        if false {
            switch name {
            case "E":
                self.flats = 0
                self.sharps = 1
            case "B":
                self.flats = 0
                self.sharps = 2
            case "F#":
                self.flats = 0
                self.sharps = 3
            case "C#":
                self.flats = 0
                self.sharps = 4
//            case "A♭":
//                self.flats = 0
//                self.sharps = 5

            case "D":
                self.flats = 1
                self.sharps = 0
            case "G":
                self.flats = 2
                self.sharps = 0
            case "C":
                self.flats = 3
                self.sharps = 0
            case "F":
                self.flats = 4
                self.sharps = 0
            case "B♭":
                self.flats = 5
                self.sharps = 0
            case "E♭":
                self.flats = 6
                self.sharps = 0
            case "A♭":
                self.flats = 7
                self.sharps = 0
            case "D♭":
                self.flats = 8
                self.sharps = 0

            default:
                self.flats = 0
                self.sharps = 0
            }
        }
        else {
            switch name {
            case "G":
                self.flats = 0
                self.sharps = 1
            case "D":
                self.flats = 0
                self.sharps = 2
            case "A":
                self.flats = 0
                self.sharps = 3
            case "E":
                self.flats = 0
                self.sharps = 4
            case "B":
                self.flats = 0
                self.sharps = 5

            case "F":
                self.flats = 1
                self.sharps = 0
            case "B♭":
                self.flats = 2
                self.sharps = 0
            case "E♭":
                self.flats = 3
                self.sharps = 0
            case "A♭":
                self.flats = 4
                self.sharps = 0
            case "D♭":
                self.flats = 5
                self.sharps = 0
            default:
                self.flats = 0
                self.sharps = 0
            }
        }
        //self.keySignature = KeySignature(keyName: name, keyType: keyType == .major ? .major : .minor)
    }
    
//    func getName() -> String {
//        var name = self.name + " "
//        switch self.keyType {
//        case .minor:
//            name += "Minor"
//        case .harmonicMinor:
//            name += "Harmonic Minor"
//        case .melodicMinor:
//            name += "Melodic Minor"
//        default:
//            name += "Major"
//        }
//        return name
//    }
    
    func getRootMidi() -> Int {
        var midi = 0
        switch name {
        case "D":
            midi = 62
        case "E":
            midi = 64
        case "F":
            midi = 65
        case "G":
            midi = 67
        case "A":
            midi = 69
        default:
            midi = 60
        }
        return midi
    }
}
