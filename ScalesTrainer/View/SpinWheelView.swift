import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

struct SpinTheWheelView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewManager = ViewManager.shared
    @State private var user:User?
    let screenWidth = UIScreen.main.bounds.size.width
    @State private var rotation: Double = 0
    @State private var wasSpun = false
    @State var totalSpinSeconds: Double = 0
    @State var totalRotation: Double = 0
    @State var navigateToScale = false
    @State var scales:[Scale] = []
    @State var scaleChoosen:Scale?
    @State private var showResultOpacity = false
    @State private var spinCount = 0
    
    private func getMaxScreenDimensionSize() -> CGFloat {
        if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
            return UIScreen.main.bounds.size.height
        }
        else {
            return UIScreen.main.bounds.size.width
        }
    }
    
    private func spinWheel() {
        withAnimation(.easeOut(duration: totalSpinSeconds)) {
            rotation += totalRotation
        }
    }
    
    func setScaleChoosen() {
        let r = Int.random(in: 0...self.scales.count-1)
        let scale = self.scales[r]
        self.scaleChoosen = scale
        let _ = ScalesModel.shared.setScale(scale: scale)
    }
    
    var body: some View {
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
                if UIDevice.current.userInterfaceIdiom != .phone {
                    Text("").padding()
                    Text("").padding()
                }
                HStack {
                    Text("").padding()
                    VStack(alignment: .leading) {
                        Text("")
                        if wasSpun {
                            if let scale = self.scaleChoosen {
                                VStack {
                                    Text("You’ve landed on...")
                                    Text("")
                                    Text("")
                                    Text("")
                                    let title = scale.getScaleDescriptionParts(name: true)
                                    Text(title).font(.title).bold()
                                    HStack {
                                        if let handImage = Figma.getHandImage(scale: scale) {
                                            handImage
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: getMaxScreenDimensionSize() * 0.05)
                                                .foregroundColor(.black)
                                            //.border(.red)
                                        }
                                        let hands = scale.getScaleDescriptionParts(hands: true)
                                        Text(hands).font(.body).foregroundColor(.black)
                                        //Spacer()
                                    }
                                    Text("")
                                    Text("")
                                    Text("")
                                    FigmaButtonWithLabel(label: {
                                        Text("Practice Now").bold()
                                    }, action: {
                                        navigateToScale = true
                                    })
                                }
                                .opacity(showResultOpacity ? 1 : 0)

                            }
                        }
                        else {
                            Text("What will you play today?").font(.title)
                            Text("")
                            Text("Spin the wheel and get a surprise")
                            Text("exercise to practise")
                            Text("")
                            Text("")
                            Text("")
                            FigmaButtonWithLabel(label: {
                                Text("Spin Now").bold()
                            }, action: {
                                spinWheel()
                                DispatchQueue.main.asyncAfter(deadline: .now() + totalSpinSeconds + 0.5) {
                                    self.showResultOpacity = false
                                    self.wasSpun = true
                                    self.spinCount += 1
                                    self.setScaleChoosen()
                                }
                            })
                        }
                        Text("")
                        Text("")
                        Text("")
                    }
                    Text("").padding()
                }
                .figmaRoundedBackground()
                .padding()
                Spacer()
            }
        }
        .onChange(of: self.spinCount) { 
            withAnimation(.easeIn(duration: 1.0)) {
                showResultOpacity = true
            }
        }
        .commonToolbar(
            title: "Spin the Wheel",
            helpMsg: "",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser("SpinWheelView .onAppear")
            self.user = user
            //self.scales = MusicBoardAndGrade.getScales(boardName: user.board, grade: user.grade)
            self.scales = MusicBoardAndGrade.getScales(boardName: user.boardAndGrade.board.name,
                                                       grade: user.boardAndGrade.grade)

            wasSpun = false
            totalSpinSeconds = 3.0 + Double.random(in: 0...1.0)
            ///Make sure it centers on a slice
            totalRotation = (360.0 * 2) + Double(Int.random(in: 0...8)) * (360.0 / 8.0)
        }
        .navigationDestination(isPresented: $navigateToScale) {
            if let user = user {
                if let scale = self.scaleChoosen {
                    ScalesView(user: user,
                               scale: scale)
                               //practiceModeHand: .right)
                }
            }
        }
        .onChange(of: viewManager.boardPublished) {oldValue, newValue in
            dismiss()
        }
        .onChange(of: viewManager.gradePublished) {oldValue, newValue in
            dismiss()
        }
        .navigationTitle("Spin the Wheel")
    }
}

