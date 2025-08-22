import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit
import SwiftUI

struct SinglePickList<Item: Hashable>: View {
    let title:String
    let items: [Item]
    let initiallySelectedIndex: Int?
    let label: (Item) -> String
    let onPick: (Item, Int) -> Void   // callback to parent

    @State private var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text(title).font(.title).padding()
        VStack {
            List {
                ForEach(items.indices, id: \.self) { i in
                    let isSelected = (selectedIndex == i)
                    Button {
                        selectedIndex = i
                        onPick(items[i], i)
                        dismiss()
                    } label: {
                        HStack {
                            Text(label(items[i]))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .onAppear {
            if let idx = initiallySelectedIndex, items.indices.contains(idx) {
                selectedIndex = idx
            }
        }
        .navigationTitle("Select One")
    }
}

extension SinglePickList where Item == ScaleType {
    init(title:String,
        items: [ScaleType],
         initiallySelectedIndex: Int? = nil,
         onPick: @escaping (ScaleType, Int) -> Void) {
        self.title = title
        self.items = items
        self.initiallySelectedIndex = initiallySelectedIndex
        self.label = { $0.description }
        self.onPick = onPick
    }
}

struct ChooseYourExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var user:User?
    @State private var studentScales:StudentScales?
    @State private var forceRefreshChart = 0
    @State private var selectType = false
    @State private var selectedType:ScaleType = ScaleType.any
    @State private var scaleTypes:[ScaleType] = []
    
    //let screenWidth = UIScreen.main.bounds.size.width
    //let screenHeight = UIScreen.main.bounds.size.height
    let leftEdge = UIScreen.main.bounds.size.width * 0.04
    
    func setVisibleCells(_ ctx:String, studentScales:StudentScales, typeFilter:ScaleType) {
        studentScales.processAllScales(procFunction: {studentScale in
            if let user = user {
                let board = user.board
                    if let scale = MusicBoardAndGrade.getScale(boardName:board, grade: user.grade, scaleId: studentScale.scaleId) {
                        studentScale.setVisible(way: typeFilter == .any ? true : scale.scaleType == typeFilter)
                    }
            }
        })
        studentScales.debug(ctx)
        self.forceRefreshChart += 1
    }

    func headerView() -> some View {
        HStack {
            FigmaButton(label: {
                let label = self.selectedType.description
                Text(label)
            }, action: {
                selectType = true
            })
            FigmaButton(label: {
                Text("Keys")
            }, action: {
                //showPopup = true
                //selectedItem: String? = nil
            })
            Spacer()
        }
    }
    
    func getselectedIndex() -> Int {
        for i in 0..<self.scaleTypes.count {
            if self.scaleTypes[i] == self.selectedType {
                return i
            }
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 0)  {
            VStack {
                let screenWidth = UIScreen.main.bounds.size.width
//                let screenHeight = UIScreen.main.bounds.size.height
//                let cellWidth = screenWidth * 0.16
//                let cellHeight = screenHeight * 0.2
//                let cellPadding = screenWidth * 0.002
                let leftEdge = screenWidth * (UIDevice.current.userInterfaceIdiom == .phone ? 0.005 : 0.04)
                
                VStack {
                    headerView()
                    if let studentScales = studentScales {
                        ScalesGridView(studentScales: studentScales, refreshCount: $forceRefreshChart)
                    }
                    Spacer()
                }
                .padding(.leading, leftEdge)
            }
        }
        .commonToolbar(
            title: "Choose Your Exercise",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser()
            self.user = user
            let studentScales = user.getStudentScales()
            self.studentScales = studentScales
            setVisibleCells("OnAppear", studentScales: studentScales, typeFilter: .any)
            
            ///Make sure the list is in the order in which the type is first seen in the syllabus
            var allTypesSet: Set<ScaleType> = []
            for scale in studentScales.studentScales {
                if let scale = MusicBoardAndGrade.getScale(boardName: user.board, grade: user.grade, scaleId: scale.scaleId) {
                    allTypesSet.insert(scale.scaleType)
                }
            }
            self.scaleTypes = [.any]
            for scale in studentScales.studentScales {
                if let scale = MusicBoardAndGrade.getScale(boardName: user.board, grade: user.grade, scaleId: scale.scaleId) {
                    if allTypesSet.contains(scale.scaleType) {
                        self.scaleTypes.append(scale.scaleType)
                        allTypesSet.remove(scale.scaleType)
                    }
                }
            }
        }
//        .onChange(of: selectedDayOffset) {oldValue, day in
//        }
        .sheet(isPresented: $selectType) {
            let alreadySelected = self.getselectedIndex()
            SinglePickList(title: "Exercise Types", items: self.scaleTypes,
                initiallySelectedIndex: alreadySelected) { selectedType, _ in
                if let studentScales = studentScales {
                    setVisibleCells("SelectType", studentScales: studentScales, typeFilter: selectedType)
                }
                //if let selectedType = selectedType {
                    self.selectedType = selectedType
//                }
//                else {
//                    self.selectedType = .notSet
//                }
            }
        }
        .onChange(of: ViewManager.shared.isPracticeChartActive) {oldValue, newValue in
            if newValue == false {
                dismiss()
            }
        }
    }
}

