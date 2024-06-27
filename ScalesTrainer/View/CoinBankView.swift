import SwiftUI

struct CoinView: View {
    let coinCount:Int
    let coinWidth:Double
    let coinHeight:Double
    let angleOffset: Double  // Angle to tilt the coin ellipse

    var body1: some View {
        Ellipse()
            .stroke(Color.blue, lineWidth: 1)
            .frame(width: coinWidth, height: coinHeight)
    }
    var body: some View {
        Ellipse()
            .strokeBorder(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing), lineWidth: coinWidth * 0.05)
            .background(Ellipse().fill(Color.yellow)) // Base color of the coin
            .frame(width: coinWidth, height: coinHeight)
            .rotation3DEffect(.degrees(angleOffset * 5), axis: (x: 1, y: 0, z: 0)) // Rotate each coin around the x-axis
            .shadow(radius: coinWidth * 0.1) // Enhanced shadow for added depth
    }
}

struct CoinStackView: View {
    let screenHeightRatio:Double //how much height to take
    let screenWidthRatio:Double //how much width to take
    let totalCoins:Int //how many to show
    let showBet:Bool
    let showMsg:Bool
    
    @State var pileHeights:[Int] = []
    @State var pileHorzLocations:[Double] = []
    @State var pileVertLocations:[Double] = []
    @State var drawingOrder:[Int] = []

    let coinOverlapHeightWise = 0.6 //0.8 ///0.5
    @State var coinHeight = 0.0
    @State var coinWidth = 0.0
    
    func getPileCount() -> Int {
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
    
    func calculatePileHeights() {
        pileHeights = Array(repeating: 0, count: getPileCount())
        pileVertLocations = Array(repeating: 0.0, count: getPileCount())
        drawingOrder = Array(repeating: 0, count: getPileCount())
        let perPile = totalCoins / getPileCount()
        var sum = 0
        for i in 0..<totalCoins {
            pileHeights[i % pileHeights.count] += 1
        }
        for cnt in 0..<pileHeights.count {
            let delta = Int.random(in: 1..<4)
            var r = Int.random(in: 0..<pileHeights.count)
            if pileHeights[r] > delta {
                pileHeights[r] -= delta
                r = Int.random(in: 0..<pileHeights.count)
                if pileHeights[r] > 0 {
                    pileHeights[r] += delta
                }
            }
        }
    }
    
    func getFrameHeight() -> Double {
        return (Double(pileHeights.max() ?? 1) * coinHeight) * (1.0 - coinOverlapHeightWise) * 1.0
    }
    
    func debug() {
        print("=======LOW H:", "coins", totalCoins, "heightEach", coinHeight, "overlap", coinOverlapHeightWise, "heightRatio", screenHeightRatio)
        print(" == UIScreen height", UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        print(" heights", pileHeights, "HorzLocs", pileHorzLocations)
    }
    
    func lowestPilePos(_ index:Int) -> Double {
        let totHeight = Double(pileHeights.max()!) * (coinHeight * (1.0 - coinOverlapHeightWise))
        let offset = totHeight * 0.5 - Double(index) * (coinHeight * (1.0 - coinOverlapHeightWise))
        return offset
    }

    var body: some View {
        VStack {
            ZStack {
                ForEach(drawingOrder, id: \.self) { index in
                    ZStack {
                        ForEach(0..<pileHeights[index], id: \.self) { pileIndex in
                            CoinView(coinCount: self.totalCoins, coinWidth:coinWidth, coinHeight:coinHeight, angleOffset: Double(pileIndex))
                                //.offset(y: CGFloat(pileIndex) * coinHeight)// * coinOverlapHeightWise) // Vertical spacing in pile
                                .offset(y: CGFloat(lowestPilePos(pileIndex)))// * coinOverlapHeightWise) // Vertical spacing in pile
                        }
                    }
                    ///Horizontal pile postion
                    .offset(x: pileHorzLocations[index], y: pileVertLocations[index])
                    //.frame(width: coinHeight * 2.0 * Double(pileHorzLocations.count), height: getFrameHeight())
                }
//                if showMsg {
//                    if showBet {
//                        Text("You bet \(coinBank.lastBet) coins")
//                    }
//                    else {
//                        Text("You have \(coinBank.total) coins")
//                    }
//                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * screenHeightRatio)
//        .border(.green, width: 1)
        .onAppear() {
            if self.totalCoins > 0 {
                calculatePileHeights()
                let totalHeight = UIScreen.main.bounds.height * self.screenHeightRatio
                let totalWidth = UIScreen.main.bounds.width * self.screenWidthRatio
                ///Coin height drives all the other layout measurements
                ///Leave some of the allocated height blank spaced
                coinHeight = totalHeight / Double(pileHeights.max()!) * 0.4
                if coinHeight > UIScreen.main.bounds.height * 0.05 {
                    coinHeight = UIScreen.main.bounds.height * 0.05
                }
                ///Make sure they all fit widthwise
                coinWidth = coinHeight * 20.0
                if coinWidth * Double(pileHeights.count) > totalWidth {
                    coinWidth = totalWidth / Double(pileHeights.count)
                    //coinHeight = coinWidth / 20.0
                }
                pileHorzLocations = Array(repeating: 0.0, count: getPileCount())
                ///Make the piles overlap widthwise to some amount
                for i in 0..<pileHorzLocations.count {
                    pileHorzLocations[i] = (Double(i - pileHorzLocations.count/2) ) * coinWidth * 0.80
                }
                ///Draw the shorter piles last to make sure they appear in front of higher piles
                drawingOrder = pileHeights.enumerated().sorted { $0.element > $1.element }.map { $0.offset }
                for i in 0..<pileHorzLocations.count {
                    pileVertLocations[drawingOrder[i]] = Double(i) * coinHeight * 0.1
                }
                //debug()
            }
        }
    }
}

struct CoinBankView: View {
    let practiceJournal: PracticeJournal
    //let screenHeightRatio:Double //e.g. 0.5 take 1/2 the screen height.
    let coinBank = CoinBank.shared
    
    @State var background = UIGlobals.shared.getBackground()
    func getTitle() -> String {
        var title = "Coin Bank for \(practiceJournal.title)"
        let name = Settings.shared.firstName
        if name.count > 0 {
            title = name + "'s \(title)"
        }
        return title
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
                    
                    if coinBank.total > 0 {
                        CoinStackView(screenHeightRatio: 0.4, screenWidthRatio: 0.8, totalCoins: CoinBank.shared.total, showBet: false, showMsg: false)
                        //.border(.cyan, width: 2)
                    }
                    Text("You have \(coinBank.total) coins").font(.title2)
                    if coinBank.total > 1 {
                        Text("Spend them wisely 😊").font(.title2)
                    }
                    Text("")
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8) //, height: UIScreen.main.bounds.height * 0.8)
        }
    }
}


