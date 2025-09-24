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

//struct PickBackingStyle: View {
//    
//    struct PickBackingStyle {
//        @Binding var backingPresetNumber: Int
//        
//        struct Preset: Identifiable {
//            let id = UUID()
//            let name: String
//            let preset: Int
//        }
//        
//        /// All available instruments
//        let instruments: [Preset]
//        
//        init(backingPresetNumber: Binding<Int>) {
//            _backingPresetNumber = backingPresetNumber
//            
//            // initialise the array here
//            instruments = [
//                Preset(name: "Piano",       preset: 0),
//                Preset(name: "Vibraphone",  preset: 11),
//                Preset(name: "Marimba",     preset: 12),
//                Preset(name: "Cello",       preset: 1),
//                Preset(name: "Synthesiser", preset: 2),
//                Preset(name: "Guitar",      preset: 3)
//            ]
//        }
//        
//        /// Helper to get the display name for the current selection
//        private func backingSoundName(for number: Int) -> String {
//            instruments.first(where: { $0.preset == number })?.name ?? "Unknown"
//        }
//    }
//        
//    var body: some View {
//        HStack {
//            Text(LocalizedStringResource("Backing Track Sound")).padding() //.font(.title2).padding(0)
//            Picker("Select Value", selection: $backingPresetNumber) {
//                ForEach(0..<8) { number in
//                    Text("\(backingSoundName(number))")
//                }
//            }
//            .pickerStyle(.menu)
//            .onChange(of: backingPresetNumber, {
//                //user.settings.backingSamplerPreset = backingPresetNumber
//                //AudioManager.shared.resetAudioKit()
//            })
//        }
//    }
//}



struct PickBackingStyle: View {
    @Binding var backingPresetNumber: Int

    struct Preset: Identifiable, Hashable {
        let id = UUID()
        let preset: Int
        let name: String
    }

    /// All available instruments
    let instruments: [Preset]

    init(backingPresetNumber: Binding<Int>) {
        _backingPresetNumber = backingPresetNumber
        ///Sep25 Use Polyphone app to list names and presets of a given sf2 file
        instruments = [
            Preset(preset: 0, name: "Piano"),
            Preset(preset: 2, name: "Electric Piano"),
            Preset(preset: 6, name: "Harpsichord"),
            Preset(preset: 7, name: "Clavinet"),
            Preset(preset: 9, name: "Glockspiel"),
            Preset(preset: 10, name: "Music Box"),
            Preset(preset: 11, name: "Vibraphone"),
            Preset(preset: 12, name: "Marimba"),
            Preset(preset: 15, name: "Dulcimer"),
            Preset(preset: 19, name: "Church Organ"),
            Preset(preset: 20, name: "Reed Organ"),
            Preset(preset: 21, name: "Accordian"),
            Preset(preset: 24, name: "Nylon String Guitar"),
            Preset(preset: 25, name: "Steel String Guitar"),
            Preset(preset: 32, name: "Acoustic Bass"),
            Preset(preset: 40, name: "Violin"),
            Preset(preset: 41, name: "Viola"),
            Preset(preset: 42, name: "Cello"),
            Preset(preset: 46, name: "Harp"),
            Preset(preset: 48, name: "Strings"),
            Preset(preset: 49, name: "Synth Strings"),
            Preset(preset: 60, name: "French Horns"),
            Preset(preset: 71, name: "Clarinet"),
            //Preset(preset: 0, name: ""),
        ]
    }

    /// Display name for the currently selected preset number
    private func backingSoundName(_ number: Int) -> String {
        instruments.first(where: { $0.preset == number })?.name ?? "Unknown"
    }

