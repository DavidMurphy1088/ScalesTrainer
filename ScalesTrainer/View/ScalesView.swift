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
    @Environment(\.dismiss) var dismiss
    let user:User
    let scale:Scale
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.defaultMinListRowHeight) var systemSpacing

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
    @State var emailPopupSheet: ActiveSheet?
    @State var exerciseProcess:RunningProcess? = nil
    @State private var spacingHorizontal:CGFloat = 12
    
    let spacingVertical:CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? UIScreen.main.bounds.size.height * 0.02 : UIScreen.main.bounds.size.height * 0.02
    //let spacingVertical:CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4 : 4
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    init(user:User, scale:Scale) {//}, handType:HandType) {
        self.user = user
        self.scale = scale
    }
    
//    func SelectScaleParametersView() -> some View {
//        HStack {
//            if false {
//                Spacer()
//                MetronomeView()
//                //.padding()
//                Spacer()
//                HStack(spacing: 0) {
//                    let compoundTime = self.scale.timeSignature.top % 3 == 0
//                    Image(compoundTime ? "crotchetDotted" : "crotchet")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: UIScreen.main.bounds.size.width * (compoundTime ? 0.02 : 0.015))
//                    ///Center it
//                    //.padding(.bottom, 8)
//                    //.padding(.horizontal, 0)
//                    Text(" =").padding(.horizontal, 0)
//                        .padding(.horizontal, 0)
//                }
//                Picker(String(scalesModel.tempoChangePublished), selection: $tempoIndex) {
//                    ForEach(scalesModel.tempoSettings.indices, id: \.self) { index in
//                        Text("\(scalesModel.tempoSettings[index])").padding(.horizontal, 0)
//                    }
//                }
//                .pickerStyle(.menu)
//                
//                .onChange(of: tempoIndex, {
//                    scalesModel.setTempo("ScalesView changeTempoIndex", self.tempoIndex)
//                })
//            }
//
//            if true {
//                Spacer()
//                Text(LocalizedStringResource("Viewing Direction"))
//                Picker("Select Value", selection: $directionIndex) {
//                    ForEach(scalesModel.directionTypes.indices, id: \.self) { index in
//                        if scalesModel.selectedScaleSegment >= 0 {
//                            Text("\(scalesModel.directionTypes[index])")
//                        }
//                    }
//                }
//                .pickerStyle(.menu)
//                .onChange(of: directionIndex, {
//                    scalesModel.setSelectedScaleSegment(self.directionIndex)
//                })
//            }
//            
//            Spacer()
//            GeometryReader { geo in
//                HStack {
//                    Button(action: {
//                        self.directionIndex = self.directionIndex == 0 ? 1 : 0
//                        scalesModel.setSelectedScaleSegment(self.directionIndex)
//                    }) {
//                        Image("arrow_up")
//                            .renderingMode(.template)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height: geo.size.height * 1.0)
//                            //.foregroundColor(self.directionIndex == 0 ? AppOrange : Color.black)
//                            .foregroundColor(scalesModel.directionOfPlay == ScalesModel.DirectionOfPlay.upwards ? AppOrange : Color.black)
//                    }
//                    Button(action: {
//                        self.directionIndex = self.directionIndex == 0 ? 1 : 0
//                        scalesModel.setSelectedScaleSegment(self.directionIndex)
//                    }) {
//                        Image("arrow_down")
//                            .renderingMode(.template)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height: geo.size.height * 1.0)
//                            //.foregroundColor(self.directionIndex == 1 ? AppOrange : Color.black)
//                            .foregroundColor(scalesModel.directionOfPlay == ScalesModel.DirectionOfPlay.downwards ? AppOrange : Color.black)
//
//                    }
//                }
//            }
//            Spacer()
//        }
//    }
    
    func getStopButtonText(process: RunningProcess) -> String {
        let text:String
//        if metronome.isLeadingIn {
//            ///2 ticks per beat
//            text = "  Leading In  " //\((metronome.timerTickerCountPublished / 2) + 1)"
//        }
//        else {
            switch process {
            case.leadingTheScale:
                text = "Stop Leading"
            case.backingOn:
                text = "Stop Backing Harmony"
            case.followingScale :
                text = "Stop Following"
            case.playingAlong :
                text = "Stop Play Along"
            default:
                text = ""
            }
        //}
        return text
    }
    
    func StopProcessView(user:User) -> some View {
        VStack(spacing:0) {
            if [.playingAlong, .followingScale, .leadingTheScale, .backingOn]
                .contains(scalesModel.runningProcessPublished) {
                HStack {
                    let title = getStopButtonText(process: scalesModel.runningProcessPublished)
//                        Button(action: {
//                            scalesModel.setRunningProcess(.none)
//                            if [ .followingScale, .leadingTheScale].contains(scalesModel.runningProcessPublished) {
//                                if user.settings.practiceChartGamificationOn {
//                                    ///Stopped by user before exercise process stopped it
//                                    if exerciseState.statePublished == .exerciseWon  {
//                                        //exerciseState.setExerciseState(ctx: "ScalesView, StopProcessView() WON", .wonAndFinished)
//                                    }
//                                    else {
//                                        exerciseState.setExerciseState("ScalesView, user stopped", .exerciseAborted)
//                                    }
//                                }
//                            }
//                        }) {
//                            Text("\(title)")
//                        }
//                        .buttonStyle(.borderedProminent)
                    FigmaButton(title,
                    action: {
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
                    })
                }
            }

            if [.recordingScale].contains(scalesModel.runningProcessPublished) {
                HStack {
                    FigmaButton("Stop Recording",
                        action: {
                            metronome.stop("end record")
                            exerciseState.setExerciseState("end record", .exerciseNotStarted)
                            scalesModel.setRunningProcess(.none)
                        })
                }
            }
            
            if scalesModel.recordingIsPlaying {
//                Button(action: {
//                    AudioManager.shared.stopPlayingRecordedFile()
//                }) {
//                    Text("Stop Hearing")//.padding().font(.title2).hilighted(backgroundColor: .blue)
//                }
//                .buttonStyle(.borderedProminent)
                FigmaButton("Stop Hearing",
                    action: {
                        AudioManager.shared.stopPlayingRecordedFile()
                    })
            }

        }
    }
    
    func scaleIsAcousticCapable(scale:Scale) -> Bool {
        if user.settings.useMidiSources {
            return true
        }
        return scale.hands.count == 1
    }

    func SelectActionView() -> some View {
        VStack(spacing:0) {
            HStack(alignment: .top) {
                if self.scaleIsAcousticCapable(scale: self.scale) {
                    Spacer()
                    HStack()  {
                        FigmaButton("Follow",
                        action: {
                            metronome.stop("ScalesView follow")
                            scalesModel.exerciseBadge = ExerciseBadge.getRandomExerciseBadge()
                            self.exerciseProcess = RunningProcess.followingScale
                            self.exerciseState.setExerciseState("Follow", settings.isDeveloperModeOn() ?
                                                                ExerciseState.State.exerciseStarted : ExerciseState.State.exerciseAboutToStart)
                            self.directionIndex = 0
                        })
                    }
                    //.padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
                }
                
                if self.scaleIsAcousticCapable(scale: self.scale) {
                    Spacer()
                    HStack() {
                        FigmaButton("Lead",
                        action: {
                            metronome.stop("ScalesView Lead")
                            if scalesModel.runningProcessPublished == .leadingTheScale {
                                scalesModel.setRunningProcess(.none)
                            }
                            else {
                                //scalesModel.exerciseBadge = ExerciseBadge.getRandomExerciseBadge()
                                self.exerciseProcess = RunningProcess.leadingTheScale
                                self.exerciseState.setExerciseState("Lead the Scale", settings.isDeveloperModeOn() ?
                                                                    ExerciseState.State.exerciseStarted : ExerciseState.State.exerciseAboutToStart)
                            }
                            self.directionIndex = 0
                        })

                    }
                    //.padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                }
                
                Spacer()
                HStack {
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Play\u{200B}Along" : "Play Along"
                    FigmaButton(title,
                    action: {
                        self.exerciseState.setExerciseState("PlayAlong", ExerciseState.State.exerciseAboutToStart)
                        self.exerciseProcess = RunningProcess.playingAlong
                    })
                }
                
                if self.scale.getBackingChords() != nil {
                    Spacer()
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Backing" : "Backing Track"
                        FigmaButton(title,
                        action: {
                            self.exerciseState.setExerciseState("Backing", ExerciseState.State.exerciseAboutToStart)
                            self.exerciseProcess = RunningProcess.backingOn
                        })
                    }
                }
                
                Spacer()
                HStack {
//                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Record" : "Record"
//                    FigmaButton(title,
//                    action: {
//                        if scalesModel.runningProcessPublished == .recordingScale {
//                            scalesModel.setRunningProcess(.none)
//                        }
//                        else {
//                            exerciseState.setExerciseState("Record", .exerciseWithoutBadgesAboutToStart)
//                            scalesModel.setRunningProcess(.recordingScale)
//                        }
//                    })
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Backing" : "Backing Track"
                        FigmaButton("Record",
                        action: {
                            self.exerciseState.setExerciseState("Record", ExerciseState.State.exerciseAboutToStart)
                            self.exerciseProcess = RunningProcess.recordingScale
                        })
                    }
                }

                if scalesModel.recordedAudioFile != nil {
                    Spacer()
                    HStack {
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Hear" : "Hear Recording"
                        FigmaButton(title,
                        action: {
                            AudioManager.shared.playRecordedFile()
                        })
                    }
                    //.padding(.vertical, UIDevice.current.userInterfaceIdiom == .phone ? 0 : 6)
                    //.padding(.horizontal, 0)
                }
                Spacer()
            }
        }
    }
