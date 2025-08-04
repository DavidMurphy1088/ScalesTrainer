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

struct SelectHandForPractice: View {
    let user:User
    let practiceChart:PracticeChart
    let practiceCell:PracticeChartCell
    let scale:Scale
    @State var practiceModeHand:HandType?
    @State var navigateToScale = false
    let imageSize = UIScreen.main.bounds.size.width * 0.05
    
    init(user:User, practiceChart:PracticeChart, practiceCell:PracticeChartCell) {
        self.user = user
        self.practiceChart = practiceChart
        self.practiceCell = practiceCell
        self.scale = practiceCell.scale
    }
    
    func setScale(practiceHands:[Int]) {
        ScalesModel.shared.setScaleByRootAndType(scaleRoot: practiceCell.scale.scaleRoot, scaleType: practiceCell.scale.scaleType,
                                                 scaleMotion: practiceCell.scale.scaleMotion,
                                                 minTempo: practiceCell.scale.minTempo, octaves: practiceCell.scale.octaves,
                                                 hands: practiceHands,
                                                 dynamicTypes: practiceCell.scale.dynamicTypes,
                                                 articulationTypes: practiceCell.scale.articulationTypes,
                                                 ctx: "PracticeChartHands",
                                                 scaleCustomisation:practiceCell.scale.scaleCustomisation)
    }
    
    var body: some View {
        let nameFull = scale.getScaleName(handFull: false)
        let name = scale.getScaleName(showHands: false, handFull: false)
        VStack(spacing: 0) {
            //VStack(spacing: 0) {
                Text(nameFull).font(.title)
            //}
            VStack(spacing: 0) {
                Text("In the exam \(nameFull) must be played with both hands.")
                Text("But here you can practise \(name) hands separately.")
            }
            .padding()
            Button(action: {
                setScale(practiceHands: [0,1])
                navigateToScale = true
                practiceModeHand = nil
            }) {
                VStack(spacing: 0)  {
                    HStack {
                        Image("hand_left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:imageSize)
                        Image("hand_right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:imageSize)
                    }
                    Text("Practise Hands Together")
                }
            }
            .padding()
            Text("")
            HStack {
                Button(action: {
                    setScale(practiceHands: [1])
                    practiceModeHand = .left
                    navigateToScale = true
                }) {
                    VStack {
                        Image("hand_left_orange")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:imageSize)
                        Text("Practise Left Hand")
                    }
                }
                .padding()
                Button(action: {
                    setScale(practiceHands: [0])
                    navigateToScale = true
                    practiceModeHand = .left
                }) {
                    VStack {
                        Image("hand_right_orange")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:imageSize)
                        Text("Practise Right Hand")
                    }
                }
                .padding()
            }

//            HStack(spacing: 40) {
//                Button("Cancel") {
//                }
//                .padding()
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(8)
//            }
        }
        .onAppear {
            //navigateToScale = false ///Having this here casues the back navigation to screw up. No idea why 😰
        }
        .navigationDestination(isPresented: $navigateToScale) {
            ScalesView(user: user, practiceChart: practiceChart,
                       practiceChartCell: practiceCell,
                       practiceModeHand: practiceModeHand)
        }
    }
}

struct CellView: View {
    let user:User
    let column:Int
    let practiceChart:PracticeChart
    @Binding var scalesInChart: [String]
    
    @ObservedObject var practiceCell: PracticeChartCell
    var cellWidth:CGFloat
    var cellHeight:CGFloat
    var cellPadding:CGFloat
    @Binding var opacityValue:Double
    @Binding var showHands: Bool
    
    var barHeight = 8.0
    @State private var sheetHeight: CGFloat = .zero
    @State var navigateToScaleDirectly = false
    @State var navigateToSelectHands = false
    @State var practiceModeHand:HandType? = nil
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
    
