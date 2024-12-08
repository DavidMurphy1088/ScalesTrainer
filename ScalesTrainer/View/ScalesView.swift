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
    @EnvironmentObject var orientationInfo: OrientationInfo
    let initialRunProcess:RunningProcess?
    let practiceChartCell:PracticeChartCell?

    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var badgeBank = BadgeBank.shared
    
    //@StateObject private var orientationObserver = DeviceOrientationObserver()
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
    @State var lastBadgeImage = 0
    //let inspection = Inspection<ScalesView>() // For ViewInspector
    
    ///Practice Chart badge control
    @State var practiceChartBadgeImage = Image("pet_dogface")
    
    init(initialRunProcess:RunningProcess?, practiceChartCell:PracticeChartCell?) {
        self.initialRunProcess = initialRunProcess
        self.practiceChartCell = practiceChartCell
    }

    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    func SelectScaleParametersView() -> some View {
        HStack {            
            HStack(spacing: 0) {
                let compoundTime = scalesModel.scale.timeSignature.top % 3 == 0
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
    
//    func badgePointsNeeded() -> Int {
//        if Settings.shared.practiceChartGamificationOn {
//            return 3 * scalesModel.scale.getScaleNoteCount() / 4
//        }
//        else {
//            return 0
//        }
//    }
    
    func StopProcessView() -> some View {
        VStack {
            if [.playingAlongWithScale, .followingScale, .leadingTheScale, .backingOn].contains(scalesModel.runningProcessPublished) {
                HStack {
                    let text = getStopButtonText(process: scalesModel.runningProcessPublished)
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                        if [ .followingScale, .leadingTheScale].contains(scalesModel.runningProcessPublished) {
                            if Settings.shared.practiceChartGamificationOn {
                                if badgeBank.badgeState == .won  {
                                    //practiceChartCell?.adjustBadges(delta: 1)
                                }
                                else {
                                    badgeBank.setBadgeState(.lost)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    badgeBank.setBadgeState(.offScreen)
                                }
                            }
                        }
                    }) {
                        Text("\(text)")
                        //.padding().font(.title2).hilighted(backgroundColor: .blue)
                    }
                    .buttonStyle(.borderedProminent)
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
                    }
                    .buttonStyle(.borderedProminent)
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
                            Text("Stop Recording Scale")//.padding().font(.title2).hilighted(backgroundColor: .blue)
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
                    Text("Stop Hearing")//.padding().font(.title2).hilighted(backgroundColor: .blue)
                }
                .buttonStyle(.borderedProminent)
            }
            
            if scalesModel.synchedIsPlaying {
                Button(action: {
                    scalesModel.setRunningProcess(.none)
                }) {
                    Text("Stop Hearing")//.padding().font(.title2).hilighted(backgroundColor: .blue)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    func scaleIsAcousticCapable(scale:Scale) -> Bool {
        if Settings.shared.enableMidiConnnections {
            return true
        }
        else {
            return scale.hands.count == 1
        }
    }
    
    func setBadgeImage() -> Image {
        //let names = ["pet_penguinface", "pet_catface","pet_dogface", "sea_creature_1", "sea_creature_2" ]
        //let names = ["pet_dogface", "sea_creature_2", "pet_penguinface","badge_koala", "badge_tiger", "badge_giraffe" , "badge_camel" , "badge_owl"]
        let names = ["badge_1", "badge_2", "badge_3", "badge_4", "badge_5", "badge_6", "badge_7", "badge_8"]
        var r = 0
        while true {
            r = Int.random(in: 0...names.count-1)
            if r != lastBadgeImage {
                lastBadgeImage = r
                break
            }
        }
        return Image(names[r])
    }
    
    func SelectActionView() -> some View {
        VStack {

            HStack(alignment: .top) {
                Spacer()
                if self.scaleIsAcousticCapable(scale: self.scalesModel.scale) {
                    HStack()  {
                        let title = NSLocalizedString(UIDevice.current.userInterfaceIdiom == .phone ? "Follow" : "Follow", comment: "ProcessMenu")
                        Button(action: {
                            scalesModel.setRunningProcess(.followingScale)
                            scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                            badgeBank.setBadgeState(.visible)
                        }) {
                            Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .buttonStyle(.bordered)
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
                
                if self.scaleIsAcousticCapable(scale: self.scalesModel.scale) {
                    Spacer()
                    HStack() {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Lead" : "Lead"
                        Button(action: {
                            if scalesModel.runningProcessPublished == .leadingTheScale {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                practiceChartBadgeImage = setBadgeImage()
                                scalesModel.setRunningProcess(.leadingTheScale)
                                scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
                                badgeBank.setBadgeState(.visible)
                            }
                        }) {
                            Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("button_lead")
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
                        Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    .buttonStyle(.bordered)
                    
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
                        Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    .buttonStyle(.bordered)
                    
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
                            Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .buttonStyle(.bordered)
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
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Backing" : "Backing Track" //"Backing Track\nHarmony"
                        Button(action: {
                            if scalesModel.runningProcessPublished == .backingOn {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                scalesModel.setRunningProcess(.backingOn)
                            }
                        }) {
                            Text(title)//.font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .buttonStyle(.bordered)
                        
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
            //height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 5 : 5)
            height = UIScreen.main.bounds.size.height / (orientationInfo.isPortrait ? 5 : 5)
        }
        else {
            //height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 3 : 4)
            height = UIScreen.main.bounds.size.height / (orientationInfo.isPortrait  ? 4 : 3)
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
    
    func getBadgeMessage() -> String {
        let remaining = badgeBank.badgePointsNeededToWin()
        var msg = ""
        if badgeBank.badgeState == .won {
            msg = "😊 You Won Me 😊"
        }
        else {
            if remaining == 1 {
                msg = "Win me with one more correct note"
            }
            else {
                msg = BadgeBank.shared.totalCorrect == 0 ? "Win me with just \(remaining) notes correct" : "Win me with \(remaining) more notes correct"
            }
        }
        return (msg)
    }
    
    func staffCanFit() -> Bool {
        var canFit = true
        if self.scalesModel.scale.hands.count > 1 {
            //if UIDevice.current.userInterfaceIdiom == .phone && !orientationObserver.orientation.isPortrait {
            if UIDevice.current.userInterfaceIdiom == .phone && !orientationInfo.isPortrait {
                canFit = false
            }
        }
        return canFit
    }
        
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ScaleTitleView(scale: scalesModel.scale)
                    .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
                    //.padding(.vertical)
                    .padding(.horizontal, 0)
                HStack {
                    Spacer()
                    if scalesModel.runningProcessPublished == .none {
                        SelectScaleParametersView()
                        .padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
                        //.padding()
                    }
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        HideandShowView()
                        .padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
                        //.padding()
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
            
            if staffCanFit() {
                if scalesModel.showStaff {
                    if let score = scalesModel.score {
                        VStack {
                            ScoreView(score: score, widthPadding: false)
                        }
                        .commonFrameStyle(backgroundColor: Color.white)
                    }
                }
            }
            
            if scalesModel.runningProcessPublished != .none || scalesModel.recordingIsPlaying || scalesModel.synchedIsPlaying {
                StopProcessView()
            }
            else {
                SelectActionView().commonFrameStyle(backgroundColor: Color.white)
            }
            
            if Settings.shared.practiceChartGamificationOn && badgeBank.show {
                BadgeView(scale: scalesModel.scale).commonFrameStyle(backgroundColor: Color.white)
                //if Settings.shared.isDeveloperMode() {
                    HStack {
                        let msg = getBadgeMessage()
                        Text(msg)
                            .padding()
                            .foregroundColor(.blue)
                            .font(badgeBank.badgeState == .won ? .title : .title2)
                            .opacity(badgeBank.badgeState == .offScreen ? 0.0 : 1.0)
                            .zIndex(1) // Keeps it above other views
                        
                        self.practiceChartBadgeImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIScreen.main.bounds.height * 0.05)
                        
                            ///Appear state
                            //.offset(y: badgeBank.badgeState == .offScreen ? 400 : 0)
                            .rotationEffect(Angle(degrees: badgeBank.badgeState == .offScreen ? 180 : 0))
                            .rotation3DEffect( //3D flip around its vertical axis
                                Angle(degrees: badgeBank.badgeState == .offScreen ? 75 : 0),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(.easeInOut(duration: 1), value: badgeBank.badgeState)

                            ///Won state
                            .scaleEffect(badgeBank.badgeState == .won ? 1.5 : 1.0) //Change size
                            .rotationEffect(Angle(degrees: badgeBank.badgeState == .won ? 360 : 0)) //Spin badge
                            .rotation3DEffect( //3D flip around its vertical axis
                                Angle(degrees: badgeBank.badgeState == .won ? 180 : 0),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(.easeInOut(duration: [.won].contains(badgeBank.badgeState) ? 2.0 : 0), value: badgeBank.badgeState)

                            ///Lost state
                            .rotationEffect(Angle(degrees: badgeBank.badgeState == .lost ? 180 : 0)) //Turn downwards
                            //.animation(.easeInOut(duration: [.won,.lost].contains(badgeBank.badgeState) ? 2.0 : 1), value: badgeBank.badgeState)
                            //.animation(.easeInOut(duration: 2), value: badgeBank.badgeState)
                            .offset(y: badgeBank.badgeState == .lost ? 400 : 0) //send down
                            //.animation(.easeInOut(duration: [.won,.lost].contains(badgeBank.badgeState) ? 2.0 : 1), value: badgeBank.badgeState)
                            .animation(.easeInOut(duration: 2), value: badgeBank.badgeState)

                            .opacity(badgeBank.badgeState == .offScreen ? 0.0 : 1.0)
                    }
                //}
            }
            
            Spacer()
        }
        //.inspection.inspect(inspection)
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
            //self.scalesModel.scale.debug111("SV")
            scalesModel.setResultInternal(nil, "ScalesView.onAppear")
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
            if scalesModel.scale.scaleMotion == .contraryMotion && scalesModel.scale.hands.count == 2 {
                PianoKeyboardModel.sharedCombined = PianoKeyboardModel.sharedLH.join(fromKeyboard: PianoKeyboardModel.sharedRH, scale: scalesModel.scale)
                if let combined = PianoKeyboardModel.sharedCombined {
                    //let middleKeyIndex = combined.getKeyIndexForMidi(midi: scalesModel.scale.scaleNoteState[0][0].midi, segment: 0)
                    let middleKeyIndex = combined.getKeyIndexForMidi(midi: scalesModel.scale.getScaleNoteState(handType: .right, index: 0).midi, segment: 0)
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
            scalesModel.setShowStaff(true)
            badgeBank.setShow(false)
            badgeBank.numberToWin = (scalesModel.scale.getScaleNoteCount() * 3) / 4
            scalesModel.setRecordedAudioFile(nil)
            //if scalesModel.scale.debugOn {
                //scalesModel.scale.debug1("In View1", short: false)
            //}
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
                    if scalesModel.recordedTapsFileName != nil {
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

