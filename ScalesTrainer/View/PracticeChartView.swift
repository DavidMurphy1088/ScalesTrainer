import SwiftUI

// Define the model
struct PracticeCell {
    var scaleRoot: ScaleRoot
    var scaleType: ScaleType
    var hand:String
    var selected: Bool
}

class PracticeChart {
    static let shared = PracticeChart(rows: 10, columns: 3)
    var rows: Int
    var columns: Int
    var cells: [[PracticeCell]]
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
        self.cells = []
        let rowScales = [("E", ScaleType.major),
                         ("B", ScaleType.major),
                         ("E", ScaleType.harmonicMinor),
                         ("B", ScaleType.harmonicMinor),
                         ("E", ScaleType.melodicMinor),
                         ("B", ScaleType.harmonicMinor),
                         ("B", ScaleType.arpeggioMajor),
                         ("E", ScaleType.arpeggioMinor),
                         ("B", ScaleType.major),
                         ("A", ScaleType.major)
        ]
        for i in 0..<10 {
            let hands = ["RH", "LH", "Hands Together"].shuffled()
            var row:[PracticeCell] = []
            for j in 0..<3 {
                let k = i % rowScales.count
                row.append(PracticeCell(scaleRoot: ScaleRoot(name: rowScales[k].0), scaleType: rowScales[k].1, hand: hands[j], selected: false))
            }
            self.cells.append(row)
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
    @State var navigateToScales = false
    let padding = 5.0
    
    func barWidth(_ factor:Double) -> CGFloat {
        return (cellWidth / 2.0) * factor
    }
    
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
    
    var body: some View {
        VStack {
//            NavigationLink(destination: ScalesView(initialRunProcess: RunningProcess.none)) {
//                Text(cell.scaleRoot.name + " " + cell.scaleType.description + " " + cell.hand)
//                    .padding(5)
//                    .foregroundColor(.blue)
//            }
                
            Button(action: {
                let _ = ScalesModel.shared.setScale(scale: Scale(scaleRoot: ScaleRoot(name: cell.scaleRoot.name),
                                                                 scaleType: cell.scaleType,
                                                                 octaves: Settings.shared.defaultOctaves,
                                                                 hand: cell.hand == "LH" ? 1 : 0))
                navigateToScales = true
            }) {
                let label = cell.scaleRoot.name + " " + cell.scaleType.description + " " + cell.hand
                Text(label)
                    .foregroundColor(.blue)
            }
            .padding(self.padding)
                                
            NavigationLink(destination: ScalesView(), isActive: $navigateToScales) {
            }.frame(width: 0.0)

            VStack {
                HStack {
                    Text("Progress")
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
            .padding(self.padding)
            
            HStack {
                Button(action: {
                    showingDetail = true
                }) {
                    //Text("Notes").foregroundColor(.blue)
                    Image(systemName: "note.text")
                }
                .padding(.vertical, 0)
                .padding(.horizontal)
                Text("    ")
                Toggle(isOn: $cell.selected) {
                    Text("Completed").foregroundColor(.black).padding(.horizontal, 0).padding(.vertical, 0)
                }
            }
            .padding(self.padding)
            //.border(.red)

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
                let name = Settings.shared.firstName
                let name1 = name + (name.count>0 ? "'s" : "")
                Text("\(name1) Notes").font(.title).foregroundColor(.blue)
                let label = cell.scaleRoot.name + " " + cell.scaleType.description //+ " " + cell.hand
                Text(label).font(.title).foregroundColor(.black)
                Text("📈 📉 📊").font(.title).padding()
                Text("Various progress assessments and notes for this scale...").padding()
//                .overlay {
//                    GeometryReader { geometry in
//                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
//                    }
//                }
//                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
//                    sheetHeight = newHeight
//                }
                .presentationDetents([.height(sheetHeight)])
            }
        }
    }
}

struct PracticeChartView: View {
    @State private var practiceChart = PracticeChart.shared
    var daysOfWeek:[String] = []
    let background = UIGlobals.shared.getBackground()
    
    init(rows: Int, columns: Int) {
        //_practiceChart = State(initialValue: PracticeChart(rows: rows, columns: columns, scaleNames: scaleNames))
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
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            
            let screenWidth = UIScreen.main.bounds.width //geometry.size.width
            let screenHeight = UIScreen.main.bounds.height
            let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
            let cellHeight: CGFloat = screenHeight / 9.0
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
                    
                    ///Rows
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

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
