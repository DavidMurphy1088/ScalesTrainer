import SwiftUI

class BadgeBank : ObservableObject {
    static let shared = BadgeBank()
    
    @Published private(set) var totalCorrect: Int = 0
    func setTotalCorrect(_ value:Int) {
        DispatchQueue.main.async {
            self.totalCorrect = value
        }
    }
    
    @Published private(set) var totalIncorrect: Int = 0
    func setTotalIncorrect(_ value:Int) {
        DispatchQueue.main.async {
            self.totalIncorrect = value
        }
    }
    
    @Published private(set) var show: Bool = false
    func setShow(_ value:Bool) {
        DispatchQueue.main.async {
            self.show = value
        }
    }
}

struct HexagramShape: View {
    var size: CGFloat
    var offset: CGFloat
    var color:Color
    
    var body: some View {
        ZStack {
            // Bottom (inverted) triangle filled with red
            Path { path in
                let halfSize = size / 2
                let height = sqrt(3) * halfSize
                let center = CGPoint(x: size, y: size)
                
                let bottomTrianglePoints = [
                    CGPoint(x: center.x, y: center.y + height / 2 + offset),
                    CGPoint(x: center.x - halfSize, y: center.y - height / 2 + offset),
                    CGPoint(x: center.x + halfSize, y: center.y - height / 2 + offset)
                ]
                
                path.move(to: bottomTrianglePoints[0])
                path.addLine(to: bottomTrianglePoints[1])
                path.addLine(to: bottomTrianglePoints[2])
                path.addLine(to: bottomTrianglePoints[0])
            }
            .fill(color)
            
            // Top (upright) triangle filled with blue
            Path { path in
                let halfSize = size / 2
                let height = sqrt(3) * halfSize
                let center = CGPoint(x: size, y: size)
                
                let topTrianglePoints = [
                    CGPoint(x: center.x, y: center.y - height / 2 - offset),
                    CGPoint(x: center.x - halfSize, y: center.y + height / 2 - offset),
                    CGPoint(x: center.x + halfSize, y: center.y + height / 2 - offset)
                ]
                
                path.move(to: topTrianglePoints[0])
                path.addLine(to: topTrianglePoints[1])
                path.addLine(to: topTrianglePoints[2])
                path.addLine(to: topTrianglePoints[0])
            }
            .fill(color)
        }
        .frame(width: size * 2, height: size * 2)
    }
}

struct BadgeView: View {
    let scale:Scale
    @ObservedObject var bank = BadgeBank.shared
    @State private var size: CGFloat = 0
    @State private var offset: CGFloat = 5.0
    @State private var rotationAngle: Double = 0
    @State private var verticalOffset: CGFloat = -20
    
    var body: some View {
        VStack {
            HStack {
                Text("\(scale.getScaleName(handFull: true, octaves: false, tempo: false, dynamic: false, articulation: false)) Stars").font(.title)
                Text("Correct:\(bank.totalCorrect)")
                Text("Incorrect:\(bank.totalIncorrect)")
                Button(action: {
                    bank.setShow(false)
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                }
            }
            HStack(spacing: 4) {
                let c = Color(red: 1.0, green: 0.8431, blue: 0.0)
                ForEach(0..<scale.scaleNoteState[scale.hand].count, id: \.self) { n in
                    if n == BadgeBank.shared.totalCorrect - 1  {
                        ZStack {
                            Text("⊙").foregroundColor(.blue)
                            //Text("\(n)").foregroundColor(.blue)
                            if BadgeBank.shared.totalCorrect > 0 {
                                HexagramShape(size: size, offset: offset, color: c)
                                    .rotationEffect(Angle.degrees(rotationAngle))
                                    .offset(y: verticalOffset)
                                    .onAppear {
                                        withAnimation(Animation.easeOut(duration: 0.5)) {
                                            rotationAngle = 360
                                            verticalOffset = 0
                                        }
                                    }
                            }
                        }
                        .frame(width:size, height: size)
                    }
                    else {
                        ZStack {
                            Text("⊙").foregroundColor(.blue)
                            //Text("\(n)").foregroundColor(.blue)
                            HexagramShape(size: size, offset: offset, color: c).opacity(n < BadgeBank.shared.totalCorrect  ? 1 : 0)
                        }
                        .frame(width:size, height: size)
                    }
                }
            }
            .onChange(of: BadgeBank.shared.totalCorrect, {
                verticalOffset = -50
                rotationAngle = 0
            })
        }
        .onAppear() {
            self.size = UIScreen.main.bounds.size.width / (Double(scale.scaleNoteState[scale.hand].count) * 1.7)
        }
    }
}
