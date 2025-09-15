import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation
import AudioKit
import SwiftUI

struct ChooseYourExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewManager = ViewManager.shared
    @State private var user:User?
    @State private var studentScales:StudentScales?
    @State private var forceRefreshChart = 0
    
    @State private var selectType = false
    @State private var selectedType:ScaleType = ScaleType.any
    @State private var scaleTypes:[ScaleType] = []
    
    static let allKeys = "All Keys"
    @State private var selectKey = false
    @State private var selectedKey:String = allKeys
    @State private var scaleKeys:[String] = []
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    let leftEdge = UIScreen.main.bounds.size.width * 0.04
    
    func setVisibleCells(_ ctx:String, studentScales:StudentScales, typeFilter:ScaleType?, keyFilter:String?) {
        studentScales.processAllScales(procFunction: {studentScale in
            if let scale = studentScale.scale {
                studentScale.setVisible(way: false)
                if let typeFilter = typeFilter {
                    studentScale.setVisible(way: typeFilter == .any ? true : scale.scaleType == typeFilter)
                }
                if let keyFilter = keyFilter {
                    studentScale.setVisible(way: keyFilter == ChooseYourExerciseView.allKeys ? true : scale.getScaleKeyName() == keyFilter)
                }
            }
        })
        //studentScales.debug(ctx)
        self.forceRefreshChart += 1
    }

    func headerView() -> some View {
        HStack {
            FigmaButton(self.selectedType.description, action: {
                selectType = true
            })
            .popover(isPresented: $selectType) {
                let alreadySelected = self.getSelectedTypeIndex()
                SinglePickList(title: "Exercise Types", items: self.scaleTypes,
                               initiallySelectedIndex: alreadySelected) { selectedType, _ in
                    self.selectedKey = ChooseYourExerciseView.allKeys
                    if let studentScales = studentScales {
                        setVisibleCells("SelectType", studentScales: studentScales,
                                        typeFilter: selectedType, keyFilter: nil)
                    }
                    self.selectedType = selectedType
                }
                .presentationCompactAdaptation(.popover)
            }
            
            FigmaButton(self.selectedKey, action: {
                selectKey = true
            })
            .popover(isPresented: $selectKey) {
                //ToolbarTitleHelpView(helpMessage: "some message test test test test test test test test test ")
                let alreadySelected = self.getSelectedKeyIndex()
                
                SinglePickList(title: "Exercise Keys", items: self.scaleKeys,
                    initiallySelectedIndex: alreadySelected) { selectedKey, _ in
                    self.selectedType = ScaleType.any
                    if let studentScales = studentScales {
                        setVisibleCells("SelectKeys", studentScales: studentScales,
                                        typeFilter: nil, keyFilter: selectedKey)
                    }
                    self.selectedKey = selectedKey
                }
                .presentationCompactAdaptation(.popover)
            }
            
            Spacer()
        }
    }
    func getSelectedTypeIndex() -> Int {
        for i in 0..<self.scaleTypes.count {
            if self.scaleTypes[i] == self.selectedType {
                return i
            }
        }
        return 0
    }
    
    func getSelectedKeyIndex() -> Int {
        for i in 0..<self.scaleKeys.count {
            if self.scaleKeys[i] == self.selectedKey {
                return i
            }
        }
        return 0
    }

    var body: some View {
        VStack(spacing: 0)  {
            VStack {
                let screenWidth = UIScreen.main.bounds.size.width
                let leftEdge = screenWidth * (UIDevice.current.userInterfaceIdiom == .phone ? 0.005 : 0.04)
                
                VStack {
                    headerView()
                    if let studentScales = studentScales {
                        ScalesGridView(studentScales: studentScales, refreshCount: $forceRefreshChart,
                                       navigationTitle: "Choose Your Exercise")
                    }
                    Spacer()
                }
                .padding(.leading, leftEdge)
            }
        }
        .commonToolbar(
            title: "Choose Your Exercise", helpMsg: "",
            onBack: { dismiss() }
        )
        //.toolbar(.hidden, for: .tabBar) // Hide the TabView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser("ChooseExercise view, .onAppear")
            self.user = user
            let studentScales = user.getStudentScales()
            self.studentScales = studentScales
            setVisibleCells("OnAppear", studentScales: studentScales, typeFilter: .any, keyFilter: nil)
            self.scaleTypes = studentScales.getScaleTypes()
            self.scaleKeys = [ChooseYourExerciseView.allKeys] + studentScales.getScaleKeys().sorted()
            if selectedKey == ChooseYourExerciseView.allKeys {
                setVisibleCells("SelectType", studentScales: studentScales,
                                typeFilter: selectedType, keyFilter: nil)
            }
            else {
                setVisibleCells("SelectKeys", studentScales: studentScales,
                                typeFilter: nil, keyFilter: selectedKey)
            }
        }

        .onChange(of: viewManager.boardPublished) {oldValue, newValue in
            dismiss()
        }
        .onChange(of: viewManager.gradePublished) {oldValue, newValue in
            dismiss()
        }

    }
}

