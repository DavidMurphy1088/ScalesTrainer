import SwiftUI

struct EndOfExerciseView: View {
    let badge: Badge
    let scalesModel:ScalesModel
    let exerciseMessage:String?
    let callback: (_ retry:Bool) -> Void
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
                            callback(false)
                        }
                        .font(.title)
                        .padding()
                        
                        Button("Retry") {
                            callback(true)
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
                Button("OK") {
                    callback(false)
                }
                .font(.title)
                .disabled(isCountingDown)
                .padding()
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
            PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: keyboardModel, keyColor: Color.white, plainStyle: true)
                .frame(width:7 * keyHeight, height: keyHeight)
                .cornerRadius(16)
                .padding(.bottom, 0)
                //.border(AppOrange)
                .outlinedStyleView()
            Text("Middle C").font(.callout)
            //Text("\(scalesModel.scale.getScaleDescription(hands:true))").font(.callout)
        }
        .onAppear() {
            if let score = scalesModel.getScore() {
                keyboardModel.configureKeyboardForScaleStartView1(scale:scalesModel.scale, score:score, start: 37, numberOfKeys: 47,
                                                                                        scaleStartMidi: ScalesModel.shared.scale.getMinMax(handIndex: 0).0, handType: .right)
            }
        }
    }
    
}

struct StartCountdownView: View {
    @ObservedObject private var metronome = Metronome.shared
    let callback: () -> Void
    @State var waitForFirstLeadIn = true
    
    func stayAlive(countdown:Int) -> Bool {
        if waitForFirstLeadIn {
            waitForFirstLeadIn = countdown == 0
        }
        if countdown > 0 {
            return true
        }
        else {
            if waitForFirstLeadIn {
                return true
            }
            else {
                ///close the popup[
                callback()
                return false
            }
        }
    }
    
    var body: some View {
        VStack {
            if let countdown = metronome.leadInCountdownPublished {
                if stayAlive(countdown: countdown)  {
                    VStack {
                        Text("")
                        if countdown > 0 {
                            let message = "Starting in \(countdown)"
                            Text(message)
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                                .foregroundColor(countdown == 1 ? AppOrange : Color(.blue))
                                .foregroundColor(Color(.blue))
                                .padding()
                        }
                        //}
                        Text("")
                    }
                    .background(Color.white.opacity(1.0))
                    .cornerRadius(30)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 3))
                    .shadow(radius: 10)
                    .onAppear() {
                        waitForFirstLeadIn = true
                    }
                }
            }
        }
    }
}

struct StartExerciseView: View {
    let badge: Badge
    let scalesModel:ScalesModel
    let callback: (_ cancelled: Bool) -> Void
    
    @State private var countdown = 0
    @State private var isCountingDown = false
    
    var body: some View {
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        GeometryReader {geo in
            VStack(spacing:0) {
                let imageSize = compact ? 0.2 : 0.2
                //if !compact {
                    Spacer()
                //}
                Text("Win \(badge.name)").font(compact ? .title : .title)
                    //.padding()
                if !compact {
                    Spacer()
                }
                Image(badge.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width * imageSize, height: geo.size.height * imageSize)
                    
                Spacer()
                
                PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: geo.size.height * 0.20)
                    .frame(width: geo.size.width * 0.99, height: geo.size.height * 0.4)
                    //.border(.red)

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
