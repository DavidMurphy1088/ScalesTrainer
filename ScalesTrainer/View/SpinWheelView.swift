import SwiftUI

enum WheelMode {
    case pickRandomScale
    case identifyTheScale
}

struct SpinWheelView: View {
    let practiceJournal:PracticeJournal
    let mode: WheelMode
    enum SpinState {
        case notStarted
        case spinning
        case stopped
    }
    @State private var spinState:SpinState = .notStarted
    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 5 // Duration in seconds
    @State private var maxRotations: Double = 2 // Max rotations per second
    @State private var wheelSize: CGFloat = 0.8 // Size as a percentage of screen width
    @State private var selectedIndex = 0
    let width = 0.8
    @State var background = UIGlobals.shared.getBackground()
    
    func getScaleNames(mode:WheelMode) -> [String] {
        var allScales:[String] = []
        var roots:Set<String> = []
        for scale in practiceJournal.scaleGroup.scales {
            //roots.insert(scale.scaleType.description)
            roots.insert(scale.scaleRoot.name)
            allScales.append(scale.getName())
            //print(scale.getName(), scale.scaleType.description)
        }
        return mode == .pickRandomScale ? allScales : Array(roots) 
    }
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                VStack {
                    Text("Spin The Scale Wheel").font(.title)//.foregroundColor(.blue)
                }
                .commonTitleStyle()
                .frame(width: UIScreen.main.bounds.width * width)
                .padding()
                
                VStack {
                    GeometryReader { geometry in
                        ZStack {
                            SegmentedCircleView(elements: getScaleNames(mode:mode), rotation: rotation, wheelSize: wheelSize * geometry.size.width)
                                .frame(width: wheelSize * geometry.size.width, height: wheelSize * geometry.size.width)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            // Fixed arrow
                            Arrow()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.purple)
                                .position(x: geometry.size.width * 0.92, y: geometry.size.height / 2)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)

                    Spacer()
                    if spinState == .notStarted {
                        Button(action: {
                            startSpinning(elements: getScaleNames(mode:mode))
                        }) {
                            HStack {
                                Text("Spin")
                                    .padding()
                                    .font(.title2)
                                    .hilighted(backgroundColor: .blue)
                            }
                        }
                    }
                    if spinState == .stopped {
                        NavigationLink(destination: ScalesView(practiceJournalScale: practiceJournal.scaleGroup.scales[self.selectedIndex])) {
                            Text(" Go To Scale \(practiceJournal.scaleGroup.scales[self.selectedIndex].getName())").padding() //.foregroundStyle(Color .blue) //.hilighted(backgroundColor: .blue)
                                .font(.title2)
                                .hilighted(backgroundColor: .blue)
                        }
                        
                    }
                    Spacer()
                }
                .commonFrameStyle(backgroundColor: .white)
                .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.7)
                Spacer()
            }
        }
        .onAppear() {
            spinState = .notStarted
            background = UIGlobals.shared.getBackground()
        }
    }

    func startSpinning(elements:[String]) {
        spinState = .spinning
        let totalRotations = maxRotations * totalDuration * 360 // Total rotation in degrees
        let randomAngle = Double.random(in: 0..<360) // Random angle to add to the final rotation

        withAnimation(Animation.timingCurve(0.5, 0, 0.5, 1, duration: totalDuration)) {
            rotation += totalRotations + randomAngle
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            spinState = .stopped
            // Adjust to ensure the rotation ends at a random position
            rotation = rotation.truncatingRemainder(dividingBy: 360)
            // Determine which segment is at the top
            let segmentAngle = 360.0 / Double(elements.count)
            let index = Int((360 - rotation) / segmentAngle) % elements.count
            self.selectedIndex = index
            print("Top segment: \(elements[index])")
        }
    }
}

struct SegmentedCircleView: View {
    let elements: [String]
    let rotation: Double
    let wheelSize: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<elements.count) { index in
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
    let size = 40
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

