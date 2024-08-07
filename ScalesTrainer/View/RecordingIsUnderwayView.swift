import SwiftUI

struct RecordingIsUnderwayView: View {
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
                    //.animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            animate.toggle()
                        }
                    }
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width / 2.0, height: width / 2.0)
                    .foregroundColor(.green)

            }
            .padding()
            .hilighted(backgroundColor: .white)
            .onAppear {
                self.animate.toggle()
            }
        }
    }
}

