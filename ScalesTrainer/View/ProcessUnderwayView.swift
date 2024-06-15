import SwiftUI

struct ProcessUnderwayView: View {
    @State private var isRecording = true
    @State private var animate = false

    var body: some View {
        VStack {
            ZStack {
                let width = CGFloat(UIScreen.main.bounds.size.width / 12)
                Circle()
                    .trim(from: 0.0, to: 0.8)
                    .stroke(Color.blue, lineWidth: 4)
                    .rotationEffect(Angle(degrees: animate ? 360 : 0))
                    .frame(width: width, height: width)
                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
                
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width / 2.0, height: width / 2.0)
                    .foregroundColor(.green)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true))

//                // Musical notes animation
//                if isRecording {
//                    ForEach(0..<5) { i in
//                        Image(systemName: "music.note")
//                            .foregroundColor(.blue)
//                            .offset(y: animate ? -100 : -50)
//                            .rotationEffect(Angle(degrees: Double(i) * 36))
//                            .animation(Animation.easeInOut(duration: 1).repeatForever().delay(Double(i) * 0.2))
//                    }
//                }
            }
            .padding()
            .hilighted(backgroundColor: .white)
            .onAppear {
                self.animate.toggle()
            }
        }
    }
}

