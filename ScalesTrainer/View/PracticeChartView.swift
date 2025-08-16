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
    @State var navigateToScale = false
    //@State var practiceModeHand:HandType? = nil
    @State var showLicenceRequiredScale = false
    @State var licenceRequiredMessage:String = ""

    let padding = 5.0

    func getMinBadgeIndex() -> Int {
        var min = self.practiceCell.badges.count - 5
        if min < 0  {
            min = 0
        }
        return min
    }
    
    func getScaleName() -> [String] {
        var scaleName:[String] = ["",""] //,""]
        let scale = practiceCell.scale.getScaleName(showHands: false, handFull: false, octaves: false)
        //let scale = "D Minor Broekn Chords"
        let words = scale.components(separatedBy: " ")
        var nextLine = ""
        var index = 0
        for word in words {
            if (nextLine.count >= 7) {
                if index < scaleName.count {
                    scaleName[index] = nextLine
                }
                index += 1
                nextLine = ""
            }
            if nextLine.count > 0 {
                nextLine += " "
            }
            nextLine += word
        }
        if (nextLine.count > 0) {
            if index < scaleName.count {
                scaleName[index] = nextLine
            }
        }
        return scaleName
    }
    
    ///Does this chart cell have its scale in the known-correct list
    func isCorrectSet() -> Bool {
        let name = practiceCell.scale.getScaleIdentificationKey()
        return self.scalesInChart.contains(name)
    }
    
    func handNameAndImage(scale:Scale) -> (String, String) {
        if scale.hands.count < 1 {
            return ("","")
        }
        if scale.hands.count == 2 {
            return ("Together","figma_hands_together")
        }
        else {
            if practiceCell.scale.hands[0] == 0 {
                return ("Right Hand", "figma_right_hand")
            }
            else {
                return ("Left Hand", "figma_left_hand")
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let chartHands = practiceCell.scale.hands
            //setScale(requiredHands: chartHands)
            self.navigateToScale = true
        }) {
            VStack(alignment: .leading) {
                let scaleNameWords:[String] = self.getScaleName()
                VStack(alignment: .leading) {
                    ForEach(scaleNameWords, id: \.self) { word in
                        Text(word).font(.title2)
                    }
                }
                .frame(height: cellHeight * 0.4)
                HStack() {
                    Image(handNameAndImage(scale: practiceCell.scale).1)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.black)
                        .frame(height: cellWidth * 0.15)
                    Text(handNameAndImage(scale: practiceCell.scale).0)
                }

                HStack {
                    Spacer()
                    let forwardSize = cellWidth * 0.2
                    Image("figma_forward_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: forwardSize, height: forwardSize)
                }
            }
            .padding()
            .foregroundColor(.black).opacity(opacityValue)
            .frame(width: cellWidth, height: cellHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(practiceCell.color.getColor()) //.opacity(opacityValue))
                    .shadow(color: .black.opacity(opacityValue), radius: 1, x: 4, y: 4)
            )
            .padding(.bottom, 8)   // <- room for shadow
            .padding(.trailing, 8) // <- room for shadow
            .navigationTitle("Practice Chart")
        }
        .navigationDestination(isPresented: $navigateToScale) {
            if practiceCell.scale.hands.count == 1 {
                ScalesView(user:user, scale: practiceCell.scale)
            }
            else {
                SelectHandForPractice(user:user, scale: practiceCell.scale, titleColor: practiceCell.color.getColor())
            }
        }
    }
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
                let cellHeight = screenHeight * 0.2
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
        .onChange(of: ViewManager.shared.isPracticeChartActive) {oldValue, newValue in
            if newValue == false {
                dismiss()
            }
        }
    }
}
