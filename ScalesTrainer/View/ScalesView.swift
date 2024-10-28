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

struct MetronomeView: View {
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = Metronome.shared
    
    var body: some View {
        let beat = (metronome.timerTickerCountPublished % 4) + 1
        Button(action: {
            //scalesModel.setMetronomeTicking(way: !scalesModel.isMetronomeTicking())
            metronome.setTicking(way: !metronome.isMetronomeTicking())
            if metronome.isMetronomeTicking() {
                metronome.start()
            }
            else {
                metronome.stop()
            }
        }) {
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
}

struct ScalesView: View {
    let initialRunProcess:RunningProcess?
    let practiceChartCell:PracticeChartCell?

    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var badgeBank = BadgeBank.shared
    
    @StateObject private var orientationObserver = DeviceOrientationObserver()
    let settings = Settings.shared

    @ObservedObject private var metronome = Metronome.shared
    private let audioManager = AudioManager.shared

    @State private var numberOfOctaves = Settings.shared.defaultOctaves
    @State private var rootNameIndex = 0
    @State private var scaleTypeNameIndex = 0
    @State private var directionIndex = 0
    @State private var tempoIndex = 0
    @State private var bufferSizeIndex = 11
    @State private var startMidiIndex = 4
    @State var amplitudeFilter: Double = 0.00
    @State var recordingScale = false
    @State var showResultPopup = false
    @State var notesHidden = false
    @State var scaleFollowWithSound = false
    @State var helpShowing:Bool = false
    @State private var emailShowing = false
    @State var emailResult: MFMailComposeResult? = nil
    @State var activeSheet: ActiveSheet?
    
    ///Practice Chart badge control
    @State private var practiceChartBadgeVisibleState = 0 //0 down off screen, 1 centered and visible, 2 go top, 3 go bottom
    let practiceChartBadgeImage = Image("pet_dogface")
    @State private var practiceChartBadgeRotationAngle: Double = 0
    
    init(initialRunProcess:RunningProcess?, practiceChartCell:PracticeChartCell?) {
        self.initialRunProcess = initialRunProcess
        self.practiceChartCell = practiceChartCell
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

//            Button(action: {
//                metronome.setTicking(on: !metronome.isTiming)
//            }) {
                MetronomeView()
//            }
//            .padding()
            
            HStack(spacing: 0) {
                //let unicodeCrotchet = "\u{2669}\u{00B7}"
                let compoundTime = scalesModel.scale.timeSignature.top % 3 == 0
                //Text("\(NSLocalizedString("Tempo", comment: "MenuView"))").padding(.horizontal, 0)
                Image(compoundTime ? "crotchetDotted" : "crotchet")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.size.width * (compoundTime ? 0.02 : 0.015))
                    ///Center it
                    .padding(.bottom, 8)
                Text(" =").padding(.horizontal, 0)
            }
            Picker(String(scalesModel.tempoChangePublished), selection: $tempoIndex) {
                ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
                    Text("\(scalesModel.tempoSettings[index])").padding(.horizontal, 0)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 0)

            
            //Spacer()
            Text(LocalizedStringResource("Viewing\nDirection"))
            Picker("Select Value", selection: $directionIndex) {
                ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
                    if scalesModel.selectedScaleSegment >= 0 {
                        Text("\(scalesModel.directionTypes[index])")
                    }
                }
            }
            .pickerStyle(.menu)
            .onChange(of: directionIndex, {
                scalesModel.setSelectedScaleSegment(self.directionIndex)
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
    
    func getStopButtonText(process: RunningProcess) -> String {
        let text:String
        if metronome.isLeadingIn {
            text = "  Leading In  \(metronome.timerTickerCountPublished)"
        }
        else {
            switch process {
            case.leadingTheScale:
                text = "Stop Leading"
            case.backingOn:
                text = "Stop Backing Harmony"
            case.followingScale :
                text = "Stop Following"
            case.playingAlongWithScale :
                text = "Stop Play Along"
            default:
                text = ""
            }
        }
        return text
    }
    
    func badgePointsNeeded() -> Int {
        if Settings.shared.practiceChartGamificationOn {
            return 2 * scalesModel.scale.getScaleNoteCount() / 3
        }
        else {
            return 0
        }
    }
    
    func StopProcessView() -> some View {
        VStack {

            if [.playingAlongWithScale, .followingScale, .leadingTheScale, .backingOn].contains(scalesModel.runningProcessPublished) {
                HStack {
                    let text = getStopButtonText(process: scalesModel.runningProcessPublished)
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                        if [ .followingScale, .leadingTheScale].contains(scalesModel.runningProcessPublished) {
                            if Settings.shared.practiceChartGamificationOn {
                                if BadgeBank.shared.totalCorrect >= badgePointsNeeded()  {
                                    self.practiceChartBadgeVisibleState = 2
                                    practiceChartCell?.adjustBadges(delta: 1)
                                }
                                else {
                                    self.practiceChartBadgeVisibleState = 3
                                    withAnimation(.easeInOut(duration: 1)) {
                                        practiceChartBadgeRotationAngle += 180 // Spin 360 degrees
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    practiceChartBadgeRotationAngle = 0
                                    self.practiceChartBadgeVisibleState = 0
                                }
                            }
                        }
                    }) {
                        Text("\(text)")
                        .padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                        
                }
            }

            if [.recordingScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    MetronomeView()
                    //let text = metronome.isLeadingIn ? "  Leading In  " : "Stop Recording The Scale"
                    ///1.0.11 recording now has no lead in
                    let text = "Stop Recording The Scale"
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
                    //let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: true, dynamic:true, articulation:true)
                    let name = scalesModel.scale.getScaleName(handFull: true, octaves: true)
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
            
            if scalesModel.recordingIsPlaying {
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
        VStack {

            HStack(alignment: .top) {
                Spacer()
                if scalesModel.scale.scaleMotion != .contraryMotion {
                    HStack()  {
                        let title = NSLocalizedString(UIDevice.current.userInterfaceIdiom == .phone ? "Follow" : "Follow", comment: "ProcessMenu")
                        Button(action: {
                            scalesModel.setRunningProcess(.followingScale)
                            scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                            self.practiceChartBadgeVisibleState = 1
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Button(action: {
                                showHelp("Follow")
                            }) {
                                VStack {
                                    Image(systemName: "questionmark.circle")
                                        .imageScale(.large)
                                        .font(.title2)//.bold()
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 0)
                }
                
                if scalesModel.scale.scaleMotion != .contraryMotion {
                    Spacer()
                    HStack() {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Lead" : "Lead"
                        Button(action: {
                            if scalesModel.runningProcessPublished == .leadingTheScale {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                scalesModel.setRunningProcess(.leadingTheScale)
                                scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
                                self.practiceChartBadgeVisibleState = 1
                            }
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Button(action: {
                                showHelp("Lead")
                            }) {
                                VStack {
                                    Image(systemName: "questionmark.circle")
                                        .imageScale(.large)
                                        .font(.title2)//.bold()
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 0)
                }
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Play Along" : "Play Along With"
                    //                Button(scalesModel.runningProcessPublished == .playingAlongWithScale ? "Stop Playing Along" : NSLocalizedString("Play Along", comment: "Menu")) {
                    //                    scalesModel.setRunningProcess(.playingAlongWithScale)
                    //                    scalesModel.setProcessInstructions("Play along with the scale as its played")
                    //                }
                    Button(action: {
                        scalesModel.setRunningProcess(.playingAlongWithScale)
                        scalesModel.setProcessInstructions("Play along with the scale as its played")
                    }) {
                        Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Button(action: {
                            showHelp("Play Along With")
                        }) {
                            VStack {
                                Image(systemName: "questionmark.circle")
                                    .imageScale(.large)
                                    .font(.title2)//.bold()
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 0)
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Record" : "Record"
                    Button(action: {
                        if scalesModel.runningProcessPublished == .recordingScale {
                            scalesModel.setRunningProcess(.none)
                        }
                        else {
                            scalesModel.setRunningProcess(.recordingScale)
                        }
                        
                    }) {
                        Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Button(action: {
                            showHelp("Record")
                        }) {
                            VStack {
                                Image(systemName: "questionmark.circle")
                                    .imageScale(.large)
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 0)
                
                if scalesModel.recordedAudioFile != nil {
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Hear" : "Hear Recording"
                        Button(action: {
                            AudioManager.shared.playRecordedFile()
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        if UIDevice.current.userInterfaceIdiom != .phone {
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
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 0)
                }
                
                if scalesModel.scale.getBackingChords() != nil {
                    Spacer()
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Backing" : "Backing Track\nHarmony"
                        Button(action: {
                            //hearingBacking.toggle()
                            if scalesModel.runningProcessPublished == .backingOn {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                scalesModel.setRunningProcess(.backingOn)
                            }
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Button(action: {
                                showHelp("Backing Track Harmony")
                            }) {
                                VStack {
                                    Image(systemName: "questionmark.circle")
                                        .imageScale(.large)
                                        .font(.title2)//.bold()
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, 0)
                }
                Spacer()
            }
//            if UIDevice.current.userInterfaceIdiom != .phone {
//                Text("")
//            }
        }
    }
    
    func getKeyboardHeight(keyboardCount:Int) -> CGFloat {
        var height:Double
        if scalesModel.scale.needsTwoKeyboards() {
            height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 8 : 8)
        }
        else {
            height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 3 : 4)
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
    
    func getBadgeOffset() -> Int {
        if self.practiceChartBadgeVisibleState == 0 {
            return 300
        }
        if self.practiceChartBadgeVisibleState == 2 {
            return Int(0-UIScreen.main.bounds.height)
        }
        if self.practiceChartBadgeVisibleState == 3 {
            return 0 - Int(300)
        }
        return 0
    }
    
    func getBadgeMessage() -> String {
        let remaining = self.badgePointsNeeded() - BadgeBank.shared.totalCorrect
        var msg = ""
        if remaining > 0 {
            if remaining == 1 {
                msg = "Win me with one more correct note 😊"
            }
            else {
                msg = BadgeBank.shared.totalCorrect == 0 ? "Win me with just \(remaining) notes correct 😊" : "Win me with \(remaining) more notes correct 😊"
            }
        }
        else {
            msg = "😊 You won me 😊"
        }
        return msg
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ScaleTitleView(scale: scalesModel.scale)
                    .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
                    .padding(.vertical)
                    .padding(.horizontal, 0)
                HStack {
                    Spacer()
                    if scalesModel.runningProcessPublished == .none {
                        SelectScaleParametersView()
                        //.padding(.vertical, 0)
                        //.padding()
                    }
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        HideandShowView()
                        //.padding(.vertical, 0)
                            .padding()
                    }
                    Spacer()
                }
                .commonFrameStyle(backgroundColor: Color.white)
            }
            
            if scalesModel.showKeyboard {
                VStack {
                    if let joinedKeyboard = PianoKeyboardModel.sharedCombined {
                        ///Scale is contrary with LH and RH joined on one keyboard
                        PianoKeyboardView(scalesModel: scalesModel, viewModel: joinedKeyboard, keyColor: Settings.shared.getKeyboardColor1())
                            .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                        //                            PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedRH, keyColor: Settings.shared.getKeyColor())
                        //                                .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                        //                            PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedLH, keyColor: Settings.shared.getKeyColor())
                        //                                .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                    }
                    else {
                        if scalesModel.scale.needsTwoKeyboards() {
                            PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedRH, keyColor: Settings.shared.getKeyboardColor1())
                                .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                            PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedLH, keyColor: Settings.shared.getKeyboardColor1())
                                .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                        }
                        else {
                            let keyboard = scalesModel.scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                            PianoKeyboardView(scalesModel: scalesModel, viewModel: keyboard, keyColor: Settings.shared.getKeyboardColor1())
                                .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                        }
                    }
                }
                .commonFrameStyle()
                if UIDevice.current.userInterfaceIdiom != .phone {
                    if ![.brokenChordMajor, .brokenChordMinor].contains(scalesModel.scale.scaleType) {
                        if scalesModel.showLegend {
                            LegendView(hands: scalesModel.scale.hands, scale: scalesModel.scale)
                                .commonFrameStyle(backgroundColor: Color.white)
                        }
                    }
                }
            }
            
            if scalesModel.showStaff {
                if scalesModel.scale.hands.count < 2 {
                    if let score = scalesModel.scores[scalesModel.scale.hands[0]] {
                        VStack {
                            ScoreView(score: score, widthPadding: false)
                        }
                        .commonFrameStyle(backgroundColor: Color.white)
                    }
                }
                else {
                    if let scoreRH = scalesModel.scores[0] {
                        VStack {
                            ScoreView(score: scoreRH, widthPadding: false)
                        }
                        .commonFrameStyle(backgroundColor: Color.white)
                    }
                    if let scoreLH = scalesModel.scores[1] {
                        VStack {
                            ScoreView(score: scoreLH, widthPadding: false)
                        }
                        .commonFrameStyle(backgroundColor: Color.white)
                    }
                }
            }
            
//            if badgeBank.show {
//                
//            }
            
            if scalesModel.runningProcessPublished != .none || scalesModel.recordingIsPlaying || scalesModel.synchedIsPlaying {
                StopProcessView()
            }
            else {
                SelectActionView().commonFrameStyle(backgroundColor: Color.white)
            }
            
            if Settings.shared.practiceChartGamificationOn && badgeBank.show {
                BadgeView(scale: scalesModel.scale).commonFrameStyle(backgroundColor: Color.white)
                ///Practice chart badge temporarily removed awaiting more design
                if Settings.shared.isDeveloperMode() {
                    self.practiceChartBadgeImage
                        .offset(x: self.practiceChartBadgeVisibleState == 2 ? -UIScreen.main.bounds.width / 2 : 0, y: CGFloat(self.getBadgeOffset()))
                        .animation(.easeInOut(duration: [2,3].contains(self.practiceChartBadgeVisibleState) ? 2.0 : 1), value:  practiceChartBadgeVisibleState)
                        .rotationEffect(.degrees(practiceChartBadgeRotationAngle))
                        .opacity(practiceChartBadgeVisibleState == 0 ? 0.0 : 1.0)
                    
                    Text(getBadgeMessage())
                        .padding()
                        .foregroundColor(.blue)
                        .opacity(practiceChartBadgeVisibleState == 0 ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 0.5), value: practiceChartBadgeVisibleState)
                        .zIndex(1) // Keeps it above other views
                }
            }
            
            Spacer()
        }
        ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
        ///If setting either width or height always also set the other otherwise landscape vs. portrai layout is wrecked.
        //.frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.86)
        .commonFrameStyle()
    
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }
        .onChange(of: tempoIndex, {
            scalesModel.setTempo(self.tempoIndex)
        })

        ///Every time the view appears, not just the first.
        ///Whoever calls up this view has set the scale already
        .onAppear {
            scalesModel.setResultInternal(nil, "ScalesView.onAppear")
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
            if scalesModel.scale.scaleMotion == .contraryMotion && scalesModel.scale.hands.count == 2 {
                PianoKeyboardModel.sharedCombined = PianoKeyboardModel.sharedLH.join(fromKeyboard: PianoKeyboardModel.sharedRH, scale: scalesModel.scale)
                if let combined = PianoKeyboardModel.sharedCombined {
                    let middleKeyIndex = combined.getKeyIndexForMidi(midi: scalesModel.scale.scaleNoteState[0][0].midi, segment: 0)
                    if let middleKeyIndex = middleKeyIndex {
                        combined.pianoKeyModel[middleKeyIndex].hilightKeyToFollow = .middleOfKeyboard
                    }
                }
            }
            else {
                PianoKeyboardModel.sharedCombined = nil
            }
            
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
            scalesModel.setRecordedAudioFile(nil)
        }
        
        .onDisappear {
            metronome.removeAllProcesses()
            scalesModel.setRunningProcess(.none)
            PianoKeyboardModel.sharedCombined = nil  ///DONT delete, required for the next view initialization

            ///Clean up any recorded files
            if false {
                ///This deletes the practice chart AND shouldnt
                if Settings.shared.isDeveloperMode()  {
                    let fileManager = FileManager.default
                    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                        do {
                            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                            for fileURL in fileURLs {
                                do {
                                    try fileManager.removeItem(at: fileURL)
                                    //Logger.shared.log("Removed file at \(fileURL)")
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

