import SwiftUI

struct CellView: View {
    @Binding var cellScale: Scale
    ///let description:String
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
    
    func getHandStr(hand:Int) -> String {
        return hand == 0 ? "Right Hand" : "Left Hand"
    }
    
    func getDescr() -> String {
        return self.cellScale.scaleRoot.name + " " + self.cellScale.scaleType.description
    }
    
    func determineNumberOfBadges() -> Int {

        return Int.random(in: 0..<3)
    }
    
    var body: some View {
        VStack {
            Button(action: {
                ScalesModel.shared.setScale(scale: cellScale)
                navigateToScales = true
            }) {
                let label = cellScale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic:false, articulation:false)
                Text(label)
                    .foregroundColor(.blue)
            }
            .padding(self.padding)
            
            NavigationLink(destination: ScalesView(), isActive: $navigateToScales) {
            }.frame(width: 0.0)
            
            HStack {
                Button(action: {
                    showingDetail = true
                }) {
                    Image(systemName: "note.text")
                        //.resizable()
                        //.scaledToFit()
                }
                .padding(.vertical, 0)
                .padding(.horizontal)
            }
            .padding(self.padding)
            
            HStack {
                let badges = determineNumberOfBadges()
                if badges > 0 {
                    ForEach(0..<badges, id: \.self) { _ in
                        Image("gold_star")
                            //.resizable()
                            //.scaledToFit()
                    }
                }
                else {
                    Image("gold_star")
                        //.resizable()
                        //.scaledToFit()
                        .opacity(0.0)
                }
            }
            .padding()
        }
        .frame(width: cellWidth) //, height: cellHeight)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .sheet(isPresented: $showingDetail) {
            VStack {

                let label = cellScale.scaleRoot.name + " " + cellScale.scaleType.description + ", " + (cellScale.hand == 0 ? "Right Hand" : "Left Hand")
                Text(label).font(.title).foregroundColor(.black)
                Text("Minimum ♩=70, mf, legato").font(.title2).foregroundColor(.black)
                
                VStack {
                    Text("Tips").font(.title).foregroundColor(.black)
                    Text("Legato - To play your scale legato, smoothly connect each note to the next without any breaks or gaps in sound, like you're gently flowing from one note to the other.").font(.title2).foregroundColor(.black)
                }.padding()
                
                VStack {
                    Text("Your Progress With \(self.getDescr())").font(.title).foregroundColor(.black)
                    Text("This view could show various progress assessments and notes for this scale...").font(.title2).foregroundColor(.black)
                    Text("📊").font(.title).padding()
                    Text("📈 ").font(.title).padding()
                    Text("📉").font(.title).padding()
                }.padding()

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
            
            VStack {
                TitleView(screenName: "Practice Chart")
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        
                        // Column Headers
                        HStack(spacing: 0) {
                            ForEach(0..<practiceChart.columns, id: \.self) { index in
                                VStack {
                                    //Text("Day \(index + 1)")
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
                                    CellView(cellScale: $practiceChart.cells[row][column],
                                             cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding)
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
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
