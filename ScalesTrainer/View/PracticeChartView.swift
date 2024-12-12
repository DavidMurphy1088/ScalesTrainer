import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

struct BlankCellView: View {
    var cellWidth: CGFloat
    var cellHeight: CGFloat

    var body: some View {
        VStack {
        }
        .frame(width: cellWidth) //, height: cellHeight)
    }
}

struct CellView: View {
    let column:Int
    let practiceChart:PracticeChart
    @ObservedObject var practiceCell: PracticeChartCell
    var cellWidth:CGFloat
    var cellHeight:CGFloat
    var cellPadding:CGFloat
    @Binding var opacityValue:Double
    @Binding var showHands: Bool
    
    var barHeight = 8.0
    @State private var sheetHeight: CGFloat = .zero
    @State var navigateToScale = false
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
    
    func determineNumberOfBadges() -> Int {
        return Int.random(in: 0..<3)
    }
    
    func setHilighted(scale:Scale) {
        for row in practiceChart.rows {
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
    
    func handsView() -> some View {
        HStack {
            Image("hand_left")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.purple)
                .opacity(0.5)
                .scaledToFit()
                .frame(height: 25)
            
            Button(action: {
                //self.handPicked = .left
                setScale(hands: [1])
                if practiceCell.isLicensed {
                    navigateToScale = true
                }
            }) {
                HStack {
                    Text("Left Hand").font(.body)
                }
            }
            .buttonStyle(.bordered)
            Image("hand_right")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.purple)
                .opacity(0.5)
                .scaledToFit()
                .frame(height: 25)
            Button(action: {
                //self.handPicked = .right
                setScale(hands:[0])
                if practiceCell.isLicensed {
                    navigateToScale = true
                }
            }) {
                let label = practiceCell.scale.getScaleName(handFull: true)
                HStack {
                    Text("Right Hand").font(.callout)
                }
            }
            .buttonStyle(.bordered)
        }
        .opacity(opacityValue)
    }
    
    func setScale(hands:[Int]) {
        ScalesModel.shared.setScaleByRootAndType(scaleRoot: practiceCell.scale.scaleRoot, scaleType: practiceCell.scale.scaleType,
                                                 scaleMotion: practiceCell.scale.scaleMotion,
                                                 minTempo: practiceCell.scale.minTempo, octaves: practiceCell.scale.octaves,
                                                 hands: hands, ctx: "PracticeChart",
                                                 scaleCustomisation:practiceCell.scale.scaleCustomisation)
    }
    
    func starView() -> some View {
        HStack {
            NavigationLink(destination: ScalesView(practiceChartCell: practiceCell), isActive: $navigateToScale) {
            }.frame(width: 0.0)

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
    }
    
    func getMinBadgeIndex() -> Int {
        var min = self.practiceCell.badges.count - 5
        if min < 0  {
            min = 0
        }
        return min
    }
    
    func badgeView() -> some View {
        HStack {
            ForEach(0..<practiceCell.badges.count, id: \.self) {index in
                if index < self.getMinBadgeIndex() {
                    if index == 0 {
                        Text(" \(practiceCell.badges.count)..").font(.title2)
                    }
                }
                else {
                    Image(practiceCell.badges[index].imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                }
            }
        }
        .opacity(opacityValue)
    }

    var body: some View {
        VStack {
            Button(action: {
                setScale(hands: practiceCell.scale.hands)
                if practiceCell.isLicensed {
                    navigateToScale = true
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
            
            if practiceCell.scale.hands.count == 2 {
                if self.showHands {
                    handsView()
                }
            }
            
            //Spacer()
            starView()
            Spacer()
            badgeView()
            
            Spacer()
            //.border(.red)
        }
        .frame(width: cellWidth) //, height: cellHeight)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2)
        )
        .onAppear() {
            //self.handPicked = nil
        }
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
    @State private var showHands = false
    
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
        GeometryReader { geometry in
            ///Tried using GeometryReader since it supposedly reacts to orientation changes.
            ///But using it casues all the child view centering not to work
            //let screenWidth = UIScreen.main.bounds.width
            //let screenHeight = UIScreen.main.bounds.height
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
            let cellHeight: CGFloat = screenHeight / 12.0
            
            let cellPadding = cellWidth * 0.015 // 2% of the cell width as padding
            let minorScaleTypes:[String] = ["Harmonic", "Natural", "Melodic"]
            
            VStack {
                VStack(spacing: 0) {
                    TitleView(screenName: "Practice Chart", showGrade: true).commonFrameStyle()
                        .accessibilityIdentifier("chart_title")
                    HStack {
                        Spacer()
                        let title = UIDevice.current.userInterfaceIdiom == .phone ? "Minor" : "MinorType"
                        Text(LocalizedStringResource("\(title)")).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .body).padding(0)
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
                        Text("\(self.redrawCounter)").opacity(0.0).padding(0)
                        
                        if UIDevice.current.userInterfaceIdiom != .phone {
                            Spacer()
                            Button(action: {
                                helpShowing = true
                            }) {
                                Text("Instructions")
                            }
                            .buttonStyle(.bordered)
                            //.padding()
                        }
                        
                        Spacer()
                        Button(action: {
                            self.showHands.toggle()
                        }) {
                            Text(self.showHands ? "Hide Hands" : "Show Hands")
                        }
                        .buttonStyle(.bordered)
                        //.padding()
                        
                        Spacer()
                        Button(action: {
                            cellOpacityValue = 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                sleep(1)
                                doShuffle(update: true)
                                withAnimation(.linear(duration: 1.0)) {
                                    cellOpacityValue = 1.0
                                }
                                practiceChart.saveToFile()
                            }
                        }) {
                            Text("Shuffle")
                        }
                        .buttonStyle(.bordered)
                        //.padding()
                        
//                        if Settings.shared.isDeveloperMode() {
//                            Spacer()
//                            Button(action: {
//                                practiceChart.deleteFile()
//                            }) {
//                                Text("Delete")
//                            }
//                            .buttonStyle(.bordered)
//                            //.padding()
//                        }
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
                        ForEach(0..<practiceChart.rows.count, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<practiceChart.columns, id: \.self) { column in
                                    if column < practiceChart.rows[row].count {
                                        CellView(column: column, practiceChart: practiceChart, practiceCell: practiceChart.rows[row][column],
                                                 cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding, opacityValue: $cellOpacityValue, showHands: $showHands)
                                        .padding(cellPadding)
                                    }
                                    else {
                                        BlankCellView(cellWidth: cellWidth, cellHeight: cellHeight)
                                        .padding(cellPadding)
                                    }
                                }
                            }
                        }
                    }
                    .id(reloadTrigger)
                }
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
