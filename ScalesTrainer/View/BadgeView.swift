import SwiftUI

struct HexagramShape: View {
    var size1: CGFloat
    var offset: CGFloat
    var color:Color
    
    var body: some View {
        ZStack {
            // Bottom (inverted) triangle filled with red
            Path { path in
                let halfSize = size1 / 2
                let height = sqrt(3) * halfSize
                let center = CGPoint(x: size1, y: size1)
                
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
                let halfSize = size1 / 2
                let height = sqrt(3) * halfSize
                let center = CGPoint(x: size1, y: size1)
                
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
        .frame(width: size1 * 2, height: size1 * 2)
    }
}

///The badge view for the exercise view
struct BadgesView: View {
    @ObservedObject var badgeBank:BadgeBank
    let scale:Scale
    @State private var badgeIconSize: CGFloat = 0
    @State private var offset: CGFloat = 5.0
    @State private var rotationAngle: Double = 0
    @State private var verticalOffset: CGFloat = -50
    @State var imageIds:[Int] = []
    @State var handType = KeyboardType.right
    
    init(scale:Scale) {
        self.badgeBank = BadgeBank.shared
        self.scale = scale
    }
    
    func imageName(imageSet:Int, n:Int) -> String {
        var name = ""
        if n >= imageIds.count {
            return ""
        }
        if imageSet == 1 {
            switch imageIds[n]  {
            case 1: name = "pet_catface"
            case 2: name = "pet_penguinface"
            default: name = "pet_dogface"
            }
        }
        if imageSet == 2 {
            switch imageIds[n] {
            case 1: name = "bug_butterfly"
            case 2: name = "bug_bee"
            default: name = "bug_beetle"
            }
        }
        if imageSet == 3 {
            switch imageIds[n] {
            case 1: name = "dinosaur_1"
            case 2: name = "dinosaur_2"
            default: name = "dinosaur_3"
            }
        }
        if imageSet == 4 {
            switch imageIds[n] {
            case 1: name = "sea_creature_1"
            case 2: name = "sea_creature_2"
            default: name = "sea_creature_3"
            }
        }
        
        return name
    }
    
    func getDotSpace() -> CGFloat {
        if ScalesModel.shared.scale.octaves > 1 {
            return UIDevice.current.userInterfaceIdiom == .phone ? 4 : 10
        }
        else {
            return 10
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Note Badges").font(.title3)
//                Button(action: {
//                    badgeBank.setShow(false)
//                }) {
//                    Image(systemName: "xmark")
//                        .foregroundColor(.blue)
//                }
            }
            HStack(spacing: getDotSpace()) {
                let c = Color(red: 1.0, green: 0.8431, blue: 0.0)
                let imWidth = CGFloat(40)
                
                ForEach(0..<scale.getScaleNoteStates(handType: handType).count, id: \.self) { scaleNoteNumber in
                    if scaleNoteNumber == badgeBank.totalCorrect - 1  {
                        ZStack {
                            Text("⊙").foregroundColor(.blue)
                            if badgeBank.totalCorrect > 0 {
                                if let user = Settings.shared.getCurrentUser() {
                                    if user.settings.badgeStyle == 0 {
                                        HexagramShape(size1: badgeIconSize, offset: offset, color: c)
                                            .rotationEffect(Angle.degrees(rotationAngle))
                                            .offset(y: verticalOffset)
                                            .onAppear {
                                                withAnimation(Animation.easeOut(duration: 1.0)) {
                                                    rotationAngle = 360
                                                    verticalOffset = 0
                                                }
                                            }
                                    }
                                }
                                else {
                                    if let user = Settings.shared.getCurrentUser() {
                                        Image(self.imageName(imageSet: user.settings.badgeStyle, n: scaleNoteNumber))
                                            .resizable()
                                            .frame(width: imWidth)
                                            .rotationEffect(Angle.degrees(rotationAngle))
                                            .offset(y: verticalOffset)
                                            .onAppear {
                                                withAnimation(Animation.easeOut(duration: 1.0)) {
                                                    rotationAngle = 360
                                                    verticalOffset = 0
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .frame(width:badgeIconSize, height: badgeIconSize)
                    }
                    else {
                        ZStack {
                            Text("⊙").foregroundColor(.blue)
                            if scaleNoteNumber < badgeBank.totalCorrect {
                                if let user = Settings.shared.getCurrentUser() {
                                    if user.settings.badgeStyle == 0 {
                                        HexagramShape(size1: badgeIconSize, offset: offset, color: c).opacity(scaleNoteNumber < badgeBank.totalCorrect  ? 1 : 0)
                                    }
                                    else {
                                        Image(self.imageName(imageSet: user.settings.badgeStyle, n: scaleNoteNumber))
                                            .resizable()
                                            .frame(width: imWidth)
                                    }
                                }
                            }
                        }
                        .frame(width:badgeIconSize, height: badgeIconSize)//.opacity(n < BadgeBank.shared.totalCorrect  ? 1 : 0)
                    }
                }
            }
            Text("")
            .onChange(of: badgeBank.totalCorrect, {
                verticalOffset = -50
                rotationAngle = 0
            })
        }
        .onAppear() {
            self.handType = KeyboardType.right //scale.hand == 2 ? 0 : scale.hand
            //self.size1 = UIScreen.main.bounds.size.width / (Double(scale.getScaleNoteStates(handType: handType).count) * 1.7)
            self.badgeIconSize = UIScreen.main.bounds.size.width / (Double(scale.getScaleNoteCount()) * 1.7)
            ///Ensure not more than 2 concurrent same values
            for _ in 0..<scale.getScaleNoteStates(handType: handType).count {
                var newValue: Int
                repeat {
                    newValue = Int.random(in: 0..<3)
                } while imageIds.count >= 2 && newValue == imageIds[imageIds.count - 1] && newValue == imageIds[imageIds.count - 2]
                
                self.imageIds.append(newValue)
            }
        }
    }
}
