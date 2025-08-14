import SwiftUI

enum SpinState {
    case notStarted
    case selectedBet
    case spinning
    case spunAndStopped
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

struct SegmentView: View {
    let index: Int
    let total: Int
    let text: String
    let wheelSize: CGFloat
    let posx:CGFloat
    let posy: CGFloat
    
    var body: some View {
        let angle = 360.0 / Double(total)
        let startAngle = angle * Double(index)
        let endAngle = startAngle + angle
        let radius = wheelSize / 2

        return ZStack {
            Path { path in
                let center = CGPoint(x: posx, y: posy)
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: endAngle), clockwise: false)
            }
            .fill(Color(hue: Double(index) / Double(total), saturation: 0.8, brightness: 0.8))
            ///Segment outline
            .overlay(
                Path { path in
                    let center = CGPoint(x: posx, y: posy)
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: endAngle), clockwise: false)
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 2)
            )

            Text("\(  text)") ///push start of title away from center
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption : .title3).bold(true)
                .foregroundColor(.white)
                .rotationEffect(.degrees((startAngle + endAngle) / 2))
                .position(x: posx + CGFloat(radius / 2 * cos((startAngle + angle / 2) * .pi / 180)),
                          y: posy + CGFloat(radius / 2 * sin((startAngle + angle / 2) * .pi / 180)))
        }
    }
}

struct SegmentedCircleView: View {
    let elements: [String]
    let rotation: Double
    let wheelSize: CGFloat
    
    var body1: some View {
        VStack {
            Text("SC")
        }
        .rotationEffect(.degrees(rotation))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                    //if index == 0 {
                        SegmentView(index: index, total: elements.count, text: elements[index], wheelSize: wheelSize,
                                    posx:geometry.size.width/2, posy:geometry.size.height/2)
                        //.position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
                    //}
                }
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

struct SpinWheelView: View {
    @Environment(\.dismiss) var dismiss
    let user:User
    @ObservedObject var scalesModel = ScalesModel.shared
    @State var practiceChart:PracticeChart // = boardAndGrade.practiceChart
    @ObservedObject private var exerciseState = ExerciseState.shared
    
    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 3 // Duration in seconds
    @State private var maxRotations: Double = 1 // Max rotations per second
    
    @State private var wheelSize: CGFloat = 0

    @State private var selectedScaleType = 0
    @State private var selectedScaleRoot = 0
    @State private var selectedHand = 0
    @State var spinState:SpinState = .notStarted

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
            var name = ""
            if let customisation = scale.scaleCustomisation {
                if let customName = customisation.customScaleNameWheel {
                    name = customName
                }
            }
            if name.count == 0 {
                name = scale.getScaleName(handFull: false)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ///push outward from wheel center to avoid overcrowding
                    name = "         " + scale.abbreviateFileName(name: name)
                }
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
            self.spinState = .spunAndStopped
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
            self.spinState = .spunAndStopped
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
        VStack(spacing: 0) {
            ToolbarTitleView(screenName: "Spin The Wheel").padding(.vertical, 0)
            VStack {
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
                
                if [SpinState.notStarted, SpinState.selectedBet].contains(self.spinState) {
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                startSpinningWheel(scaleNames: getScaleNames())
                            }) {
                                HStack {
                                    Text(" Spin The Wheel ").fancyTextStyle()
                                }
                            }
                            //.compactButtonStyle(trim: false)
                        }
                        Spacer()
                    }
                }
                
                if self.spinState == SpinState.spunAndStopped {
                    let scale = scalesModel.scale
                    let practiceChartCell:PracticeChartCell? = practiceChart.getCellForScale(scale:scale)
                    NavigationLink(destination: ScalesView(user: user, practiceChart: practiceChart, practiceChartCell: practiceChartCell, practiceModeHand: nil)) {
                        let name = scale.getScaleName(handFull: true, octaves: true)
                        Text(" Go To Scale \(name) - Good Luck 😊").padding()
                            .font(.title2)
                            .hilighted(backgroundColor: .blue)
                    }
                }
                Spacer()
            }
            //.screenBackgroundStyle()
        }
        .onAppear() {
            self.spinState = .notStarted
            //self.wheelSize = orientationInfo.isPortrait ? 0.95 * UIScreen.main.bounds.width : 0.55 * UIScreen.main.bounds.width
            self.wheelSize = 0.45 * UIScreen.main.bounds.width
        }
        .onChange(of: ViewManager.shared.isSpinWheelActive) {oldValue, newValue in
            if newValue == false {
                dismiss()
            }
        }

        ///Block the back button for a badge attempt
        //.navigationBarBackButtonHidden(scalesModel.spinState == .spunAndStopped)
    }
}

