import SwiftUI

enum WheelMode {
    case pickRandomScale
    case identifyTheScale
}

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


struct SpinWheelView: View {
    let practiceJournal:PracticeJournal
    let mode: WheelMode
    enum SpinState {
        //case notStarted
        case betting
        case betted
        case spun
        case stopped
    }
    @State private var spinState:SpinState = .betting
    @State private var rotation: Double = 0
    @State private var totalDuration: Double = 3 // Duration in seconds
    @State private var maxRotations: Double = 1 // Max rotations per second
    @State private var wheelSize: CGFloat = 0.8 // Size as a percentage of screen width
    @State private var selectedIndex = 0
    @State private var width = 0.0 //DeviceOrientationObserver().orientation.isAnyLandscape ? 0.5 : 0.8

    @State var background = UIGlobals.shared.getBackground()
    @State private var selectedBet:Int = 0
    @State private var betSizes:[Int] = []

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
    
    func getTitle() -> String {
        var title = "Scales for \(practiceJournal.title)"
        let name = Settings.shared.firstName
        if name.count > 0 {
            title = name + "'s \(title)"
        }
        return title
    }
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                Text(getTitle()).font(.title).commonTitleStyle()
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
                    CoinStackView(showBet: false, showMsg: true, scalingSize: 50)
                        .padding()
                        .hilighted(backgroundColor: .blue)

                    if [.betting, .betted].contains(spinState) {
                        if let practiceJournal = PracticeJournal.shared {
                            VStack {
                                //CoinStackView(practiceJournal: practiceJournal, scalingSize: 30)
                                Picker("Select a number", selection: $selectedBet) {
                                    ForEach(betSizes, id: \.self) { num in
                                        Text(num == 0 ? "None" : "\(num)").bold().foregroundColor(Color.blue)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .clipShape(RoundedRectangle(cornerRadius: 10))  // Clip the background to rounded corners
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)  // Shape to use as the border
                                    .stroke(Color.gray, lineWidth: 2)  // Gray border with a width of 2
                                )
                                .onChange(of: selectedBet) { oldValue, newValue in
                                    spinState = newValue > 0 ? .betted : .betting
                                }
                                .padding()
                                HStack {
                                    Spacer()
                                    HStack {
                                        Text("Spin For How Many Coins?")
                                            .padding()
                                            .font(.title2)
                                    }
                                    
                                    if spinState == .betted {
                                        Spacer()
                                        Button(action: {
                                            CoinBank.shared.lastBet = selectedBet
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
                                    Spacer()
                                }
                            }
                        }
                    }

                    if spinState == .stopped {
                        NavigationLink(destination: ScalesView(practiceJournalScale: practiceJournal.scaleGroup.scales[self.selectedIndex], runProcess: .recordingScale)) {
                            Text(" Go To Scale \(practiceJournal.scaleGroup.scales[self.selectedIndex].getName())").padding() //.foregroundStyle(Color .blue) //.hilighted(backgroundColor: .blue)
                                .font(.title2)
                                .hilighted(backgroundColor: .blue)
                        }
                        
                    }
                    Spacer()
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * width, height: UIScreen.main.bounds.height * 0.9)
        }
        .onAppear() {
            betSizes = Array(0...CoinBank.shared.total / 2)
            spinState = .betting
            background = UIGlobals.shared.getBackground()
            width = DeviceOrientationObserver().orientation.isAnyLandscape ? 0.45 : 0.9
        }
    }

    func startSpinning(elements:[String]) {
        spinState = .spun
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
            //print("Top segment: \(elements[index])")
        }
    }
}

