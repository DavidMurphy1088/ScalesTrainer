import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

struct SpinTheWheelView: View {
    @Environment(\.dismiss) var dismiss
    @State private var user:User?
    let screenWidth = UIScreen.main.bounds.size.width
    @State private var rotation: Double = 0
    @State private var wasSpun = false
    @State var totalSpinSeconds: Double = 0
    @State var totalRotation: Double = 0
    @State var navigateToScale = false
    
    private func getMaxScreenDimensionSize() -> CGFloat {
        if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
            return UIScreen.main.bounds.size.height
        }
        else {
            return UIScreen.main.bounds.size.width
        }
    }
    
    private func spinWheel() {
          // seconds
        //let totalRotation: Double = 1440 // degrees (4 full spins)
        // Animate using easeOut to slow down gradually
        withAnimation(.easeOut(duration: totalSpinSeconds)) {
            rotation += totalRotation
        }
    }
    
    var body: some View {
        //ZStack to ensure that rectangle corners of rotating circle image dont cover the text and button
        ZStack()  {
            HStack {
                Spacer()
                ZStack {
                    let wheelDiameter = getMaxScreenDimensionSize() * 0.60
                    Image("figma_spinwheel")
                        .resizable()
                        .scaledToFit()
                        .frame(height: wheelDiameter)
                        .rotationEffect(.degrees(rotation))
                    if wasSpun {
                        Image("figma_arrowhead")
                            .resizable()
                            .scaledToFit()
                            .frame(height: wheelDiameter * 0.1)
                            .offset(x: 0 - wheelDiameter * 0.5)
                    }
                }
                Text("").padding()
                Text("").padding()
                Text("").padding()
            }

            HStack {
                Text("").padding()
                Text("").padding()
                HStack {
                    Text("").padding()
                    VStack(alignment: .leading) {
                        Text("")
                        if wasSpun {
                            Text("You’ve landed on...").font(.title)
                            Text("")
                            //Text("Spin the wheel and get a surprise")
                            //Text("exercise to practise")
                            Text("")
                            Text("")
                            Text("")
                            FigmaButton(label: {
                                Text("Practice Now").bold()
                            }, action: {
                                if let user = user {
                                    navigateToScale = true
//                                    ScalesView(user: user,
//                                               practiceModeHand: .right)
                                }
                            })
                        }
                        else {
                            Text("What will you play today?").font(.title)
                            Text("")
                            Text("Spin the wheel and get a surprise")
                            Text("exercise to practise")
                            Text("")
                            Text("")
                            Text("")
                            FigmaButton(label: {
                                Text("Spin Now").bold()
                            }, action: {
                                spinWheel()
                                DispatchQueue.main.asyncAfter(deadline: .now() + totalSpinSeconds + 0.5) {
                                    self.wasSpun = true
                                }
                            })
                        }
                        Text("")
                        Text("")
                        Text("")
                    }
                    Text("").padding()
                }
                .figmaRoundedBackground(fillColor: Figma.colorFromRGB(236, 234, 238), opacity: 1.0)
                .padding()
                Spacer()
            }
        }
        .commonToolbar(
            title: "Spin the Wheel",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser()
            self.user = user
            //let practiceChart = user.getPracticeChart()
            wasSpun = false
            totalSpinSeconds = 3.0 + Double.random(in: 0...1.0)
            ///Make sure it centers on a slice
            totalRotation = (360.0 * 2) + Double(Int.random(in: 0...8)) * (360.0 / 8.0)
        }
        .navigationDestination(isPresented: $navigateToScale) {
            if let user = user {
                ScalesView(user: user,
                           //practiceChart: practiceChart,
                           //practiceChartCell: practiceCell,
                           practiceModeHand: .right)
            }
        }
        .navigationTitle("Spin the Wheel")

    }
}

