import SwiftUI
import SwiftUI
import CoreData
import MessageUI
import WebKit

enum ActiveSheet: Identifiable {
    case emailRecording
    var id: Int {
        hashValue
    }
}

struct ScalesView: View {
    let initialRunProcess:RunningProcess?

    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var coinBank = CoinBank.shared
    
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared
    
    @ObservedObject private var pianoKeyboardViewModel: PianoKeyboardModel
    private var metronome = MetronomeModel.shared
    private let audioManager = AudioManager.shared

    @State private var numberOfOctaves = Settings.shared.defaultOctaves
    @State private var handIndex = 0
    @State private var rootNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 5 ///60 BPM
    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    @State var amplitudeFilter: Double = 0.00
    @State var hearingBacking = false
    @State var hearingRecording = false
    @State var showingTapData = false
    @State var recordingScale = false
    @State var showResultPopup = false
    @State var notesHidden = false
    @State var scaleFollowWithSound = false
    @State var helpShowing:Bool = false
    @State private var emailShowing = false
    @State var emailResult: MFMailComposeResult? = nil
    @State var activeSheet: ActiveSheet?
    
    let backgroundImage = UIGlobals.shared.getBackground()
    
    init(initialRunProcess:RunningProcess? = nil) {
        self.pianoKeyboardViewModel = PianoKeyboardModel.shared
        self.initialRunProcess = initialRunProcess
    }
    
    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    ///Set state of the model and the view
    func setState(octaves:Int, hand:Int) {
        ///There maybe a change in octaves or LH vs. RH
        let root = scalesModel.scale.scaleRoot
        let scaleType = scalesModel.scale.scaleType
        scalesModel.setScaleByRootAndType(scaleRoot: root, scaleType: scaleType, octaves: octaves, hand: hand, ctx: "ScalesView setState")
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
                setState(octaves: self.numberOfOctaves, hand: handIndex)
            })
            Spacer()
            
            Text("Octaves:").padding(0)
            Picker("Select", selection: $numberOfOctaves) {
                ForEach(1..<5) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: numberOfOctaves, {
                setState(octaves: numberOfOctaves, hand: handIndex)
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
    
    func log124() -> Int {
        //print("============= VIEW ABOUT TO RECORD", scalesModel.scale.getScaleName(), "Octaves:", scalesModel.scale.octaves)
        return 0
    }
    
    func leadInMsg() -> String {
        let leadIn = Settings.shared.scaleLeadInBarCount
        var msg = "Leading In For "
        if leadIn == 1 {
             msg += "One Bar"
        }
        else {
            msg += "\(leadIn) Bars"
        }
        return msg
    }
    
    func StopProcessView() -> some View {
        VStack {
            if scalesModel.runningProcess == .leadingIn {
                Spacer()
                VStack {
                    Text("👉 \(leadInMsg())")
                    Text("\(scalesModel.scale.getScaleName())")
                }
                .padding().font(.title2).commonFrameStyle()

                Spacer()
            }
            if scalesModel.runningProcess == .followingScale {
                ProcessUnderwayView()
                VStack {
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Following Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
            if scalesModel.runningProcess == .practicing {
                ProcessUnderwayView()
                VStack {
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Practicing").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
            if scalesModel.runningProcess == .playingAlongWithScale {
                HStack {
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Playing Along").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
            if [.recordingScale].contains(scalesModel.runningProcess) {
                Spacer()
                VStack {
                    Text("Recording \(scalesModel.scale.getScaleName())").font(.title).padding()
                    ProcessUnderwayView()
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Recording Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                    if coinBank.lastBet > 0 {
                        CoinStackView(totalCoins: coinBank.lastBet, compactView: false).padding()
                    }
                }
                .commonFrameStyle()
                Spacer()
            }
            
            if scalesModel.runningProcess == .hearingRecording {
                Button(action: {
                    scalesModel.setRunningProcess(.none)
                }) {
                    Text("Stop Hearing").padding().font(.title2).hilighted(backgroundColor: .blue)
                }
            }
        }
    }
    
    func SelectActionView() -> some View {
        HStack(alignment: .top) {
            Spacer()
            
            VStack()  {
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
                Text("")
                Button("Follow\nThe\nScale") {
                    scalesModel.setRunningProcess(.followingScale)
                    scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            
            Spacer()
            VStack() {
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
                Text("")
                Button(scalesModel.runningProcess == .practicing ? "Stop Practicing" : "Practice") {
                    if scalesModel.runningProcess == .practicing {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.practicing)
                        scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            
            Spacer()
            VStack {
                Button(action: {
                    showHelp("PlayAlong")
                }) {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .font(.title2)//.bold()
                            .foregroundColor(.green)
                    }
                }
                Text("")
                Button(scalesModel.runningProcess == .playingAlongWithScale ? "Stop Playing Along" : "Play Along\nWith Scale") {
                    scalesModel.setRunningProcess(.playingAlongWithScale)
                    scalesModel.setProcessInstructions("Play along with the scale as its played")
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            
            Spacer()
            VStack {
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
                Text("")
                Button(scalesModel.runningProcess == .recordingScale ? "Stop Recording" : "Record\nThe\nScale") {
                    if scalesModel.runningProcess == .recordingScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.recordingScale)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            
            if scalesModel.resultDisplay != nil {
                VStack {
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
                    Text("")
                    Button(hearingRecording ? "Stop Hearing Your Recording" : "Hear\nYour\nRecording") {
                        scalesModel.setRunningProcess(.hearingRecording)
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
            }
            
            Spacer()
            VStack {
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
                Text("")
                Button(hearingBacking ? "Backing Off" : "Backing\nOn") {
                    hearingBacking.toggle()
                    if hearingBacking {
                        scalesModel.setBacking(true)
                    }
                    else {
                        scalesModel.setBacking(false)
                    }
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
            
            Spacer()
        }

    }
    
    func DeveloperView() -> some View {
        HStack {
            Spacer()
            Button("READ_TEST_DATA") {
                scalesModel.setRunningProcess(.recordScaleWithFileData)
            }.padding()
            if scalesModel.tapHandlerEventSetPublished  {
                Spacer()
                HStack {
                    Spacer()
                    Button("Show Tap Data") {
                        showingTapData = true
                    }
                    if Settings.shared.recordDataMode {
                        Spacer()
                        if MFMailComposeViewController.canSendMail() {
                            Button("Send Tap Data") {
                                activeSheet = .emailRecording
                            }
                        }
                        else {
                            Text("No mail")
                        }
                    }
                }
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
    
    func getMailInfo() -> String {
        let mailInfo:String = scalesModel.recordedTapsFileName ?? "No file name"
//        let currentDate = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMMM-dd-HH:mm"
//        let dateString = dateFormatter.string(from: currentDate)
        return mailInfo
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
                if scalesModel.showParameters {
                    VStack {
                        Text(scalesModel.scale.getScaleName()).font(.title)//.padding()
                        if scalesModel.runningProcess == .none {
                            SelectScaleParametersView()
                        }
                        ViewSettingsView()
                    }
                    .commonFrameStyle()
                }
                
                if scalesModel.showKeyboard {
                    VStack {
                        PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardViewModel)
                            .frame(height: getKeyboardHeight())
                            .border(Color.gray)
                            .padding()
                    }
                    .commonFrameStyle()
                }
                
                if scalesModel.showStaff {
                    if let score = scalesModel.score {
                        VStack {
                            ScoreView(score: score, widthPadding: false)
                                .border(Color.gray)
                                .padding()
                        }
                        .commonFrameStyle()
                    }
                }
                
                if scalesModel.showLegend {
                    LegendView().commonFrameStyle()
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
                    
                    if let result = scalesModel.resultDisplay {
                        HStack {
                            ResultView(keyboardModel: PianoKeyboardModel.shared, result: result)
//                            ZStack {
//                                CoinStackView(totalCoins: coinBank.totalCoinsInBank, compactView: true)
//                                VStack {
//                                    Text("")
//                                    Text(coinBank.getCoinsStatusMsg()).padding()
//                                    Spacer()
//                                }
//                            }
                        }
                        .commonFrameStyle()
                    }
                    SelectActionView().commonFrameStyle()
                }
                
                if settings.recordDataMode {
                    DeveloperView().commonFrameStyle()
                }
            
                Spacer()
            }
            ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
            ///If setting either width or height always also set the other otherwise landscape vs. portrai layout is wrecked.
            .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.86)
        }
        
        .sheet(isPresented: $showingTapData) {
            TapDataView(keyboardModel: PianoKeyboardModel.shared)
        }
        
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }
    
//        .alert(isPresented: $askKeepTapsFile) {
//            Alert(
//                title: Text("Keep Recording File?"),
//                message: Text("Keep Recording File?"),
//                primaryButton: .default(Text("Yes")) {
//                },
//                secondaryButton: .cancel(Text("No")) {
//                    let fileManager = FileManager.default
//                    if let url = scalesModel.recordedTapsFileURL {
//                        do {
//                            try fileManager.removeItem(at: url)
//                            Logger.shared.log(scalesModel, "Taps file deleted successfully \(url)")
//                        }
//                        catch {
//                            Logger.shared.reportError(scalesModel, "Failed to delete file: \(error) \(url)")
//                        }
//                    }
//                    else {
//                        Logger.shared.reportError(scalesModel, "No taps file to delete")
//                    }
//                }
//            )
//        }
        
        ///Every time the view appears, not just the first.
        ///Whoever calls up this view has set the scale already
        .onAppear {
            scalesModel.setResultInternal(nil, "ScalesView.onAppear")
            PianoKeyboardModel.shared.resetKeysWerePlayedState()
            pianoKeyboardViewModel.keyboardAudioManager = audioManager
            self.handIndex = scalesModel.scale.hand
            ///Causes setState()
            //self.numberOfOctaves = Settings.shared.defaultOctaves
            self.directionIndex = 0
            if let process = initialRunProcess {
                scalesModel.setRunningProcess(process)
            }
        }
        
        .onDisappear {
            metronome.stop()
            ///Clean up any recorded files
            if Settings.shared.recordDataMode {
                let fileManager = FileManager.default
                if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    do {
                        let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                        for fileURL in fileURLs {
                            do {
                                try fileManager.removeItem(at: fileURL)
                            } catch {
                                Logger.shared.reportError(fileManager, error.localizedDescription)
                            }
                        }
                    } catch {
                        Logger.shared.reportError(fileManager, error.localizedDescription)
                    }
                }
            }
        }
        //.navigationBarTitle("\(activityMode.name)", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())

        .sheet(item: $activeSheet) { item in
            switch item {
            case .emailRecording:
                if MFMailComposeViewController.canSendMail() {
                    if let url = scalesModel.recordedTapsFileURL {
                        SendMailView(isShowing: $emailShowing, result: $emailResult,
                                     messageRecipient:"davidmurphy1088@gmail.com",
                                     messageSubject: "Scales Trainer \(getMailInfo())",
                                     messageContent: "\(getMailInfo())\n\nPlease add details if the scale was assessed incorrectly. Also include tempo and articulation info\n",
                                     attachmentFilePath: url)
                    }
                }
            }
        }

    }
}

