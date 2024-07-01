import SwiftUI
import SwiftUI

import SwiftUI

struct CoinView: View {
    let coinWidth: CGFloat
    let coinHeight: CGFloat
    let angleOffset: Double  // Angle to tilt the coin ellipse
    //let animate:Bool
    
    @State private var offset: CGFloat = 0
    @State private var isShaking = false

    var body: some View {
        let darkYellow = Color(red: 192 / 255.0, green: 128 / 255.0, blue: 0 / 255.0)
        
        Ellipse()
            .strokeBorder(LinearGradient(gradient: Gradient(colors: [darkYellow, .orange]), startPoint: .leading, endPoint: .trailing), lineWidth: coinWidth * 0.05)
            .background(Ellipse().fill(Color.yellow)) // Base color of the coin
            .frame(width: coinWidth, height: coinHeight)
            .offset(x: offset)
//            .onAppear {
//                if animate {
//                    withAnimation(Animation.easeInOut(duration: 0.1).repeatForever()) {
//                        offset = 2
//                        isShaking.toggle()
//                    }
//                }
//            }
    }
}

struct CoinStackView: View {
    @ObservedObject var coinBank = CoinBank.shared
    let totalCoins:Int //how many to show
    let compactView:Bool
    
    @State var frameHeight:Double = 0
    @State var frameWidth:Double = 0
    
    let coinOverlapHeightWise = 0.7 //How much of coin n+1 height overlaps coin n
    let pileOverlapWidthWise = 0.3 //How much of pile n+1 width overlaps pile n

    ///How many piles of coins?
    func getPileCount() -> Int {
        coinBank.coinHeight = coinBank.coinWidth * 0.4
//        if true {
//            return 3
//        }
        ///Make it always odd so it can be centered in the view
        if totalCoins == 0 {
            return 1
        }
        if totalCoins < 6 {
            return totalCoins/2 + 1
        }
        if totalCoins < 20 {
            return 3
        }
        if totalCoins < 30 {
            return 7
        }
        return 15
    }
    
    ///Calc random placement of coins in the coin piles
    func calculatePileCoinCounts() {
        let coinSize = self.compactView ? 0.05 : 0.1
        coinBank.coinWidth = UIScreen.main.bounds.width * coinSize
        let pileCount = getPileCount()
        coinBank.pileCoinCounts = Array(repeating: 0, count: pileCount)
        coinBank.pileDrawingHeights = Array(repeating: 0.0, count: pileCount)
        
        //pileVertLocations = Array(repeating: 0.0, count: pileCount)
        coinBank.drawingOrder = Array(repeating: 0, count: pileCount)

        for i in 0..<totalCoins {
            coinBank.pileCoinCounts[i % coinBank.pileCoinCounts.count] += 1
        }
        for _ in 0..<coinBank.pileCoinCounts.count {
            var r = Int.random(in: 0..<coinBank.pileCoinCounts.count)
            let delta = Int.random(in: 1..<4)
            if coinBank.pileCoinCounts[r] > delta {
                coinBank.pileCoinCounts[r] -= delta
                r = Int.random(in: 0..<coinBank.pileCoinCounts.count)
                //if coinBank.pileCoinCounts[r] > 0 {
                    coinBank.pileCoinCounts[r] += delta
                //}
            }
        }
        
        ///Pile display height is a full coin height + the overlap height for each additional coin
        for i in 0..<pileCount {
            let pileSize = coinBank.pileCoinCounts[i]
            let overlapSize = Double((pileSize - 1)) * (1.0 - coinOverlapHeightWise) * coinBank.coinHeight
            coinBank.pileDrawingHeights[i] = coinBank.coinHeight + overlapSize
        }
        //debug("after calculatePileHeights2")
    }
    
    func getPileFrameHeight() -> Double {
        calculatePileCoinCounts()
//        pileHorzLocations = Array(repeating: 0.0, count: getPileCount())
//        ///Make the piles overlap widthwise to some amount
//        for i in 0..<pileHorzLocations.count {
//            pileHorzLocations[i] = (Double(i - pileHorzLocations.count/2) ) * coinBank.coinWidth * 0.80
//        }
        ///Draw the shorter piles last to make sure they appear in front of higher piles
        coinBank.drawingOrder = coinBank.pileCoinCounts.enumerated().sorted { $0.element > $1.element }.map { $0.offset }
//        for i in 0..<pileHorzLocations.count {
//            pileVertLocations[coinBank.drawingOrder[i]] = Double(i) * coinBank.coinHeight * 0.1
//        }
        ///Add height so each shorter pile can be displayed in front of the highest pile one coin overlap lower - i.e. in foreground
        var height = coinBank.pileDrawingHeights.max() ?? 0
        let coinSizeDiff = (coinBank.pileCoinCounts.max() ?? 0) - (coinBank.pileCoinCounts.min() ?? 0)
        //height += Double(getPileCount() - 1) * (1.0 - coinOverlapHeightWise) * coinBank.coinHeight
        height += Double(coinSizeDiff) * (1.0 - coinOverlapHeightWise) * coinBank.coinHeight
        return height
    }
    
    func getPileFrameWidth() -> Double {
        return coinBank.coinWidth + Double((getPileCount() - 1)) * (coinBank.coinWidth * pileOverlapWidthWise)
    }
    