    func setStarred(scale:Scale) {
        for row in practiceChart.rows {
            for chartCell in row {
                if chartCell.scale.getScaleIdentificationKey() == scale.getScaleIdentificationKey(){
                    chartCell.setStarred(way: !chartCell.isStarred)
                }
            }
        }
    }

    
    func starView() -> some View {
        HStack {
            HStack {
                Button(action: {
                    setStarred(scale: practiceCell.scale)
                }) {
                    let name = practiceCell.isStarredPublished ? "star.fill" : "star"
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
            if practiceCell.badges.count > 0 {
                Text(" \(practiceCell.badges.count)").font(.custom("MarkerFelt-Wide", size: 24)).foregroundColor(.purple).bold()
//                    .padding(4) // Adds spacing so the text isn't touching the circle
//                        .background(
//                            Circle()
//                                .stroke(Color.purple, lineWidth: 2) 
//                        )
            }
            ForEach(0..<practiceCell.badges.count, id: \.self) {index in
                if index < self.getMinBadgeIndex() {
                    if index == 0 {
                        Text("..").font(.title2)
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
    
    func getName() -> String {
        var cellName = ""
        let scale = practiceCell.scale
        if scale.scaleType == .chromatic {
            
        }
        if let customisation = scale.scaleCustomisation {
            if let name = customisation.customScaleName {
                cellName = name
            }
        }
        if cellName.count == 0 {
            cellName = practiceCell.scale.getScaleName(handFull: true)
        }
        return cellName
    }
    
    ///Does this chart cell have its scale in the known-correct list
    func isCorrectSet() -> Bool {
        let name = practiceCell.scale.getScaleIdentificationKey()
        return self.scalesInChart.contains(name)
    }
    
    func setScale(requiredHands:[Int]) {
        ScalesModel.shared.setScaleByRootAndType(scaleRoot: practiceCell.scale.scaleRoot, scaleType: practiceCell.scale.scaleType,
                                                 scaleMotion: practiceCell.scale.scaleMotion,
                                                 minTempo: practiceCell.scale.minTempo, octaves: practiceCell.scale.octaves,
                                                 hands: requiredHands,
                                                 dynamicTypes: practiceCell.scale.dynamicTypes,
                                                 articulationTypes: practiceCell.scale.articulationTypes,
                                                 ctx: "PracticeChartHands",
                                                 scaleCustomisation:practiceCell.scale.scaleCustomisation)
    }
    
    var body: some View {
        VStack {
            Button(action: {
                if practiceCell.isLicensed {
                    if practiceCell.scale.hands.count == 1 {
                        let chartHands = practiceCell.scale.hands
                        if chartHands.count > 1 {
                            setScale(requiredHands: [0,1])
                        }
                        else {
                            setScale(requiredHands: [chartHands[0]])
                        }
                        navigateToScaleDirectly = true
                    }
                    else {
                        navigateToSelectHands = true
                    }
                }
                else {
                    self.showLicenceRequiredScale = true
                    self.licenceRequiredMessage = "A subscription is required to access \n" + practiceCell.scale.getScaleName(handFull: true)
                }
            }) {
                HStack {
                    Text(getName())
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
            
            //Spacer()
            starView()
            Spacer()
            badgeView()
            if Settings.shared.isDeveloperModeOn() {
                Button(action: {
                    if !isCorrectSet() {
                        ScalesModel.shared.setKeyboardAndScore(scale: practiceCell.scale, callback: {_,score in
                            //score.debug11(ctx: "", handType: .none)
                            Firebase.shared.writeKnownCorrect(scale: practiceCell.scale, score: score, board: practiceChart.board, grade: self.practiceChart.grade)
                        })
                        //self.isCorrectSet = true
                    }
                    else {
                        ScalesModel.shared.setKeyboardAndScore(scale: practiceCell.scale, callback: {_,score in
                            let key = practiceCell.scale.getScaleIdentificationKey()
                            Firebase.shared.deleteFromRealtimeDatabase(board: practiceChart.board, grade: self.practiceChart.grade, key: key,
                                                                       callback:{_ in })
                        })
                    }
                }) {
                    let correctSet = self.isCorrectSet()
                    Text(correctSet ? "Delete Correct" : "Set Correct").foregroundColor(correctSet ? .black : .red)
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .navigationDestination(isPresented: $navigateToScaleDirectly) {
            ScalesView(user:user, practiceChart: self.practiceChart, practiceChartCell: self.practiceCell, practiceModeHand: nil)
        }
        .navigationDestination(isPresented: $navigateToSelectHands) {
            SelectHandForPractice(user:user, practiceChart: practiceChart, practiceCell: practiceCell)
        }
        .frame(width: cellWidth) //, height: cellHeight)
        .background(Color.white)
        .cornerRadius(10)
        ///Border?
//        .overlay(
//            RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2)
//        )
        .onAppear() {
            let scaleName = self.practiceCell.scale.getScaleName(handFull: true, motion:true, octaves: true)
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

struct PracticeChartViewOld: View {
    @Environment(\.dismiss) var dismiss
    let user:User
    @State private var practiceChart:PracticeChart
    var daysOfWeek:[String] = []
    @State var minorTypeIndex:Int = 0
    @State private var reloadTrigger = false
    @State private var redrawCounter = 0
    @State private var helpShowing = false
    @State private var cellOpacityValue: Double = 1.0
    @State private var showHands = false
    @State var minorScaleTypes:[String] = []
    @State var scalesInChart:[String] = []
    
    init(user:User, practiceChart:PracticeChart) {
        self.user = user
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
        VStack(spacing: 0)  {
            //ScreenTitleView(screenName: "Practice Chart").padding(.vertical, 0)
            VStack {
                ///Tried using GeometryReader since it supposedly reacts to orientation changes.
                ///But using it casues all the child view centering not to work
                let screenWidth = UIScreen.main.bounds.size.width //geometry.size.width
                let screenHeight = UIScreen.main.bounds.size.height //geometry.size.height
                let cellWidth = (screenWidth / CGFloat(practiceChart.columns + 1)) * 1.2 // Slightly smaller width
                let cellHeight: CGFloat = screenHeight / 12.0
                let cellPadding = cellWidth * 0.015 // 2% of the cell width as padding
                VStack {
                    VStack(spacing: 0) {
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
                                case 1:newType = .melodicMinor
                                default:newType = .naturalMinor
                                }
                                practiceChart.minorScaleType = minorTypeIndex
                                practiceChart.changeScaleTypes(selectedTypes: [.harmonicMinor, .naturalMinor, .melodicMinor],
                                                               selectedMotions:[.similarMotion], newType: newType)
                                practiceChart.savePracticeChartToFile()
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
                                //.buttonStyle(.bordered)
                                //.padding()
                            }
                            
//                            Spacer()
//                            Button(action: {
//                                self.showHands.toggle()
//                            }) {
//                                if UIDevice.current.userInterfaceIdiom == .phone {
//                                    Text(self.showHands ? "Hide" : "Hands")
//                                }
//                                else {
//                                    Text(self.showHands ? "Hide Hands" : "Show Hands")
//                                }
//                            }
                            
                            Spacer()
                            Button(action: {
                                cellOpacityValue = 0.1
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    sleep(1)
                                    doShuffle(update: true)
                                    withAnimation(.linear(duration: 1.0)) {
                                        cellOpacityValue = 1.0
                                    }
                                    practiceChart.savePracticeChartToFile()
                                }
                            }) {
                                Text("Shuffle")
                            }
                            //.buttonStyle(.bordered)
                            //.padding()
                            
                            Spacer()
                        }
                        .outlinedStyleView()
                    }
                    
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
                        ScrollView(.vertical) {
                            ///Rows
                            ForEach(0..<practiceChart.rows.count, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<practiceChart.columns, id: \.self) { column in
                                        if column < practiceChart.rows[row].count {
                                            CellView(user: user, column: column, practiceChart: practiceChart, scalesInChart: $scalesInChart, practiceCell: practiceChart.rows[row][column],
                                                     cellWidth: cellWidth, cellHeight: cellHeight, cellPadding: cellPadding, opacityValue: $cellOpacityValue, showHands: $showHands)
                                            .outlinedStyleView()
                                            .padding(cellPadding)
                                        }
                                        else {
                                            BlankCellView(cellWidth: cellWidth, cellHeight: cellHeight)
                                                .outlinedStyleView()
                                                .padding(cellPadding)
                                        }
                                    }
                                }
                            }
                        }
                        .id(reloadTrigger)
                        //.frame(height: UIScreen.main.bounds.size.height * 0.67)
                        Spacer()
                    }
                }
                //.padding() ///DO NOT DELETE - else the scroller underlaps the TabView at bottom
            }
            .screenBackgroundStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //.navigationBarHidden(true)
        //.navigationViewStyle(StackNavigationViewStyle())
        .onAppear() {
            self.minorScaleTypes = self.practiceChart.grade == 1 ? ["Harmonic", "Melodic", "Natural"] : ["Harmonic", "Melodic"]
            minorTypeIndex = practiceChart.minorScaleType
            if Settings.shared.isDeveloperModeOn() {
                Firebase.shared.readAllScales(board: self.practiceChart.board, grade:self.practiceChart.grade) { scalesAndScores in
                    self.scalesInChart = scalesAndScores.map { $0.0 }
                }
            }
        }
        .onDisappear() {
        }
        .sheet(isPresented: $helpShowing) {
            HelpView(topic: "Practice Chart")
        }
        .onChange(of: ViewManager.shared.isPracticeChartActive) { newValue in
            if newValue == false {
                dismiss()
            }
        }
    }
}

struct PracticeChartView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Text("")
            Text("")
            Text("...Practice Chart somewhere here...")
            Spacer()
        }
        .commonToolbar(
            title: "Practice Chart",
            //showBackButton: true,
            //backTitle: "Activities",
            onBack: { dismiss() }
        )
    }
}
