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
    @ObservedObject var viewManager = ViewManager.shared

    @State private var user:User?
    @State private var studentScales:StudentScales?
    @State private var helpShowing = false
    @State var minorScaleTypes:[ScaleType] = []
    @State var selectedMinorType:ScaleType = ScaleType.major
    @State private var cellOpacity:Double = 1.0
    @State private var showMinorTypeSelection:Bool = false
    @State private var minorTypeSelection: String? = nil
    @State private var forceRefreshChart = 0
    let screenWidth = UIScreen.main.bounds.size.width
    
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
            var visible = studentScale.practiceDay == visibleDayOffset
            if let scale = studentScale.scale {
                if [ScaleType.naturalMinor, ScaleType.harmonicMinor, ScaleType.melodicMinor].contains(scale.scaleType)  {
                    if scale.scaleType != user?.selectedMinorType {
                        visible = false
                    }
                }
            }
            studentScale.setVisible(way: visible)
        })
        //studentScales.debug1(ctx)
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
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        
        var body: some View {
            HStack(spacing: 12) {
                HStack {
                    ForEach(0..<daysToShow, id: \.self) { dayIndex in
                        let dayNameIndex = (currentDayOfWeekNum + dayIndex) % dayNames.count
                        Button(action: {
                            selectedDayColumn = dayIndex
                        }) {
                            Text("\(dayNames[dayNameIndex])")
                                .foregroundColor(dayIndex == selectedDayColumn ? .white : .primary)
                                .padding(.vertical, compact ? 4 : 8)
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
    
    func getSelectedTypeIndex(userType: ScaleType) -> Int {
        for i in 0..<self.minorScaleTypes.count {
            if self.minorScaleTypes[i] == userType {
                return i
            }
        }
        return 0
    }

    var body: some View {
        let leftEdge = screenWidth * (UIDevice.current.userInterfaceIdiom == .phone ? 0.005 : 0.04)
        let compact = UIDevice.current.userInterfaceIdiom == .phone
        
        VStack(spacing: 0)  {
            //let screenWidth = UIScreen.main.bounds.size.width
            //let screenHeight = UIScreen.main.bounds.size.height

            VStack {
                //Text("DayOfWeek:\(self.currentDayOfWeekNum)")
                HStack {
                    let minorLabel = self.selectedMinorType.description + " ▼"
                    FigmaButton(minorLabel, action: { //imageName:"figma_down_arrowhead"
                        showMinorTypeSelection = true
                    })
                    .popover(isPresented: $showMinorTypeSelection) {
                        if let user = self.user {
                            if let selectedMinorType = user.selectedMinorType {
                                let alreadySelected = self.getSelectedTypeIndex(userType: selectedMinorType)
                                SinglePickList(title: "Minor Types", items: self.self.minorScaleTypes,
                                               initiallySelectedIndex: alreadySelected) { selectedMinorType, _ in
                                    self.selectedMinorType = selectedMinorType
                                    user.selectedMinorType = selectedMinorType
                                    let newStudentScales:StudentScales = user.getStudentScales()
                                    newStudentScales.setPracticeDaysForScales(studentScales: newStudentScales.studentScales, minorType: selectedMinorType)
                                    self.studentScales = newStudentScales
                                    Settings.shared.save()
                                    if let studentScales = studentScales {
                                        setVisibleCells("SelectType", studentScales: studentScales, dayOffset: selectedDayOffset)
                                    }
                                }
                                .presentationCompactAdaptation(.popover)
                            }
                        }
                    }
                    FigmaButton("Shuffle", imageName1:"figma_shuffle", action: {
                        cellOpacity = 0.0
                        doShuffle()
                        withAnimation(.easeIn(duration: 3.0)) {
                            cellOpacity = 1.0
                        }
                    })
                    Spacer()
                    SelectDayOfWeek(dayNames: self.dayNames, daysToShow: daysInChart,
                                    currentDayOfWeekNum: self.currentDayOfWeekNum,
                                    selectedDayColumn: $selectedDayOffset, opacity: $cellOpacity)
                    .frame(width: UIScreen.main.bounds.width * (compact ? 0.4 : 0.3))
                }
                
                Text("")
                
                VStack(spacing: 0) {
                    if let studentScales = studentScales {
                        ScalesGridView(studentScales: studentScales, refreshCount: $forceRefreshChart,
                                       navigationTitle: "Practise Chart")
                    }
                }
                Spacer()
            }
        }
        .padding(.leading, leftEdge)
        .commonToolbar(
            title: "Practice Chart",
            helpMsg: "All technical work is covered in a three-day rotation. Choose your minor scale preference and shuffle the chart from time to time to keep the order fresh.",
            onBack: { dismiss() }
        )
        //.toolbar(.hidden, for: .tabBar) // Hide the TabView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser("Prac Chart .OnAppear")
            self.user = user
            let studentScales = user.getStudentScales()
            if !studentScales.arePracticeDaysSet() {
                studentScales.setPracticeDaysForScales(studentScales: studentScales.studentScales, minorType: self.selectedMinorType)
            }
            
            self.studentScales = studentScales
            let minorTypes = studentScales.getScaleTypes()
            
            self.minorScaleTypes = []
            ///Ensure this order and default is harmonic
            for scaleType in [ScaleType.harmonicMinor, ScaleType.naturalMinor, .melodicMinor] {
                for type in minorTypes {
                    if type == scaleType {
                        self.minorScaleTypes.append(type)
                    }
                }
            }
            if let selectedMinorType = user.selectedMinorType {
                self.selectedMinorType = selectedMinorType
            }

            setVisibleCells("on appear", studentScales: studentScales, dayOffset: selectedDayOffset)
        }
        .onChange(of: selectedDayOffset) {oldValue, day in
            if let studentScales = studentScales {
                setVisibleCells("set DAY", studentScales: studentScales, dayOffset: selectedDayOffset)
            }
        }
        .sheet(isPresented: $showMinorTypeSelection) {

        }
        .onChange(of: viewManager.boardPublished) {oldValue, newValue in
            dismiss()
        }
        .onChange(of: viewManager.gradePublished) {oldValue, newValue in
            dismiss()
        }
    }
}

