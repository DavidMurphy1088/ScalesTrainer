import Speech
import AVFoundation
import Speech

///Not used currently. Delege methods to handle the parts of a speech recognition
//class SpeechRecognitionManager: NSObject, SFSpeechRecognitionTaskDelegate {
//    private var speechRecognizer: SFSpeechRecognizer!
//    private var recognitionTask: SFSpeechRecognitionTask?
//    var ctr = 0
//    
//    override init() {
//        super.init()
//        self.speechRecognizer = SFSpeechRecognizer()
//    }
//
//    func startRecognition(with audioURL: URL) {
//        let request = SFSpeechURLRecognitionRequest(url: audioURL)
//        recognitionTask = speechRecognizer.recognitionTask(with: request, delegate: self)
//    }
//
//    // MARK: SFSpeechRecognitionTaskDelegate Methods
//
//    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
//        print("Detected speech")
//    }
//
//    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
//        print("Current (didHypothesizeTranscription) transcription: \(ctr) \(transcription.formattedString)")
//    }
//
//    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
//        print("Final (didFinishRecognition) transcription: \(ctr) \(recognitionResult.bestTranscription.formattedString)")
//        ctr += 1
//    }
//
//    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
//        print("Finished reading audio.")
//    }
//
//    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
//        print("Task was cancelled.")
//    }
//
//    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
//        if successfully {
//            print("Recognition finished successfully.")
//        } else {
//            print("Recognition did not finish successfully.")
//        }
//    }
//}

class SpeechManager : NSObject, MetronomeTimerNotificationProtocol, SFSpeechRecognitionTaskDelegate, ObservableObject {
    static let shared = SpeechManager()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine() //AudioManager.shared.engine //AVAudioEngine()
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var isRunning = false
    var ctr = 0
    let countInWords = ["one", "two", "three", "four"]
    var wordIndex = 0
    
    private override init() {
        super.init()
        Logger.shared.log(self, "Inited")
        requestPermissions()
    }
    
    func metronomeStart() {
        wordIndex = 0
    }
    
    func metronomeTicked(timerTickerNumber: Int) -> Bool {
        let utterance = AVSpeechUtterance(string: countInWords[wordIndex])
        //utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust the rate as needed
        speechSynthesizer.speak(utterance)
        wordIndex += 1
        return wordIndex >= countInWords.count
    }
    
    func metronomeStop() {
        
    }
    
    func speak(_ text: String) {
        let voice = AVSpeechSynthesisVoice()
        print("Default Voice Language: \(voice.language), Name: \(voice.name), Quality: \(voice.quality.rawValue)")

        let utterance = AVSpeechUtterance(string: text)
        //utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.25  // Adjust the rate of speech here
        utterance.volume = 0.1
        speechSynthesizer.speak(utterance)
    }
    
    func startAudioEngine() {
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.removeTap(onBus: 0)
        let bufferSize = 1024 //1024
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: recordingFormat) { [unowned self] (buffer, when) in

            ctr += 1
            self.recognitionRequest?.append(buffer)
        }
        Logger.shared.log(self, "Installed speech tap")

        do {
            try audioEngine.start()
            Logger.shared.log(self, "started speech tap AudioEngine")
            //DispatchQueue.main.async {
                self.isRunning = true
            //}
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }
    
    func stopAudioEngine() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        Logger.shared.log(self, "stopped AudioEngine")
        //DispatchQueue.main.async {
            self.isRunning = false
        //}
    }
    
    // ==== delegate
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        print("Detected speech")
    }
    
    func startSpeechRecognition() {
        if let task = self.recognitionTask {
            task.cancel()
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.taskHint = .confirmation
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        Logger.shared.log(self, "started SpeechRecognition")
         //Keep speech recognition data on device - what does this do ??????????????
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
            if #available(iOS 17, *) {
                //recognitionRequest.customizedLanguageModel = self.lmConfiguration
            }
        }
        recognitionRequest.shouldReportPartialResults = true
        
        if false {
            //recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, delegate: self.taskDelegate)
        }
        else {
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    return
                }
                guard let result = result else { return }
                
                print(self!.ctr, "final:", result.isFinal ,"count:", result.transcriptions.count, "Recognized Speech: \(result.bestTranscription.formattedString)")
                //self?.checkForHello(in: result.bestTranscription)
                let command = result.bestTranscription.formattedString
                //self?.speechRecognizer.
//                if result.isFinal {
//                    self?.stopAudioEngine()
//                }
                ScalesModel.shared.processSpeech(speech: command)
                //ScalesModel.shared.processCommand(command: command)
            }
        }
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                Logger.shared.log(self, "Speech recognition authorization granted")
                //self.startAudioEngine()
            case .denied:
                Logger.shared.log(self, "Speech recognition authorization denied")
            case .restricted:
                Logger.shared.log(self, "Speech recognition authorization restricted")
            case .notDetermined:
                Logger.shared.log(self, "Speech recognition authorization not determined yet")
            @unknown default:
                Logger.shared.reportError(self, "Unknown speech recognition authorization status")
            }
        }
    }
}
