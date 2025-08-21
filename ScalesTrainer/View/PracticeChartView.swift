import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit

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

struct PracticeChartView: View {
    @Environment(\.dismiss) var dismiss
    @State private var user:User?
    @State private var studentScales:StudentScales?
    @State var minorTypeIndex:Int = 0
    @State private var helpShowing = false
    @State var minorScaleTypes:[String] = []
    @State private var cellOpacity:Double = 1.0
    @State private var showPopup = false
    @State private var minorTypeSelection: String? = nil
    @State private var forceRefreshChart = 0
    
    let daysInChart = 3
    @State var dayNames:[String] = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    @State private var currentDayOfWeekNum = Calendar.current.component(.weekday, from: Date()) - 1
    @State private var selectedDayOffset:Int = 0
    
    func setVisibleCells(_ ctx:String, studentScales:StudentScales, dayOffset:Int) {
        let chartStart = studentScales.createdDayOfWeek //+ 1
        var visibleDayOffset:Int
        visibleDayOffset = (currentDayOfWeekNum - chartStart) % daysInChart
        if visibleDayOffset < 0 {
            visibleDayOffset = (currentDayOfWeekNum + 7 - chartStart) % daysInChart
        }
        visibleDayOffset = (visibleDayOffset + dayOffset) % daysInChart
        studentScales.processAllScales(procFunction: {studentScale in
            studentScale.setVisible(way: studentScale.practiceDay == visibleDayOffset)
        })
        studentScales.debug(ctx)
        self.forceRefreshChart += 1
    }
    
    func doShuffle() {
        if let studentScales = studentScales {
            studentScales.shuffle()
            setVisibleCells("shuffle", studentScales: studentScales, dayOffset: 0)
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
                    //Text("DayOfWeek:\(self.currentDayOfWeekNum)")
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
                        })
                        Spacer()
                        SelectDayOfWeek(dayNames: self.dayNames, daysToShow: daysInChart, currentDayOfWeekNum: self.currentDayOfWeekNum,
                                        selectedDayColumn: $selectedDayOffset, opacity: $cellOpacity)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                    }
                    .padding(.leading, leftEdge)
                    
                    Text("")
                    
                    VStack(spacing: 0) {
                        if let studentScales = studentScales {
                            ScalesGridView(studentScales: studentScales, refreshCount: $forceRefreshChart)
                        }
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
            let user = Settings.shared.getCurrentUser()
            self.user = user
            let studentScales = user.getStudentScales()
            self.studentScales = studentScales
            self.minorScaleTypes = self.studentScales!.grade == 1 ? ["Harmonic", "Melodic", "Natural"] : ["Harmonic", "Melodic"]
            minorTypeIndex = studentScales.minorScaleType
            if Settings.shared.isDeveloperModeOn() {
//                Firebase.shared.readAllScales(board: studentScales.board, grade:studentScales.grade) { scalesAndScores in
//                    self.scalesInChart = scalesAndScores.map { $0.0 }
//                }
            }
            setVisibleCells("set DAY", studentScales: studentScales, dayOffset: 0)
        }
        .onChange(of: selectedDayOffset) {oldValue, day in
            if let studentScales = studentScales {
                setVisibleCells("set DAY", studentScales: studentScales, dayOffset: day)
            }
        }
        .sheet(isPresented: $showPopup) {
            MinorTypePopup (
                selectedItem: $minorTypeSelection,
                isPresented: $showPopup,
                onDone: {
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

