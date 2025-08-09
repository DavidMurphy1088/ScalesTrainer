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
struct MinorTypePopup: View {
    let items: [String] = ["Harmonic Minor", "Melodic Minor", "Natural Minor"]
    @Binding var selectedItem: String?
    @Binding var isPresented: Bool
    var onDone: () -> Void
    
    @State private var tempSelection: String? = nil

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    if tempSelection == item {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle()) // make whole row tappable
                .onTapGesture {
                    tempSelection = item
                }
            }
            .navigationTitle("Select the Minor Type")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Done") {
                    selectedItem = tempSelection
                    isPresented = false
                    onDone()
                    
                }
                .disabled(tempSelection == nil) // disable until picked
            )
            .onAppear {
                tempSelection = selectedItem // show existing selection
            }
        }
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
    let practiceChart:PracticeChart
    @Binding var scalesInChart: [String]
    
    @ObservedObject var practiceCell: PracticeChartCell
    let cellWidth:CGFloat
    let cellHeight:CGFloat
    let cellPadding:CGFloat
    @Binding var opacityValue: Double
    @State var shuffleCount:Int

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
    
    func getMinBadgeIndex() -> Int {
        var min = self.practiceCell.badges.count - 5
        if min < 0  {
            min = 0
        }
        return min
    }
    
    func getName() -> String {
        var cellName = ""
//        let scale = practiceCell.scale
//        if scale.scaleType == .chromatic {
//            
//        }
//        if let customisation = scale.scaleCustomisation {
//            if let name = customisation.customScaleName {
//                cellName = name
//            }
//        }
        //if cellName.count == 0 {
        cellName = practiceCell.scale.getScaleName(handFull: false)
        //}
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
    
    func color(from string: String) -> Color {
        switch string.lowercased() {
        case "blue": return .blue
        case "cyan": return .cyan
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "white": return .white
        case "yellow": return .yellow
        default:
            return .clear // fallback if name is unrecognized
        }
    }

    var body: some View {
        Button(action: {
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
        }) {
            VStack {
                Text(getName())
                    .font(.headline)
                Text("C:\(shuffleCount)")
            }
            .padding()
            .foregroundColor(.black).opacity(opacityValue)
            .frame(width: cellWidth, height: cellHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color(from: practiceCell.color).opacity(opacityValue))
                    .shadow(color: .black.opacity(opacityValue), radius: 1, x: 4, y: 4)
            )
            .padding(.horizontal, cellPadding)
            .padding(.bottom, 8)   // <- room for shadow
            .padding(.trailing, 8) // <- room for shadow
            .navigationTitle("Practice Chart")

        }
        .navigationDestination(isPresented: $navigateToScaleDirectly) {
            ScalesView(user:user, practiceChart: self.practiceChart, practiceChartCell: self.practiceCell, practiceModeHand: nil)
        }
        .navigationDestination(isPresented: $navigateToSelectHands) {
            SelectHandForPractice(user:user, practiceChart: practiceChart, practiceCell: practiceCell)
        }
    }
    
    //    func badgeView() -> some View {
    //        HStack {
    //            if practiceCell.badges.count > 0 {
    //                Text(" \(practiceCell.badges.count)").font(.custom("MarkerFelt-Wide", size: 24)).foregroundColor(.purple).bold()
    //            }
    //            ForEach(0..<practiceCell.badges.count, id: \.self) {index in
    //                if index < self.getMinBadgeIndex() {
    //                    if index == 0 {
    //                        Text("..").font(.title2)
    //                    }
    //                }
    //                else {
    //                    Image(practiceCell.badges[index].imageName)
    //                        .resizable()
    //                        .scaledToFit()
    //                        .frame(height: 30)
    //                }
    //            }
    //        }
    //        .opacity(opacityValue)
    //    }
}

struct PracticeChartView: View {
    @Environment(\.dismiss) var dismiss
    @State private var user:User?
    @State private var practiceChart:PracticeChart?
    @State var currentDayOfWeekNum = 0
    @State var daysOfWeek = Array(0...6)
    @State var dayNames:[String] = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    @State var minorTypeIndex:Int = 0
    @State private var reloadTrigger = false
    @State private var redrawCounter = 0
    @State private var helpShowing = false
    @State private var showHands = false
    @State var minorScaleTypes:[String] = []
    @State var scalesInChart:[String] = []
    @State private var selectedDayColumn:Int = 0
    @State private var cellOpacity:Double = 1.0
    @State private var doShuffleCount:Int = 0
    @State private var showPopup = false
    @State private var minorTypeSelection: String? = nil
    
