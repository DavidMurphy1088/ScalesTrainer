
import Foundation
import Speech

class Result : ObservableObject {
    @Published var correctCount = 0
    @Published var wrongCount = 0
    
    func reset() {
        DispatchQueue.main.async {
            self.correctCount = 0
            self.wrongCount = 0
        }
    }
    
    func updateResult(correct : Int, wrong: Int) {
        DispatchQueue.main.async {
            self.correctCount += correct
            self.wrongCount += wrong
            print("===== Update", self.correctCount)
        }
    }
}

class ScalesModel : ObservableObject {
    public static let shared = ScalesModel()

    @Published var requiredStartAmplitude:Double? = nil
    @Published var statusMessage = ""
    
    let result = Result()
    
    let keyValues = ["C", "G", "D", "A", "E", "F", "B♭", "E♭", "A♭", "D♭"]
    var selectedKey = 0
    
    let scaleTypes = ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Arpegeggio", "Chromatic"]
    
    let octaveNumberValues = [1,2,3,4]
    let selectedOctaves = 0
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler = PitchTapHandler(requiredStartAmplitude: 0, scaleMatcher: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    let speechManager = SpeechManager.shared
    var speechWords:[String] = []
    
    @Published var recordingScale = false
    
    init() {
        let amplitude = UserDefaults.standard.double(forKey: "requiredStartAmplitude")
        if amplitude > 0 {
            self.requiredStartAmplitude = amplitude
        }
    }
    
    func processSpeech(speech: String) {
        logger.log(self, "Process speech \(speech)")
        let words = speech.split(separator: " ")
        print("==============", speech, words.count, words)
        //speechManager.resetRequest()
        DispatchQueue.main.async {
            self.recordingScale = true
        }
        //recordScale()
    }
    
    func getScale() -> Scale {
        let keyName = keyValues[selectedKey]
        let key = Key(name: keyName, keyType: .major)
        let scale = Scale(key: key, scaleType: .major, octaves: octaveNumberValues[selectedOctaves])
        return scale
    }
    
    func getScaleMatcher() -> ScaleMatcher  {
        return ScaleMatcher(scale: getScale(), mismatchesAllowed: 8)
    }
    
    func recordScale() {
        if let requiredAmplitude = requiredStartAmplitude {
            let scale = Scale(key: Key(), scaleType: .major, octaves: 1)
            let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: requiredAmplitude, scaleMatcher: getScaleMatcher())
            audioManager.startRecordingMicrophone(tapHandler: pitchTapHandler)
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
    
//    func getRequiredStartAmplitude() -> String {
//        if let amp = requiredStartAmplitude {
//            return String(format: "%.2f", amp)
//        }
//        else {
//            return "Not callibrated"
//        }
//    }
    
    func save() {
        UserDefaults.standard.set(requiredStartAmplitude, forKey: "requiredStartAmplitude")
    }
}
