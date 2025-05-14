import Foundation
import SwiftUI

public class TimeSliceEntry : ObservableObject, Codable, Identifiable, Equatable, Hashable {
    @Published public var showIsPlaying:Bool = false
    public let id = UUID()
    ///Hand is needed to now which staff to place the note into
    let handType:HandType
    
    public var timeSlice:TimeSlice
    private var value:Double = StaffNote.VALUE_QUARTER
    public var valueNormalized:Double? = nil
    let segments:[Int]
    
    enum CodingKeys: String, CodingKey {
        case timeSlice
        case value
    }

    init(timeSlice:TimeSlice, value:Double, handType:HandType, segments:[Int]) {
        self.timeSlice = timeSlice
        self.value = value
        self.handType = handType
        self.segments = segments
    }

    ///NB - not called for a class that is derived from this one. e.g. StaffNote
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        ///Dont encode the parent - causes infinite loop
        //try container.encode(timeSlice, forKey: .timeSlice)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decode(String.self, forKey: .value)
        let timeslice = try container.decode(String.self, forKey: .value)
        self.handType = .left
        self.segments = []
    }
    
    public static func == (lhs: TimeSliceEntry, rhs: TimeSliceEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    func setShowIsPlaying(_ way:Bool) { //status: TimeSliceEntryStatusType) {
        DispatchQueue.main.async {
            if way != self.showIsPlaying {
                let x = self as! StaffNote
                let note = self as! StaffNote
                self.showIsPlaying = way
            }
        }
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

    public func getColor(staff:Staff, resultStatus:StaffNoteResultStatus? = nil) -> Color {
        if let resultStatus = resultStatus {
            if resultStatus.rhythmOffset == 0 {
                return Color.green
            }
        }
        return Color.black
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
