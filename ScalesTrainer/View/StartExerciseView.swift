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
        GeometryReader { geo in
            VStack {
                PianoKeyboardView(scalesModel: ScalesModel.shared, viewModel: keyboardModel, keyColor: Color.white, plainStyle: true)
                    .frame(width:7 * keyHeight, height: keyHeight)
                    .cornerRadius(16)
                    .padding(.bottom, 0)
                    //.border(Color.orange)
                    //.outlinedStyleView()
                Text("Middle C").font(.callout )
            }
        }
        //.border(Color.red)
        .onAppear() {
            if let score = scalesModel.getScore() {
                keyboardModel.configureKeyboardForScaleStartView1(scale:scalesModel.scale, score:score, start: 22, numberOfKeys: 80,
                                                                                        scaleStartMidi: ScalesModel.shared.scale.getMinMax(handIndex: 0).0, handType: .right)
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
        GeometryReader {geo in
            VStack {
                let imageSize = UIDevice.current.userInterfaceIdiom == .phone ? 0.1 : 0.2
                Spacer()
                Text("Win \(badge.name)").font(.title)
                    .padding()
                
                Spacer()
                Image(badge.imageName)
                    .resizable()
                    //.scaledToFit()
                    .frame(width: geo.size.width * imageSize, height: geo.size.height * imageSize)
                    .padding()
                
                Spacer()
                PianoStartNoteIllustrationView(scalesModel: scalesModel, keyHeight: geo.size.height * 0.20)
                    .frame(width: geo.size.width * 0.95, height: geo.size.height * 0.3)
                //.border(Color.red)
                
                
                Spacer()
                if isCountingDown {
                    let message = countdown == 0 ? "Starting Now" : "Starting in \(countdown)"
                    Text(message)
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
                        .foregroundColor(countdown == 0 ? Color(.orange) : Color(.blue))
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
                    .padding()
                }
                Spacer()
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
