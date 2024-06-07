import SwiftUI

struct ScalesView: View {
    let practiceJournalScale:PracticeJournalScale

    @ObservedObject private var scalesModel = ScalesModel.shared
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared
    
    //private var keyboardModel = PianoKeyboardModel.shared
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardModel
    @ObservedObject private var speech = SpeechManager.shared
    private var metronome = MetronomeModel.shared
    private let audioManager = AudioManager.shared

    @State private var octaveNumberIndex = 0
    @State private var handIndex = 0
    @State private var rootNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 5

    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    @State var amplitudeFilter: Double = 0.00

    @State var hearingGivenScale = false
    @State var hearingBacking = false
    @State var showingTapData = false
    @State var recordingScale = false

    @State var showResultPopup = false
    @State var notesHidden = false
    @State var askKeepTapsFile = false

    @State var scaleFollowWithSound = false

    @State var helpShowing:Bool = false

    init(practiceJournalScale:PracticeJournalScale) {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
        self.practiceJournalScale = practiceJournalScale
        //self.activityMode = activityMode
    }
    
    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    ///Set state of the model and the view
    func setState(_ ctx:String) {
        scalesModel.setRunningProcess(.none)
        //scalesModel.setKeyAndScale()
        //audioManager.stopRecording()
        scalesModel.setResult(nil)
        self.hearingGivenScale = false
        self.directionIndex = 0
    }
    
