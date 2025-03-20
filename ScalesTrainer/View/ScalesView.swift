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

struct ScalesView: View {
    let practiceChart:PracticeChart?
    let practiceChartCell:PracticeChartCell?
    let practiceModeHand:HandType?
    @ObservedObject private var scalesModel = ScalesModel.shared
    @ObservedObject private var exerciseState = ExerciseState.shared

    let settings = Settings.shared
    let user = Settings.shared.getCurrentUser()
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
    @State var emailPopupSheet: ActiveSheet?
    @State var exerciseProcess:RunningProcess? = nil
    
    ///The slide up panel for badge info - which badge the student could win or did win
    //@State private var badgeMessagePanelOffset: CGFloat = 0
    //@State var badgeMessageImageRotationAngle:Double = 0

    ///Star view - the starts that are earned for each correct not
    //@State private var starViewAnimateCount:Int? = nil  //Counter that controls the animation of an exercise loss
    //@State private var starViewShakeAmount: CGFloat = 0

    ///Practice Chart badge control
    //@State var exerciseBadge:Badge?

    @State private var isLandscape: Bool = false
    @State private var spacingVertical:CGFloat = 0
    @State private var spacingHorizontal:CGFloat = 12
    
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
            Spacer()
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
            //.padding(.horizontal, 0)
            Spacer()
            
            Text(LocalizedStringResource("Viewing Direction"))
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
            
            Spacer()
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
                //if exerciseState.statePublished == .exerciseStarted {
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
                                        exerciseState.setExerciseState("ScalesView, user stopped", .exerciseAborted)
                                    }
                                }
                            }
                        }) {
                            Text("\(text)")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                //}
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
            
//            if [RunningProcess.recordingScaleForAssessment].contains(scalesModel.runningProcessPublished) {
//                Spacer()
//                VStack {
//                    //let name = scalesModel.scale.getScaleName(handFull: true, octaves: true, tempo: true, dynamic:true, articulation:true)
//                    let name = scalesModel.scale.getScaleIdentificationKey()
//                    Text("Recording \(name)").font(.title).padding()
//                    //ScaleStartView()
//                    RecordingIsUnderwayView()
//                    Button(action: {
//                        scalesModel.setRunningProcess(.none)
//                    }) {
//                        VStack {
//                            Text("Stop Recording Scale")//.padding().font(.title2).hilighted(backgroundColor: .blue)
//                        }
//                    }
//                    .buttonStyle(.borderedProminent)
////                    if coinBank.lastBet > 0 {
////                        CoinStackView(totalCoins: coinBank.lastBet, compactView: false).padding()
////                    }
//                }
//                //.commonFrameStyle()
//                Spacer()
//            }
            
            if scalesModel.recordingIsPlaying {
                Button(action: {
                    AudioManager.shared.stopPlayingRecordedFile()
                }) {
                    Text("Stop Hearing")//.padding().font(.title2).hilighted(backgroundColor: .blue)
                }
                .buttonStyle(.borderedProminent)
            }
            
//            if scalesModel.synchedIsPlaying {
//                Button(action: {
//                    scalesModel.setRunningProcess(.none)
//                }) {
//                    Text("Stop Hearing")//.padding().font(.title2).hilighted(backgroundColor: .blue)
//                }
//                .buttonStyle(.borderedProminent)
//            }
        }
    }
    
    func scaleIsAcousticCapable(scale:Scale) -> Bool {
        if user.settings.useMidiConnnections {
            return true
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
                            scalesModel.exerciseBadge = Badge.getRandomExerciseBadge()
                            self.exerciseProcess = RunningProcess.followingScale
                            self.exerciseState.setExerciseState("View follow start", settings.isDeveloperMode1() ? .exerciseStarted : .exerciseAboutToStart)
                            self.directionIndex = 0
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        //.buttonStyle(.bordered)
                        .appButtonStyle(trim: true, color: Color.orange)
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
                                scalesModel.exerciseBadge = Badge.getRandomExerciseBadge()
                                self.exerciseProcess = RunningProcess.leadingTheScale
                                self.exerciseState.setExerciseState("View lead start", settings.isDeveloperMode1() ? .exerciseAboutToStart : .exerciseAboutToStart)
                            }
                            self.directionIndex = 0
                        }) {
                            Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                        }
                        .appButtonStyle(trim: true, color: Color.orange)
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
                }
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Play\u{200B}Along" : "Play Along"
                    Button(action: {
                        scalesModel.setRunningProcess(.playingAlongWithScale)
                        self.directionIndex = 0
                    }) {
                        Text(title).font(UIDevice.current.userInterfaceIdiom == .phone ? .footnote : .body)
                    }
                    .appButtonStyle(trim: true)
                    
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
                    .appButtonStyle(trim: true)
                    
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
                        .appButtonStyle(trim: true)
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
                        .appButtonStyle(trim: true)
                        
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
        if scalesModel.scale.hands.count > 1 {
            return false
        }
        return canFit
    }
        
