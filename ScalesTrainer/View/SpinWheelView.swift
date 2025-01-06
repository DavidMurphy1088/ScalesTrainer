import SwiftUI

struct SpinWheelView: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    @ObservedObject var scalesModel = ScalesModel.shared
    @State var practiceChart:PracticeChart // = boardAndGrade.practiceChart
    
    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 3 // Duration in seconds
    @State private var maxRotations: Double = 1 // Max rotations per second
    
    @State private var wheelSize: CGFloat = 0

    @State private var selectedScaleType = 0
    @State private var selectedScaleRoot = 0
    @State private var selectedHand = 0

    func getRootNames() -> [String] {
        var scaleRoots:Set<String> = []
        for scale in practiceChart.getScales() {
            scaleRoots.insert(scale.scaleRoot.name)
        }
        return Array(scaleRoots).sorted()
    }
    
    func getTypes() -> [ScaleType] {
        var scaleTypes:Set<ScaleType> = []
        for scale in practiceChart.getScales() {
            scaleTypes.insert(scale.scaleType)
        }

        return Array(scaleTypes).sorted()
    }
    
    func getScaleNames() -> [String] {
        var res:[String] = []

        for scale in practiceChart.getScales() {
            var name = scale.getScaleName(handFull: false)
            if UIDevice.current.userInterfaceIdiom == .phone {
                ///push outward from wheel center to avoid overcrowding
                name = "         " + scale.abbreviateFileName(name: name)
            }
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
        
    func startSpinningWheel(scaleNames:[String]) {
        let totalRotations = maxRotations * totalDuration * 360 // Total rotation in degrees
        let randomAngle = Double.random(in: 0..<360) // Random angle to add to the final rotation
        withAnimation(Animation.timingCurve(0.5, 0, 0.5, 1, duration: totalDuration)) {
            rotation += totalRotations + randomAngle
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            scalesModel.setSpinState(.spunAndStopped)
            // Adjust to ensure the rotation ends at a random position
            rotation = rotation.truncatingRemainder(dividingBy: 360)
            
            // Determine which segment is at the top
            //let segments = 360.0 / Double(scaleNames.count)
            //let index = (Int((360 - rotation) / segments) + 12) % scaleNames.count
            //let index = (Int(rotation / segments) + 12) % scaleNames.count
            
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
            let _ = ScalesModel.shared.setScale(scale: practiceChart.getScales()[index])
        }
    }

    func startSpinning3Wheels(scaleTypes:[String], scaleRoots:[String], hands:[Int]) {
        let totalRotations = maxRotations * totalDuration * 360 // Total rotation in degrees
        let randomAngle = Double.random(in: 0..<360) // Random angle to add to the final rotation
        withAnimation(Animation.timingCurve(0.5, 0, 0.5, 1, duration: totalDuration)) {
            rotation += totalRotations + randomAngle
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            scalesModel.setSpinState(.spunAndStopped)
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
                              minTempo: 90, dynamicTypes: [.mf], articulationTypes: [.legato])
            let _ = ScalesModel.shared.setScale(scale: scale)
        }
    }

    var body: some View {
        VStack {
            TitleView(screenName: "Spin The Scales Wheel", showGrade: true).commonFrameStyle()
            VStack {
                //let handSizeFactor = 0.25
                //let rootSizeFactor = 0.40
                //let arrowPos = UIScreen.main.bounds.width * (orientationInfo.isPortrait ? 0.94 : 0.76)
                ZStack {
                        SegmentedCircleView(elements: getScaleNames(), rotation: rotation, wheelSize: wheelSize)
                        /// Fixed arrow
                        Arrow()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.purple)
                            //.position(x: arrowPos)//, y: geometry.size.height * 0.5)
                            .offset(x: wheelSize * 0.5)
                }
                .edgesIgnoringSafeArea(.all)
                
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

                if scalesModel.spinStatePublished == SpinState.spunAndStopped {
                    let scale = scalesModel.scale
                    //let chartCell = PracticeChart.shared.getCellIDByScale(scale: scale)
                    NavigationLink(destination: ScalesView(practiceChartCell: nil)) {
                        let name = scale.getScaleName(handFull: true, octaves: true)
                        Text(" Go To Scale \(name) - Good Luck 😊").padding()
                            .font(.title2)
                            .hilighted(backgroundColor: .blue)
                    }
                }
                Spacer()
            }
            .commonFrameStyle()
        }
        .onAppear() {
            scalesModel.setSpinState(.notStarted)
            if let chart = MusicBoardAndGrade.shared?.practiceChart {
                self.practiceChart = chart
            }
            //self.wheelSize = orientationInfo.isPortrait ? 0.9 : 0.55
            self.wheelSize = orientationInfo.isPortrait ? 0.95 * UIScreen.main.bounds.width : 0.55 * UIScreen.main.bounds.width
        }

        ///Block the back button for a badge attempt
        //.navigationBarBackButtonHidden(scalesModel.spinState == .spunAndStopped)
    }
    
}

