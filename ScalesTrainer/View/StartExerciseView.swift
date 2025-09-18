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

struct PickBackingStyle: View {
    @Binding var backingPresetNumber: Int
    func backingSoundName(_ n:Int) -> String {
        var str:String
        switch n {
        case 1: str = "Cello"
        case 2: str = "Synthesiser"
        case 3: str = "Guitar"
        case 4: str = "Saxophone"
        case 5: str = "Moog Synthesiser"
        case 6: str = "Steel Guitar"
        case 7: str = "Melody Bell"
        default:
            str = "Piano"
        }
        return str
    }
    
    var body: some View {
        HStack {
            Text(LocalizedStringResource("Backing Track Sound")).padding() //.font(.title2).padding(0)
            Picker("Select Value", selection: $backingPresetNumber) {
                ForEach(0..<8) { number in
                    Text("\(backingSoundName(number))")
                }
            }
            .pickerStyle(.menu)
            .onChange(of: backingPresetNumber, {
                //user.settings.backingSamplerPreset = backingPresetNumber
                //AudioManager.shared.resetAudioKit()
            })
        }
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
    
    func handName() -> String {
        let types = scalesModel.scale.getHandTypes()
        if types.count > 1 {
            return ""
        }
        return types[0] == .left ? "LH" : "RH"
    }
    
    var body: some View {
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        VStack() {
            
            let title = "\(activityName) The \(handName()) \(scalesModel.scale.getScaleTypeName()) Slowly"
            Text(title).font(.title).padding()
            let height = UIScreen.main.bounds.height
            
            //Relativly larger keys for phone
            PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: height * (compact ? 0.17 : 0.12))
                .padding()

            if isCountingDown {
                let message = countdown == 0 ? "Starting Now" : "Starting in \(countdown)"
                let bold:Color = FigmaColors.shared.getColor("Orange")
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
    let process:RunningProcess
    let activityName:String
    let parentCallback: (_ cancelled: Bool) -> Void
    let endExerciseCallback: () -> Void
    let figmaColors = FigmaColors()
    
    @ObservedObject private var metronome = Metronome.shared
    @State private var countdown = 0
    @State private var isCountingDown = false
    @State private var metronomeStarted = false
    let audioManager = AudioManager.shared
    @State private var confirmed = false
    @State private var backingPresetNumber = 0
    
    private func startMetronome(process:RunningProcess) {
        metronome.stop("StartExerciseView")
        
        if [.playingAlong, .backingOn].contains(process) {
            metronome.addProcessesToNotify(process: HearScalePlayer(hands: scalesModel.scale.hands, process: process, endCallback: endExerciseCallback))
            self.audioManager.configureAudio(withMic: false, recordAudio: false)
        }
        if [.recordingScale].contains(process) {
            self.audioManager.configureAudio(withMic: true, recordAudio: true)
        }
        metronome.start("StartExerciseView", doLeadIn: false, scale: scalesModel.scale)
        parentCallback(false)
    }
    
    var body: some View {
        //let compact = UIDevice.current.userInterfaceIdiom == .phone
        VStack() {
            HStack {
                if self.confirmed {
                    Text("Counting In ...").padding().foregroundColor(.green).bold()
                        .figmaRoundedBackgroundWithBorder(fillColor: .white)
                }
                else {
                    VStack {
                        if process == .backingOn {
                            PickBackingStyle(backingPresetNumber: $backingPresetNumber)
                                .padding()
                                .onChange(of: backingPresetNumber, {
                                    AudioManager.shared.backingPresetNumber = self.backingPresetNumber
                                })
                        }
                        HStack {
                            Text("Are you happy with your metronome setting?").padding()
                            FigmaButton("Yes", action : {
                                self.confirmed = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
                                    //print("Called after 1 second!")
                                    self.startMetronome(process: process)
                                }
                            })
                            FigmaButton("No", action : {
                                parentCallback(true)
                            })
                        }
                    }
                }
            }
        }
        .padding()
        
        .figmaRoundedBackgroundWithBorder()
        .onAppear() {
            self.backingPresetNumber = AudioManager.shared.backingPresetNumber
        }
    }
}

