import SwiftUI

struct CellView: View {
    let column:Int
    let practiceChart:PracticeChart
    @ObservedObject var practiceCell: PracticeChartCell
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    var cellPadding: CGFloat
    var barHeight = 8.0
    @State private var sheetHeight: CGFloat = .zero
    @State var navigateToScales = false
    let padding = 5.0
        
    func getColor() -> Color {
        return .green
    }
    
    func progress() -> Double {
        if Int.random(in: 0...3) == 0 {
            return 0.0
        }
        else {
            return Double.random(in: 0.3...0.6)
        }
    }
    
    func getHandStr(hand:Int) -> String {
        return hand == 0 ? "Right Hand" : "Left Hand"
    }
    
    func getDescr() -> String {
        //return self.practiceCell.scale.scaleRoot.name + " " + self.practiceCell.scaleType.description
        return self.practiceCell.scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic: false, articulation: false)
    }
    
    func determineNumberOfBadges() -> Int {
        return Int.random(in: 0..<3)
    }
    
    func setEnabled(scale:Scale) {
        for row in practiceChart.cells {
            for chartCell in row {
                if chartCell.scale.scaleRoot.name == scale.scaleRoot.name {
                    if chartCell.scale.hands == scale.hands {
                        if chartCell.scale.scaleType == scale.scaleType {
                            chartCell.setEnabled(way: !chartCell.enabled)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Button(action: {
                ScalesModel.shared.setScale(scale:  practiceCell.scale)
                navigateToScales = true
            }) {
                let label = practiceCell.scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
                Text(label)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(self.padding)
            Spacer()
            HStack {
                NavigationLink(destination: ScalesView(), isActive: $navigateToScales) {
                }.frame(width: 0.0)
                
                HStack {
                    Button(action: {
                        setEnabled(scale: practiceCell.scale)
                    }) {
                        let name = practiceCell.isActive ? "star.fill" : "star"
                        Image(systemName: name)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(red: 1.0, green: 0.843, blue: 0.0))
                            .frame(height: cellHeight * 0.5)
                    }
                    .padding(.vertical, 0)
                    .padding(.horizontal)
                }
                .padding(self.padding)
                .padding(.vertical, 0)
            }
            Spacer()
            //.border(.red)
        }
        .frame(width: cellWidth) //, height: cellHeight)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2)
        )
    }
}

struct Star: Identifiable {
    var id: UUID
    var xPosition: CGFloat
    var yPosition: CGFloat
    var size: CGFloat
    var duration: Double
}

struct PracticeChartView: View {
    @State private var practiceChart:PracticeChart
    var daysOfWeek:[String] = []
    @State var minorTypeIndex:Int = 0
    @State private var reloadTrigger = false
    @State private var stars: [Star] = []
    
    init(practiceChart:PracticeChart) {
        self.practiceChart = practiceChart
        self.daysOfWeek = getDaysOfWeek()
    }

    func getDaysOfWeek() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        guard let dayNames = dateFormatter.weekdaySymbols else {
            return []
        }
        let calendar = Calendar.current
        let todayIndex = calendar.component(.weekday, from: Date()) - 1 // Calendar component .weekday returns 1 for Sunday, 2 for Monday, etc.
        let reorderedDayNames = Array(dayNames[todayIndex...] + dayNames[..<todayIndex])
        return reorderedDayNames
    }
    
    // Function to add a falling star
    private func addFallingStar() {
        let star = Star(
            id: UUID(),
            xPosition: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            yPosition: -50, // Start above the top of the view
            size: CGFloat.random(in: 10...30),
            duration: Double.random(in: 2...4) // Fall duration
        )
        
        stars.append(star)

        // Move the star down the screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let index = stars.firstIndex(where: { $0.id == star.id }) {
                stars[index].yPosition = UIScreen.main.bounds.height + 50 // End below the bottom of the view
            }
        }
        
        // Remove the star after it has finished falling
        DispatchQueue.main.asyncAfter(deadline: .now() + star.duration) {
            stars.removeAll(where: { $0.id == star.id })
        }
    }
    
    var body: some View {
        ///Tried using GeometryReader since it supposedly reacts to orientation changes.
        ///But using it casues all the child view centering not to work
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
        let cellHeight: CGFloat = screenHeight / 12.0
        let cellPadding = cellWidth * 0.015 // 2% of the cell width as padding
        let minorScaleTypes:[String] = ["Harmonic", "Natural", "Melodic"]
        
//        ZStack {
//            Image(background)
//                .resizable()
//                .scaledToFill()
//                .edgesIgnoringSafeArea(.top)
//                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)

            VStack {
                VStack(spacing: 0) {
                    TitleView(screenName: "Practice Chart").commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
                    HStack {
                        Spacer()
                        Text(LocalizedStringResource("Minor Scale Type")).font(.title2).padding(0)
                        Picker("Select Value", selection: $minorTypeIndex) {
                            ForEach(minorScaleTypes.indices, id: \.self) { index in
                                Text("\(minorScaleTypes[index])")
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: minorTypeIndex, {
                            let newType:ScaleType
                            switch minorTypeIndex {
                            case 0:newType = .harmonicMinor
                            case 1:newType = .naturalMinor
                            default:newType = .melodicMinor
                            }
                            practiceChart.changeScaleTypes(oldTypes: [.harmonicMinor, .naturalMinor, .melodicMinor], newType: newType)
                            self.reloadTrigger = !self.reloadTrigger
                        })
                        Spacer()
                        Text(LocalizedStringResource("Shuffle")).font(.title2).padding(0)
                        Button(action: {
                            addFallingStar()
                            practiceChart.shuffle()
                        }) {
                            Text("Shuffle Practice Chart")
                        }
                        .padding()
                        Spacer()
                    }
                }
                .commonFrameStyle(backgroundColor: UIGlobals.shared.backgroundColor)

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        
                        // Column Headers
                        HStack(spacing: 0) {
                            ForEach(0..<practiceChart.columns, id: \.self) { index in
                                VStack {
                                    Text(self.daysOfWeek[index])
                                }
                                .frame(width: cellWidth, height: cellHeight / 1.5) // Smaller height for headers
                                .background(Color.gray)
                                .foregroundColor(.white).bold()
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .padding(cellPadding)
                            }
                        }
                        
                        ///Rows
                        ForEach(0..<practiceChart.rows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<practiceChart.columns, id: \.self) { column in
                                    CellView(column: column, practiceChart: practiceChart, practiceCell: practiceChart.cells[row][column],
                                             cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding)
                                    .padding(cellPadding)
                                }
                            }
                        }
                    }
                }
                .id(reloadTrigger)
                
            }
            .commonFrameStyle(backgroundColor: UIGlobals.shared.backgroundColor)
            //.frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.9)
//            ForEach(stars) { star in
//                Image(systemName: "star.fill")
//                //Circle()
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: star.size, height: star.size)
//                    .foregroundColor(.yellow)
//                    .position(x: star.xPosition, y: star.yPosition)
//                    .animation(.linear(duration: star.duration))
//            }
        //}
        //.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .onAppear() {
            practiceChart.getScales("View OnAppear")
        }
        .onDisappear() {
            practiceChart.savePracticeChartToFile(chart: practiceChart)
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
