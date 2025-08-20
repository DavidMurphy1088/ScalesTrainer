import SwiftUI
import Foundation
import Combine
import AVFoundation

struct ScalesGridCellView: View {
    let user:User?
    @ObservedObject var scaleToChart:ScaleToChart
    
    let cellWidth:CGFloat
    let cellHeight:CGFloat
    let cellPadding:Double
    @State var navigateToScale = false
    
    var body: some View {
        Button(action: {
            //let chartHands = practiceCell.scale.hands
            //setScale(requiredHands: chartHands)
            self.navigateToScale = true
        }) {
            VStack(spacing: 0) {
                let s = String(scaleToChart.scaleId.prefix(20)) + " day:\(scaleToChart.practiceDay)"
                Text(s)
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
    let scalesToChart:[ScaleToChart]
    let redrawCtr:Int
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    let scalesPerRow = 2
    @State private var user:User?
    @State private var scaleGrid:[[ScaleToChart]] = []

    func setIndexes() {
        var row:[ScaleToChart] = []
        for scale in self.scalesToChart {
            if row.count >= self.scalesPerRow {
                scaleGrid.append(row)
                row = []
            }
            row.append(scale)
        }
        if row.count > 0 {
            scaleGrid.append(row)
        }
    }
    
    var body: some View {
        let cellWidth = screenWidth * 0.16
        let cellHeight = screenHeight * 0.2
        let cellPadding = screenWidth * 0.002
        let leftEdge = screenWidth * 0.04
        
        ScrollView(.vertical) {
            VStack()  {
                Text("scales Block redraw:\(self.redrawCtr) count:\(self.scalesToChart.count)")
                VStack {
                    ForEach(scaleGrid, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { scaleToChart in
                                ScalesGridCellView(
                                    user:user,
                                    scaleToChart: scaleToChart,
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight,
                                    cellPadding: cellPadding)
                                .frame(width: UIScreen.main.bounds.width * 0.3)
                            }
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
            self.setIndexes()
        }
    }
}

