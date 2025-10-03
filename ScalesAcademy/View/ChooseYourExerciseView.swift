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
    
    @State private var selectMotion = false
    @State private var selectedMotion:ScaleMotion? = nil
    @State private var scaleMotions:[ScaleMotion] = []
    @State private var didDisappear = false
    
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    let leftEdge = UIScreen.main.bounds.size.width * 0.04
    
    func setVisibleCells(_ ctx:String, studentScales:StudentScales, typeFilter:ScaleType?, keyFilter:String?, motionFilter:ScaleMotion?) {
        studentScales.processAllScales(procFunction: {studentScale in
            if let scale = studentScale.scale {
                studentScale.setVisible(way: true)
                if let typeFilter = typeFilter {
                    if typeFilter != .all {
                        studentScale.setVisible(way: scale.scaleType == typeFilter)
                    }
                }
                if let keyFilter = keyFilter {
                    if keyFilter != "All" {
                        studentScale.setVisible(way: keyFilter == scale.scaleRoot.name)
                    }
                }
                if let motionFilter = motionFilter {
                    if motionFilter != .all {
                        studentScale.setVisible(way: scale.scaleMotion == motionFilter)
                    }
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
    
    func getMotionDescription(motion: ScaleMotion?) -> String {
        return self.selectedMotion == nil ? "Motion" : self.selectedMotion!.descriptionShort
    }
    
    func headerView() -> some View {
        HStack {
            let screenWidth = UIScreen.main.bounds.size.width
            FigmaButton(self.getTypeDescription(scaleType : self.selectedType), action: {
                selectType = true
            })
            .popover(isPresented: $selectType) {
                let alreadySelected = self.getSelectedTypeIndex()
                SinglePickList<ScaleType>(title: "Exercise Types", items: self.scaleTypes,
                               initiallySelectedIndex: alreadySelected) { selectedType, _ in
                    //self.selectedKey = nil
                    if let studentScales = studentScales {
                        setVisibleCells("SelectType", studentScales: studentScales,
                                        typeFilter: selectedType, keyFilter: nil, motionFilter: nil)
                    }
                    self.selectedType = selectedType
                    self.selectedKey = nil
                    self.selectedMotion = nil
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
                    //self.selectedType = nil
                    if let studentScales = studentScales {
                        setVisibleCells("SelectKeys", studentScales: studentScales,
                                        typeFilter: nil, keyFilter: selectedKey, motionFilter: nil)
                    }
                    self.selectedKey = selectedKey
                    self.selectedType = nil
                    self.selectedMotion = nil
                }
                .frame(width: screenWidth * (self.compact ? 0.10 : 0.06))
                .presentationCompactAdaptation(.popover)
            }
            
            if false {
                FigmaButton(self.getMotionDescription(motion : self.selectedMotion), action: {
                    selectMotion = true
                })
                .popover(isPresented: $selectMotion) {
                    let alreadySelected = self.getSelectedMotionIndex()
                    
                    SinglePickList<ScaleMotion>(title: "Exercise Motions", items: self.scaleMotions,
                                                initiallySelectedIndex: alreadySelected) { selectedMotion, _ in
                        //self.selectedMotion = nil
                        if let studentScales = studentScales {
                            setVisibleCells("SelectMotion", studentScales: studentScales,
                                            typeFilter: nil, keyFilter: nil, motionFilter: selectedMotion)
                        }
                        self.selectedMotion = selectedMotion
                        self.selectedType = nil
                        self.selectedKey = nil
                    }
                    .frame(width: screenWidth * 0.12)
                    .presentationCompactAdaptation(.popover)
                }
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
    
    func getSelectedMotionIndex() -> Int {
        for i in 0..<self.scaleMotions.count {
            if self.scaleMotions[i] == self.selectedMotion {
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
                    Text("")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            let user = Settings.shared.getCurrentUser("ChooseExercise view, .onAppear")
            self.user = user
            let studentScales = user.getStudentScales()
            self.studentScales = studentScales
            
            self.scaleTypes = studentScales.getScaleTypes()
            self.scaleTypes.insert(ScaleType.all, at: 0)
            
            self.scaleKeys = studentScales.getScaleKeys()//.sorted()
            self.scaleKeys.insert("All", at: 0)
            
            self.scaleMotions = studentScales.getScaleMotions()
            self.scaleMotions.insert(ScaleMotion.all, at: 0)
            if didDisappear {
                print("Returning from lower level")
            } else {
                print("Coming from higher level or initial")
                self.selectedType = nil
                self.selectedKey = nil
                self.selectedMotion = nil
                setVisibleCells("SelectType", studentScales: studentScales, typeFilter: nil, keyFilter: nil, motionFilter: nil)
            }
            didDisappear = false
            
            //self.initialTypeDescription = "Exercise Type"
            //self.initialKeyDescription = "Key"
        }

        .onChange(of: viewManager.boardPublished) {oldValue, newValue in
            dismiss()
        }
        .onChange(of: viewManager.gradePublished) {oldValue, newValue in
            dismiss()
        }
        .onDisappear() {
            didDisappear = true
        }

    }
}

