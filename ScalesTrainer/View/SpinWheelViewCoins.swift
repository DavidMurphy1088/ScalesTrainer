import SwiftUI

struct SegmentedCircleView: View {
    let elements: [String]
    let rotation: Double
    let wheelSize: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                SegmentView(index: index, total: elements.count, text: elements[index], wheelSize: wheelSize)
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

struct SegmentView: View {
    let index: Int
    let total: Int
    let text: String
    let wheelSize: CGFloat

    var body: some View {
        let angle = 360.0 / Double(total)
        let startAngle = angle * Double(index)
        let endAngle = startAngle + angle
        let radius = wheelSize / 2

        return ZStack {
            Path { path in
                let center = CGPoint(x: radius, y: radius)
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: endAngle), clockwise: false)
            }
            .fill(Color(hue: Double(index) / Double(total), saturation: 0.8, brightness: 0.8))
            .overlay(
                Path { path in
                    let center = CGPoint(x: radius, y: radius)
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: endAngle), clockwise: false)
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 2)
            )

            Text(text)
                .font(.title2) // Increase the font size
                .foregroundColor(.white)
                .rotationEffect(.degrees((startAngle + endAngle) / 2))
                .position(x: radius + CGFloat(radius / 2 * cos((startAngle + angle / 2) * .pi / 180)), y: radius + CGFloat(radius / 2 * sin((startAngle + angle / 2) * .pi / 180)))
        }
    }
}

struct Arrow: View {
    let size:Int = 40
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: size, y: 0))
            path.addLine(to: CGPoint(x: 0, y: size/2))
            path.addLine(to: CGPoint(x: size, y: size))
            path.closeSubpath()
        }
        .fill(Color.blue)
    }
}

