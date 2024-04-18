
import Foundation

class ScalesModel : ObservableObject {
    @Published var requiredStartAmplitude:Double? = nil
    @Published var statusMessage = ""

    public static let shared = ScalesModel()
    
    let keyValues = ["C", "G", "D", "A", "E", "F", "B♭", "E♭", "A♭", "D♭"]
    let scaleTypes = ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Arpegeggio", "Chromatic"]
    let octaveNumberValues = [1,2,3,4]
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler = PitchTapHandler(requiredStartAmplitude: 0, scaleMatcher: nil)
    
    init() {
        let amplitude = UserDefaults.standard.double(forKey: "requiredStartAmplitude")
        if amplitude > 0 {
            self.requiredStartAmplitude = amplitude
        }
    }
    
    func setStatusMessage(_ msg:String) {
        DispatchQueue.main.async {
            self.statusMessage = msg
        }
    }
    
    func doCallibration(amplitudes:[Float]) {
        let n = 4
        guard amplitudes.count >= n else {
            Logger.shared.log(self, "Callibration amplitudes must contain at least \(n) elements.")
            return
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        
        DispatchQueue.main.async {
            self.requiredStartAmplitude = avgAmplitude
            self.save()
        }
    }
    
    func getRequiredStartAmplitude() -> String {
        if let amp = requiredStartAmplitude {
            return String(format: "%.2f", amp)
        }
        else {
            return "Not callibrated"
        }
    }
    
    func save() {
        UserDefaults.standard.set(requiredStartAmplitude, forKey: "requiredStartAmplitude")
    }
}
