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
    @EnvironmentObject var orientationInfo: OrientationInfo
    //let initialRunProcess:RunningProcess?
    let practiceChartCell:PracticeChartCell?
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
    
    ///Practice Chart badge control
    @State var exerciseBadge:Badge?
    
    init(practiceChartCell:PracticeChartCell?) {
        //self.initialRunProcess = initialRunProcess
        self.practiceChartCell = practiceChartCell
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
                                ///Stopped by user before exercise process stopped it
                                if exerciseState.statePublished == .won  {
                                    exerciseState.setExerciseState(ctx: "ScalesView, StopProcessView() WON", .wonAndFinished)
                                }
                                else {
                                    exerciseState.setExerciseState(ctx: "ScalesView, StopProcessView() LOST", .lost)
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
        if Settings.shared.useMidiConnnections {
            return true
        }
        else {
            return scale.hands.count == 1
        }
    }
    
    func SelectActionView() -> some View {
        VStack {

            HStack(alignment: .top) {
                Spacer()
                if self.scaleIsAcousticCapable(scale: self.scalesModel.scale) {
                    HStack()  {
                        let title = NSLocalizedString(UIDevice.current.userInterfaceIdiom == .phone ? "Follow" : "Follow", comment: "ProcessMenu")
                        Button(action: {
                            scalesModel.setRunningProcess(.followingScale, practiceChartCell: practiceChartCell)
                            scalesModel.setProcessInstructions("Play the next scale note as shown by the hilighted key")
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
                                //exerciseState.setExerciseState("start", .exerciseNotStarted)
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                self.exerciseBadge = scalesModel.exerciseBadge
                                scalesModel.setRunningProcess(.leadingTheScale, practiceChartCell: self.practiceChartCell)
                                scalesModel.setProcessInstructions("Play the notes of the scale. Watch for any wrong notes.")
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
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Play\u{200B}Along" : "Play Along"
                    Button(action: {
                        scalesModel.setRunningProcess(.playingAlongWithScale)
                        scalesModel.setProcessInstructions("Play along with the scale as its played")
                    }) {
                        Text(title)
                    }
                    .buttonStyle(.bordered)
                    
                    if UIDevice.current.userInterfaceIdiom != .phone {
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
                .padding(.vertical)
                .padding(.horizontal, 0)
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Rec\u{200B}ord" : "Record"
                    Button(action: {
                        if scalesModel.runningProcessPublished == .recordingScale {
                            scalesModel.setRunningProcess(.none)
                        }
                        else {
                            scalesModel.setRunningProcess(.recordingScale)
                        }
                        
                    }) {
                        Text(title)
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
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Back\u{200B}ing" : "Backing Track" 
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
    
    func getExerciseStatusMessage(badge:Badge) -> String {
        let remaining = exerciseState.pointsNeededToWin()
        var msg = ""
        let name = badge.name
        
        switch exerciseState.statePublished {
        case .won:
            msg = "😊 You Won Me 😊"
        case .wonAndFinished:
            ///msg = "😊 You Won \(name) 😊"
            msg = "😊 You Won 😊"
        case .exerciseStarted:
            if remaining == 1 {
                msg = "Win me with one more correct note"
            }
            else {
                msg = exerciseState.totalCorrectPublished == 0 ?    "Hi - I'm \(name)✋\nWin me with just \(remaining) correct notes" :
                                                                    "Win me with \(remaining) more correct notes"
            }
        default:
            msg = ""
        }
        return (msg)
    }
    
    func staffCanFit() -> Bool {
        var canFit = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            if scalesModel.scale.scaleType == .chromatic && 
                //scalesModel.scale.scaleMotion == .contraryMotion &&
                scalesModel.scale.octaves > 1 {
                canFit = false
            }
        }
        return canFit
    }
        
    func getBadgeOffset(state:ExerciseState.State) -> (CGFloat, CGFloat) {
        ///All offsets are relative to the last postion
        if state == .exerciseNotStarted {
            //return (0, UIScreen.main.bounds.height)
            return (0, 300)
        }
//        if state == .exerciseStarted {
//            //return (0, UIScreen.main.bounds.height)
//            return (0, 0)
//        }
        if state == .lost {
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
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ScaleTitleView(scale: scalesModel.scale)
                    .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
                    .padding(.horizontal, 0)
                HStack {
                    Spacer()
                    //if scalesModel.runningProcessPublished == .none {
                        SelectScaleParametersView()
                        .padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
                    //}
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        HideAndShowView()
                        .padding(.vertical, 0) ///Keep it trim, esp. in Landscape to save vertical space
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
                    if let score = scalesModel.getScore() {
                        VStack {
                            ScoreView(scale: ScalesModel.shared.scale, score: score, barLayoutPositions: score.barLayoutPositions, widthPadding: false)
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
            
            if [.exerciseStarted, .won].contains(exerciseState.statePublished) {
                BadgesView(scale: scalesModel.scale).commonFrameStyle(backgroundColor: Color.white)
            }
            
            if Settings.shared.practiceChartGamificationOn {
                HStack {
                    if let exerciseBadge = scalesModel.exerciseBadge {
                        //if true || [ExerciseState.State.wonAndFinished, ExerciseState.State.exerciseStarted].contains(exerciseState.statePublished) {
                            let msg = getExerciseStatusMessage(badge: exerciseBadge)
                            Text(msg)
                                .padding()
                                .foregroundColor(.blue)
                                .font(exerciseState.statePublished == .won ? .title : .title2)
                                .opacity(exerciseState.statePublished == .wonAndFinished ? 1 : 0)
                                .zIndex(1) // Keeps it above other views
                            
                            ///Practice chart badge position is based on exercise state
                            ///State goes to won (when enough points) and then .wonAndFinished at end of exercise or user does "stop"
                            
                            Image(exerciseBadge.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: UIScreen.main.bounds.height * 0.05)
                            
                                .offset(x: getBadgeOffset(state: exerciseState.statePublished).0, y:getBadgeOffset(state: exerciseState.statePublished).1)
                                ///Can't use .rotation3DEffect since a subsequent offset move behaves unexpectedly
                                //                        .rotation3DEffect( //3D flip around its vertical axis
                                //                            Angle(degrees: [.won].contains(exerciseState.state) ? 360 : 0),
                                //                            axis: (x: 0.0, y: 1.0, z: 0.0)
                                //                        )
                                .animation(.easeInOut(duration: 2), value: exerciseState.statePublished)
                                .rotationEffect(Angle(degrees: exerciseState.statePublished == .lost ? 180 : 0))
                                //.opacity(exerciseState.statePublished == .exerciseNotStarted ? 0.0 : 1.0)
                                .opacity(exerciseState.statePublished == .wonAndFinished ? 1 : 0)

                        //}
                    }
                }
            }
            if Settings.shared.isDeveloperMode()  {
                if Settings.shared.useMidiConnnections {
                    Spacer()
                    TestInputView()
                }
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
            //if let process = initialRunProcess {
            //scalesModel.setRunningProcess(process, practiceChartCell: self.practiceChartCell)
            //}
            self.numberOfOctaves = scalesModel.scale.octaves
            if let tempoIndex = scalesModel.tempoSettings.firstIndex(where: { $0.contains("\(scalesModel.scale.minTempo)") }) {
                self.tempoIndex = tempoIndex
            }
            scalesModel.setShowStaff(true)
            exerciseState.setExerciseState(ctx: "ScalesView, onAppear", .exerciseNotStarted)
            scalesModel.setRecordedAudioFile(nil)
            //if scalesModel.scale.debugOn {
            //scalesModel.scale.debug1("In View1", short: false)
            //}
            if let score = scalesModel.getScore() {
                //score.debug2(ctx: "ScalesView.onAppear", handType: nil)
            }
        }
        
        .onDisappear {
            metronome.stop()
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

