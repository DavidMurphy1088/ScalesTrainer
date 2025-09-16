import SwiftUI

struct HandsView: View {
    let scale:Scale
    let imageSize = UIScreen.main.bounds.size.width * 0.03
    var body: some View {
        VStack(spacing: 0)  {
            HStack {
                if scale.hands.count > 1 || scale.hands[0] == 1 {
                    Image("figma_hand_left")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height:imageSize)
                        .foregroundColor(.black)
                }
                if scale.hands.count > 1 || scale.hands[0] == 0 {
                    Image("figma_hand_right")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height:imageSize)
                        .foregroundColor(.black)
                }
            }
        }
    }
}

//struct StartCountdownView: View {
//    @ObservedObject private var metronome = Metronome.shared
//    let scale:Scale
//    let activityName:String
//    let callback: (_ : ExerciseState.State) -> Void
//    
//    func stayAlive(countdown:Int) -> Bool {
//        if metronome.statusPublished == MetronomeStatus.running {
//            callback(ExerciseState.State.exerciseStarted)
//            return false
//        }
//        return true
//    }
//
//    var body: some View {
//        VStack {
//            let scaleName = scale.getScaleName(handFull: true)
//            GeometryReader { geo in
//                VStack(spacing:0) {
//                    Text("Starting \(activityName)").font(.title).foregroundColor(.black)
//                    Text("\(scaleName)").font(.title2).foregroundColor(.black)
//                    if metronome.statusPublished == .standby {
//                        Text("Hands ready?").font(.title2).bold()
//                    }
//                    else {
//                        if let countdown = metronome.leadInCountdownPublished {
//                            if stayAlive(countdown: countdown)  {
//                                VStack {
//                                    if countdown > 0 {
//                                        let message = "Starting in \(countdown)"
//                                        Text(message)
//                                            .font(.title2).bold()
//                                            .foregroundColor(countdown == 1 ? AppOrange : Color(.black))
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    PianoStartNoteIllustrationView(scalesModel: ScalesModel.shared, keyHeight: geo.size.height * 0.20)
//                            .frame(width: geo.size.width * 0.99, height: geo.size.height * 0.4)
//                    HandsView(scale: scale)
//
//                    Button("Back") {
//                        callback(.exerciseAborted)
//                    }
//                    Spacer()
//                }
//            }
//        }
//        .onAppear() {
//        }
//        .frame(width: UIScreen.main.bounds.width * 0.60, height: UIScreen.main.bounds.height * (UIDevice.current.userInterfaceIdiom == .phone ? 0.70 : 0.60))
//        .background(Color.white.opacity(1.0))
//        .cornerRadius(30)
//        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 3))
//        .shadow(radius: 10)
//    }
//}

/// ------------------ With badges exercises -----------------

//struct EndOfExerciseView: View {
//    let badge: ExerciseBadge
//    let scalesModel:ScalesModel
//    let exerciseMessage:String?
//    let callback: (_ retry:Bool, _ showResult:Bool) -> Void
//    let failed:Bool
//    
//    @State private var countdown = 0
//    @State private var isCountingDown = false
//    
//    var body: some View {
//        VStack {
//            if failed {
//                VStack {
//                    if let msg = exerciseMessage {
//                        VStack(spacing : 0) {
//                            Text("Sorry - \(msg)").font(.title2)
//                            Text("Try again?").font(.title2)
//                        }
//                        .padding()
//                    }
//                    HStack {
//                        FigmaButton("Back", action : {
//                            callback(false, false)
//                        })
//                        FigmaButton("Retry", action : {
//                            callback(true, false)
//                        })
//                    }
//                }
//            }
//            else {
//                //Text("😊 You  Won \(badge.name)").font(.largeTitle)
//                Text("😊 Nice Job").font(.largeTitle)
//                    .padding()
//                //            Text(badge.name).font(.largeTitle)
//                //                .padding()
////                Image(badge.imageName)
////                    .resizable()
////                    .scaledToFit()
////                    .frame(width: 120, height: 120)
////                    .padding()
//                
//                HStack {
//                    FigmaButton("Ok", action : {
//                        callback(false, false)
//                    })
//                    
//                    if Settings.shared.isDeveloperModeOn() {
//                        Button("Results") {
//                            callback(false, true)
//                        }
//                        .font(.title)
//                        .disabled(isCountingDown)
//                        .padding()
//                    
//                        FigmaButton("Results", action : {
//                            callback(false, true)
//                        })
//                    }
//                }
//            }
//        }
//        .foregroundColor(.black)
//        .padding()
//        .figmaRoundedBackgroundWithBorder()
//    }
//}

