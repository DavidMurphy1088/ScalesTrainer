import Foundation
import AVKit
import AVFoundation

public class KeySignature {
    var keyType:StaffKey.StaffKeyType
    var sharps:[Int] = [] //Notes of this pitch dont require individual accidentals, their accidental is implied by the key signature
    var flats:[Int] = [] //Notes of this pitch dont require individual accidentals, their accidental is implied by the key signature
    public var accidentalCount:Int = 0
    var accidentalType:AccidentalType

    public init(keyName:String, keyType:StaffKey.StaffKeyType) {
        self.keyType = keyType
        self.accidentalType = .sharp
        
        var count:Int = 0
        if keyType == .major {
            switch keyName {
            case "C":
                count = 0
            case "G":
                count = 1
            case "F":
                self.accidentalType = .flat
                count = 1
            case "D":
                count = 2
            case "B♭":
                self.accidentalType = .flat
                count = 2
            case "A":
                count = 3
            case "E♭":
                self.accidentalType = .flat
                count = 3
            case "E":
                count = 4
            case "A♭":
                self.accidentalType = .flat
                count = 4
            case "B":
                count = 5
            case "D♭":
                self.accidentalType = .flat
                count = 5
            case "G♭":
                self.accidentalType = .flat
                count = 6
            default:
                count = 0
            }
        }
        else {
            switch keyName {
            case "A":
                count = 0
            case "E":
                count = 1
            case "D":
                count = 1
                self.accidentalType = .flat
            case "B":
                count = 2
            case "G#":
                count = 5
                self.accidentalType = .sharp
            case "G":
                count = 2
                self.accidentalType = .flat
            case "F#":
                count = 3
            case "C":
                count = 3
                self.accidentalType = .flat
            case "C#":
                count = 4
            case "F":
                count = 4
                self.accidentalType = .flat
            case "B♭":
                count = 5
                self.accidentalType = .flat
            case "E♭":
                count = 6
                self.accidentalType = .flat
            case "A♭":
                count = 7
                self.accidentalType = .flat
            case "D♭":
                count = 8
                self.accidentalType = .flat
            default:
                count = 0
            }
        }
        self.accidentalCount = count
        setAccidentals(keyType: keyType, accidentalType: self.accidentalType)
    }
    
    func setAccidentals(keyType:StaffKey.StaffKeyType, accidentalType:AccidentalType) {
        if accidentalType == .sharp {
            if self.accidentalCount >= 1 {
                //self.accidentalCount = 1
                sharps.append(StaffNote.MIDDLE_C + 6) //F#
            }
            if self.accidentalCount >= 2 {
                sharps.append(StaffNote.MIDDLE_C + 1) //C#
            }
            if self.accidentalCount >= 3 {
                sharps.append(StaffNote.MIDDLE_C + 8) //G#
            }
            if self.accidentalCount >= 4 {
                sharps.append(StaffNote.MIDDLE_C + 3) //D#
            }
            if self.accidentalCount >= 5 {
                sharps.append(StaffNote.MIDDLE_C + 10) //A#
            }
        }
        else {
            if self.accidentalCount >= 1 {
                flats.append(StaffNote.MIDDLE_C + 10) //B♭
            }
            if self.accidentalCount >= 2 {
                flats.append(StaffNote.MIDDLE_C + 3) //E♭
            }
            if self.accidentalCount >= 3 {
                flats.append(StaffNote.MIDDLE_C + 8) //A♭
            }
            if self.accidentalCount >= 4 {
                flats.append(StaffNote.MIDDLE_C + 1) //D♭
            }
            if self.accidentalCount >= 5 {
                flats.append(StaffNote.MIDDLE_C + 6) //G♭
            }
            if self.accidentalCount >= 6 {
                flats.append(StaffNote.MIDDLE_C + 11) //C flat
            }
            if self.accidentalCount >= 7 {
                flats.append(StaffNote.MIDDLE_C + 5) 
            }
        }
    }
}
