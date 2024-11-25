import Foundation
import SwiftUI

public class TimeSliceEntry : ObservableObject, Identifiable, Equatable, Hashable {
    public let id = UUID()
    let handType:HandType
    public var timeSlice:TimeSlice
    private var value:Double = StaffNote.VALUE_QUARTER
    public var valueNormalized:Double? = nil
    let segments:[Int]
    
    init(timeSlice:TimeSlice, value:Double, handType:HandType, segments:[Int]) {
        self.timeSlice = timeSlice
        self.value = value
        self.handType = handType
        self.segments = segments
    }
    
    public static func == (lhs: TimeSliceEntry, rhs: TimeSliceEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func isDotted() -> Bool {
        if ScalesModel.shared.scale.timeSignature.bottom == 8 {
            return [1.0].contains(value)
        }
        return [0.75, 1.5, 3.0].contains(value)
    }
    
    public func getValue() -> Double {
        return self.value
    }

    public func getColor(staff:Staff) -> Color {
        return Color.black
//        var out:Color? = nil
//
//        if timeSlice.statusTag == .pitchError {
//            out = Color(.red)
//        }
//        if timeSlice.statusTag == .missingError {
//            out = Color(.yellow)
//        }
////        if adjustFor {
////            if Int.random(in: 0...10) < 5  {
////                if Int.random(in: 0...10) < 5  {
////                    out = Color(red: Double.random(in: 0.5...0.9), green: 0, blue: 0)
////                }
////                else {
////                    out = Color(red: 0, green: 0, blue: Double.random(in: 0.5...0.9))
////                }
////            }
////        }
//        if out == nil {
//            out = Color(.black)
//        }
//        return out!
    }

    func setValue(value:Double) {
        self.value = value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func getNoteValueName() -> String {
        var name = self.isDotted() ? "dotted " : ""
        switch self.value {
        case 0.25 :
            name += "semi quaver"
        case 0.50 :
            name += "quaver"
        case 1.0 :
            name += "crotchet"
        case 1.5 :
            name += "dotted crotchet"
        case 2.0 :
            name += "minim"
        case 3.0 :
            name += "minim"
        default :
            name += "semibreve"
        }
        return name
    }
    
    static func getValueName(value:Double) -> String {
        var name = ""
        switch value {
        case 0.25 :
            name += "semi quaver"
        case 0.50 :
            name += "quaver"
        case 1.0 :
            name += "crotchet"
        case 1.5 :
            name += "dotted crotchet"
        case 2.0 :
            name += "minim"
        case 3.0 :
            name += "dotted minim"
        case 4.0 :
            name += "semibreve"
        default :
            name += "unknown value \(value)"
        }
        return name
    }
}