//    struct ComponentSizes {
//        var headerHeight = 0.0
//        var keyboardHeight = 0.0
//        var scoreHeight = 0.0
//    }
    
    public enum ComponentSizeType {
        case header
        case keyboard
        case score
    }
    
    func getComponentSizes(_ callType:ComponentSizeType, keyboardCount:Int? = nil, showingStaff:Bool? = nil) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.size.height
        
        /// ----------- Header -------------
        let scale = compact ? 0.08 : 0.04
        let headerHeight = screenHeight * scale

        /// ----------- Keyboard -------------
        if callType == ComponentSizeType.keyboard {
        }
        var keyboardHeight = 0.0
        //0.5 //0.33 🔴 DONT TOUCH ANY OF THIS LIGHTLY
        //Score height is calculated with whats left after the header and keyboard heights are specified
        var keyboardHeightScale:Double = 0.40
            if let showingStaff = showingStaff {
                if !showingStaff {
                    keyboardHeightScale = 0.60
                }
            }
            if self.scale.scaleMotion == ScaleMotion.contraryMotion {
                if self.scale.hands.count > 1 {
                    ///Too many keys get too thin
                    keyboardHeightScale = 0.40
                }
            }

        if self.scale.octaves > 1 {
            ///Keys are narrower so make height less to keep proportion ratio
            //keyboardHeightScale = keyboardHeightScale * 0.5
        }
        keyboardHeight = UIScreen.main.bounds.size.height * keyboardHeightScale
        
        /// ----------- Score -------------
        let scoreHeight = (screenHeight * 0.6) - headerHeight - keyboardHeight
        
        if callType == ComponentSizeType.header {
            return headerHeight
        }
        if callType == ComponentSizeType.keyboard {
            return keyboardHeight
        }
        if callType == ComponentSizeType.score {
            return scoreHeight
        }
        return 0.0
    }
    
    func getMailInfo() -> String {
        let mailInfo:String = scalesModel.recordedTapsFileName ?? "No file name"
//        let currentDate = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMMM-dd-HH:mm"
//        let dateString = dateFormatter.string(from: currentDate)
        return mailInfo
    }
    
    func scoreCanFit() -> Bool {
        var canFit = true
        ///01Feb2025 - decided chromatic cant display well on any device or orientation
        //if UIDevice.current.userInterfaceIdiom == .phone {
            if self.scale.scaleType == .chromatic &&
                //self.scale.scaleMotion == .contraryMotion &&
                self.scale.octaves > 1 {
                canFit = false
            }
        //}
        if self.scale.hands.count > 1 {
            return false
        }
        return canFit
    }
            
    func HeaderView(height: Double) -> some View {
        HStack {
            let screenWidth = UIScreen.main.bounds.size.width
            MetronomeView(width: screenWidth * 0.66, height: height)
                //.frame(width: .infinity, height:
                .padding(sizeClass == .regular ? systemSpacing : 2)
                .figmaRoundedBackgroundWithBorder(fillColor: Color.white)
            
            HStack {
                Button(action: {
                    self.directionIndex = self.directionIndex == 0 ? 1 : 0
                    scalesModel.setSelectedScaleSegment(self.directionIndex)
                }) {
                    Image("arrow_up")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: height)
                        .foregroundColor(scalesModel.directionOfPlay == ScalesModel.DirectionOfPlay.upwards ? Color.green : Color.black)
                }
                Button(action: {
                    self.directionIndex = self.directionIndex == 0 ? 1 : 0
                    scalesModel.setSelectedScaleSegment(self.directionIndex)
                }) {
                    Image("arrow_down")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: height)
                        .foregroundColor(scalesModel.directionOfPlay == ScalesModel.DirectionOfPlay.downwards ? Color.green : Color.black)
                }
            }
            .padding(sizeClass == .regular ? systemSpacing : 2)
            .figmaRoundedBackgroundWithBorder(fillColor: Color.white)
        }
    }

    var body: some View {
        ZStack {
            VStack() {
                VStack() {
                    let headerHeight = getComponentSizes(.header)
                    HeaderView(height: headerHeight)
                        .frame(width: .infinity, height: headerHeight)
                        .padding(.horizontal, spacingHorizontal)
                        .padding(.top, spacingVertical)
                        .padding(.bottom, spacingVertical)
                        //.border(.red)
                    
                    if scalesModel.showKeyboard {
                        VStack(spacing:0) {
                            if let joinedKeyboard = PianoKeyboardModel.sharedCombined {
                                ///Scale is contrary with LH and RH joined on one keyboard
                                PianoKeyboardView(scalesModel: scalesModel, viewModel: joinedKeyboard, keyColor: user.settings.getKeyboardColor())
                            }
                            else {
                                if self.scale.needsTwoKeyboards() {
                                    PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedRH,
                                                      keyColor: user.settings.getKeyboardColor())
                                    .padding(.bottom, spacingVertical)
                                    PianoKeyboardView(scalesModel: scalesModel, viewModel: PianoKeyboardModel.sharedLH,
                                                      keyColor: user.settings.getKeyboardColor())
                                }
                                else {
                                    let keyboard = self.scale.hands[0] == 1 ? PianoKeyboardModel.sharedLH : PianoKeyboardModel.sharedRH
                                    PianoKeyboardView(scalesModel: scalesModel, viewModel: keyboard,
                                                      keyColor: user.settings.getKeyboardColor())
                                }
                            }
                        }
                        .frame(height: getComponentSizes(.keyboard, keyboardCount: self.scale.hands.count, showingStaff: scoreCanFit()))
                        //.border(.green)
                        .padding(.bottom, spacingVertical)
                        .padding(.horizontal, spacingHorizontal)
                    }
                    
                    if scoreCanFit() {
                        if let score = scalesModel.getScore() {
                            if scalesModel.showStaff {
                                let height = getComponentSizes(.score)
                                ScoreView(scale: self.scale, score: score, showResults: false, height: height)
                                    .frame(height: height)
//                                    VStack {
//                                        Text("TestScore")
//                                    }
                                    //.border(.red)
                                .padding(.bottom, spacingVertical)
                                .padding(.horizontal, spacingHorizontal)
                            }
                        }
                    }
                    
                    if [.playingAlong, .backingOn, .recordingScale].contains(scalesModel.runningProcessPublished) || scalesModel.recordingIsPlaying {
                        if [.recordingScale].contains(scalesModel.runningProcessPublished) {
                            StopProcessView(user:user)
                        }
                    }
                    else {
                        if [.exerciseStarted, .exerciseLost].contains(exerciseState.statePublished) {
                            if scalesModel.runningProcessPublished != .none {
                                ZStack {
                                    VStack(spacing:0) {
                                        if [ExerciseState.State.exerciseStarted, .exerciseLost].contains(exerciseState.statePublished) {
                                            ExerciseDropDownStarsView(user: user, scale: self.scale,
                                                                      exerciseName: scalesModel.runningProcessPublished == .followingScale ? "Follow" : "Lead",
                                                                      onClose: {
                                                exerciseState.setExerciseState("ScalesView, stars closed", .exerciseNotStarted)
                                            })
                                            .figmaRoundedBackgroundWithBorder(fillColor: Color.white)
                                            //.padding(.bottom, self.spacingVertical)
                                        }
                                        Text("")
                                    }
                                    if [.exerciseLost].contains(exerciseState.statePublished) {
                                        HStack {
                                            if let message = self.exerciseState.exerciseMessage {
                                                Text(message).padding().foregroundColor(.red)
                                            }
                                            FigmaButton("Back", action: {
                                                self.exerciseState.setExerciseState("Lost Exercise", .exerciseNotStarted)
                                            })
                                            .padding()
                                        }
                                        .figmaRoundedBackgroundWithBorder()
                                    }
                                }
                            }
                        }
                        else {
                            SelectActionView()
                        }
                    }
                                        
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            }

            ///-------- Exercise state displays ----------

            if [.exerciseAboutToStart].contains(exerciseState.statePublished) {
                if let process = self.exerciseProcess {
                    if [RunningProcess.playingAlong, .backingOn, .recordingScale].contains(self.exerciseProcess) {
                        StartExerciseView(scalesModel: self.scalesModel, process: process, activityName: exerciseState.activityName, parentCallback: {cancelled in
                            if cancelled {
                                exerciseState.setExerciseState("Excerice cancel", .exerciseNotStarted)
                            }
                            else {
                                exerciseState.setExerciseState("Start view closed", .exerciseStarted)
                            }
                        },
                        endExerciseCallback: {
                            metronome.stop("Hear scale end of exercise")
                            scalesModel.setRunningProcess(.none)
                            exerciseState.setExerciseState("End exercise", .exerciseNotStarted)
                        })
                        .padding()
                    }
                    else {
                        VStack(spacing:0) {
                            StartFollowLeadView(scalesModel: self.scalesModel, activityName: exerciseState.activityName, callback: {cancelled in
                                if cancelled {
                                    exerciseState.setExerciseState("Excerice cancel", .exerciseNotStarted)
                                }
                                else {
                                    exerciseState.setExerciseState("Start view closed", .exerciseStarted)
                                }
                            })
                            .padding()
                        }
                    }
                }
            }

            if [.exerciseWon].contains(exerciseState.statePublished) {
                ConfettiView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            if Settings.shared.isDeveloperModeOn()  {
                if user.settings.useMidiSources {
                    HStack {
                        TestInputView()
                        Spacer()
                    }
                }
            }
        }
        .commonToolbar(
            title: self.scale.getScaleDescriptionParts(name:true),
            titleMustShow: true,
            helpMsg: self.scale.getDescriptionTabbed(),
            onBack: { dismiss() }
        )
        .toolbar(.hidden, for: .tabBar) // Hide the TabView
        .edgesIgnoringSafeArea(.bottom)
        
        .sheet(isPresented: $helpShowing) {
            if let topic = scalesModel.helpTopic {
                HelpView(topic: topic)
            }
        }
        .onChange(of: exerciseState.statePublished) { oldValue, newValue in
            ///Modify showBadgeMessagePanelOffset to bring the badge message off and on the display
            //let messageTime = 3.0
            //let fallTime = 2.0
            //let offScreenoffset = UIScreen.main.bounds.height / 4
            
            if [ExerciseState.State.exerciseAboutToStart].contains(exerciseState.statePublished) {
                if false && Settings.shared.isDeveloperModeOn() {
                    exerciseState.setExerciseState("ScalesView, exercise started", .exerciseStarted)
                }
                else {
                    //showStartExercisePopup = true
                }
            }
            if [ExerciseState.State.exerciseNotStarted].contains(exerciseState.statePublished) {
                scalesModel.setRunningProcess(.none)
                scalesModel.exerciseBadge = ExerciseBadge.getRandomExerciseBadge()
            }

            if [ExerciseState.State.exerciseStarted].contains(exerciseState.statePublished) {
                if let process = self.exerciseProcess {
                    scalesModel.setRunningProcess(process)
                }
            }
            
            if [ExerciseState.State.exerciseAborted].contains(exerciseState.statePublished) {
            }
        }
                
        ///Every time the view appears, not just the first.
        ///Whoever calls up this view has set the scale already
        .onAppear {
//            var hands:[Int]
//            switch handType {
//            case .both:
//                 hands = [0,1]
//            case .left:
//                hands = [1]
//            case .right:
//                hands = [0]
//            }
            let _ = ScalesModel.shared.setScaleByRootAndType(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType,
                                                             scaleMotion: scale.scaleMotion,
                                                             minTempo: scale.minTempo, octaves: scale.octaves,
                                                             hands: scale.hands,
                                                             dynamicTypes: scale.dynamicTypes,
                                                             articulationTypes: scale.articulationTypes,
                                                             ctx: "PracticeChartHands",
                                                             scaleCustomisation:scale.scaleCustomisation)
            PianoKeyboardModel.sharedRH.resetKeysWerePlayedState()
            PianoKeyboardModel.sharedLH.resetKeysWerePlayedState()
            if self.scale.scaleMotion == .contraryMotion && self.scale.hands.count == 2 {
                if let score = scalesModel.getScore() {
                    PianoKeyboardModel.sharedCombined = PianoKeyboardModel.sharedLH.joinKeyboard(score: score, fromKeyboard: PianoKeyboardModel.sharedRH, scale: self.scale, handType: .right)
                }
                if let combined = PianoKeyboardModel.sharedCombined {
                    if let firstNote = self.scale.getScaleNoteState(handType: .right, index: 0) {
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
            self.numberOfOctaves = self.scale.octaves
            scalesModel.setTempos(scale: self.scale)

            if let tempoIndex = scalesModel.tempoSettings.firstIndex(of: self.scale.minTempo) {
                self.tempoIndex = tempoIndex
            }
            scalesModel.setShowStaff(true)
            exerciseState.setExerciseState("ScalesView onAppear", .exerciseNotStarted)
            scalesModel.setRecordedAudioFile(nil)
            scalesModel.exerciseBadge = ExerciseBadge.getRandomExerciseBadge()
            //metronome.start(doStandby: false, doLeadIn: false, scale: self.scale)
        }
        
        .onDisappear {
            metronome.stop("ScalesView .Disappear")
            metronome.removeAllProcesses("ScalesView .Disappear")
            scalesModel.setRunningProcess(.none)
            PianoKeyboardModel.sharedCombined = nil  ///DONT delete, required for the next view initialization
            //OrientationManager.unlockOrientation()
            
            ///Clean up any recorded files
            if false {
                ///This deletes the practice chart AND shouldnt
                if Settings.shared.isDeveloperModeOn()  {
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
