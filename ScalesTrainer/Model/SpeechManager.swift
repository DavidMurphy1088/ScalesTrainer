import Speech
import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine() //AudioManager.shared.engine //AVAudioEngine()
    var ctr = 0
    
    private init() {
        Logger.shared.log(self, "Inited")
        requestPermissions()
    }

    func installSpeechTap() {
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        //audioEngine.inputNode.removeTap(onBus: 0)
        let bufferSize = 1024 //1024
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: recordingFormat) { [unowned self] (buffer, when) in
//            if ctr % 20 == 0 {
//                Logger.shared.log(self, "===========> In speech tap closure, ctr:\(ctr)")
//            }
            ctr += 1
            self.recognitionRequest?.append(buffer)
            //self.recognitionRequest?.shouldReportPartialResults
        }
        Logger.shared.log(self, "Installed speech tap")

        do {
            try audioEngine.start()
            Logger.shared.log(self, "started speech tap AudioEngine")
        } catch {
            print("Could not start audio engine: \(error)")
        }
        
    }
    
    func xx() {
//        DispatchQueue.main.async {
//            print("=========== resetting task")
//            sleep(1)
//            startSpeechRecognition()
//        }
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
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
                return
            }
            guard let result = result else { return }
            
            print(self!.ctr, "final:", result.isFinal ,"count:", result.transcriptions.count, "Recognized Speech: \(result.bestTranscription.formattedString)")
            //self?.checkForHello(in: result.bestTranscription)
            ScalesModel.shared.processSpeech(speech: result.bestTranscription.formattedString)
            //self?.speechRecognizer.
            if result.isFinal {
                self?.stopAudioEngine()
            }
            //self?.xx()
        }
        
    }

    private func checkForHello(in transcription: SFTranscription) {
        let recognizedText = transcription.formattedString.lowercased()
        if recognizedText.contains("hello") {
            print("Detected 'hello'")
            // Perform any specific action here, such as notifying other components or triggering events
        }
    }

    func stopAudioEngine() {
        //audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        Logger.shared.log(self, "stopped AudioEngine")
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
