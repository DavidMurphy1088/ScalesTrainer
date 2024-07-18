import SwiftUI

// Define the model
struct PracticeCell {
    var content: String
    var selected: Bool
}

struct PracticeChart {
    var rows: Int
    var columns: Int
    var cells: [[PracticeCell]]
    
    init(rows: Int, columns: Int, scaleNames: [[String]]) {
        self.rows = rows
        self.columns = columns
        self.cells = Array(repeating: Array(repeating: PracticeCell(content: "", selected: false), count: columns), count: rows)
        
        for row in 0..<rows {
            for column in 0..<columns {
                if row < scaleNames.count && column < scaleNames[row].count {
                    cells[row][column] = PracticeCell(content: scaleNames[row][column], selected: false)
                }
            }
        }
    }
    
    mutating func updateCell(row: Int, column: Int, content: String, selected: Bool) {
        guard row < rows, column < columns else { return }
        cells[row][column] = PracticeCell(content: content, selected: selected)
    }
}

// Define the view
struct PracticeChartView: View {
    @State private var practiceChart: PracticeChart
    var daysOfWeek:[String] = []
    let background = UIGlobals.shared.getBackground()
    
    init(rows: Int, columns: Int) {
        let scaleNames = [
            ["E major RH", "E major LH", "E Major hands together"],
            ["A Minor", "E Minor", "B Minor"],
            ["F Major", "Bb Major", "Eb Major"],
            ["D Minor", "G Minor", "C Minor"]
        ]
        _practiceChart = State(initialValue: PracticeChart(rows: rows, columns: columns, scaleNames: scaleNames))
        self.daysOfWeek = getDaysOfWeek()
    }

    func getDaysOfWeek() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        guard let dayNames = dateFormatter.weekdaySymbols else {
            return [] // Return an empty array if weekdaySymbols is nil
        }
        
        // Get today's day index
        let calendar = Calendar.current
        let todayIndex = calendar.component(.weekday, from: Date()) - 1 // Calendar component .weekday returns 1 for Sunday, 2 for Monday, etc.
        
        // Create the reordered array
        let reorderedDayNames = Array(dayNames[todayIndex...] + dayNames[..<todayIndex])
        
        return reorderedDayNames
    }
    
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
        
            let screenWidth = UIScreen.main.bounds.width //geometry.size.width
            let screenHeight = UIScreen.main.bounds.height
            let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
            let cellHeight: CGFloat = screenHeight / 12.0
            let cellPadding = cellWidth * 0.015 // 2% of the cell width as padding
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Column Headers
                    HStack(spacing: 0) {
                        ForEach(0..<practiceChart.columns, id: \.self) { index in
                            VStack {
                                Text("Day \(index + 1)")
                                Text(self.daysOfWeek[index])
                            }
                            .frame(width: cellWidth, height: cellHeight / 1.5) // Smaller height for headers
                            //.background(Color.gray.opacity(0.2))
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
                    
                    // Rows
                    ForEach(0..<practiceChart.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<practiceChart.columns, id: \.self) { column in
                                CellView(cell: $practiceChart.cells[row][column], cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding)
                                    .padding(cellPadding)
                            }
                        }
                    }
                }
            }
            .padding(cellPadding)
        }
    }
}

struct CellView: View {
    @Binding var cell: PracticeCell
    @State private var showingDetail = false
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    var cellPadding: CGFloat
    var barHeight = 8.0
    @State private var sheetHeight: CGFloat = .zero

    func barWidth(_ factor:Double) -> CGFloat {
        return (cellWidth / 2.0) * factor
    }
    
    func getColor() -> Color {
        return .green
    }
    
    func progress() -> Double {
        if Int.random(in: 0...1) == 0 {
            return 0.0
        }
        else {
            return Double.random(in: 0.0...0.6)
        }
    }
    
    var body: some View {
        VStack {
            NavigationLink(destination: ScalesView(initialRunProcess: RunningProcess.none)) {
                Text(cell.content)
                    .padding(5)
                    .foregroundColor(.black)
            }
            .simultaneousGesture(TapGesture().onEnded {
                let _ = ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: "C"), scaleType: .major, octaves: Settings.shared.defaultOctaves, hand: 0))
            })

            Button(action: {
                        self.showingDetail = true
            }) {
                VStack {
                    HStack {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(width: barWidth(1.0), height: barHeight)
                            
                            Rectangle()
                                .fill(getColor())
                                .frame(width: barWidth(progress()), height: barHeight)
                        }
                    }
                }
            }
            //.padding()
            Toggle(isOn: $cell.selected) {
                Text("Completed")
                    .foregroundColor(.black)
            }
            .padding(5)
        }
        .frame(width: cellWidth, height: cellHeight) // Adjusted dimensions for cells
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .sheet(isPresented: $showingDetail) {
            VStack {
                Text("Title")
                Text("Some very long text ...")
            }
            .padding()
            .overlay {
                GeometryReader { geometry in
                    Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                }
            }
            .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                sheetHeight = newHeight
            }
            .presentationDetents([.height(sheetHeight)])
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
