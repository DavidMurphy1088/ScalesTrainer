import SwiftUI
import SwiftUI
import CoreData
import MessageUI
import WebKit

enum ActiveSheet: Identifiable {
    case emailRecording
    //case leadingIn
    var id: Int {
        hashValue
    }
}

struct MetronomeView: View {
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = MetronomeModel.shared
    
    var body: some View {
        let beat = (metronome.timerTickerCountPublished % 4) + 1
        HStack {
            Image("metronome-left")
                .resizable()
                .scaledToFit()
                .scaleEffect(x: beat % 2 == 0 ? -1 : 1, y: 1)
                //.animation(.easeInOut(duration: 0.1), value: beat)
        }
        .frame(width: UIScreen.main.bounds.size.width * 0.04)
    }
}

//struct ScaleStartView: View {
//    func showScaleStart() {
//        PianoKeyboardModel.shared1.configureKeyboardForScaleStartView(start: 36, numberOfKeys: 52, scaleStartMidi: ScalesModel.shared.scale.getMinMax().0)
//        PianoKeyboardModel.shared1.redraw()
//    }
//    
//    var body: some View {
//        VStack {
//            Text("Scale Start")
//            PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: PianoKeyboardModel.shared1, keyColor: .white)
//                .frame(height: 120)
//                .border(Color.gray)
//                .padding()
//        }
//        .onAppear() {
//            showScaleStart()
//        }
//    }
//}

struct ScalesView: View {
    let initialRunProcess:RunningProcess?
        
    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var badgeBank = BadgeBank.shared
    
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared
    
    @ObservedObject private var pianoKeyboardRightHand: PianoKeyboardModel
    @ObservedObject private var pianoKeyboardLeftHand: PianoKeyboardModel
    @ObservedObject private var metronome = MetronomeModel.shared
    private let audioManager = AudioManager.shared

    @State private var numberOfOctaves = Settings.shared.defaultOctaves
    @State private var rootNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 0
    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    @State var amplitudeFilter: Double = 0.00
    @State var hearingBacking = false
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
        self.pianoKeyboardRightHand = PianoKeyboardModel.sharedRightHand
        self.pianoKeyboardLeftHand = PianoKeyboardModel.sharedLeftHand
        self.initialRunProcess = initialRunProcess
    }
    
    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    ///Set state of the model and the view
//    func setState(octaves:Int) {
//        ///There maybe a change in octaves or LH vs. RH
//        let root = scalesModel.scale.scaleRoot
//        let scaleType = scalesModel.scale.scaleType
//        let hand = scalesModel.scale.hand
//        scalesModel.setScaleByRootAndType(scaleRoot: root, scaleType: scaleType, octaves: octaves, hand: hand, ctx: "ScalesView setState")
//        self.directionIndex = 0
//    }
    
    func SelectScaleParametersView() -> some View {
        HStack {
//            Spacer()
//            Text("Hand:")
//            Picker("Select Value", selection: $handIndex) {
//                ForEach(scalesModel.handTypes.indices, id: \.self) { index in
//                    Text("\(scalesModel.handTypes[index])")
//                }
//            }
//            .pickerStyle(.menu)
//            .onChange(of: handIndex, {
//                setState(octaves: self.numberOfOctaves, hand: handIndex)
//            })

            Button(action: {
                metronome.setTicking(on: !metronome.isTiming)
            }) {
                MetronomeView()
                    
            }
            .padding()
            
            Text(LocalizedStringResource("Tempo")).padding(.horizontal, 0)
            Picker("Select Value", selection: $tempoIndex) {
                ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
                    Text("\(scalesModel.tempoSettings[index])").padding(.horizontal, 0)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 0)
            .onChange(of: tempoIndex, {
                scalesModel.setTempo(self.tempoIndex)
            })
            
            //Spacer()
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
                scalesModel.setSelectedDirection(self.directionIndex)
            })
            
            //Spacer()
//            Text("Octaves").padding(.horizontal, 0)
//            Picker("Select", selection: $numberOfOctaves) {
//                ForEach(1..<3) { number in
//                    Text("\(number)").tag(number)
//                }
//            }
//            .pickerStyle(.menu)
//            .onChange(of: numberOfOctaves, {
//                setState(octaves: numberOfOctaves)
//            })
        }
    }