    func doShuffle() {
        if let practiceChart = practiceChart {
            practiceChart.shuffle()
            self.redrawCounter += 1
        }
    }
    
    struct SelectDayOfWeek: View {
        let dayNames:[String]
        let daysToShow:Int
        let currentDayOfWeekNum:Int
        @Binding var selectedDayColumn:Int
        @Binding var opacity:Double

        var body: some View {
            HStack(spacing: 12) {
                HStack {
                    ForEach(0..<daysToShow, id: \.self) { dayIndex in
                        let dayNameIndex = (currentDayOfWeekNum + dayIndex) % dayNames.count
                        Button(action: {
                            selectedDayColumn = dayIndex
//                            opacity = 0.0
//                            withAnimation(.easeIn(duration: 1.5)) {
//                                opacity = 0.6
//                            }
                        }) {
                            Text("\(dayNames[dayNameIndex])")
                                .foregroundColor(dayIndex == selectedDayColumn ? .white : .primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(dayIndex == selectedDayColumn ? Color.black : Color.clear)
                                )
                        }
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    var body: some View {
        VStack(spacing: 0)  {
            VStack {
                let screenWidth = UIScreen.main.bounds.size.width
                let screenHeight = UIScreen.main.bounds.size.height
                let cellWidth = screenWidth * 0.16
                let cellHeight = screenHeight * 0.1
                let cellPadding = screenWidth * 0.002
                let leftEdge = screenWidth * 0.04
                
                VStack {
                    Text("")
                    HStack {
                        FigmaButton(label: {
                            Text("Harmonic Minor")
                        }, action: {
                            showPopup = true
                            //selectedItem: String? = nil
                        })
                        FigmaButton(label: {
                            Text("Shuffle")
                        }, action: {
                            cellOpacity = 0.0
                            doShuffle()
                            withAnimation(.easeIn(duration: 3.0)) {
                                cellOpacity = 1.0
                            }
                            doShuffleCount += 1
                        })
                        Spacer()
                        SelectDayOfWeek(dayNames: self.dayNames, daysToShow: 3, currentDayOfWeekNum: self.currentDayOfWeekNum,
                                        selectedDayColumn: $selectedDayColumn, opacity: $cellOpacity)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                    }
                    .padding(.leading, leftEdge)
                    
                    Text("")
                    
                    VStack(spacing: 0) {
                        //ScrollView(.horizontal) {
                        let cellsPerRow = 5
                        if let practiceChart = self.practiceChart, let user = self.user {
                            HStack(spacing: 0) {
                                ///In the chart columns are days. e.g. column 0 is day 0, 1 is day 1 etc
                                
                                ForEach(0..<cellsPerRow, id: \.self) { row in
                                    if row < practiceChart.rows.count {
                                        if practiceChart.rows[row].count > selectedDayColumn {
                                            CellView(user: user,
                                                     practiceChart: practiceChart,
                                                     scalesInChart: $scalesInChart,
                                                     practiceCell: practiceChart.rows[row][selectedDayColumn],
                                                     cellWidth: cellWidth, cellHeight: cellHeight,
                                                     cellPadding: cellPadding,
                                                     opacityValue: $cellOpacity,
                                                     shuffleCount: doShuffleCount)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading) //required to make the HStack left align
                            .padding(.leading, leftEdge)
                            HStack(spacing: 0) {
                                if cellsPerRow < practiceChart.rows.count {
                                    ForEach(cellsPerRow..<practiceChart.rows.count, id: \.self) { row in
                                        if practiceChart.rows[row].count > selectedDayColumn {
                                            CellView(user: user, practiceChart: practiceChart, scalesInChart: $scalesInChart, practiceCell: practiceChart.rows[row][selectedDayColumn],
                                                     cellWidth: cellWidth, cellHeight: cellHeight,
                                                     cellPadding: cellPadding,
                                                     opacityValue: $cellOpacity,
                                                     shuffleCount: doShuffleCount)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, leftEdge)
                        }
                    //}
                    }
                    Spacer()
                }
            }
        }
        .commonToolbar(
            title: "Practice Chart",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            self.currentDayOfWeekNum = Calendar.current.component(.weekday, from: Date()) - 1 //zero base
            let user = Settings.shared.getCurrentUser()
            self.user = user
            let practiceChart = user.getPracticeChart()
            self.practiceChart = practiceChart
            self.minorScaleTypes = self.practiceChart!.grade == 1 ? ["Harmonic", "Melodic", "Natural"] : ["Harmonic", "Melodic"]
            minorTypeIndex = practiceChart.minorScaleType
            if Settings.shared.isDeveloperModeOn() {
                Firebase.shared.readAllScales(board: practiceChart.board, grade:practiceChart.grade) { scalesAndScores in
                    self.scalesInChart = scalesAndScores.map { $0.0 }
                }
            }
        }
        .onDisappear() {
        }
        .sheet(isPresented: $showPopup) {
            MinorTypePopup (
                selectedItem: $minorTypeSelection,
                isPresented: $showPopup,
                onDone: {
                    print("======= XXX", minorTypeSelection)
                }
            )
        }
//        .sheet(isPresented: $helpShowing) {
//            HelpView(topic: "Practice Chart")
//        }
        .onChange(of: ViewManager.shared.isPracticeChartActive) {oldValue, newValue in
            if newValue == false {
                dismiss()
            }
        }
    }
}

struct PracticeChartViewNew: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentUser: User = Settings.shared.getCurrentUser()
    var body: some View {
        VStack {
            Text("")
            Text("")
            Text("...Practice Chart somewhere here...")
            Spacer()
        }
        .commonToolbar(
            title: "Practice Chart",
            onBack: { dismiss() }
        )
    }
}


//PracticeChart var bodyOld: some View {
//        VStack {
//            Button(action: {
//                if practiceCell.isLicensed {
//                    if practiceCell.scale.hands.count == 1 {
//                        let chartHands = practiceCell.scale.hands
//                        if chartHands.count > 1 {
//                            setScale(requiredHands: [0,1])
//                        }
//                        else {
//                            setScale(requiredHands: [chartHands[0]])
//                        }
//                        navigateToScaleDirectly = true
//                    }
//                    else {
//                        navigateToSelectHands = true
//                    }
//                }
//                else {
//                    self.showLicenceRequiredScale = true
//                    self.licenceRequiredMessage = "A subscription is required to access \n" + practiceCell.scale.getScaleName(handFull: true)
//                }
//            }) {
//                HStack {
//                    Text(getName())
//                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title2)
//                        .foregroundColor(practiceCell.isLicensed ? .blue : .gray)
//                        .opacity(opacityValue)
//                    if !practiceCell.isLicensed {
//                        Image(systemName: "lock")
//                            .resizable()
//                            .scaledToFit()
//                            .foregroundColor(Color.gray)
//                        .frame(height: cellHeight * 0.3)
//                    }
//                }
//            }
//            .padding(self.padding)
//
//            //Spacer()
//            //starView()
//            Spacer()
//            badgeView()
//            if false && Settings.shared.isDeveloperModeOn() {
//                Button(action: {
//                    if !isCorrectSet() {
//                        ScalesModel.shared.setKeyboardAndScore(scale: practiceCell.scale, callback: {_,score in
//                            //score.debug11(ctx: "", handType: .none)
//                            Firebase.shared.writeKnownCorrect(scale: practiceCell.scale, score: score, board: practiceChart.board, grade: self.practiceChart.grade)
//                        })
//                        //self.isCorrectSet = true
//                    }
//                    else {
//                        ScalesModel.shared.setKeyboardAndScore(scale: practiceCell.scale, callback: {_,score in
//                            let key = practiceCell.scale.getScaleIdentificationKey()
//                            Firebase.shared.deleteFromRealtimeDatabase(board: practiceChart.board, grade: self.practiceChart.grade, key: key,
//                                                                       callback:{_ in })
//                        })
//                    }
//                }) {
//                    let correctSet = self.isCorrectSet()
//                    Text(correctSet ? "Delete Correct" : "Set Correct").foregroundColor(correctSet ? .black : .red)
//                }
//                .buttonStyle(.bordered)
//            }
//            Spacer()
//        }
//        .navigationDestination(isPresented: $navigateToScaleDirectly) {
//            ScalesView(user:user, practiceChart: self.practiceChart, practiceChartCell: self.practiceCell, practiceModeHand: nil)
//        }
//        .navigationDestination(isPresented: $navigateToSelectHands) {
//            SelectHandForPractice(user:user, practiceChart: practiceChart, practiceCell: practiceCell)
//        }
//        .frame(width: cellWidth) //, height: cellHeight)
//        .background(Color.white)
//        .cornerRadius(10)
//        .onAppear() {
//            let scaleName = self.practiceCell.scale.getScaleName(handFull: true, motion:true, octaves: true)
//        }
//        .alert(isPresented: $showLicenceRequiredScale) {
//            Alert(
//                title: Text("Subscription Required"),
//                message: Text(self.licenceRequiredMessage),
//                dismissButton: .default(Text("OK"))
//            )
//        }
//    }
