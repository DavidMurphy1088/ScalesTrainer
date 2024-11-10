import Foundation
import SwiftUI

public class StaffClef : ScoreEntry {
    let staffType:StaffType
    init(staffType:StaffType) {
        self.staffType = staffType
    }
}
