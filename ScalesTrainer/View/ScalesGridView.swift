import SwiftUI
import Foundation
import Combine
import AVFoundation

struct ScalesGridCellView: View {
    let user:User?
    @ObservedObject var scaleToChart:StudentScale
    let cellWidth:Double
    let color:Color
    let opacityValue = 0.6
    @State var navigateToScale = false
    @State var navigateToSelectHands = false
    
    func getHandImage(scale:Scale) -> Image? {
        if scale.hands.count < 1 {
            return nil
        }
        if scale.hands.count > 1 {
            return Image("figma_hand_together")
        }
        if scale.hands[0] == 0 {
            return Image("figma_hand_right")
        }
        else {
            return Image("figma_hand_left")
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
                Text("")
                VStack(alignment: .leading) {
                    Text("")
                    if let scale = self.scaleToChart.scale {
                        let scaleTitle = scale.getScaleName(showHands: false, handFull: false, octaves: false)
                        Text(scaleTitle).foregroundColor(.black)//.font(.title2)
                        HStack {
                            if let handImage = getHandImage(scale: scale) {
                                handImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: cellWidth * 0.1)
                                    //.border(.red)
                            }
                            let hands = scale.getScaleDescriptionParts(hands: true)
                            Text(hands).font(.body).foregroundColor(.black)
                            Spacer()
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
            .navigationTitle("Practice Chart")
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

    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let scalesPerRow = 4
    @State private var user:User?
    @State private var scaleGridRowCols:[[StudentScale]] = []
    @State private var layoutCount = 0
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
        //print("========= GV", self.layoutCount, self.scaleGridRowCols.count)
    }
    
    func getColor(n:Int) -> Color {
        return colors[n % colors.count]
    }
    
    var body: some View {
        let cellPadding = screenWidth * 0.002
        let cellWidth = (screenWidth / Double(self.scalesPerRow)) * 0.8
        let cellHeight = (screenHeight) * 0.15
        let paddingVertical = (UIDevice.current.userInterfaceIdiom == .phone ? screenHeight * 0.01 : 0.0)
        
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                ForEach(Array(scaleGridRowCols.enumerated()), id: \.offset) { (rowIndex, row) in
                    HStack {
                        ForEach(Array(row.enumerated()), id: \.offset) { (colIndex, scaleToChart) in
                            ScalesGridCellView(
                                user:user,
                                scaleToChart: scaleToChart,
                                cellWidth: cellWidth,
                                color:getColor(n: rowIndex * 3 + colIndex)
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
            studentScales.debug("OnAppead")
            let user = Settings.shared.getCurrentUser()
            self.user = user
            self.layout()
        }
        .onChange(of: refreshCount) { old, new in
            layout()
        }
    }
}