//    
//    func leadInMsg() -> String {
//        let leadIn = Settings.shared.scaleLeadInBarCount
//        var msg = "Leading In For "
//        if leadIn == 1 {
//             msg += "One Bar"
//        }
//        else {
//            msg += "\(leadIn) Bars"
//        }
//        return msg
//    }
    
    func StopProcessView() -> some View {
        VStack {
            
            if scalesModel.runningProcessPublished == .followingScale {
                //RecordingIsUnderwayView()
                VStack {
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("Stop Following Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
                        
            if [.playingAlongWithScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    //if Settings.shared.metronomeOn {
                        MetronomeView()
                    //}
                    let text = metronome.isLeadingIn ? "  Leading In  " : "Stop Playing"
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("\(text)")
                        .padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }

            if [.leadingTheScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    //if Settings.shared.metronomeOn {
                        //if metronome.isLeadingIn {
                            MetronomeView()
                        //}
                    //}
                    let text = metronome.isLeadingIn ? "  Leading In  " : "Stop Leading"
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("\(text)")
                        .padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }

            if [.recordingScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    //if Settings.shared.metronomeOn {
                        MetronomeView()
                    //}
                    let text = metronome.isLeadingIn ? "  Leading In  " : "Stop Recording"
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        Text("\(text)")
                        .padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                }
            }
            
            if [.recordingScaleForAssessment].contains(scalesModel.runningProcessPublished) {
                Spacer()
                VStack {
                    let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: true, dynamic:true, articulation:true)
                    Text("Recording \(name)").font(.title).padding()
                    //ScaleStartView()
                    RecordingIsUnderwayView()
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                    }) {
                        VStack {
                            Text("Stop Recording Scale").padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
//                    if coinBank.lastBet > 0 {
//                        CoinStackView(totalCoins: coinBank.lastBet, compactView: false).padding()
//                    }
                }
                .commonFrameStyle()
                Spacer()
            }
            
            if scalesModel.recordingIsPlaying1 {
                Button(action: {
                    AudioManager.shared.stopPlayingRecordedFile()
                }) {
                    Text("Stop Hearing").padding().font(.title2).hilighted(backgroundColor: .blue)
                }
            }
            
            if scalesModel.synchedIsPlaying {
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
            HStack()  {
                Button("Follow The Scale") {
                    scalesModel.setRunningProcess(.followingScale)
                    scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
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
            HStack() {
                Button(scalesModel.runningProcessPublished == .leadingTheScale ? "Stop Leading" : "Lead the Scale") {
                    if scalesModel.runningProcessPublished == .leadingTheScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.leadingTheScale)
                        scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
                    }
                }
                Button(action: {
                    showHelp("LeadTheScale")
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
                Button(scalesModel.runningProcessPublished == .playingAlongWithScale ? "Stop Playing Along" : "Play Along") {
                    scalesModel.setRunningProcess(.playingAlongWithScale)
                    scalesModel.setProcessInstructions("Play along with the scale as its played")
                }
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
            }
            .padding()
            
            Spacer()
            HStack {
                Button(scalesModel.runningProcessPublished == .recordingScale ? "Stop Recording" : "Record The Scale") {
                    if scalesModel.runningProcessPublished == .recordingScale {
                        scalesModel.setRunningProcess(.none)
                    }
                    else {
                        scalesModel.setRunningProcess(.recordingScale)
                    }
                }
                Button(action: {
                    showHelp("Record The Scale")
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
            
            if scalesModel.recordedAudioFile != nil {
                HStack {
                    Button("Hear\nRecording") {
                        AudioManager.shared.playRecordedFile()
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
            
//            if scalesModel.resultPublished != nil {
//                VStack {
//                    Button(action: {
//                        showHelp("Sync The Scale")
//                    }) {
//                        VStack {
//                            Image(systemName: "questionmark.circle")
//                                .imageScale(.large)
//                                .font(.title2)//.bold()
//                                .foregroundColor(.green)
//                        }
//                    }
//                    Text("")
//                    Button("Sync\nRecording") {
//                        scalesModel.setRunningProcess(.syncRecording)
//                    }
//
//                }
//                .frame(maxWidth: .infinity, alignment: .topLeading)
//                .padding()
//            }

            Spacer()
            HStack {
                Button(hearingBacking ? "Backing Off" : "Backing On") {
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
    
    func getKeyboardHeight(keyboardCount:Int) -> CGFloat {
        var height:Double
        if keyboardCount == 1 {
            height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 3 : 4)
        }
        else {
            height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 8 : 8)
        }
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
                    VStack(spacing: 0) {
                        //HStack {
                            let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: false, dynamic:false, articulation:false)
                            Text(name).font(.title)//.padding()
                                .padding(.vertical, 0)
                        //}
                        HStack {
                            Spacer()
                            if scalesModel.runningProcessPublished == .none {
                                SelectScaleParametersView().padding(.vertical, 0)
                            }
                            ViewSettingsView().padding(.vertical, 0)
                            Spacer()
                        }
                    }
                    .commonFrameStyle()
                }
                
                if scalesModel.showKeyboard {
                    let cornerRadius:CGFloat = 6
                    VStack {
                        if [0,2].contains(scalesModel.scale.hand) {
                            VStack {
                                PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardRightHand, keyColor: Settings.shared.getKeyColor())
                                    .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hand == 2 ? 2 : 1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray, lineWidth: 1)
                                    )

                            }
                            //.border(Color.cyan)
                        }
                        if [1,2].contains(scalesModel.scale.hand) {
                            VStack {
                                PianoKeyboardView(scalesModel: scalesModel, viewModel: pianoKeyboardLeftHand, keyColor: Settings.shared.getKeyColor())
                                    .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hand == 2 ? 2 : 1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray, lineWidth: 1)
                                    )
//                                if scalesModel.showLegend {
//                                    LegendView(keyboardHand: 1, scale: scalesModel.scale)
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray, lineWidth: 1)
//                                    )
//                                }
                            }
                            //.border(Color.red)
                        }
                        if scalesModel.showLegend {
                            LegendView(keyboardHand: 0, scale: scalesModel.scale)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray, lineWidth: 1)
                            )
                        }
                    }
                    .commonFrameStyle()
                }

                if scalesModel.showStaff {
                    if scalesModel.scale.hand < 2 {
                        if let score = scalesModel.scores[scalesModel.scale.hand] {
                            VStack {
                                ScoreView(score: score, widthPadding: false)
                            }
                            .commonFrameStyle()
                        }
                    }
                    else {
                        if let scoreRH = scalesModel.scores[0] {
                            VStack {
                                ScoreView(score: scoreRH, widthPadding: false)
                            }
                            .commonFrameStyle()
                        }
                        if let scoreLH = scalesModel.scores[1] {
                            VStack {
                                ScoreView(score: scoreLH, widthPadding: false)
                            }
                            .commonFrameStyle()
                        }
                    }
                }
                
                if badgeBank.show {
                    BadgeView(scale: scalesModel.scale).commonFrameStyle()
                }
                
                if scalesModel.runningProcessPublished != .none || scalesModel.recordingIsPlaying1 || scalesModel.synchedIsPlaying {
                    StopProcessView()
                }
                else {
                    SelectActionView().commonFrameStyle()
                }
                
                Spacer()
            }
            ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
            ///If setting either width or height always also set the other otherwise landscape vs. portrai layout is wrecked.
            .frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.86)
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
            PianoKeyboardModel.sharedRightHand.resetKeysWerePlayedState()
            pianoKeyboardRightHand.keyboardAudioManager = audioManager
            PianoKeyboardModel.sharedLeftHand.resetKeysWerePlayedState()
            pianoKeyboardLeftHand.keyboardAudioManager = audioManager

            //self.handIndex = scalesModel.scale.hand
            ///Causes setState()
            
            self.directionIndex = 0
            if let process = initialRunProcess {
                scalesModel.setRunningProcess(process)
            }
            self.numberOfOctaves = scalesModel.scale.octaves
            if let tempoIndex = scalesModel.tempoSettings.firstIndex(where: { $0.contains("\(scalesModel.scale.minTempo)") }) {
                self.tempoIndex = tempoIndex
            }
            scalesModel.setShowStaff(true) //scalesModel.scale.hand != 2)
            BadgeBank.shared.setShow(false)
        }
        
        .onDisappear {
            metronome.removeAllProcesses()
            scalesModel.setRunningProcess(.none)
            ///Clean up any recorded files
            if Settings.shared.developerModeOn  {
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
        .navigationViewStyle(StackNavigationViewStyle())

        .alert(isPresented: $scalesModel.showUserMessage) {
            Alert(title: Text("Good job 😊"), message: Text(scalesModel.userMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        
        .sheet(item: $activeSheet) { item in
            switch item {
            case .emailRecording:
                if MFMailComposeViewController.canSendMail() {
                    if let fileName = scalesModel.recordedTapsFileName {
                        if let url = scalesModel.recordedTapsFileURL {
                            SendMailView(isShowing: $emailShowing, result: $emailResult,
                                         messageRecipient:"davidmurphy1088@gmail.com",
                                         messageSubject: "Scales Trainer \(getMailInfo())",
                                         messageContent: "\(getMailInfo())\n\nPlease add details if the scale was assessed incorrectly. Please include tempo. Possibly articulation info if relevant, device position if relevant etc. \n",
                                         attachmentFilePath: url)
                        }
                    }
                }
            }

        }
    }
}