    func SelectScaleParamtersView() -> some View {
        HStack {
//            Spacer()
//            Text(LocalizedStringResource("Root"))
//            Picker("Select Value", selection: $rootNameIndex) {
//                ForEach(scalesModel.scaleRootValues.indices, id: \.self) { index in
//                    Text("\(scalesModel.scaleRootValues[index])")
//                }
//            }
//            .pickerStyle(.menu)
//            .onChange(of: rootNameIndex, {
//                scalesModel.selectedScaleRootIndex = rootNameIndex
//                setState("KeyChange")
//            })
//            
//            Spacer()
//            Text(LocalizedStringResource("Scale")).padding(0)
//            Picker("Select Value", selection: $scaleTypeNameIndex) {
//                ForEach(scalesModel.scaleTypeNames.indices, id: \.self) { index in
//                    Text("\(scalesModel.scaleTypeNames[index])")
//                }
//            }
//            .pickerStyle(.menu)
//            .onChange(of: scaleTypeNameIndex, {
//                scalesModel.selectedScaleTypeNameIndex = scaleTypeNameIndex
//                setState("ScaleTypeChange")
//            })
            
            Spacer()
            Text("Hand:")
            Picker("Select Value", selection: $handIndex) {
                ForEach(scalesModel.handTypes.indices, id: \.self) { index in
                    Text("\(scalesModel.handTypes[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: handIndex, {
                scalesModel.selectedHandIndex = handIndex
                setState("HandChange")
            })
            Spacer()
            
            Text("Octaves:").padding(0)
            Picker("Select Value", selection: $octaveNumberIndex) {
                ForEach(scalesModel.octaveNumberValues.indices, id: \.self) { index in
                    Text("\(scalesModel.octaveNumberValues[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: octaveNumberIndex, {
                scalesModel.selectedOctavesIndex = octaveNumberIndex
                setState("OctavesChange")
            })
            
            Spacer()
            Text(LocalizedStringResource("Viewing\nDirection"))
            Picker("Select Value", selection: $directionIndex) {
                ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
                    if scalesModel.selectedDirection >= 0 {
                        Text("\(scalesModel.directionTypes[index])")
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: directionIndex, {
                scalesModel.setDirection(self.directionIndex)
            })
            
            Spacer()
            Text(LocalizedStringResource("Tempo"))
            Picker("Select Value", selection: $tempoIndex) {
                ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
                    Text("\(scalesModel.tempoSettings[index])")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: tempoIndex, {
                scalesModel.setTempo(self.tempoIndex)
            })

            Spacer()
        }
    }
    
    func StopProcessView() -> some View {
        VStack {
            if scalesModel.runningProcess == .followingScale {
                VStack {
                    Spacer()
                    Button(scalesModel.runningProcess == .followingScale ? "Stop Following" : "Follow The Scale") {
                        if scalesModel.runningProcess == .followingScale {
                            scalesModel.setRunningProcess(.none)
                        }
                        else {
                            scalesModel.setRunningProcess(.followingScale)
                            ScalesModel.shared.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                        }
                    }
                    Button("Stop Following Scale") {
                        scalesModel.setRunningProcess(.none)
                    }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    Spacer()
                }
            }
            if scalesModel.runningProcess == .practicing {
                VStack {
                    Spacer()
                    ProcessUnderwayView()
                    Button("Stop Practicing") {
                        scalesModel.setRunningProcess(.none)
                    }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    Spacer()
                }
            }
            if scalesModel.runningProcess == .identifyingScale {
                HStack {
                    Spacer()
                    Button("Stop Hearing Scale") {
                        scalesModel.setRunningProcess(.none)
                    }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    Spacer()
                }
            }
            if [.recordingScale].contains(scalesModel.runningProcess) {
                Spacer()
                VStack {
                    if scalesModel.leadInBar == nil {
                        ProcessUnderwayView()
                        Button("Stop Recording Scale") {
                            scalesModel.setRunningProcess(.none)
                            if Settings.shared.recordDataMode {
                                self.askKeepTapsFile = true
                            }
                        }
                        .padding()
                        .hilighted(backgroundColor: .blue)
                    }
                    else {
                        Text("  Recording Lead-In...  ").padding().hilighted()
                    }
                }
                Spacer()
            }
        }
    }
    func ActionView() -> some View {
        HStack {
            Spacer()
            HStack {
                Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear The Scale") {
                    hearingGivenScale.toggle()
                    if hearingGivenScale {
                        metronome.startTimer(notified: PianoKeyboardModel.shared, tempoMultiplier: 1.0, onDone: {
                            self.hearingGivenScale = false
                        })
                    }
                    else {
                        metronome.stop()
                    }
                }
                Button(action: {
                    showHelp("Hear The Scale")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            
            Spacer()
            HStack(spacing: 4) {
                Button(scalesModel.runningProcess == .followingScale ? "Stop Following" : "Follow The Scale") {
                    if scalesModel.runningProcess == .followingScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.followingScale)
                        ScalesModel.shared.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                    }
                }
                
                Button(action: {
                    showHelp("Follow The Scale")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            
            Spacer()
            HStack(spacing: 4) {
                Button(scalesModel.runningProcess == .practicing ? "Stop Practicing" : "Practice") {
                    if scalesModel.runningProcess == .practicing {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.practicing)
                        ScalesModel.shared.setProcessInstructions("Play the notes of the scale. But watch for any wrong notes.")
                    }
                }
                Button(action: {
                    showHelp("Practice")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            
            Spacer()
            HStack {
                Button(scalesModel.runningProcess == .recordingScale ? "Stop Recording" : "Record The Scale") {
                    if scalesModel.runningProcess == .recordingScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.recordingScale)
                    }
                }.padding()

                Button(action: {
                    showHelp("Record The Scale")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            
            Spacer()
            HStack {
                Button(hearingBacking ? "Backing Off" : "Backing On") {
                    hearingBacking.toggle()
                    if hearingBacking {
                        metronome.startTimer(notified: Backer(), tempoMultiplier: 1.0, onDone: {
                            //self.hearingGivenScale = false
                            //scalesModel.startPracticeHandler()
                        })
                    }
                    else {
                        metronome.stop()
                    }
                }
                Button(action: {
                    showHelp("Backing")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            Spacer()
        }
    }
    
    func DeveloperView() -> some View {
        HStack {
            Spacer()
            Button("READ_TEST_DATA") {
                scalesModel.setRunningProcess(.recordingScaleWithData)
            }.padding()
            Spacer()
            if scalesModel.recordedTapEvents != nil {
                Spacer()
                Button("Show Tap Data") {
                    showingTapData = true
                }.padding()
            }
            Spacer()
        }
    }
    
    func getKeyboardHeight() -> CGFloat {
        var height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 3 : 4)
        if scalesModel.scale.octaves > 1 {
            ///Keys are narrower so make height less to keep proportion ratio
            height = height * 0.7
        }
        return height
    }
    
    var body: some View {
        ZStack {
            VStack {
                Image(UIGlobals.shared.screenImageBackground)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.top)
                    .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            }
            VStack {
                if scalesModel.showKeyboard {
                    VStack {
                        if scalesModel.runningProcess == .none {
                            SelectScaleParamtersView()//.commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                        }
                        Text(scalesModel.scale.getScaleName()).font(.title).padding()
                        PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                            .frame(height: getKeyboardHeight())
                            //.commonFrameStyle(backgroundColor: .white).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                            .padding()
                        
                        if scalesModel.showStaff {
                            VStack {
                                if let score = scalesModel.score {
                                    ScoreView(score: score, widthPadding: false)
                                }
                            }//.commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                        }
                        LegendView()
                    }
                    .commonFrameStyle(backgroundColor: .white)
                }

                if scalesModel.runningProcess != .none {
                    StopProcessView()
                }
                else {
                    if let userMessage = scalesModel.userMessage {
                        Text(userMessage)
                    }

                    if let result = scalesModel.result {
                        VStack {
//                            if let score = scalesModel.score {
//                                let scoreWithDurations = scalesModel.createScore(scale: scalesModel.scale, showTempoVariation: true)
//                                //scalesModel.setShowStaff(true)
//                                ScoreView(score: scoreWithDurations, widthPadding: false)
//                            }
                        }
                        //.commonFrameStyle(backgroundColor: .clear).padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                        ResultView(keyboardModel: PianoKeyboardModel.shared, result: result)
                    }
                    ActionView().commonFrameStyle(backgroundColor: .white)//.padding(.vertical, orientationObserver.orientation.isPortrait ? nil : 0)
                    if settings.recordDataMode {
                        DeveloperView().commonFrameStyle(backgroundColor: .white)
                    }
                }
                Spacer()
            }
            ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
            .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.90)
            //.border(.red)
        }
        
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
        }
        
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }

        .onChange(of: scalesModel.result, {
//            if scalesModel.result != nil {
//                scalesModel.setShowStaff(true)
//            }
        })
    
        .alert(isPresented: $askKeepTapsFile) {
            Alert(
                title: Text("Keep Taps File?"),
                message: Text("Keep Taps File?"),
                primaryButton: .default(Text("Yes")) {
                },
                secondaryButton: .cancel(Text("No")) {
                    let fileManager = FileManager.default
                    if let url = scalesModel.recordedTapsFileURL {
                        do {
                            try fileManager.removeItem(at: url)
                            Logger.shared.log(scalesModel, "Taps file deleted successfully \(url)")
                        }
                        catch {
                            Logger.shared.reportError(scalesModel, "Failed to delete file: \(error) \(url)")
                        }
                    }
                    else {
                        Logger.shared.reportError(scalesModel, "No taps file to delete")
                    }
                }
            )
        }
        
        ///Every time the view appears, not just the first.
        .onAppear {
            scalesModel.setKeyAndScale(scaleRoot: self.practiceJournalScale.scaleRoot, scaleType: self.practiceJournalScale.scaleType)
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            scalesModel.setRunningProcess(.none)

            ///Dont carry over result from one screen to next
            ScalesModel.shared.setResult(nil)
            
            //self.rootNameIndex = scalesModel.selectedScaleRootIndex
            //self.scaleTypeNameIndex = scalesModel.selectedScaleTypeNameIndex
            self.handIndex = scalesModel.selectedHandIndex
            self.octaveNumberIndex = scalesModel.selectedOctavesIndex
            self.directionIndex = scalesModel.selectedDirection

//            if ["Hear and Identify A Scale"].contains(activityMode.name) {
//                let scaleRoot = Int.random(in: 0...scalesModel.scaleRootValues.count - 1)
//                let scaleType = Int.random(in: 0...scalesModel.scaleTypeNames.count - 1)
//                let hand = Int.random(in: 0...1)
//                scalesModel.selectedHandIndex = hand
//                scalesModel.selectedScaleRootIndex = scaleRoot
//                scalesModel.selectedScaleTypeNameIndex = scaleType
//                setState("ScaleTypeChange")
//                scalesModel.setRunningProcess(.identifyingScale)
//                metronome.startTimer(notified: IdentifyScalePlayer(), tempoMultiplier: 0.35, onDone: {
//                    //self.hearingGivenScale = false
//                    //scalesModel.startPracticeHandler()
//                })
//            }
        }
        .onDisappear {
            metronome.stop()
        }
        //.navigationBarTitle("\(activityMode.name)", displayMode: .inline)
        //.navigationBar
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


