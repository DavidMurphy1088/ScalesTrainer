import SwiftUI

struct CoinView: View {
    let scalingSize:Double
    let coinCount:Int
    let angleOffset: Double  // Angle to tilt the coin ellipse
    
    func getWidth() -> Double {
        return coinCount < 25 ? scalingSize * 1.2 : scalingSize * 0.3
    }
    
    var body: some View {
        Ellipse()
            .strokeBorder(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing), lineWidth: getWidth() * 0.1)
            .background(Ellipse().fill(Color.yellow)) // Base color of the coin
            .frame(width: getWidth(), height: getWidth() * 0.5) // Increased size for larger appearance
            .rotation3DEffect(.degrees(angleOffset * 5), axis: (x: 1, y: 0, z: 0)) // Rotate each coin around the x-axis
            .shadow(radius: getWidth() * 0.1) // Enhanced shadow for added depth
    }
}

struct CoinStackView: View {
    let showBet:Bool
    let coinBank:CoinBank = CoinBank.shared
    let showMsg:Bool

    @State var coinPiles:[Int] = []
    let scalingSize:Double// = 100.0
    @State var totalCoinCount = 0
    
    func getPileCount() -> Int {
        if totalCoinCount < 20 {
            return 3
        }
        if totalCoinCount < 30 {
            return 7
        }
        return 10
    }
    
    func calculatePiles() {
        coinPiles = Array(repeating: 0, count: getPileCount())
        var ctr = 0
        
        while true {
            let sum = coinPiles.reduce(0, +)
            if sum >= totalCoinCount {
                break
            }
            let maxr:Int
//            if ctr % 3 == 0 {
//                maxr = 5
//            }
//            else {
                maxr = 2
//            }
            let r = Int.random(in: 0..<maxr)
            if r == 0 {
                let pile = ctr % coinPiles.count
                coinPiles[pile] += 1
            }
            ctr += 1
        }
    }
    
    var body: some View {
        VStack {
            let pileOffsetDelta = CGFloat(scalingSize / 10.0) //30)
            HStack(spacing: scalingSize * 0.25) {
                ForEach(0..<coinPiles.count, id: \.self) { index in
                    ZStack {
                        ForEach(0..<coinPiles[index], id: \.self) { coinIndex in
                            CoinView(scalingSize: scalingSize, coinCount: self.totalCoinCount, angleOffset: Double(coinIndex))
                                .offset(y: CGFloat(coinIndex) * -scalingSize/5.0) // Adjust for larger coin overlap
                        }
                    }
                    .offset(x: (pileOffsetDelta))
                    //.offset(x: (index % 2 == 0 ? pileOffsetDelta : 0 - pileOffsetDelta)) //, y:index % 2 == 0 ? 0 : pileOffsetDelta * 3)
                    //.border(Color .red)
                }
                if showMsg {
                    if showBet {
                        Text("You bet \(coinBank.lastBet) coins")
                    }
                    else {
                        Text("You have \(coinBank.total) coins")
                    }
                }
            }
        }
        .onAppear() {
            self.totalCoinCount = (showBet ? coinBank.lastBet : coinBank.total)
            if self.coinPiles.count == 0 {
                calculatePiles()
            }
        }
    }
}

struct CoinBankView: View {
    let practiceJournal: PracticeJournal
    
    let scalingSize:Double// = 100.0
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
                    CoinStackView(showBet: false, showMsg: false, scalingSize: scalingSize)
                        .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.height * 0.4)
                        //.border(.red)
                    Text("You have \(coinBank.total) coins").font(.title2)
                    Text("Spend them wisely 😊").font(.title2)
                    Text("")
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.8)
        }

    }
}


