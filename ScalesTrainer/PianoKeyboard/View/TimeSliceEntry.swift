import Foundation
import SwiftUI

public enum TimeSliceEntryStatusType {
    case none
    case playedCorrectly
    case wrongPitch
    case wrongValue
}

public class TimeSliceEntry : ObservableObject, Identifiable, Equatable, Hashable {
    @Published public var status:TimeSliceEntryStatusType = .none
    
    public let id = UUID()
    public var staffNum:Int //Narrow the display of the note to just one staff
    public var timeSlice:TimeSlice

    private var value:Double = StaffNote.VALUE_QUARTER
    public var valueNormalized:Double? = nil

    init(timeSlice:TimeSlice, value:Double, staffNum: Int = 0) {
        self.value = value
        self.staffNum = staffNum
        self.timeSlice = timeSlice
    }
    
    public static func == (lhs: TimeSliceEntry, rhs: TimeSliceEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func isDotted() -> Bool {
        return [0.75, 1.5, 3.0].contains(value)
    }
    
//    func log(ctx:String) -> Bool {

//    }
    
    public func getValue() -> Double {
        return self.value
    }

    public func getColor(ctx:String, staff:Staff, adjustFor:Bool, log:Bool? = false) -> Color {
        var out:Color? = nil

        if timeSlice.statusTag == .pitchError {
            out = Color(.red)
        }
        if timeSlice.statusTag == .missingError {
            out = Color(.yellow)
        }
//        if adjustFor {
//            if Int.random(in: 0...10) < 5  {
//                if Int.random(in: 0...10) < 5  {
//                    out = Color(red: Double.random(in: 0.5...0.9), green: 0, blue: 0)
//                }
//                else {
//                    out = Color(red: 0, green: 0, blue: Double.random(in: 0.5...0.9))
//                }
//            }
//        }
        if out == nil {
            out = Color(.black)
        }
        return out!
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
