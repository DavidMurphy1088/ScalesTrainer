import SwiftUI

struct EndOfExerciseView: View {
    let badge: Badge
    let scalesModel:ScalesModel
    let exerciseMessage:String?
    let callback: (_ cancelled: Bool) -> Void
    
    @State private var countdown = 0
    @State private var isCountingDown = false
    
    var body: some View {
        VStack {
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
                callback(true)
            }
            .font(.title)
            .disabled(isCountingDown)
            .padding()
        }
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.blue, lineWidth: 3))
        .shadow(radius: 10)
    }
}

struct StartExerciseView: View {
    let badge: Badge
    let scalesModel:ScalesModel
    let exerciseMessage:String?
    let callback: (_ cancelled: Bool) -> Void
    
    @State private var countdown = 0
    @State private var isCountingDown = false

    var body: some View {
        VStack {
            Spacer()
            if let msg = exerciseMessage {
                VStack {
                    Text("🔺 Sorry, \(msg)").font(.title2)
                    Text("Try again?").font(.title2)
                }
                .padding()
            }
            Text("Win \(badge.name)").font(.title)
                .padding()
            Image(badge.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding()

            if isCountingDown {
                let message = countdown == 0 ? "Starting Now" : "Starting in \(countdown) ..."
                Text(message)
                    .font(.title)
                    //.foregroundColor(.red)
                    .padding()
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    callback(true)
                }
                .font(.title)
                .disabled(isCountingDown)
                .padding()
                
                Spacer()
                Button("Start") {
                    scalesModel.setRunningProcess(RunningProcess.none)
                    startCountdown()
                }
                .font(.title)
                .disabled(isCountingDown)
                .padding()
                
                Spacer()
            }
            .padding()
        }
        .background(Color.white.opacity(1.0))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.blue, lineWidth: 3))
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
