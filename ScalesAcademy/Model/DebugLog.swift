import Foundation

struct DebugLogEntry: Identifiable {
    let id = UUID()
    let serial: Int
    let midi: Int
    let amplitude: Float
}

class DebugLog: ObservableObject {
    static let shared = DebugLog()
    @Published private(set) var entries: [DebugLogEntry] = []
    private var counter = 0

    func clear() {
        counter = 0
        entries = []
    }

    @discardableResult
    func append(midi: Int, amplitude: Float) -> DebugLogEntry {
        counter += 1
        let entry = DebugLogEntry(serial: counter, midi: midi, amplitude: amplitude)
        entries.append(entry)
        return entry
    }
}