    func debug1(_ ctx: String) {
        print("\n====CoinBankView", ctx)
        print(" LOW H:", "coins", totalCoins, "heightEach", coinBank.coinHeight, "overlap", coinOverlapHeightWise)
        print(" UIScreen height", UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        print(" heights", coinBank.pileCoinCounts, "drawwingHeights:", coinBank.pileDrawingHeights)
        print(" Draw order", coinBank.drawingOrder)
    }
    
    func coinYPos(_ pileIndex:Int, _ indexInPile:Int) -> Double {
        ///Offset the coin veritically based on its position in the pile
        let midIndex = coinBank.pileCoinCounts[pileIndex] / 2
        let overlapHeight = coinBank.coinHeight * (1.0 - coinOverlapHeightWise)
        var y = Double(indexInPile - midIndex) * overlapHeight
        if coinBank.pileCoinCounts[pileIndex] % 2 == 0 {
            y += overlapHeight / 2.0
        }
        ///Offset the postion to level the pile with the largest pile
        var foregroundOffset = 0.0
        if coinBank.pileCoinCounts[pileIndex] < coinBank.pileCoinCounts.max() ?? 0 {
            let displayDiff = (coinBank.pileDrawingHeights.max() ?? 0) - coinBank.pileDrawingHeights[pileIndex]
            let coinCountDiff = (coinBank.pileCoinCounts.max() ?? 0) - coinBank.pileCoinCounts[pileIndex]
            foregroundOffset = displayDiff / 2.0  + (Double(coinCountDiff) * overlapHeight) / 2.0
        }
        return y + foregroundOffset
    }
    
    func pileXPos(_ idx:Int) -> Double {
        let mid = getPileCount() / 2
        let width = coinBank.coinWidth * pileOverlapWidthWise
        var xPos = Double(idx - mid) * width
        ///Center if number of piles is even
        if getPileCount() % 2 == 0 {
            xPos += width / 2.0
        }
        return xPos
    }
    
    func log(_ pileIdx:Int, _ pileXidx:Int, _ index:Int) -> Int {
        print("===== pile", pileIdx, "PileXPos:", pileXidx, "\tindex", index)
      return 0
    }
    
    var body: some View {
        VStack {
            ZStack {
                GeometryReader { geometry in
                    ForEach(coinBank.drawingOrder, id: \.self) { pileIndex in
                        ForEach(0..<coinBank.pileCoinCounts[pileIndex], id: \.self) { indexInPile in
                            let indexInPile = coinBank.pileCoinCounts[pileIndex] - indexInPile - 1
                            //let x = log(pileIndex, Int(xPos(pileIndex)), indexInPile)
                            CoinView(coinWidth:coinBank.coinWidth, coinHeight:coinBank.coinHeight, angleOffset: Double(indexInPile))
                            ///Position one coin in the pile
                            ///Position center required first since its  a GeometryReader the apply offset
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Center the ellipse within GeometryReader
                                .offset(y: coinYPos(pileIndex, indexInPile))
                        }
                        //.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .offset(x: pileXPos(pileIndex))
                    }
                }
            }
            .frame(width: frameWidth, height: frameHeight)
            //        .border(.green, width: 1)
            .onAppear() {
                self.frameHeight = getPileFrameHeight()
                self.frameWidth = getPileFrameWidth()
                if self.totalCoins > 0 {
                    //debug(" after .InAppear ")
                }
            }
        }
//        HStack {
//            Spacer()
//            Text(getCoinsStatusMsg()).font(self.compactView ? .caption : .title2)
//            //Text(getCountFace()).font(.title)
//            Spacer()
//        }
    }
}

struct CoinBankView: View {
    //let practiceJournal: PracticeJournal
    let coinBank = CoinBank.shared
    
    @State var background = UIGlobals.shared.getBackground()
    func getTitle() -> String {
        //var title = "Coin Bank for \(practiceJournal.title)"
        var title = "Coin Bank"
        let name = Settings.shared.firstName
        if name.count > 0 {
            title = name + "'s \(title)"
        }
        return title
    }
    var body1: some View {
        ZStack {
            CoinStackView(totalCoins: CoinBank.shared.totalCoinsInBank, compactView: false)
                .border(.cyan, width: 2)
            Rectangle().frame(height: 1).foregroundColor(.black).padding(.horizontal)
            Rectangle().frame(width: 1).foregroundColor(.black).padding(.horizontal)
        }
    }
    var body: some View {
        ZStack {
            Image(background)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                VStack {
                    Text(getTitle()).font(.title).commonTitleStyle()
                }
                VStack {
                    //Text("")
                    Text("").padding(/*@START_MENU_TOKEN@*/EdgeInsets()/*@END_MENU_TOKEN@*/)
                    
                    if coinBank.totalCoinsInBank > 0 {
                        CoinStackView(totalCoins: CoinBank.shared.totalCoinsInBank, compactView: false)
                        //.border(.cyan, width: 2)
                    }
                    if coinBank.totalCoinsInBank > 1 {
                        //Text("Spend them wisely 😊").font(.title2)
                    }
                    Text(coinBank.getCoinsStatusMsg())
                    Text("You can earn more coins by recording scales 😊")
                    Text("")
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8) //, height: UIScreen.main.bounds.height * 0.8)
        }
    }
}


