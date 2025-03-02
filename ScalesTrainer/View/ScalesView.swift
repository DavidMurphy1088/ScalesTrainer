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
                    .scaleEffect(x: beat/2 % 2 == 0 ? -1 : 1, y: 1)
                    //.animation(.easeInOut(duration: 0.1), value: beat)
            }
            .frame(width: UIScreen.main.bounds.size.width * 0.04)
        }
    }
}

struct SlideUpPanel : View {
    let user:User
    let exerciseState:ExerciseState
    let msg:String
    let imageName:String
    @State var badgeImageRotationAngle:Double = 0
    
    var body: some View {
        VStack {
            HStack {
                Text(msg)
                    .padding()
                    .foregroundColor(.blue)
                    .font(.title2)
                //.opacity(exerciseState.statePublished == .wonAndFinished ? 1 : 0)
                    .zIndex(1) // Keeps it above other views

                ///Practice chart badge position is based on exercise state
                ///State goes to won (when enough points) and then .wonAndFinished at end of exercise or user does "stop"
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIScreen.main.bounds.height * 0.04)
//                    .offset(x: getBadgeOffset(state: exerciseState.statePublished).0,
//                            y: getBadgeOffset(state: exerciseState.statePublished).1)
                .rotationEffect(Angle(degrees: self.badgeImageRotationAngle))
                    .animation(.easeInOut(duration: 1), value: self.badgeImageRotationAngle)
                    .padding()
                    .onChange(of: exerciseState.statePublished) { _ in
                        withAnimation(.easeInOut(duration: 1)) {
                            if exerciseState.statePublished == .exerciseWon {
                                badgeImageRotationAngle += 360
                            }
                        }
                    }
                //.opacity(exerciseState.statePublished == .wonAndFinished ? 1 : 0)
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.size.width * 0.6)
        .frame(height: UIScreen.main.bounds.size.height * 0.07)
        .background(user.settings.getKeyboardColor()) //opacity(0.9)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct ScalesView: View {
    let practiceChart:PracticeChart?
    let practiceChartCell:PracticeChartCell?
    let practiceModeHand:HandType?
    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var exerciseState = ExerciseState.shared

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
    @State var lastBadgeNumber = 0
    @State private var isLandscape: Bool = false
    @State private var badgeImageRotationAngle: Double = 0
    @State private var spacingVertical:CGFloat = 0
    @State private var spacingHorizontal:CGFloat = 12
    ///The slide up panel for badge info
    @State private var showPanel = false
    @State private var showPanelOffset: CGFloat = UIScreen.main.bounds.height 
    
    ///Practice Chart badge control
    @State var exerciseBadge:Badge?
    
    init(practiceChart:PracticeChart?, practiceChartCell:PracticeChartCell?, practiceModeHand:HandType?) {
        self.practiceChart = practiceChart
        self.practiceChartCell = practiceChartCell
        self.practiceModeHand = practiceModeHand
    }

    func showHelp(_ topic:String) {
        scalesModel.helpTopic = topic
        self.helpShowing = true
    }
    
    func SelectScaleParametersView() -> some View {
        HStack {       
            MetronomeView()
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
            ///2 ticks per beat
            text = "  Leading In  " //\((metronome.timerTickerCountPublished / 2) + 1)"
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
    
    func StopProcessView(user:User) -> some View {
        VStack {
            if [.playingAlongWithScale, .followingScale, .leadingTheScale, .backingOn].contains(scalesModel.runningProcessPublished) {
                HStack {
                    let text = getStopButtonText(process: scalesModel.runningProcessPublished)
                    Button(action: {
                        scalesModel.setRunningProcess(.none)
                        if [ .followingScale, .leadingTheScale].contains(scalesModel.runningProcessPublished) {
                            if user.settings.practiceChartGamificationOn {
                                ///Stopped by user before exercise process stopped it
                                if exerciseState.statePublished == .exerciseWon  {
                                    //exerciseState.setExerciseState(ctx: "ScalesView, StopProcessView() WON", .wonAndFinished)
                                }
                                else {
                                    exerciseState.setExerciseState(ctx: "ScalesView, StopProcessView() LOST", .exerciseLost)
                                }
                            }
                        }
                    }) {
                        Text("\(text)")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if [.recordingScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    //MetronomeView()
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
                    let name = scalesModel.scale.getScaleIdentificationKey()
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
                //.commonFrameStyle()
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
        if let user = settings.getCurrentUser() {
            if user.settings.useMidiConnnections {
                return true
            }
        }
        return scale.hands.count == 1
    }
    
    func SelectActionView() -> some View {
        VStack {
            HStack(alignment: .top) {
                if self.scaleIsAcousticCapable(scale: self.scalesModel.scale) {
                    Spacer()
                    HStack()  {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Fol\u{200B}low" : "Follow"

                        Button(action: {
                            scalesModel.setRunningProcess(.followingScale, practiceChart: practiceChart, practiceChartCell: practiceChartCell)
                            scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
                            self.directionIndex = 0
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        //.buttonStyle(.bordered)
                        .blueButtonStyle(trim: true)
                        if false {
                            Button(action: {
                                showHelp("Follow")
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
                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
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
                                self.exerciseBadge = scalesModel.exerciseBadge
                                scalesModel.setRunningProcess(.leadingTheScale, practiceChart: self.practiceChart, practiceChartCell: self.practiceChartCell)
                                scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
                            }
                            self.directionIndex = 0
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .blueButtonStyle(trim: true)
                        .accessibilityIdentifier("button_lead")
                        if false {
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
                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
                }
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Play\u{200B}Along" : "Play Along"
                    Button(action: {
                        scalesModel.setRunningProcess(.playingAlongWithScale)
                        scalesModel.setProcessInstructions("Play along with the scale as its played")
                        self.directionIndex = 0
                    }) {
                        Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    .blueButtonStyle(trim: true)
                    
                    if false {
                        Button(action: {
                            showHelp("Play Along")
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
                .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                //.padding(.horizontal, 0)
                
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
                    .blueButtonStyle(trim: true)
                    
                    if false {
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
                .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                //.padding(.horizontal, 0)
                
                if scalesModel.recordedAudioFile != nil {
                    Spacer()
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Hear" : "Hear Recording"
                        Button(action: {
                            AudioManager.shared.playRecordedFile()
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .blueButtonStyle(trim: true)
                        if false {
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
                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
                }
                
                if scalesModel.scale.getBackingChords() != nil {
                    Spacer()
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Backing" : "Backing Track"
                        Button(action: {
                            if scalesModel.runningProcessPublished == .backingOn {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                scalesModel.setRunningProcess(.backingOn)
                            }
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .blueButtonStyle(trim: true)
                        
                        if false {
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
                    .padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
                }
                Spacer()
            }
        }
    }
    
    func getKeyboardHeight(keyboardCount:Int) -> CGFloat {
        var height:Double
        
        if scalesModel.scale.needsTwoKeyboards() {
            //height = UIScreen.main.bounds.size.height / (orientationObserver.orientation.isAnyLandscape ? 5 : 5)
            //height = UIScreen.main.bounds.size.height / (orientationInfo.isPortrait ? 5 : 5)
            ///16 Feb 2025 Can be a bit longer due to just minimizing some other UI heights in landscape
            height = UIScreen.main.bounds.size.height / (isLandscape ? 4 : 5)
        }
        else {
            //height = UIScreen.main.bounds.size.height / (isLandscape  ? 3 : 4)
            height = UIScreen.main.bounds.size.height / (isLandscape  ? 4 : 3)
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
    
    func getExerciseStatusMessage(badge:Badge) -> String {
        let remaining = exerciseState.pointsNeededToWin()
        var msg = ""
        let name = badge.name
        
        switch exerciseState.statePublished {
        case .exerciseNotStarted1:
            msg = ""
        case .exerciseStarting:
            msg = "Win \(name) ✋"
        case .exerciseRunning:
            msg = ""
        case .exerciseWon:
            msg = "😊 You Won \(name) 😊"
        case .exerciseLost:
            msg = ""
        }
        print("==================== ⬅️ getExerciseStatusMessage", exerciseState.statePublished, msg)
        return (msg)
    }
    
    func staffCanFit() -> Bool {
        var canFit = true
        ///01Feb2025 - decided chromatic cant display well on any device or orientation
        //if UIDevice.current.userInterfaceIdiom == .phone {
            if scalesModel.scale.scaleType == .chromatic &&
                //scalesModel.scale.scaleMotion == .contraryMotion &&
                scalesModel.scale.octaves > 1 {
                canFit = false
            }
        //}
        return canFit
    }
        
    func getBadgeOffset(state:ExerciseState.State) -> (CGFloat, CGFloat) {
        ///All offsets are relative to the last postion
        if state == .exerciseNotStarted1 {
            //return (0, UIScreen.main.bounds.height)
            return (0, 300)
        }
//        if state == .exerciseStarted {
//            //return (0, UIScreen.main.bounds.height)
//            return (0, 0)
//        }
        if state == .exerciseLost {
            //return (0, UIScreen.main.bounds.height)
            ///The image is rotated down so negative offset sends it down
            return (0, UIScreen.main.bounds.height * -0.5)
        }
//        if [.wonAndFinished].contains(state) {
//            //return (UIScreen.main.bounds.width * -0.5, UIScreen.main.bounds.height * -0.75)
//            return (UIScreen.main.bounds.width * -0.3, UIScreen.main.bounds.height * -0.75)
//        }
        return (0,0) //Exercise started
    }
    
    func hasVerticalSpace() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        return !isLandscape
    }
    
    func HeaderView() -> some View {
        HStack {
            Spacer()
            SelectScaleParametersView()
            if UIDevice.current.userInterfaceIdiom == .phone {
                if isLandscape {
                    //HideAndShowView(compact: true)
                }
            }
            else {
                HideAndShowView(compact: false)
            }
            Spacer()
        }
        .padding(.vertical)
//        .outlinedStyleView(opacity: 0.3)
//        .padding(.vertical, spacingVertical)
//        .padding(.horizontal, spacingHorizontal)
    }
    
    func setVerticalSpacing() {
        if isLandscape {
            self.spacingVertical = UIDevice.current.userInterfaceIdiom == .phone ? 0 : 0
        }
        else {
            self.spacingVertical = UIDevice.current.userInterfaceIdiom == .phone ? 0 : 12
        }
    }
    
    var body: some View {
        
        ZStack {
            VStack(spacing:0) {
                VStack(spacing: 0) {
                    ScaleTitleView(scale: scalesModel.scale, practiceModeHand: practiceModeHand)
                        //.border(Color.red)
                }
                VStack {
                    HeaderView()
                        .outlinedStyleView(opacity: 0.3)
                        .padding(.top, spacingVertical)
                        //.padding(.bottom, spacingVertical)
                        .padding(.horizontal, spacingHorizontal)
                    if scalesModel.showKeyboard {
                        if let user = settings.getCurrentUser() {
                            VStack {
                                if let joinedKeyboard = PianoKeyboardModel.sharedCombined {
                                    ///Scale is contrary with LH and RH joined on one keyboard
                                    PianoKeyboardView(scalesModel: scalesModel, viewModel: joinedKeyboard, keyColor: user.settings.getKeyboardColor())
                                        .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                                }
                                else {
                                    if scalesModel.scale.needsTwoKeyboards() {
                                        PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedRH, keyColor: user.settings.getKeyboardColor())
                                            .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                                        PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedLH,
                                                          keyColor: user.settings.getKeyboardColor())
                                        .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                                    }
                                    else {
                                        let keyboard = scalesModel.scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                                        PianoKeyboardView(scalesModel: scalesModel, viewModel: keyboard,
                                                          keyColor: user.settings.getKeyboardColor())
                                        .frame(height: getKeyboardHeight(keyboardCount: scalesModel.scale.hands.count))
                                    }
                                }
                            }
                            .outlinedStyleView(opacity: 0.3)
                            .padding(.top, spacingVertical)
                            .padding(.horizontal, spacingHorizontal)
//                            .cornerRadius(spacingHorizontal)
//                            .padding(.vertical, spacingVertical)
//                            .padding(.horizontal, spacingHorizontal)
                            
                        }
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            if ![.brokenChordMajor, .brokenChordMinor].contains(scalesModel.scale.scaleType) {
                                if scalesModel.showLegend {
                                    LegendView(hands: scalesModel.scale.hands, scale: scalesModel.scale)
                                        .padding(.top, 2)
                                    //.border(Color.red, width: 1)
                                }
                            }
                        }
                    }
                    
                    if staffCanFit() {
                        if let score = scalesModel.getScore() {
                            VStack(spacing: 0) {
                                if scalesModel.showStaff {
                                    ScoreView(scale: ScalesModel.shared.scale, score: score)
                                }
                            }
                            //.border(Color.red, width: 1)
                            .outlinedStyleView(opacity: 0.3)
                            .padding(.top, spacingVertical)
                            .padding(.horizontal, spacingHorizontal)
                        }
                    }
                    
                    if scalesModel.runningProcessPublished != .none || scalesModel.recordingIsPlaying || scalesModel.synchedIsPlaying {
                        if let user = settings.getCurrentUser() {
                            StopProcessView(user:user)
                        }
                    }
                    else {
                        SelectActionView()
                    }
                    
                    ///-------- Badges mesages and displays ----------
                    
                    if let user = Settings.shared.getCurrentUser() {
                        if user.settings.practiceChartGamificationOn {
                            if let exerciseBadge = scalesModel.exerciseBadge {
                                ///Show the horizontal row of badges
                                if [ExerciseState.State.exerciseStarting, ExerciseState.State.exerciseRunning, ExerciseState.State.exerciseWon].contains(exerciseState.statePublished) {
                                    BadgesView(scale: scalesModel.scale, onClose: {
                                        exerciseState.setExerciseState(ctx: "", .exerciseNotStarted1)
                                    })
                                        .outlinedStyleView()
                                        .padding(.vertical, spacingVertical)
                                        .padding(.horizontal, spacingHorizontal)
                                }
                            }
                        }
                    }
                    
                    if Settings.shared.isDeveloperMode1()  {
                        if let user = Settings.shared.getCurrentUser() {
                            if user.settings.useMidiConnnections {
                                Spacer()
                                TestInputView()
                            }
                        }
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .screenBackgroundStyle()
                //.border(Color.pink, width:2)
            }
            
            if showPanel {
                if let user = Settings.shared.getCurrentUser() {
                    if user.settings.practiceChartGamificationOn {
                        if let badge = scalesModel.exerciseBadge {
                            SlideUpPanel(user: user, exerciseState: exerciseState, msg:self.getExerciseStatusMessage(badge: badge), imageName: badge.imageName)
                                .offset(y: showPanelOffset)
                                //.offset(x: showPanelOffset)
                                .onAppear {
                                    if showPanel {
                                        withAnimation(.easeInOut(duration: 1.0)) {
                                            showPanelOffset = 0 // Slide in slowly
                                        }
                                    }
                                }
                                .onChange(of: showPanel) { newValue in
                                    withAnimation(.easeInOut(duration: 1.0)) {
                                        showPanelOffset = newValue ? 0 : UIScreen.main.bounds.height // Slide up/down slowly
                                        //showPanelOffset = newValue ? 0 : UIScreen.main.bounds.width
                                    }
                                }
                                .ignoresSafeArea(edges: .bottom)
                                .frame(maxHeight: .infinity, alignment: .bottom) // Keeps it at bottom
                                .zIndex(1)
                        }
                    }
                }
            }
        }
        //.inspection.inspect(inspection)
        ///Dont make height > 0.90 otherwise it screws up widthways centering. No idea why 😡
        ///If setting either width or height always also set the other otherwise landscape vs. portrai layout is wrecked.
        //.frame(width: UIScreen.main.bounds.width * 0.95, height: UIScreen.main.bounds.height * 0.86)
        //.commonFrameStyle()
    
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }
        .onChange(of: tempoIndex, {
            scalesModel.setTempo(self.tempoIndex)
        })
        .onChange(of: exerciseState.statePublished, {
            ///Slide in the badge message
            if [ExerciseState.State.exerciseStarting, ExerciseState.State.exerciseWon].contains(exerciseState.statePublished) {
                self.showPanel = true
                self.showPanelOffset = UIScreen.main.bounds.height
            }
            else {
                self.showPanel = false
            }
        })

        ///Determine device orientation
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    isLandscape = geometry.size.width > geometry.size.height
                    setVerticalSpacing()
                }
                .onChange(of: geometry.size) { newSize in
                    isLandscape = newSize.width > newSize.height
                    setVerticalSpacing()
                }
                
        })
        //.screenBackgroundStyle()
        
        ///Every time the view appears, not just the first.
        ///Whoever calls up this view has set the scale already
        .onAppear {
            scalesModel.setResultInternal(nil, "ScalesView.onAppear")
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
            if scalesModel.scale.scaleMotion == .contraryMotion && scalesModel.scale.hands.count == 2 {
                if let score = scalesModel.getScore() {
                    PianoKeyboardModel.sharedCombined = PianoKeyboardModel.sharedLH.joinKeyboard(score: score, fromKeyboard: PianoKeyboardModel.sharedRH, scale: scalesModel.scale, handType: .right)
                }
                if let combined = PianoKeyboardModel.sharedCombined {
                    let middleKeyIndex = combined.getKeyIndexForMidi(midi: scalesModel.scale.getScaleNoteState(handType: .right, index: 0).midi)
                    if let middleKeyIndex = middleKeyIndex {
                        combined.pianoKeyModel[middleKeyIndex].hilightKeyToFollow = .middleOfKeyboard
                    }
                }
            }
            else {
                PianoKeyboardModel.sharedCombined = nil
            }
            self.directionIndex = 0
            self.numberOfOctaves = scalesModel.scale.octaves
            if let tempoIndex = scalesModel.tempoSettings.firstIndex(where: { $0.contains("\(scalesModel.scale.minTempo)") }) {
                self.tempoIndex = tempoIndex
            }
            scalesModel.setShowStaff(true)
            exerciseState.setExerciseState(ctx: "ScalesView, onAppear", .exerciseNotStarted1)
            scalesModel.setRecordedAudioFile(nil)

            if UIDevice.current.userInterfaceIdiom == .phone {
                if scalesModel.scale.scaleMotion == .contraryMotion && scalesModel.scale.octaves > 1 {
                    OrientationManager.lockOrientation(.landscape, andRotateTo: .landscapeLeft)
                }
                else {
                    ///If need two keyboards (which take space) and two staves then lock portrait
//                    if PianoKeyboardModel.sharedCombined == nil {
//                        if scalesModel.scale.needsTwoKeyboards() {
//                            OrientationManager.lockOrientation(.portrait, andRotateTo: .portrait)
//                        }
//                    }
                    OrientationManager.lockOrientation(.portrait, andRotateTo: .portrait)
                }
            }
        }
        
        .onDisappear {
            metronome.stop()
            metronome.removeAllProcesses()
            scalesModel.setRunningProcess(.none)
            PianoKeyboardModel.sharedCombined = nil  ///DONT delete, required for the next view initialization
            OrientationManager.unlockOrientation()
            
            ///Clean up any recorded files
            if false {
                ///This deletes the practice chart AND shouldnt
                if Settings.shared.isDeveloperMode1()  {
                    let fileManager = FileManager.default
                    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                        do {
                            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                            for fileURL in fileURLs {
                                do {
                                    try fileManager.removeItem(at: fileURL)
                                    //Logger.shared.log("Removed file at \(fileURL)")
                                } catch {
                                    AppLogger.shared.reportError(fileManager, error.localizedDescription)
                                }
                            }
                        } catch {
                            AppLogger.shared.reportError(fileManager, error.localizedDescription)
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

