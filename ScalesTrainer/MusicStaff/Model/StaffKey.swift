import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit


public class StaffKey : ObservableObject, Equatable, Hashable, Identifiable {
    public let id = UUID()
    public var keySig: KeySignature
    public var type: StaffKeyType
    public enum StaffKeyType {
        case major
        case minor
    }
        
    ///The midi closest to middle C
    public var centralMidi = 0
    
    public static func == (lhs: StaffKey, rhs: StaffKey) -> Bool {
        return (lhs.type == rhs.type) && (lhs.keySig.accidentalCount == rhs.keySig.accidentalCount) &&
        (lhs.keySig.accidentalType == rhs.keySig.accidentalType)
    }
    
    public init(type: StaffKeyType, keySig:KeySignature) {
        self.keySig = keySig
        self.type = type
        if keySig.accidentalType == .sharp {
            switch keySig.accidentalCount {
            case 0:
                centralMidi = 60
            case 1:
                centralMidi = 55 ///G
            case 2:
                centralMidi = 62
            case 3:
                centralMidi = 57
            case 4:
                centralMidi = 64
            case 5:
                centralMidi = 59 //B major
            case 6:
                centralMidi = 66 //F# major
            case 7:
                centralMidi = 61 //C#
            default:
                centralMidi = 60
            }
        }
        else {
            switch keySig.accidentalCount {
            case 0:
                centralMidi = 60 //C
            case 1:
                centralMidi = 65 //F
            case 2:
                centralMidi = 58 //B flat
            case 3:
                centralMidi = 63 //E flat
            case 4:
                centralMidi = 56 //A flat
            case 5:
                centralMidi = 61 //D flat
            case 6:
                centralMidi = 66 //G flat
            case 7:
                centralMidi = 59 //B
            default:
                centralMidi = 60
            }
        }
        if type == .minor {
            centralMidi -= 3
            if 60 - centralMidi > 6 {
                centralMidi += 12
            }
        }
    }
        
    public func hasKeySignatureNote(note:Int) -> Bool {
        var result:Bool = false
        for n in keySig.sharps {
            let octaves = StaffNote.getAllOctaves(note: n)
            if octaves.contains(note) {
                result = true
                return result
            }
        }
        for n in keySig.flats {
            let octaves = StaffNote.getAllOctaves(note: n)
            if octaves.contains(note) {
                result = true
                return result
            }
        }

        return result
    }
    
//    ///Return the chord triad type for a scale degree
//    public func getTriadType(scaleOffset: Int) -> Chord.ChordType {
//        if self.type == KeyType.major {
//            if ([0, 5, 7].contains(scaleOffset)) {
//                return Chord.ChordType.major
//            }
//            if ([11].contains(scaleOffset)) {
//                return Chord.ChordType.diminished
//            }
//            return Chord.ChordType.minor
//        }
//        else {
//            if ([0, 5, 7].contains(scaleOffset)) {
//                return Chord.ChordType.minor
//            }
//            if ([2].contains(scaleOffset)) {
//                return Chord.ChordType.diminished
//            }
//            return Chord.ChordType.major
//        }
//    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(keySig.accidentalCount)
    }
    
    ///Return the key's description
    public func getKeyName(withType:Bool) -> String {
        var desc = ""
        if keySig.accidentalType == AccidentalType.sharp {
            switch self.keySig.accidentalCount {
            case 0:
                desc = self.type == StaffKeyType.major ? "C" : "A"
            case 1:
                desc = self.type == StaffKeyType.major ? "G" : "E"
            case 2:
                desc = self.type == StaffKeyType.major ? "D" : "B"
            case 3:
                desc = self.type == StaffKeyType.major ? "A" : "F#"
            case 4:
                desc = self.type == StaffKeyType.major ? "E" : "C#"
            default:
                desc = "unknown"
            }
        }
        else {
            switch self.keySig.accidentalCount {
            case 0:
                desc = self.type == StaffKeyType.major ? "C" : "A"
            case 1:
                desc = self.type == StaffKeyType.major ? "F" : "D"
            case 2:
                desc = self.type == StaffKeyType.major ? "B♭" : "G"
            case 3:
                desc = self.type == StaffKeyType.major ? "E♭" : "C"
            case 4:
                desc = self.type == StaffKeyType.major ? "A♭" : "F"
            case 5:
                desc = self.type == StaffKeyType.major ? "D♭" : "B♭"
            case 6:
                desc = self.type == StaffKeyType.major ? "G♭" : "E♭"
            case 7:
                desc = self.type == StaffKeyType.major ? "B" : "A♭"
            default:
                desc = "unknown"
            }
        }
        if withType {
            switch self.type {
            case StaffKeyType.major:
                desc += " Major"
            case StaffKeyType.minor:
                desc += " Minor"
            }
        }
        return desc
    }

    public func getKeyTagName() -> String {
        let keyTag:String
        switch keySig.accidentalCount {
        case 1:
            keyTag = "G"
        case 2:
            keyTag = "D"
        case 3:
            keyTag = "A"
        case 4:
            keyTag = "E"
        case 5:
            keyTag = "B"
        default:
            keyTag = "C"
        }
        return keyTag
    }
    
    public func makeTriadAt(timeSlice:TimeSlice, rootMidi:Int, value:Double, staffNum:Int) -> [StaffNote] {
        var result:[StaffNote] = []
        result.append(StaffNote(timeSlice:timeSlice, num: rootMidi, value: value, staffNum: staffNum))
        result.append(StaffNote(timeSlice:timeSlice, num: rootMidi + 4, value: value, staffNum: staffNum))
        result.append(StaffNote(timeSlice:timeSlice, num: rootMidi + 7, value: value, staffNum: staffNum))
        return result
    }
    
    ///Get the notes names for the given triad symbol
    func getTriadNoteNames(triadSymbol:String) -> String {
        var result = ""
        var rootPos = 0
        switch triadSymbol {
        case "IV":
            rootPos = 5
        case "V":
            rootPos = 7
        default:
            rootPos = 0
        }
        let firstPitch = centralMidi + rootPos
        for offset in [0, 4, 7] {
            let name = StaffNote.getNoteName(midiNum: firstPitch + offset)
            if result.count > 0 {
                result = result + " - "
            }
            result = result + name
        }
        return result
    }
}
