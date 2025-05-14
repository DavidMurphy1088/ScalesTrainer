import SwiftUI

struct HandsView: View {
    let scale:Scale
    let color:Color = Color.green
    let imageSize = UIScreen.main.bounds.size.width * 0.05
    var body: some View {
        VStack(spacing: 0)  {
            HStack {
                if scale.hands.count > 1 || scale.hands[0] == 1 {
                    Image("hand_left")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height:imageSize)
                        .foregroundColor(color)
                }
                if scale.hands.count > 1 || scale.hands[0] == 0 {
                    Image("hand_right")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(height:imageSize)
                        .foregroundColor(color)
                }
            }
        }
    }
}

struct StartCountdownView: View {
    @ObservedObject private var metronome = Metronome.shared
    let scale:Scale
    let activityName:String
    let callback: (_ : ExerciseState.State) -> Void
    
    func stayAlive(countdown:Int) -> Bool {
        if metronome.statusPublished == MetronomeStatus.running {
            callback(ExerciseState.State.exerciseStarted)
            return false
        }
        return true
    }

    var body: some View {
        VStack {
            let scaleName = scale.getScaleName(handFull: true)
            GeometryReader { geo in
                VStack(spacing:0) {
                    Text("Starting \(activityName)").font(.title)
                    Text("\(scaleName)").font(.title2)
                    if metronome.statusPublished == .standby {
                        Text("Hands ready?").font(.title2).bold()
                    }
                    else {
                        if let countdown = metronome.leadInCountdownPublished {
                            if stayAlive(countdown: countdown)  {
                                VStack {
                                    if countdown > 0 {
                                        let message = "Starting in \(countdown)"
                                        Text(message)
                                            .font(.title2).bold()
                                            .foregroundColor(countdown == 1 ? AppOrange : Color(.blue))
                                    }
                                }
                            }
                        }
                    }
                    PianoStartNoteIllustrationView(scalesModel: ScalesModel.shared, keyHeight: geo.size.height * 0.20)
                            .frame(width: geo.size.width * 0.99, height: geo.size.height * 0.4)
                    HandsView(scale: scale)

                    Button("Cancel") {
                        callback(.exerciseAborted)
                    }
                    //.font(.title2)
                    //.padding()
                    Spacer()
                }
            }
        }
        .onAppear() {
        }
        .frame(width: UIScreen.main.bounds.width * 0.60, height: UIScreen.main.bounds.height * (UIDevice.current.userInterfaceIdiom == .phone ? 0.70 : 0.60))
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 3))
        .shadow(radius: 10)
    }
}

/// ------------------ With badges exercises -----------------

struct EndOfExerciseView: View {
    let badge: Badge
    let scalesModel:ScalesModel
    let exerciseMessage:String?
    let callback: (_ retry:Bool, _ showResult:Bool) -> Void
    let failed:Bool
    
    @State private var countdown = 0
    @State private var isCountingDown = false
    
    var body: some View {
        VStack {
            if failed {
                VStack {
                    if let msg = exerciseMessage {
                        VStack(spacing : 0) {
                            Text("Sorry 😢 - \(msg)").font(.title2)
                            Text("Try again?").font(.title2)
                        }
                        .padding()
                    }
                    HStack {
                        Button("Cancel") {
                            callback(false, false)
                        }
                        .font(.title)
                        .padding()
                        
                        Button("Retry") {
                            callback(true, false)
                        }
                        .font(.title)
                        .padding()
                    }
                }
            }
            else {
                Text("😊 You  Won \(badge.name)").font(.largeTitle)
                    .padding()
                //            Text(badge.name).font(.largeTitle)
                //                .padding()
                Image(badge.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding()
                
                HStack {
                    Button("OK") {
                        callback(false, false)
                    }
                    .font(.title)
                    .disabled(isCountingDown)
                    .padding()
                    
                    if Settings.shared.isDeveloperMode1() {
                        Button("Results") {
                            callback(false, true)
                        }
                        .font(.title)
                        .disabled(isCountingDown)
                        .padding()
                    }
                }
            }
        }
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.blue, lineWidth: 3))
        .shadow(radius: 10)
    }
}

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
                .outlinedStyleView()
            Text("Middle C").font(.callout)
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
    let badge: Badge
    let scalesModel:ScalesModel
    let activityName:String
    let callback: (_ cancelled: Bool) -> Void
    
    @State private var countdown = 0
    @State private var isCountingDown = false
    
    var body: some View {
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        GeometryReader {geo in
            VStack(spacing:0) {
                let imageSize = compact ? 0.2 : 0.2
                if !compact {
                    Spacer()
                }
                Text("\(activityName) - Win \(badge.name)").font(compact ? .title : .title)
                    //.padding()
                if !compact {
                    Spacer()
                }
                Image(badge.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width * imageSize, height: geo.size.height * imageSize)
                if !compact {
                    Spacer()
                }
                PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: geo.size.height * 0.20)
                    .frame(width: geo.size.width * 0.99, height: geo.size.height * 0.4)
                    //.border(.red)
                HandsView(scale: scalesModel.scale)
                if !compact {
                    Spacer()
                }
                if isCountingDown {
                    let message = countdown == 0 ? "Starting Now" : "Starting in \(countdown)"
                    Text(message)
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                        .foregroundColor(countdown == 0 ? AppOrange : Color(.blue))
                        .padding()
                }
                else {
                    HStack {
                        Button("Cancel") {
                            callback(true)
                        }
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                        .disabled(isCountingDown)
                        .padding()
                        
                        Button("Start") {
                            scalesModel.setRunningProcess(RunningProcess.none)
                            startCountdown()
                        }
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                        .disabled(isCountingDown)
                        .padding()
                    }
                    //.padding()
                }
                //if !compact {
                    Spacer()
                //}
            }
        }
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 3))
        .shadow(radius: 10)
    }

    private func startCountdown() {
        countdown = 3
        isCountingDown = true

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
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