//    func getBadgeOffset(state:ExerciseState.State) -> (CGFloat, CGFloat) {
//        ///All offsets are relative to the last postion
//        if state == .exerciseNotStarted {
//            //return (0, UIScreen.main.bounds.height)
//            return (0, 300)
//        }
//
//        if state == .exerciseLost {
//            //return (0, UIScreen.main.bounds.height)
//            ///The image is rotated down so negative offset sends it down
//            return (0, UIScreen.main.bounds.height * -0.5)
//        }
////        if [.wonAndFinished].contains(state) {
////            //return (UIScreen.main.bounds.width * -0.5, UIScreen.main.bounds.height * -0.75)
////            return (UIScreen.main.bounds.width * -0.3, UIScreen.main.bounds.height * -0.75)
////        }
//        return (0,0) //Exercise started
//    }
    
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
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                if isLandscape {
//                    //HideAndShowView(compact: true)
//                }
//            }
//            else {
//                HideAndShowView(compact: false)
//            }
            Spacer()
        }
        .padding()

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
//                VStack(spacing: 0) {
//                    ScaleTitleView(scale: scalesModel.scale, practiceModeHand: practiceModeHand)
//                    //.border(Color.red)
//                }
                VStack {
                    HStack {
                        Spacer()
                        ScaleTitleView(scale: scalesModel.scale, practiceModeHand: practiceModeHand)
                            .outlinedStyleView(opacity: 0.3)
                        Spacer()
                        HeaderView()
                            .outlinedStyleView(opacity: 0.3)
//                            .padding(.top, spacingVertical)
//                            .padding(.bottom)
//                            .padding(.horizontal, spacingHorizontal)
                        //.padding()
                        Spacer()
                    }
                    .background(
                        LinearGradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    .outlinedStyleView(opacity: 0.3)
                    .padding(.horizontal, spacingHorizontal)

                    if scalesModel.showKeyboard {
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
                        //.outlinedStyleView(opacity: 0.3)
                        .padding(.top, spacingVertical)
                        .padding(.horizontal, spacingHorizontal)
                                                    
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            if ![.brokenChordMajor, .brokenChordMinor].contains(scalesModel.scale.scaleType) {
                                if scalesModel.showLegend {
                                    LegendView(hands: scalesModel.scale.hands, scale: scalesModel.scale)
                                        .padding(.top, 0)
                                        .padding(.horizontal)
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
                    
                    if [.leadingTheScale, .followingScale, .backingOn, .playingAlongWithScale, .recordingScale].contains(scalesModel.runningProcessPublished) ||
                                                                                      scalesModel.recordingIsPlaying {
                    //if scalesModel.runningProcessPublished != .none || scalesModel.recordingIsPlaying { //} || scalesModel.synchedIsPlaying {
                        StopProcessView(user:Settings.shared.getCurrentUser())
                    }
                    else {
                        SelectActionView()
                    }
                    
                    ///-------- Exercise stars mesages and displays ----------
                    
                    if user.settings.practiceChartGamificationOn {
                        if let exerciseBadge = scalesModel.exerciseBadge {
                            ///Show the horizontal row of badges
                            VStack {
                                if [ExerciseState.State.exerciseStarted, .exerciseLost].contains(exerciseState.statePublished) {
                                    ExerciseBadgesView(scale: scalesModel.scale,
                                                       exerciseName: scalesModel.runningProcessPublished == .followingScale ? "Follow" : "Lead",
                                                       onClose: {
                                        exerciseState.setExerciseState("ScalesView, stars closed", .exerciseNotStarted)
                                    })
                                        .outlinedStyleView()
                                        .padding()
                                    if exerciseState.showHelp {
                                        let height = UIScreen.main.bounds.height * 0.07
                                        PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: height * 0.9)
                                            .frame(width: UIScreen.main.bounds.width * 0.50, height: height)
                                            .outlinedStyleView()
                                        //.border(Color.red, width: 1)
                                            .padding()
                                    }
                                }
                            }
                        }
                    }
                    
                    if Settings.shared.isDeveloperMode1()  {
                        if user.settings.useMidiConnnections {
                            Spacer()
                            TestInputView()
                        }
                    }
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .screenBackgroundStyle()
            }

            if [.exerciseAboutToStart].contains(exerciseState.statePublished) {
                if let badge = scalesModel.exerciseBadge {
                    VStack {
                        StartExerciseView(badge: badge, scalesModel: self.scalesModel, callback: {cancelled in
                            if cancelled {
                                exerciseState.setExerciseState("Popup", .exerciseNotStarted)
                            }
                            else {
                                exerciseState.setExerciseState("Popup", .exerciseStarted)
                            }
                        })
                        .frame(width: UIScreen.main.bounds.width * 0.60, height: UIScreen.main.bounds.height * (UIDevice.current.userInterfaceIdiom == .phone ? 1.0 : 0.60))
                    }
                    .padding()
                }
            }
            if [.exerciseWon].contains(exerciseState.statePublished) {
                if let badge = scalesModel.exerciseBadge {
                    VStack {
                        EndOfExerciseView(badge: badge, scalesModel: self.scalesModel, exerciseMessage: self.exerciseState.exerciseMessage, callback: {retry in
                            exerciseState.setExerciseState("Popup", .exerciseNotStarted)
                        }, failed: false)
                        .frame(width: UIScreen.main.bounds.width * 0.40, height: UIScreen.main.bounds.height * 0.25)                    }
                    .padding()
                }
            }
            if [.exerciseLost].contains(exerciseState.statePublished) {
                if let badge = scalesModel.exerciseBadge {
                    VStack {
                        EndOfExerciseView(badge: badge, scalesModel: self.scalesModel, exerciseMessage: self.exerciseState.exerciseMessage, callback: {retry in
                            if retry {
                                exerciseState.setExerciseState("Popup", .exerciseAboutToStart)
                            }
                            else {
                                exerciseState.setExerciseState("Popup", .exerciseNotStarted)
                            }
                        }, failed: true)
                        .frame(width: UIScreen.main.bounds.width * 0.40, height: UIScreen.main.bounds.height * 0.25)                    }
                    .padding()
                }
            }
        }
        //.navigationBarHidden(true) // Hide the navigation bar
        .toolbar(.hidden, for: .tabBar) // Hide the TabView
        .edgesIgnoringSafeArea(.bottom)
        
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }
        .onChange(of: tempoIndex, {
            scalesModel.setTempo("ScalesView changeTempoIndex", self.tempoIndex)
        })
        .onChange(of: exerciseState.statePublished) { oldValue, newValue in
            ///Modify showBadgeMessagePanelOffset to bring the badge message off and on the display
            //let messageTime = 3.0
            //let fallTime = 2.0
            //let offScreenoffset = UIScreen.main.bounds.height / 4
            
            if [ExerciseState.State.exerciseAboutToStart].contains(exerciseState.statePublished) {
                if false && Settings.shared.isDeveloperMode1() {
                    exerciseState.setExerciseState("ScalesView, exercise started", .exerciseStarted)
                }
                else {
                    //showStartExercisePopup = true
                }
            }
            if [ExerciseState.State.exerciseNotStarted].contains(exerciseState.statePublished) {
                scalesModel.setRunningProcess(.none)
                scalesModel.exerciseBadge = Badge.getRandomExerciseBadge()
            }

            if [ExerciseState.State.exerciseStarted].contains(exerciseState.statePublished) {
                if let process = self.exerciseProcess {
                    scalesModel.setRunningProcess(process, practiceChart: practiceChart, practiceChartCell: practiceChartCell)
                }
            }
            
            if [ExerciseState.State.exerciseWon].contains(exerciseState.statePublished) {
                scalesModel.exerciseBadge = Badge.getRandomExerciseBadge()
//                DispatchQueue.main.asyncAfter(deadline: .now() + messageTime) {
//                    withAnimation(.easeInOut(duration: fallTime * 2.0)) {
//                        scalesModel.setRunningProcess(.none)
//                    }
//                }
            }
            if [ExerciseState.State.exerciseAborted].contains(exerciseState.statePublished) {
            }
        }
        
        ///Determine device orientation
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    isLandscape = geometry.size.width > geometry.size.height
                    setVerticalSpacing()
                }
                .onChange(of: geometry.size) { oldSize, newSize in
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
                    if let firstNote = scalesModel.scale.getScaleNoteState(handType: .right, index: 0) {
                        let middleKeyIndex = combined.getKeyIndexForMidi(midi: firstNote.midi)
                        if let middleKeyIndex = middleKeyIndex {
                            combined.pianoKeyModel[middleKeyIndex].hilightType = .middleOfKeyboard
                        }
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
            exerciseState.setExerciseState("ScalesView onAppear", .exerciseNotStarted)
            scalesModel.setRecordedAudioFile(nil)
            scalesModel.exerciseBadge = Badge.getRandomExerciseBadge()
            
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                if scalesModel.scale.scaleMotion == .contraryMotion && scalesModel.scale.octaves > 1 {
//                    OrientationManager.lockOrientation(.landscape, andRotateTo: .landscapeLeft)
//                }
//                else {
//                    OrientationManager.lockOrientation(.portrait, andRotateTo: .portrait)
//                }
//            }
        }
        
        .onDisappear {
            metronome.stop()
            metronome.removeAllProcesses()
            scalesModel.setRunningProcess(.none)
            PianoKeyboardModel.sharedCombined = nil  ///DONT delete, required for the next view initialization
            //OrientationManager.unlockOrientation()
            
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

        .sheet(item: $emailPopupSheet) { item in
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

