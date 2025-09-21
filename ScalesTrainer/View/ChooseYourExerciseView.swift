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
    @State private var selectedType:ScaleType? = nil
    @State private var scaleTypes:[ScaleType] = []
    //@State private var initialTypeDescription:String = ""
    
    //static let allKeys = "All Keys"
    @State private var selectKey = false
    @State private var selectedKey:String? = nil
    @State private var scaleKeys:[String] = []
    //@State private var initialKeyDescription:String = ""
    
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    let leftEdge = UIScreen.main.bounds.size.width * 0.04
    
    func setVisibleCells(_ ctx:String, studentScales:StudentScales, typeFilter:ScaleType?, keyFilter:String?) {
        studentScales.processAllScales(procFunction: {studentScale in
            if let scale = studentScale.scale {
                studentScale.setVisible(way: true)
                if let typeFilter = typeFilter {
                    studentScale.setVisible(way: scale.scaleType == typeFilter)
                }
                if let keyFilter = keyFilter {
                    studentScale.setVisible(way: keyFilter == scale.scaleRoot.name)
                }
            }
        })
        self.forceRefreshChart += 1
    }
    
    func getTypeDescription(scaleType: ScaleType?) -> String {
//        if self.initialTypeDescription.count > 0 {
//            return self.initialTypeDescription
//        }
//        else {
//            if let type = self.selectedType {
//                return type.description
//            }
//            else {
//                return ""
//            }
//        }
        return self.selectedType == nil ? "Exercise Type" : self.selectedType!.description
    }
    
    func getKeyDescription(key: String?) -> String {
//        if self.initialKeyDescription.count > 0 {
//            return self.initialKeyDescription
//        }
//        else {
//            if let key = self.selectedKey {
//                return key
//            }
//            else {
//                return ""
//            }
//        }
        return self.selectedKey == nil ? "Key" : self.selectedKey!
    }
    
    func headerView() -> some View {
        HStack {
            let screenWidth = UIScreen.main.bounds.size.width
            FigmaButton(self.getTypeDescription(scaleType : self.selectedType), action: {
                selectType = true
            })
            .popover(isPresented: $selectType) {
                let alreadySelected = self.getSelectedTypeIndex()
                SinglePickList(title: "Exercise Types", items: self.scaleTypes,
                               initiallySelectedIndex: alreadySelected) { selectedType, _ in
                    self.selectedKey = nil
                    if let studentScales = studentScales {
                        setVisibleCells("SelectType", studentScales: studentScales,
                                        typeFilter: selectedType, keyFilter: nil)
                    }
                    self.selectedType = selectedType
                    self.selectedKey = nil
                }
                .frame(width: screenWidth * 0.20)
                .presentationCompactAdaptation(.popover)
            }
            
            FigmaButton(self.getKeyDescription(key : self.selectedKey), action: {
                selectKey = true
            })
            .popover(isPresented: $selectKey) {
                let alreadySelected = self.getSelectedKeyIndex()
                
                SinglePickList(title: "Exercise Keys", items: self.scaleKeys,
                    initiallySelectedIndex: alreadySelected) { selectedKey, _ in
                    self.selectedType = nil
                    if let studentScales = studentScales {
                        setVisibleCells("SelectKeys", studentScales: studentScales,
                                        typeFilter: nil, keyFilter: selectedKey)
                    }
                    self.selectedKey = selectedKey
                    self.selectedType = nil
                }
                    .frame(width: screenWidth * (self.compact ? 0.10 : 0.06))
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
            title: "Choose Your Exercise",
            helpMsg: "Here you’ll find all technical work for your grade. Set filters to find what you’re looking for quickly. You only need to practise one minor type.",
            onBack: { dismiss() }
        )
        //.toolbar(.hidden, for: .tabBar) // Hide the TabView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser("ChooseExercise view, .onAppear")
            self.user = user
            let studentScales = user.getStudentScales(withPracticeDays: false)
            self.studentScales = studentScales
            setVisibleCells("OnAppear", studentScales: studentScales, typeFilter: nil, keyFilter: nil)
            self.scaleTypes = studentScales.getScaleTypes()
            self.scaleKeys = studentScales.getScaleKeys()//.sorted()
            self.selectedType = nil
            self.selectedKey = nil
            setVisibleCells("SelectType", studentScales: studentScales, typeFilter: nil, keyFilter: nil)
            //self.initialTypeDescription = "Exercise Type"
            //self.initialKeyDescription = "Key"
        }

        .onChange(of: viewManager.boardPublished) {oldValue, newValue in
            dismiss()
        }
        .onChange(of: viewManager.gradePublished) {oldValue, newValue in
            dismiss()
        }

    }
}

