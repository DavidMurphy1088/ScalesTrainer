import Foundation
import Speech
import Combine

class Result : ObservableObject {
    @Published var correctCount = 0
    @Published var wrongCount = 0
    
//    func reset() {
//        DispatchQueue.main.async {
//            self.correctCount = 0
//            self.wrongCount = 0
//        }
//    }
    
    func updateResult(correct : Int, wrong: Int) {
        DispatchQueue.main.async {
            self.correctCount += correct
            self.wrongCount += wrong
        }
    }
}

public class ScalesModel : ObservableObject {
    public static var shared = ScalesModel()

    @Published var requiredStartAmplitude:Double? = nil
    @Published var amplitudeFilter:Double = 0.0
    
    @Published var statusMessage = ""
    @Published var speechListenMode = false
    @Published var recordingAvailable = false
    @Published var speechLastWord = ""
    @Published private(set) var forcePublish = 0 //Called to force a repaint of keyboard

    var scale:Scale = Scale(key: Key(name: "C", keyType: .minor), scaleType: .naturalMinor, octaves: 1)
    
    var result:Result? = nil
    
    let keyValues = ["C", "G", "D", "A", "E", "F", "B♭", "E♭", "A♭"]
    var selectedKey = Key()
    
    let scaleTypes = ["Major", "Minor", "Harmonic Minor", "Melodic Minor", "Arpeggio", "Chromatic"]
    var selectedScaleType = 0
    
    var directionTypes = ["Ascending", "Descending"]
    var selectedDirection = 0
    
    var handTypes = ["Right Hand", "Left Hand"]

    let octaveNumberValues = [1,2,3,4]
    let selectedOctaves = 0
    
    let bufferSizeValues = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 2048+1024, 4096, 2*4096, 4*4096, 8*4096, 16*4096]
    let startMidiValues = [12, 24, 36, 48, 60, 72, 84, 96]
    
    let callibrationTapHandler = PitchTapHandler(requiredStartAmplitude: 0, scaleMatcher: nil, scale: nil)
    let audioManager = AudioManager.shared
    let logger = Logger.shared
    
    ///Speech
    let speechManager = SpeechManager.shared
    var speechWords:[String] = []
    var speechCommandsReceived = 0
    
    @Published var recordingScale = false
    @Published var listening = false

    init() {
        var value = UserDefaults.standard.double(forKey: "requiredStartAmplitude")
        if value > 0 {
            self.requiredStartAmplitude = value
        }
        value = UserDefaults.standard.double(forKey: "amplitudeFilter")
        if value > 0 {
            self.amplitudeFilter = value
        }
    }
    
    func forceRepaint() {
        DispatchQueue.main.async {
            self.forcePublish += 1
        }
    }
    
    func setKey(index:Int) {
        let name = keyValues[index]
        self.selectedKey = Key(name: name, keyType: .major)
    }
    
    func setDirection(_ index:Int) {
        self.selectedDirection = index
        self.scale.setFingerBreaks(direction: index)
    }

    func setSpeechListenMode(_ way:Bool) {
        DispatchQueue.main.async {
            self.speechListenMode = way
            if way {
                self.speechManager.speak("Hello")
                sleep(2)
                if !self.speechManager.isRunning {
                    self.speechManager.startAudioEngine()
                    self.speechManager.startSpeechRecognition()
                }
            }
            else {
                self.speechManager.stopAudioEngine()
            }
        }
    }
    
    func processSpeech(speech: String) {
        let words = speech.split(separator: " ")
        guard words.count > 0 else {
            return
        }
        speechCommandsReceived += 1
        var m = "Process speech. commandCtr:\(speechCommandsReceived) Words:\(words)"
        logger.log(self, m)
        if words[0].uppercased() == "START" {
            speechManager.stopAudioEngine()
            startRecordingScale()
        }
        DispatchQueue.main.async {
            self.speechLastWord = String(words[0])
            self.speechManager.stopAudioEngine()
            self.speechManager.startAudioEngine()
            self.speechManager.startSpeechRecognition()
        }
    }
    
    func setScale(octaveIndex:Int) {
        //let key = Key(name: selectedKey, keyType: .major)
        var scaleType:ScaleType = .major
        switch selectedScaleType {
        case 1:
            scaleType = .naturalMinor
        case 2:
            scaleType = .harmonicMinor
        case 3:
            scaleType = .melodicMinor
        default:
            scaleType = .major
        }
        self.scale = Scale(key: self.selectedKey,
                           scaleType: scaleType,
                           octaves: octaveIndex + 1)
    }
    
    func getScaleMatcher() -> ScaleMatcher  {
        return ScaleMatcher(scale: self.scale, mismatchesAllowed: 8)
    }
    
    //======================
    
    func startListening() {
        self.scale.resetPlayMidiStatus()
        
        if let requiredAmplitude = self.requiredStartAmplitude {
            self.result = nil
            Logger.shared.log(self, "Start listening")
            DispatchQueue.main.async {
                self.listening = true
                //self.recordingAvailable = false
            }
            let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: requiredAmplitude, scaleMatcher: nil, scale:self.scale)
            self.audioManager.startRecordingMicrophone(tapHandler: pitchTapHandler, recordAudio: false)
        }
    }

    func stopListening() {
        Logger.shared.log(self, "Stop recording scale")
        DispatchQueue.main.async {
            self.listening = false
        }
        audioManager.stopRecording()
    }
    
    func startRecordingScale() {
        self.scale.resetPlayMidiStatus()
        if let requiredAmplitude = self.requiredStartAmplitude {
            if self.speechListenMode {
                sleep(1)
                self.speechManager.speak("Please start your scale")
                sleep(2)
            }
            self.result = nil
            Logger.shared.log(self, "Start recording scale")
            DispatchQueue.main.async {
                self.recordingScale = true
                self.recordingAvailable = false
            }
            let pitchTapHandler = PitchTapHandler(requiredStartAmplitude: requiredAmplitude, scaleMatcher: self.getScaleMatcher(), scale: nil)
            self.audioManager.startRecordingMicrophone(tapHandler: pitchTapHandler, recordAudio: true)
        }
    }
    
    func stopRecordingScale() {
        Logger.shared.log(self, "Stop recording scale")
        DispatchQueue.main.async {
            self.recordingScale = false
        }
        audioManager.stopRecording()
        DispatchQueue.main.async {
//            self.speechManager.startAudioEngine()
//            self.speechManager.startSpeechRecognition()
            if let file = self.audioManager.recorder?.audioFile {
                if file.duration > 0 {
                    self.recordingAvailable = true
                }
            }
        }
    }
    
    func setStatusMessage(_ msg:String) {
        DispatchQueue.main.async {
            self.statusMessage = msg
        }
    }
    
    func doCallibration(type:CallibrationType, amplitudes:[Float]) {
        let n = 4
        guard amplitudes.count >= n else {
            Logger.shared.log(self, "Callibration amplitudes must contain at least \(n) elements.")
            return
        }
        
        let highest = amplitudes.sorted(by: >).prefix(n)
        let total = highest.reduce(0, +)
        let avgAmplitude = Double(total / Float(highest.count))
        
        DispatchQueue.main.async {
            if type == .amplitudeFilter {
                self.amplitudeFilter = avgAmplitude
            }
            else {
                self.requiredStartAmplitude = avgAmplitude
            }
            self.save(type: type, value: avgAmplitude)
        }
    }
        
    func save(type:CallibrationType, value:Double) {
        let key = type == .startAmplitude ? "requiredStartAmplitude" : "amplitudeFilter"
        UserDefaults.standard.set(value, forKey: key)
    }
}
