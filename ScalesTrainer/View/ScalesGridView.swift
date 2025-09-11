import SwiftUI
import Foundation
import Combine
import AVFoundation

struct ScalesGridCellView: View {
    let user:User?
    @ObservedObject var scaleToChart:StudentScale
    let cellWidth:Double
    let color:Color
    @Binding var scoreTestScaleIds:[String]
    let navigationTitle:String
    
    let opacityValue = 0.6
    @State var navigateToScale = false
    @State var navigateToSelectHands = false
    @State private var fadeIn = false
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func testDataButtons(user:User) -> some View {
        VStack {
            if let scale = scaleToChart.scale {
                Button(action: {
                    if scoreTestScaleIds.contains(scaleToChart.scaleId) {
                        Firebase.shared.deleteFromRealtimeDatabase(board: user.boardAndGrade.board.name, grade: user.boardAndGrade.grade,
                                                                   key: scaleToChart.scaleId, callback: {_ in
                            scoreTestScaleIds.removeAll { $0 == scaleToChart.scaleId }
                        })
                    }
                    else {
                        ScalesModel.shared.setKeyboardAndScore(scale: scale, callback: {_, score in
                            Firebase.shared.writeKnownCorrect(scale: scale, score: score, board: user.boardAndGrade.board.name,
                                                              grade: user.boardAndGrade.grade)
                            scoreTestScaleIds.append(scaleToChart.scaleId)
                        })
                    }
                }) {
                    let x = scoreTestScaleIds.contains(scaleToChart.scaleId)
                    Text(x ? "Delete Testdata" : "Set Testdata").foregroundColor(x ? .black : .red)
                        .background(.white)
                }
                .buttonStyle(.bordered)
                .background(.white)
            }
        }
    }
        
    var body: some View {
        Button(action: {
            if let scale = self.scaleToChart.scale {
                if scale.hands.count == 1 {
                    self.navigateToScale = true
                }
                else {
                    self.navigateToSelectHands = true
                }
            }
        }) {
            HStack(alignment: .top) {
                let compact = UIDevice.current.userInterfaceIdiom == .phone 
                Text("")
                VStack(alignment: .leading) {
                    if !compact {
                        Text("")
                    }
                    if let scale = self.scaleToChart.scale {
                        HStack {
                            Text(" ")
                            VStack(alignment: .leading) {
                                let scaleTitle = scale.getScaleName(showHands: false, handFull: false, octaves: false)
                                Text(scaleTitle)
                                    .foregroundColor(.black)
                                    .font(compact ? .callout : .title3)
                                    .multilineTextAlignment(.leading)   // ensures left alignment on wraps
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    if let handImage = Figma.getHandImage(scale: scale) {
                                        handImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: cellWidth * 0.16)
                                            .contrast(1.2)
                                            .brightness(-0.15)
                                            //.saturation(0.8) // Slightly desaturate for heavier look
                                    }
                                    let hands = scale.getScaleDescriptionParts(hands: true)
                                    Text(hands).font(compact ? .callout : .title3).foregroundColor(.black).font(.footnote)
                                }
                            }
                        }
                        if Settings.shared.isDeveloperModeOn() {
                            if let user = user {
                                self.testDataButtons(user: user)
                                Spacer()
                            }
                        }
                        if !compact {
                            HStack {
                                Spacer()
                                Image("figma_forward_button")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: cellWidth * 0.15)
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.color) //.opacity(opacityValue))
                    .shadow(color: .black.opacity(opacityValue), radius: 1, x: 4, y: 4)
            )
            .opacity(fadeIn ? 1 : 0)  // start invisible
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        fadeIn = true
                    }
            }
            .onAppear {
//                print("=========+Appear", scoreTestScaleIdExists)
//                self.testExists = scoreTestScaleIdExists
            }
            .onChange(of: scaleToChart.scale?.getScaleIdentificationKey()) {
                fadeIn = false
                withAnimation(.easeIn(duration: 1.0)) {
                    fadeIn = true
                }
            }
            .navigationTitle(navigationTitle)
            .navigationDestination(isPresented: $navigateToScale) {
                if let user = user, let scale = scaleToChart.scale {
                    ScalesView(user:user, scale: scale)
                }
            }
            .navigationDestination(isPresented: $navigateToSelectHands) {
                if let user = user, let scale = scaleToChart.scale {
                    SelectHandForPractice(user:user, scale: scale, titleColor: self.color)
                }
            }
        }
    }
}

struct ScalesGridView : View {
    let studentScales:StudentScales
    @Binding var refreshCount: Int
    let navigationTitle:String

    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let scalesPerRow = 4
    @State private var user:User?
    @State private var scaleGridRowCols:[[StudentScale]] = []
    @State private var layoutCount = 0
    @State private var scoreTestScaleIds:[String] = []
    
    let colors:[Color] = [
        Color(red: 98/255.0, green: 202/255.0, blue: 215/255.0),
        Color(red: 250/255.0, green: 162/255.0, blue: 72/255.0),
        Color(red: 156/255.0, green: 215/255.0, blue: 98/255.0),
        Color(red: 255/255.0, green: 83/255.0, blue: 108/255.0)
    ]

    func layout() {
        scaleGridRowCols = []
        var row:[StudentScale] = []
        for scale in self.studentScales.studentScales {
            if scale.visible {
                if row.count >= self.scalesPerRow {
                    scaleGridRowCols.append(row)
                    row = []
                }
                row.append(scale)
            }
        }
        if row.count > 0 {
            scaleGridRowCols.append(row)
        }
        layoutCount += 1
    }
    
    func getColor(n:Int) -> Color {
        return colors[n % colors.count]
    }
    
    var body: some View {
        //let cellPadding = screenWidth * 0.002
        let cellWidth = (screenWidth / Double(self.scalesPerRow)) * 0.8
        let cellHeight = (screenHeight) * 0.15
        let paddingVertical = (UIDevice.current.userInterfaceIdiom == .phone ? screenHeight * 0.01 : screenHeight * 0.004)
        
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(Array(scaleGridRowCols.enumerated()), id: \.offset) { (rowIndex, row) in
                    HStack {
                        ForEach(Array(row.enumerated()), id: \.offset) { (colIndex, scaleToChart) in
                            //let scoreTestDataExists = self.scoreTestScaleIds.contains(scaleToChart.scaleId)
                            ScalesGridCellView(
                                user:user,
                                scaleToChart: scaleToChart,
                                cellWidth: cellWidth,
                                color:getColor(n: rowIndex * 3 + colIndex),
                                scoreTestScaleIds: $scoreTestScaleIds,
                                navigationTitle: self.navigationTitle
                            )
                            .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                    .padding(.vertical, paddingVertical)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            //.border(.green)
        }
        //.border(.green)
        .onAppear() {
            //studentScales.debug("OnAppead")
            let user = Settings.shared.getCurrentUser("SalesGrivView .onAppear")
            self.user = user
            if Settings.shared.isDeveloperModeOn() {
                Firebase.shared.readAllScales(board: user.boardAndGrade.board.name, grade: user.boardAndGrade.grade, completion: {data in
                    for (scaleKey, staffJSON, _) in data {
                        self.scoreTestScaleIds.append(scaleKey)
                    }
                })
            }
            self.layout()
        }
        .onChange(of: refreshCount) { old, new in
            layout()
        }
    }
}

