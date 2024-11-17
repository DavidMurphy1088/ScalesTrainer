import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

struct CellView: View {
    let column:Int
    let practiceChart:PracticeChart
    @ObservedObject var practiceCell: PracticeChartCell
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    var cellPadding: CGFloat
    @Binding var opacityValue: Double
    var barHeight = 8.0
    @State private var sheetHeight: CGFloat = .zero
    @State var navigateToScales = false
    @State var showLicenceRequiredScale = false
    @State var licenceRequiredMessage:String = ""
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
    
//    func getDescr() -> String {
//        //return self.practiceCell.scale.scaleRoot.name + " " + self.practiceCell.scaleType.description
//        return self.practiceCell.scale.getScaleName(handFull: true)
//    }
    
    func determineNumberOfBadges() -> Int {
        return Int.random(in: 0..<3)
    }
    
    func setHilighted(scale:Scale) {
        for row in practiceChart.cells {
            for chartCell in row {
                if chartCell.scale.scaleRoot.name == scale.scaleRoot.name {
                    if chartCell.scale.hands == scale.hands {
                        if chartCell.scale.scaleType == scale.scaleType {
                            chartCell.setHilighted(way: !chartCell.hilighted)
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Button(action: {
                ScalesModel.shared.setScaleByRootAndType(scaleRoot: practiceCell.scale.scaleRoot, scaleType: practiceCell.scale.scaleType,
                                                         scaleMotion: practiceCell.scale.scaleMotion,
                                                         minTempo: practiceCell.scale.minTempo, octaves: practiceCell.scale.octaves,
                                                         hands: practiceCell.scale.hands, ctx: "PracticeChart")
                if practiceCell.isLicensed {
                    navigateToScales = true
                }
                else {
                    self.showLicenceRequiredScale = true
                    self.licenceRequiredMessage = "A subscription is required to access \n" + practiceCell.scale.getScaleName(handFull: true)
                }
            }) {
                let label = practiceCell.scale.getScaleName(handFull: true)
                HStack {
                    Text(label)
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title2)
                        .foregroundColor(practiceCell.isLicensed ? .blue : .gray)
                        .opacity(opacityValue)
                    if !practiceCell.isLicensed {
                        Image(systemName: "lock")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.gray)
                        .frame(height: cellHeight * 0.3)
                    }
                }
            }
            .padding(self.padding)

            Spacer()
            HStack {
                //if practiceCell.isLicensed {
                    NavigationLink(destination: ScalesView(initialRunProcess: nil, practiceChartCell: practiceCell), isActive: $navigateToScales) {
                    }.frame(width: 0.0)
                //}
                HStack {
                    Button(action: {
                        setHilighted(scale: practiceCell.scale)
                    }) {
                        let name = practiceCell.isActive ? "star.fill" : "star"
                        Image(systemName: name)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(red: 1.0, green: 0.843, blue: 0.0))
                            .frame(height: cellHeight * 0.4)
                    }
                    .padding(.vertical, 0)
                    .padding(.horizontal)
                }
                .padding(self.padding)
                .padding(.vertical, 0)
            }
            if Settings.shared.isDeveloperMode() {
                if Settings.shared.practiceChartGamificationOn  {
                    HStack {
                        ForEach(0..<practiceCell.badgeCount, id: \.self) { index in
                            Image("pet_dogface")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 30)
                        }
                    }
                }
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
        .alert(isPresented: $showLicenceRequiredScale) {
            Alert(
                title: Text("Subscription Required"),
                message: Text(self.licenceRequiredMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct PracticeChartView: View {
    @State private var practiceChart:PracticeChart
    var daysOfWeek:[String] = []
    @State var minorTypeIndex:Int = 0
    @State private var reloadTrigger = false
    @State private var redrawCounter = 0
    @State private var helpShowing = false
    @State private var cellOpacityValue: Double = 1.0
    
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
        //let todayIndex = calendar.component(.weekday, from: Date()) - 1 // Calendar component .weekday returns 1 for Sunday, 2 for Monday, etc.
        //let reorderedDayNames = Array(dayNames[todayIndex...] + dayNames[..<todayIndex])
        let reorderedDayNames = Array(dayNames[practiceChart.firstColumnDayOfWeekNumber...] + dayNames[..<practiceChart.firstColumnDayOfWeekNumber])
        return reorderedDayNames
    }
    
    func doShuffle(update:Bool) {
        for _ in 0..<24 {
            practiceChart.shuffle()
        }
        self.redrawCounter += 1
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
        
        VStack {
            VStack(spacing: 0) {
                TitleView(screenName: "Practice Chart", showGrade: true).commonFrameStyle()
                HStack {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Spacer()
                        Text(LocalizedStringResource("Instructions")).font(.title2).padding(0)
                        Button(action: {
                            helpShowing = true
                        }) {
                            Text("Instructions")
                        }
                        .padding()
                    }

                    Spacer()
                    let title = UIDevice.current.userInterfaceIdiom == .phone ? "Minor" : "Minor Scale Type"
                    Text(LocalizedStringResource("\(title)")).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title2).padding(0)
                    Text("\(self.redrawCounter)").opacity(0.0).padding(0)
                    Picker("Select Value", selection: $minorTypeIndex) {
                        ForEach(minorScaleTypes.indices, id: \.self) { index in
                            Text("\(minorScaleTypes[index])").font(.body)
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
                        practiceChart.minorScaleType = minorTypeIndex
                        practiceChart.changeScaleTypes(oldTypes: [.harmonicMinor, .naturalMinor, .melodicMinor], newType: newType)
                        self.reloadTrigger = !self.reloadTrigger
                    })
                    
                    Spacer()
                    Button(action: {
                        cellOpacityValue = 0.1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            sleep(1)
                            doShuffle(update: true)
                            withAnimation(.linear(duration: 1.0)) {
                                cellOpacityValue = 1.0
                            }
                        }
                   }) {
                        Text("Shuffle")
                    }
                    .padding()
                    
//                    if Settings.shared.practiceChartGamificationOn {
//                        Spacer()
//                        Button(action: {
//                            practiceChart.reset()
//                        }) {
//                            Text("Reset")
//                        }
//                        .padding()
//                    }

                    Spacer()
                }
            }
            .commonFrameStyle()

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    
                    // Column Headers
                    HStack(spacing: 0) {
                        ForEach(0..<practiceChart.columns, id: \.self) { index in
                            VStack {
                                Text(self.daysOfWeek[index])
                            }
                            .frame(width: cellWidth, height: cellHeight / 1.5) // Smaller height for headers
                            .background(index == practiceChart.todaysColumn ? Color.blue : Color.gray)
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
                                         cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding, opacityValue: $cellOpacityValue)
                                .padding(cellPadding)
                            }
                        }
                    }
                }
                .id(reloadTrigger)
            }
        }
        .commonFrameStyle()
        
        .onAppear() {
            minorTypeIndex = practiceChart.minorScaleType
        }
        .onDisappear() {
            practiceChart.saveToFile()
        }
        .sheet(isPresented: $helpShowing) {
            HelpView(topic: "Practice Chart")
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
