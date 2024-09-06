import SwiftUI

struct CellView: View {
    let column:Int
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
    
    var body: some View {
        VStack {
            Button(action: {
                ScalesModel.shared.setScale(scale:  practiceCell.scale)
                navigateToScales = true
            }) {
                let label = practiceCell.scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
                Text(label)
                    .foregroundColor(.blue)
            }
            .padding(self.padding)
            Spacer()
            HStack {
                NavigationLink(destination: ScalesView(), isActive: $navigateToScales) {
                }.frame(width: 0.0)
                
                HStack {
                    Button(action: {
                        practiceCell.setEnabled(way: !practiceCell.enabled)
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

struct PracticeChartView: View {
    @State private var practiceChart:PracticeChart
    var daysOfWeek:[String] = []
    let background = UIGlobals.shared.getBackground()
    
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
    
    var body: some View {
        ///Tried using GeometryReader since it supposedly reacts to orientation changes.
        ///But using it casues all the child view centering not to work
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
        let cellHeight: CGFloat = screenHeight / 12.0
        let cellPadding = cellWidth * 0.015 // 2% of the cell width as padding
        
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            
            VStack {
                TitleView(screenName: "Practice Chart")
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
                                    CellView(column: column, practiceCell: practiceChart.cells[row][column],
                                             cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding)
                                    .padding(cellPadding)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.9)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .onAppear() {
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
