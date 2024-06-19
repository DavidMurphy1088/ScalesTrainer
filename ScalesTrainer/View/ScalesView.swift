import SwiftUI

struct ScalesView: View {
    let practiceJournalScale:PracticeJournalScale

    @ObservedObject private var scalesModel = ScalesModel.shared
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared
    
    //private var keyboardModel = PianoKeyboardModel.shared
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardModel
    //@ObservedObject private var speech = SpeechManager.shared
    private var metronome = MetronomeModel.shared
    private let audioManager = AudioManager.shared

    @State private var octaveNumberIndex = 0
    @State private var handIndex = 0
    @State private var rootNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 2 ///60 BPM

    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    
    @State var amplitudeFilter: Double = 0.00

    @State var hearingGivenScale = false
    @State var hearingBacking = false
    @State var hearingRecording = false
    @State var showingTapData = false
    @State var recordingScale = false

    @State var showResultPopup = false
    @State var notesHidden = false
    @State var askKeepTapsFile = false

    @State var scaleFollowWithSound = false

    @State var helpShowing:Bool = false
    let backgroundImage = UIGlobals.shared.getBackground()
    
    init(practiceJournalScale:PracticeJournalScale) {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
        self.practiceJournalScale = practiceJournalScale
    }
    
    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    ///Set state of the model and the view
    func setState(scaleRoot:ScaleRoot, scaleType: ScaleType, octaves:Int, hand:Int) {
        scalesModel.setRunningProcess(.none)
        ///There maybe a change in octaves or LH vs. RH
        scalesModel.setKeyAndScale(scaleRoot: scaleRoot, scaleType: scaleType, octaves: octaves, hand: hand)
        //scalesModel.setKeyAndScale()
        //audioManager.stopRecording()
        scalesModel.setResult(nil)
        self.hearingGivenScale = false
        self.directionIndex = 0
    }
    
    func SelectScaleParametersView() -> some View {
        HStack {

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
                setState(scaleRoot: scalesModel.scale.scaleRoot, 
                         scaleType: scalesModel.scale.scaleType,
                         octaves: scalesModel.octaveNumberValues[octaveNumberIndex],
                         hand: scalesModel.selectedHandIndex)
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
                setState(scaleRoot: scalesModel.scale.scaleRoot, 
                         scaleType: scalesModel.scale.scaleType,
                         octaves: scalesModel.octaveNumberValues[octaveNumberIndex],
                         hand: scalesModel.selectedHandIndex)
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

                    Button("Stop Following Scale") {
                        scalesModel.setRunningProcess(.none)
                    }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    //Spacer()
                }
            }
            if scalesModel.runningProcess == .practicing {
                VStack {
                    //Spacer()
                    ProcessUnderwayView()
                    Button("Stop Practicing") {
                        scalesModel.setRunningProcess(.none)
                    }
                    .padding()
                    .hilighted(backgroundColor: .blue)
                    //Spacer()
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
                    Text("Recording \(scalesModel.scale.getScaleName())").padding()
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
                        Text("  Metronome Lead-In...  ").padding().hilighted()
                    }
                }
                .commonFrameStyle()
                .frame(width: UIScreen.main.bounds.width * 0.6)
                Spacer()
            }
        }
    }
    
    func SelectActionView() -> some View {
        HStack {
            Spacer()
            VStack {
                Button(hearingGivenScale ? "Stop Hearing Scale" : "Hear\nThe\nScale") {
                    hearingGivenScale.toggle()
                    if hearingGivenScale {
                        //metronome.startTimer(notified: PianoKeyboardModel.shared, onDone: {
                        metronome.startTimer(notified: HearScalePlayer(), countAtQuaverRate: true, onDone: {
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
            VStack(spacing: 4) {
                Button("Follow\nThe\nScale") {
                    scalesModel.setRunningProcess(.followingScale)
                    ScalesModel.shared.setProcessInstructions("Play the next scale note as shown by the hilighted key")
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
            VStack(spacing: 4) {
                Button(scalesModel.runningProcess == .practicing ? "Stop Practicing" : "Practice") {
                    if scalesModel.runningProcess == .practicing {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.practicing)
                        ScalesModel.shared.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
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
            VStack {
                Button(scalesModel.runningProcess == .recordingScale ? "Stop Recording" : "Record\nThe\nScale") {
                    if scalesModel.runningProcess == .recordingScale {
                        scalesModel.setRunningProcess(.none)
                        //AudioManager.shared.stopRecording()

                    }
                    else {
                        scalesModel.setRunningProcess(.recordingScale)
                        //AudioManager.shared.startRecordingMicWithTapHandler(tapHandler: PracticeTapHandler(amplitudeFilter:0.0, hilightPlayingNotes:false), recordAudio: true)
                    }
                }

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
            
            if let result = scalesModel.result {
                VStack {
                    Button(hearingRecording ? "Stop Hearing Your Recording" : "Hear\nYour\nRecording") {
                        scalesModel.setRunningProcess(.hearingRecording)
                    }
                    Button(action: {
                        showHelp("Hear Recording")
                    }) {
                        VStack {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            VStack {
                Button(hearingBacking ? "Backing Off" : "Backing\nOn") {
                    hearingBacking.toggle()
                    if hearingBacking {
                        scalesModel.setBacking(true)
                    }
                    else {
                        scalesModel.setBacking(false)
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
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.top)
                    .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            }
            VStack {
                if scalesModel.showKeyboard {
                    VStack {
                        if scalesModel.runningProcess == .none {
                            SelectScaleParametersView()
                        }
                        Text(scalesModel.scale.getScaleName()).font(.title).padding()
                        PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                            .frame(height: getKeyboardHeight())
                            .border(Color.gray)
                            .padding()
                        
                        if scalesModel.showStaff {
                            VStack {
                                if let score = scalesModel.score {
                                    ScoreView(score: score, widthPadding: false)
                                        .border(Color.gray)
                                        .padding()
                                }
                            }
                        }
                        LegendView()//.padding()
                    }
                    .commonFrameStyle()
                }

                if scalesModel.runningProcess != .none {
                    //Spacer()
                    StopProcessView()
                    //Spacer()
                }
                else {
                    if let userMessage = scalesModel.userMessage {
                        Text(userMessage).padding().commonFrameStyle()
                    }

                    if let result = scalesModel.result {
                        ResultView(keyboardModel: PianoKeyboardModel.shared, result: result).commonFrameStyle()
                    }
                    
                    SelectActionView().commonFrameStyle()
                    
                    if settings.recordDataMode {
                        DeveloperView().commonFrameStyle()
                    }
                }
                Spacer()
            }
            ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
            ///If setting either width or height always also set the other otherwise landscape vs. portrai layout is wrecked.
            .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.86)
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
            setState(scaleRoot: self.practiceJournalScale.scaleRoot, scaleType: self.practiceJournalScale.scaleType,
                     octaves: self.practiceJournalScale.octaves ?? 1, hand: self.practiceJournalScale.hand ?? 0)
            
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            
            //self.rootNameIndex = scalesModel.selectedScaleRootIndex
            //self.scaleTypeNameIndex = scalesModel.selectedScaleTypeNameIndex
            self.handIndex = scalesModel.selectedHandIndex
            self.octaveNumberIndex = scalesModel.selectedOctavesIndex
            self.directionIndex = scalesModel.selectedDirection
        }
        .onDisappear {
            metronome.stop()
        }
        //.navigationBarTitle("\(activityMode.name)", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


