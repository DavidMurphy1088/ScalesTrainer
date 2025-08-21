import SwiftUI
import Foundation
import Combine
import AVFoundation

struct ScalesGridCellView: View {
    let user:User?
    @ObservedObject var scaleToChart:StudentScale
    
    let cellWidth:CGFloat
    let cellHeight:CGFloat
    let cellPadding:Double
    let color:Color
    let opacityValue = 0.6
    @State var navigateToScale = false
    
//    func handNameAndImage(scale:Scale) -> (String, String) {
//        if scaleToChart.scale.hands.count < 1 {
//            return ("","")
//        else {
//            if practiceCell.scale.hands[0] == 0 {
//                return ("Right Hand", "figma_right_hand")
//            }
//            else {
//                return ("Left Hand", "figma_left_hand")
//            }
//        }
//    }
        
    var body: some View {
        Button(action: {
            //let chartHands = practiceCell.scale.hands
            //setScale(requiredHands: chartHands)
            self.navigateToScale = true
        }) {
//            VStack(alignment: .leading, spacing: 0.0) {
//                //let s = String(scaleToChart.scaleId.prefix(20)) + " day:\(scaleToChart.practiceDay) vis:\(scaleToChart.visible)"
//                let s = String(scaleToChart.scaleId.prefix(10)) + " vis:\(scaleToChart.visible)"
//                Text(s)
//            }
            VStack(alignment: .leading) {
                let scaleNameWords:[String] = ["Some", "Scale"] //self.getScaleName()
                VStack(alignment: .leading) {
                    ForEach(scaleNameWords, id: \.self) { word in
                        Text(word).font(.title2)
                    }
                }
                //.frame(height: cellHeight * 0.4)
                            //.border(.white)
//                            HStack() {
//                                Image(handNameAndImage(scale: practiceCell.scale).1)
//                                    .resizable()
                .frame(width: cellWidth, height: cellHeight)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color) //.opacity(opacityValue))
                        .shadow(color: .black.opacity(opacityValue), radius: 1, x: 4, y: 4)
                )
                .padding(.bottom, 8)   // <- room for shadow
                .padding(.trailing, 8) // <- room for shadow
                .navigationTitle("Practice Chart")
            }
            .navigationDestination(isPresented: $navigateToScale) {
                //if practiceCell.scale.hands.count == 1 {
                if let user = user {
                    let scale:Scale = MusicBoardAndGrade.getScale(boardName: user.board,
                                                                  grade : user.grade,
                                                                  scaleKey: scaleToChart.scaleId)!
                    ScalesView(user:user, scale: scale)
                }
                //}
                //            else {
                //                SelectHandForPractice(user:user, scale: practiceCell.scale, titleColor: practiceCell.color.getColor())
                //            }
            }
        }
    }

}

struct ScalesGridView : View {
    let studentScales:StudentScales
    @Binding var refreshCount: Int

    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let scalesPerRow = 3
    @State private var user:User?
    @State private var scaleGridRowCols:[[StudentScale]] = []
    @State private var layoutCount = 0
    let colors = ["mint","blue","cyan","green","indigo","orange","pink","purple","red","teal","white","yellow"]
    
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
        print("========= GV", self.layoutCount, self.scaleGridRowCols.count)
    }
    
    func getColor(n:Int) -> Color {
        let clr = colors[n]
        switch clr.lowercased() {
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
        let cellWidth = screenWidth * 0.12
        let cellHeight = screenHeight * 0.2
        let cellPadding = screenWidth * 0.002
        let leftEdge = screenWidth * 0.04
        
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                Text("ScalesGridView - scalesCount:\(self.studentScales.studentScales.count) layout:\(self.layoutCount)")
                ForEach(scaleGridRowCols, id: \.self) { row in
                    VStack(alignment: .leading) {
                        HStack {
                            //Text("Row :\(row.count)")
                            ForEach(row, id: \.self) { scaleToChart in
                                let n = Int.random(in: 0...5)
                                ScalesGridCellView(
                                    user:user,
                                    scaleToChart: scaleToChart,
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight,
                                    cellPadding: cellPadding,
                                    color:getColor(n: n)
                                    )
                                .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.height * 0.15)
                                //.outlinedStyleView()
                                .padding(cellPadding)
                                //.border(getColor(n: Int.random(in: 5))
                            }
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) ///LEft aling the grid
                .padding(.leading, leftEdge)
            }
        }
        .onAppear() {
            let user = Settings.shared.getCurrentUser()
            self.user = user
            //self.nextcolor1 = 0
            self.layout()
        }
        .onChange(of: refreshCount) { old, new in
            layout()
        }
    }
}