struct PianoStartNoteIllustrationView: View {
    let scalesModel:ScalesModel
    let keyHeight:Double
    @State private var flash = false
    let keyboardModel = PianoKeyboardModel(name: "PianoStartNoteIllustrationView", keyboardNumber: 1)
    
    var body: some View {
        VStack(spacing:0) {
            PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: keyboardModel, keyColor: Color.white, miniKeyboardStyle: true)
                .frame(width:7 * keyHeight, height: keyHeight)
                .cornerRadius(16)
                .padding(.bottom, 0)
                .figmaRoundedBackground()
            Text("Middle C").font(.callout).padding()
        }
        .onAppear() {
            if let score = scalesModel.getScore() {
                keyboardModel.configureKeyboardForScaleStartView1(scale:scalesModel.scale, score:score, start: 37, numberOfKeys: 47, handType: .right)
            }
        }
    }
}

///Prepare a Follow, Lead and start the exercise when the user hits start. No metronome
///
struct StartFollowLeadView: View {
    let scalesModel:ScalesModel
    let activityName:String
    let callback: (_ cancelled: Bool) -> Void
    let figmaColors = FigmaColors()
    
    @State private var countdown = 0
    @State private var isCountingDown = false
    
    var body: some View {
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        VStack() { //spacing:0

            Text("\(activityName) Slowly").font(.title).padding()
            let height = UIScreen.main.bounds.height
            
            //Relativly larger keys for phone
            PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: height * (compact ? 0.17 : 0.12))
                .padding()

            if isCountingDown {
                let message = countdown == 0 ? "Starting Now" : "Starting in \(countdown)"
                let bold:Color = FigmaColors.shared.color("Orange")
                let closeToStart = countdown < 2
                Text(message)
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                    .foregroundColor(closeToStart ? bold : Color(.black))
                    .padding()
                    .fontWeight(closeToStart ? .bold : .regular)
                    .figmaRoundedBackgroundWithBorder(fillColor: .white)
            }
            else {
                HStack {
                    FigmaButton("Back", action : {
                        callback(true)
                    })

                    FigmaButton("Start", action : {
                        scalesModel.setRunningProcess(RunningProcess.none)
                        startCountdown()
                    })
                }
            }
            if compact {
                Spacer()
            }
            else {
                Text("").padding()
            }
        }
        .figmaRoundedBackgroundWithBorder()
    }

    private func startCountdown() {
        countdown = 3
        isCountingDown = true

        //Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { timer in

            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
                isCountingDown = false
                callback(false)
            }
        }
    }
}


struct StartExerciseView: View {
    let scalesModel:ScalesModel
    let activityName:String
    let callback: (_ cancelled: Bool) -> Void
    let figmaColors = FigmaColors()
    
    @ObservedObject private var metronome = Metronome.shared
    @State private var countdown = 0
    @State private var isCountingDown = false
    @State private var metronomeChecked = false
    let audioManager = AudioManager.shared
    
    private func startMetronome() {
        metronome.stop("StartExerciseView")
        self.audioManager.configureAudio(withMic: false, recordAudio: false)
        metronome.addProcessesToNotify(process: HearScalePlayer(hands: scalesModel.scale.hands, process: .playingAlong))
        metronome.start("StartExerciseView", doLeadIn: true, scale: scalesModel.scale)
        callback(false)
    }
    
    var body: some View {
        //let compact = UIDevice.current.userInterfaceIdiom == .phone
        VStack() {
            if metronomeChecked {
                Text("StartExercise")
                FigmaButton("Start", action : {
                    
                })
            }
            else {
                HStack {
                    Text("Are you happy with your metronome setting?").padding()
                    FigmaButton("Yes", action : {
                        self.metronomeChecked = true
                        self.startMetronome()
                    })
                    FigmaButton("No", action : {
                        callback(true)
                    })
                }
            }
        }
        .padding()
        .figmaRoundedBackgroundWithBorder()
    }
}