//struct SpinWheelViewCoins: View {
//    @ObservedObject var scalesModel = ScalesModel.shared
//    let boardGrade:MusicBoardGrade
//
//    @State private var rotation: Double = 0
//    @State private var totalDuration: Double = 3 // Duration in seconds
//    @State private var maxRotations: Double = 1 // Max rotations per second
//    @State private var wheelSize: CGFloat = 0.8 // Size as a percentage of screen width
//    @State private var width = 0.0 //DeviceOrientationObserver().orientation.isAnyLandscape ? 0.5 : 0.8
//
//    @State private var selectedScaleType = 0
//    @State private var selectedScaleRoot = 0
//    @State private var selectedHand = 0
//
//    @State var background = UIGlobals.shared.getBackground()
//    @State private var selectedBet:Int = 0
//    @State private var betSizes:[Int] = []
//    
//    ///Warn on early exit
//    @Environment(\.presentationMode) var presentationMode
//    @State private var promptForEarlyExit = false
//
//    func getRootNames() -> [String] {
//        var scaleRoots:Set<String> = []
//        for scale in boardGrade.getScales() {
//            scaleRoots.insert(scale.scaleRoot.name)
//        }
//        return Array(scaleRoots).sorted()
//    }
//    
//    func getTypes() -> [ScaleType] {
//        var scaleTypes:Set<ScaleType> = []
//        for scale in boardGrade.getScales() {
//            scaleTypes.insert(scale.scaleType)
//        }
//
//        return Array(scaleTypes).sorted()
//    }
//    
//    func getTypeNames() -> [String] {
//        var res:[String] = []
//        for t in getTypes() {
//            res.append(t.description)
//        }
//        return res
//    }
//    
////    func getCoinState() -> String {
////        let coins = CoinBank.shared.totalCoinsInBank
////        var msg = "\(coins) Coin"
////        if coins > 1 {
////            msg += "s"
////        }
////        msg += " remaining. "
////        let lastBet = CoinBank.shared.lastBet
////        if lastBet > 0 {
////            msg += "\(lastBet) Coin"
////            if lastBet > 1 {
////                msg += "s"
////            }
////            msg += " to spin."
////        }
////        return msg
////    }
//    
////    func log4(index:Int, group: MusicBoard, scale: PracticeJournalScale) -> Int {
////        return 0
////    }
//    
//    var body: some View {
//        ZStack {
//            Image(background)
//                .resizable()
//                .scaledToFill()
//                .edgesIgnoringSafeArea(.top)
//                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
//            VStack {
//                TitleView(screenName: "")
//                VStack {
//                    ZStack {
//                        GeometryReader { geometry in
//                            let handSizeFactor = 0.25
//                            let rootSizeFactor = 0.40
//                            let arrowPos = geometry.size.width * 0.92
//                            ZStack {
//                                ///Scale Types
//                                SegmentedCircleView(elements: getTypeNames(), rotation: rotation, wheelSize: wheelSize * geometry.size.width)
//                                    .frame(width: wheelSize * geometry.size.width, height: wheelSize * geometry.size.width)
//                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
//                                /// Fixed arrow
//                                Arrow()
//                                    .frame(width: 30, height: 30)
//                                    .foregroundColor(.purple)
//                                    .position(x: arrowPos, y: geometry.size.height / 2)
//                                
//                                ///Scale Roots
//
//                                SegmentedCircleView(elements: getRootNames(), rotation: rotation, wheelSize: wheelSize * geometry.size.width * rootSizeFactor)
//                                    .frame(width: wheelSize * geometry.size.width * rootSizeFactor, height: wheelSize * geometry.size.width * rootSizeFactor)
//                                    .position(x: geometry.size.width * 0.74, y: geometry.size.height * 0.25)
//                                Arrow()
//                                    .frame(width: 30, height: 30)
//                                    .foregroundColor(.purple)
//                                    .position(x: arrowPos, y: geometry.size.height * 0.25)
//
//                                ///Randomise which hand
//                                SegmentedCircleView(elements: ["Left", "Right"], rotation: rotation, wheelSize: wheelSize * geometry.size.width * handSizeFactor)
//                                    .frame(width: wheelSize * geometry.size.width * handSizeFactor, height: wheelSize * geometry.size.width * handSizeFactor)
//                                    .position(x: geometry.size.width * 0.80, y: geometry.size.height * 0.75)
//                                Arrow()
//                                    .frame(width: 30, height: 30)
//                                    .foregroundColor(.purple)
//                                    .position(x: arrowPos, y: geometry.size.height * 0.75)
//
//                            }
//                        }
//                        .edgesIgnoringSafeArea(.all)
//                        VStack {
//                            Spacer()
//                            VStack {
//                                //CoinStackView(totalCoins: CoinBank.shared.totalCoinsInBank, compactView: false)
//                                //.border(Color.cyan, width: 3)
//                                //.padding()
//                                //.hilighted(backgroundColor: .blue)
//                                //Text(CoinBank.shared.getCoinsStatusMsg()).font(.title2)
//                            }
//                        }
//                        //.frame(maxHeight: .infinity, alignment: .top)
//                        //.border(Color.red)
//                    }
//
//                    if [SpinState.notStarted, SpinState.selectedBet].contains(scalesModel.spinState) {
//                        HStack {
//                            if coinBase.totalCoinsInBank > 1 {
//                                Spacer()
//                                Picker("Select a number", selection: $selectedBet) {
//                                    ForEach(betSizes, id: \.self) { num in
//                                        Text(num == 0 ? "None" : "\(num)").bold().foregroundColor(Color.blue)
//                                    }
//                                }
//                                .pickerStyle(WheelPickerStyle())
//                                .clipShape(RoundedRectangle(cornerRadius: 10))  // Clip the background to rounded corners
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 10)  // Shape to use as the border
//                                        .stroke(Color.gray, lineWidth: 2)  // Gray border with a width of 2
//                                )
//                                .onChange(of: selectedBet) { oldValue, newValue in
//                                    scalesModel.setSpinState1(newValue > 0 ? SpinState.selectedBet : .notStarted)
//                                    CoinBank.shared.setLastBet(newValue)
//                                }
//                                .padding()
//                            }
//                            Spacer()
//                            VStack {
//                                if coinBase.totalCoinsInBank > 1 {
//                                    if CoinBank.shared.lastBet == 0 {
//                                        Text("Spin for how many coins?").padding().font(.title2)
//                                    }
//                                }
//                                ///Let them spin but dont go to record scale if coinBase.totalCoinsInBank == 1
//                                if scalesModel.spinState == SpinState.selectedBet || coinBase.totalCoinsInBank == 1 {
//                                    Button(action: {
//                                        startSpinning(scaleTypes: self.getTypeNames(),
//                                                      scaleRoots: self.getRootNames(),
//                                                      hands: [1,0])
//                                    }) {
//                                        HStack {
//                                            Text(" Spin The Wheel ")
//                                                .padding()
//                                                .font(.title2)
//                                                .hilighted(backgroundColor: .blue)
//                                        }
//                                    }
//                                }
//                            }
//                            Spacer()
//                        }
//                    }
//
//                    if scalesModel.spinState == SpinState.spunAndStopped {
//                        if coinBase.totalCoinsInBank <= 1 {
//                            Text("Sorry, you dont have enough coins 😌").font(.title2)
//                        }
//                        else {
//                            let scale = scalesModel.scale
//                            NavigationLink(destination: ScalesView(initialRunProcess: nil)) {
//                                let name = scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:true, articulation:true)
//                                Text(" Go To Scale \(name) - Good Luck 😊").padding() //.foregroundStyle(Color .blue) //.hilighted(backgroundColor: .blue)
//                                    .font(.title2)
//                                    .hilighted(backgroundColor: .blue)
//                            }
//                        }
//                    }
//                    Spacer()
//                }
//                .commonFrameStyle(backgroundColor: .white)
//            }
//            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.9)
//        }
//        .onAppear() {
//            CoinBank.shared.setLastBet(0)
//            betSizes = Array(0...coinBase.totalCoinsInBank / 2)
//            scalesModel.setSpinState1(.notStarted)
//            background = UIGlobals.shared.getBackground()
//            width = DeviceOrientationObserver().orientation.isAnyLandscape ? 0.45 : 0.9
//        }
////        .alert(isPresented: $promptForEarlyExit) {
////            Alert(title: Text("Warning"), message: Text("Are you sure you want to go back?"), primaryButton: .default(Text("No")) {
////                self.presentationMode.wrappedValue.dismiss()
////            }, secondaryButton: .cancel(Text("No")))
////        }
//        .navigationBarBackButtonHidden(scalesModel.spinState == .spunAndStopped && coinBase.totalCoinsInBank > 1)
//        // Hide default back button to avoid user cancelling coin bet
////        .navigationBarItems(leading: Button(action: {
////            if scalesModel.spinState == .spunAndStopped {
////                self.promptForEarlyExit = true // Show alert when custom back button is tapped
////            }
////            else {
////                self.promptForEarlyExit = false
////            }
////        }) {
////            Image(systemName: "chevron.left")
////            Text("Back")
////        })
//        //.navigationBarTitle("Screen B", displayMode: .inline)
//        .onDisappear {
//            //self.promptForEarlyExit = promptForEarlyExit
//        }
//    }
//    
//    func startSpinning(scaleTypes:[String], scaleRoots:[String], hands:[Int]) {
//        let totalRotations = maxRotations * totalDuration * 360 // Total rotation in degrees
//        let randomAngle = Double.random(in: 0..<360) // Random angle to add to the final rotation
//        withAnimation(Animation.timingCurve(0.5, 0, 0.5, 1, duration: totalDuration)) {
//            rotation += totalRotations + randomAngle
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
//            scalesModel.setSpinState1(.spunAndStopped)
//            // Adjust to ensure the rotation ends at a random position
//            rotation = rotation.truncatingRemainder(dividingBy: 360)
//            // Determine which segment is at the top
//            var segments = 360.0 / Double(scaleTypes.count)
//            var index = Int((360 - rotation) / segments) % scaleTypes.count
//            self.selectedScaleType = index
//            
//            segments = 360.0 / Double(scaleRoots.count)
//            index = Int((360 - rotation) / segments) % scaleRoots.count
//            self.selectedScaleRoot = index
//
//            segments = 360.0 / Double(hands.count)
//            index = Int((360 - rotation) / segments) % hands.count
//            self.selectedHand = index
//
//            let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoots[selectedScaleRoot]), 
//                              scaleType: getTypes()[self.selectedScaleType],
//                              octaves: Settings.shared.defaultOctaves, hand: hands[self.selectedHand],
//                              minTempo: 90, dynamicType: .mf, articulationType: .legato)
//            let _ = ScalesModel.shared.setScale(scale: scale)
//        }
//    }
//}
//