    var body: some View {
        HStack {
            Text("Backing Track Sound")
                .padding(.trailing, 8)

            Picker("Select Value", selection: $backingPresetNumber) {
                ForEach(instruments) { item in
                    Text(item.name).tag(item.preset)
                }
            }
            .pickerStyle(.menu)
            .figmaRoundedBackgroundWithBorder(fillColor: .white) //, opacity: <#T##Double#>, outlineBox: <#T##Bool#>)
        }
        .onChange(of: backingPresetNumber) { oldValue, newValue in
            backingPresetNumber = newValue
            // e.g. persist & re-init audio:
            // user.settings.backingSamplerPreset = newValue
            // AudioManager.shared.resetAudioKit()
        }
        .accessibilityLabel(Text("Backing: \(backingSoundName(backingPresetNumber))"))
        .padding()
    }
}

struct PianoStartNoteIllustrationView: View {
    let scalesModel:ScalesModel
    let keyHeight:Double
    @State private var flash = false
    let keyboardModel = PianoKeyboardModel(name: "PianoStartNoteIllustrationView", keyboardNumber: 1)
    
    var body: some View {
        VStack(spacing:0) {
            PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: keyboardModel,
                              keyColor: Color.white, miniKeyboardStyle: true)
                .frame(width:7 * keyHeight, height: keyHeight)
                .cornerRadius(8)
                .padding(.bottom, 0)
                .figmaRoundedBackgroundWithBorder()
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
    let figmaColors = FigmaColors.shared
    
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
                let bold:Color = FigmaColors.shared.getColor1("StartFollowLeadView", "Orange")
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
                        ///startCountdown() Thee should be no countdown
                        callback(false)
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
    let countInRequired:Bool
    let parentCallback: (_ cancelled: Bool) -> Void
    let endExerciseCallback: () -> Void
    let figmaColors = FigmaColors.shared
    
    @ObservedObject private var metronome = Metronome.shared
    @State private var countdown = 0
    @State private var isCountingDown = false
    @State private var metronomeStarted = false
    let audioManager = AudioManager.shared
    @State private var startCountdown = false
    @State private var backingPresetNumber = 0
    
    private func startMetronome(process:RunningProcess) {
        metronome.stop("StartExerciseView")
        var doLeadIn = false
        if [.playingAlong, .backingOn].contains(process) {
            metronome.addProcessesToNotify(process: HearScalePlayer(hands: scalesModel.scale.hands, process: process, endCallback: endExerciseCallback))
            self.audioManager.configureAudio(withMic: false, recordAudio: false)
            doLeadIn = true
        }
        if [.recordingScale].contains(process) {
            self.audioManager.configureAudio(withMic: true, recordAudio: true)
        }
        metronome.start("StartExerciseView", doLeadIn: doLeadIn, scale: scalesModel.scale)
        //parentCallback(false)
    }
    
    var body: some View {
        //let compact = UIDevice.current.userInterfaceIdiom == .phone
        VStack() {
            HStack {
                if self.startCountdown {
                    HStack {
                        if let count = self.metronome.leadInCountdownPublished {
                            Text("Counting In \(count)").padding().bold()
                        }
                        else {
                            Text("Starting Count In ...").padding().bold()
                        }
                    }
                    .onChange(of: self.metronome.leadInCountdownPublished, {
                        if let count = self.metronome.leadInCountdownPublished {
                            if count <= 1 {
                                ///Take down this start view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    parentCallback(false)
                                }
                            }
                        }
                    })
                }
                else {
                    VStack {
                        if process == .backingOn {
                            PickBackingStyle(backingPresetNumber: $backingPresetNumber)
                                .padding()
                                .onChange(of: backingPresetNumber, {
                                    AudioManager.shared.backingInstrumentNumber = self.backingPresetNumber
                                })
                        }
                        HStack {
                            Text("Are you happy with your metronome setting?").padding()
                            FigmaButton("Yes", action : {
                                //DispatchQueue.main.asyncAfter(deadline: .now() + 1.50) {
                                    self.startMetronome(process: process)
                                //}
                                if self.countInRequired {
                                    self.startCountdown = true
                                }
                                else {
                                    parentCallback(false)
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
            self.backingPresetNumber = AudioManager.shared.backingInstrumentNumber
        }
    }
}

