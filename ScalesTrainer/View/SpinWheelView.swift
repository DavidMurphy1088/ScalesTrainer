import SwiftUI

struct SpinWheelView: View {
    @ObservedObject var scalesModel = ScalesModel.shared
    let boardGrade:MusicBoardGrade

    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 3 // Duration in seconds
    @State private var maxRotations: Double = 1 // Max rotations per second
    @State private var wheelSize: CGFloat = 0.8 // Size as a percentage of screen width
    @State private var width = 0.0 //DeviceOrientationObserver().orientation.isAnyLandscape ? 0.5 : 0.8

    @State private var selectedScaleType = 0
    @State private var selectedScaleRoot = 0
    @State private var selectedHand = 0

    @State var background = UIGlobals.shared.getBackground()

    func getRootNames() -> [String] {
        var scaleRoots:Set<String> = []
        for scale in boardGrade.scales {
            scaleRoots.insert(scale.scaleRoot.name)
        }
        return Array(scaleRoots).sorted()
    }
    
    func getTypes() -> [ScaleType] {
        var scaleTypes:Set<ScaleType> = []
        for scale in boardGrade.scales  {
            scaleTypes.insert(scale.scaleType)
        }

        return Array(scaleTypes).sorted()
    }
    
    func getTypeNames() -> [String] {
        var res:[String] = []
        for t in getTypes() {
            res.append(t.description)
        }
        return res
    }
    
    func log4(index:Int, group: MusicBoard, scale: PracticeJournalScale) -> Int {
        return 0
    }
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                TitleView(screenName: "Spin The Scale Wheel")
                VStack {
                    ZStack {
                        GeometryReader { geometry in
                            let handSizeFactor = 0.25
                            let rootSizeFactor = 0.40
                            let arrowPos = geometry.size.width * 0.92
                            ZStack {
                                ///Scale Types
                                SegmentedCircleView(elements: getTypeNames(), rotation: rotation, wheelSize: wheelSize * geometry.size.width)
                                    .frame(width: wheelSize * geometry.size.width, height: wheelSize * geometry.size.width)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                /// Fixed arrow
                                Arrow()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                    .position(x: arrowPos, y: geometry.size.height / 2)
                                
                                ///Scale Roots
                                SegmentedCircleView(elements: getRootNames(), rotation: rotation, wheelSize: wheelSize * geometry.size.width * rootSizeFactor)
                                    .frame(width: wheelSize * geometry.size.width * rootSizeFactor, height: wheelSize * geometry.size.width * rootSizeFactor)
                                    .position(x: geometry.size.width * 0.74, y: geometry.size.height * 0.25)
                                Arrow()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                    .position(x: arrowPos, y: geometry.size.height * 0.25)

                                ///Randomise which hand
                                SegmentedCircleView(elements: ["Left", "Right"], rotation: rotation, wheelSize: wheelSize * geometry.size.width * handSizeFactor)
                                    .frame(width: wheelSize * geometry.size.width * handSizeFactor, height: wheelSize * geometry.size.width * handSizeFactor)
                                    .position(x: geometry.size.width * 0.80, y: geometry.size.height * 0.75)
                                Arrow()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                    .position(x: arrowPos, y: geometry.size.height * 0.75)

                            }
                        }
                        .edgesIgnoringSafeArea(.all)
                    }

                    if [SpinState.notStarted, SpinState.selectedBet].contains(scalesModel.spinState) {
                        HStack {
                            Spacer()
                            VStack {
                                Button(action: {
                                    startSpinning(scaleTypes: self.getTypeNames(),
                                                  scaleRoots: self.getRootNames(),
                                                  hands: [1,0])
                                }) {
                                    HStack {
                                        Text(" Spin The Wheel ").padding().font(.title2).hilighted(backgroundColor: .blue)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }

                    if scalesModel.spinState == SpinState.spunAndStopped {
                        let scale = scalesModel.scale
                        NavigationLink(destination: ScalesView(initialRunProcess: nil)) {
                            Text(" Go To Scale \(scale.getScaleName()) - Good Luck 😊").padding()  
                                .font(.title2)
                                .hilighted(backgroundColor: .blue)
                        }
                    }
                    Spacer()
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
        }
        .onAppear() {
            scalesModel.setSpinState1(.notStarted)
            background = UIGlobals.shared.getBackground()
            width = DeviceOrientationObserver().orientation.isAnyLandscape ? 0.45 : 0.9
        }
        .navigationBarBackButtonHidden(scalesModel.spinState == .spunAndStopped)
    }
    
    func startSpinning(scaleTypes:[String], scaleRoots:[String], hands:[Int]) {
        let totalRotations = maxRotations * totalDuration * 360 // Total rotation in degrees
        let randomAngle = Double.random(in: 0..<360) // Random angle to add to the final rotation
        withAnimation(Animation.timingCurve(0.5, 0, 0.5, 1, duration: totalDuration)) {
            rotation += totalRotations + randomAngle
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            scalesModel.setSpinState1(.spunAndStopped)
            // Adjust to ensure the rotation ends at a random position
            rotation = rotation.truncatingRemainder(dividingBy: 360)
            // Determine which segment is at the top
            var segments = 360.0 / Double(scaleTypes.count)
            var index = Int((360 - rotation) / segments) % scaleTypes.count
            self.selectedScaleType = index
            
            segments = 360.0 / Double(scaleRoots.count)
            index = Int((360 - rotation) / segments) % scaleRoots.count
            self.selectedScaleRoot = index

            segments = 360.0 / Double(hands.count)
            index = Int((360 - rotation) / segments) % hands.count
            self.selectedHand = index

            let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoots[selectedScaleRoot]),
                              scaleType: getTypes()[self.selectedScaleType],
                              octaves: Settings.shared.defaultOctaves, hand: hands[self.selectedHand ])
            let _ = ScalesModel.shared.setScale(scale: scale)
        }
    }
}

