import SwiftUI

struct SpinWheelView: View {
    @ObservedObject var scalesModel = ScalesModel.shared
    //@StateObject private var orientationObserver = DeviceOrientationObserver()
    let board:MusicBoard
    let boardGrade:MusicBoardGrade

    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 3 // Duration in seconds
    @State private var maxRotations: Double = 1 // Max rotations per second
    
    //@State private var wheelSize: CGFloat = UIScreen.main.bounds.size.height * (DeviceOrientationObserver().orientation.isAnyLandscape ? 0.1 : 0.1)
    @State private var wheelSize: CGFloat = 0
    //0.5 // Size as a percentage of screen width
    //@State private var width = 0.0 //DeviceOrientationObserver().orientation.isAnyLandscape ? 0.5 : 0.8

    @State private var selectedScaleType = 0
    @State private var selectedScaleRoot = 0
    @State private var selectedHand = 0

    func getRootNames() -> [String] {
        var scaleRoots:Set<String> = []
        for scale in boardGrade.getScales() {
            scaleRoots.insert(scale.scaleRoot.name)
        }
        return Array(scaleRoots).sorted()
    }
    
    func getTypes() -> [ScaleType] {
        var scaleTypes:Set<ScaleType> = []
        for scale in boardGrade.getScales() {
            scaleTypes.insert(scale.scaleType)
        }

        return Array(scaleTypes).sorted()
    }
    
    func getScaleNames() -> [String] {
        var res:[String] = []
        //for scale in boardGrade.getScales() {
        for scale in PracticeChart.shared.getScales("Spin") {
            let name = scale.getScaleName(handFull: false)
            //let name = scale.getScaleName(handFull: false, octaves: false)
            res.append(name)
        }
        return res
    }
    
    func getTypeNames() -> [String] {
        var res:[String] = []
        for t in getTypes() {
            res.append(t.description)
        }
        return res
    }
    
//    func log4(index:Int, group: MusicBoard, scale: PracticeJournalScale) -> Int {
//        return 0
//    }
    
    func startSpinningWheel(scaleNames:[String]) {
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
            let segments = 360.0 / Double(scaleNames.count)
            let index = Int((360 - rotation) / segments) % scaleNames.count
            self.selectedScaleType = index
//            segments = 360.0 / Double(scaleRoots.count)
//            index = Int((360 - rotation) / segments) % scaleRoots.count
//            self.selectedScaleRoot = index
//
//            segments = 360.0 / Double(hands.count)
//            index = Int((360 - rotation) / segments) % hands.count
//            self.selectedHand = index

//            let scale = Scale(scaleRoot: ScaleRoot(name: scaleRoots[selectedScaleRoot]),
//                              scaleType: getTypes()[self.selectedScaleType],
//                              octaves: Settings.shared.defaultOctaves, hand: hands[self.selectedHand],
//                              minTempo: 90, dynamicType: .mf, articulationType: .legato)
            let _ = ScalesModel.shared.setScale(scale: boardGrade.getScales()[index])
        }
    }

    func startSpinning3Wheels(scaleTypes:[String], scaleRoots:[String], hands:[Int]) {
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
                              scaleType: getTypes()[self.selectedScaleType], scaleMotion: .similarMotion,
                              octaves: Settings.shared.defaultOctaves, hands: hands,
                              minTempo: 90, dynamicType: .mf, articulationType: .legato)
            let _ = ScalesModel.shared.setScale(scale: scale)
        }
    }

    var body: some View {
        VStack {
            TitleView(screenName: "Spin The Scales Wheel").commonFrameStyle()
            VStack {
                ZStack {
                    GeometryReader { geometry in
                        let handSizeFactor = 0.25
                        let rootSizeFactor = 0.40
                        let arrowPos = geometry.size.width * 0.92
                        ZStack {
                            if true {
                                SegmentedCircleView(elements: getScaleNames(), rotation: rotation, wheelSize: wheelSize * geometry.size.width)
                                    .frame(width: wheelSize * geometry.size.width, height: wheelSize * geometry.size.width)
                                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                                /// Fixed arrow
                                Arrow()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                                    .position(x: arrowPos, y: geometry.size.height * 0.5)
                            }
                            else {
                                ///Three independent wheels
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
                    }
                    .edgesIgnoringSafeArea(.all)
                }

                if [SpinState.notStarted, SpinState.selectedBet].contains(scalesModel.spinState) {
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                //startSpinning3Wheels(scaleTypes: self.getTypeNames(),scaleRoots: self.getRootNames(),hands: [1,0])
                                startSpinningWheel(scaleNames: getScaleNames())
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
                        let name = scale.getScaleName(handFull: true, octaves: true)
                        Text(" Go To Scale \(name) - Good Luck 😊").padding()
                            .font(.title2)
                            .hilighted(backgroundColor: .blue)
                    }
                }
                Spacer()
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.backgroundColor)
            //.frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.8)
        }
        .onAppear() {
            scalesModel.setSpinState1(.notStarted)
            self.wheelSize = DeviceOrientationObserver().orientation.isAnyLandscape ? 0.55 : 0.9
        }
        ///Block the back button for a badge attempt
        //.navigationBarBackButtonHidden(scalesModel.spinState == .spunAndStopped)
    }
    
}

