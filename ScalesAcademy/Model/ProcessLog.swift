import Foundation

class ProcessLog: ObservableObject {
    static let shared = ProcessLog()
    @Published private(set) var lines: [String] = []
    @Published private(set) var header: String = ""
    private var paused = false
    private var counter = 0
    private var startTime: Date? = nil

    func clear() {
        DispatchQueue.main.async {
            self.lines = []
            self.header = ""
            self.counter = 0
            self.paused = false
            self.startTime = Date()
        }
    }

    func pause() {
        DispatchQueue.main.async { self.paused = true }
    }

    func resume() {
        DispatchQueue.main.async { self.paused = false }
    }

    func setHeader(_ text: String) {
        DispatchQueue.main.async { self.header = text }
    }

    /// Log a numbered line. Prints to console and stores in popup when not paused.
    /// Safe to call from any thread.
    func log(_ line: String) {
        DispatchQueue.main.async {
            guard !self.paused else { return }
            self.counter += 1
            let elapsed = self.startTime.map { Date().timeIntervalSince($0) } ?? 0.0
            let secs = Int(elapsed)
            let hundredths = Int((elapsed - Double(secs)) * 100)
            let timeStr = String(format: "%02d.%02d", secs, hundredths)
            let numbered = "\(timeStr) \(self.counter): \(line)"
            print(numbered)
            self.lines.append(numbered)
        }
    }
}
