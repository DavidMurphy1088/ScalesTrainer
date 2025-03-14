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

///The badge view for the exercise 
struct ExerciseBadgesView: View {
    @ObservedObject var exerciseBadgesList:ExerciseBadgesList
    let scale:Scale
    let onClose: () -> Void
    @State private var badgeIconSize: CGFloat = 0
    @State private var offset: CGFloat = 5.0
    @State private var rotationAngle: Double = 0
    @State private var verticalOffset: CGFloat = -50
    @State var imageIds:[Int] = []
    @State var handType = KeyboardType.right
    
    init(scale:Scale, onClose: @escaping () -> Void) {
        self.exerciseBadgesList = ExerciseBadgesList.shared
        self.scale = scale
        self.onClose = onClose
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
        ZStack(alignment: .topTrailing) { // Ensure button is positioned at the top-right
            VStack {
                HStack {
                    Text("Note Badges").font(.title3)
                }
                HStack(spacing: getDotSpace()) {
                    let c = Color(red: 1.0, green: 0.8431, blue: 0.0)
                    let imWidth = CGFloat(40)
                    let animationDuration = 0.1
                    
                    ///Draw a place for every note in the scale. Put badges in places where the note was played
                    ForEach(0..<scale.getScaleNoteStates(handType: handType).count, id: \.self) { scaleNoteNumber in
                        if scaleNoteNumber == exerciseBadgesList.totalBadges - 1  {
                            ///Drop in the last badge awarded
                            ZStack {
                                Text("⊙").foregroundColor(.blue)
                                if exerciseBadgesList.totalBadges > 0 {
                                    if let user = Settings.shared.getCurrentUser() {
                                        if user.settings.badgeStyle == 0 {
                                            HexagramShape(size1: badgeIconSize, offset: offset, color: c)
                                                .rotationEffect(Angle.degrees(rotationAngle))
                                                .offset(y: verticalOffset)
                                                .onAppear {
                                                    withAnimation(Animation.easeOut(duration: animationDuration)) {
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
                                                    withAnimation(Animation.easeOut(duration: animationDuration)) {
                                                        rotationAngle = 360
                                                        verticalOffset = 0
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                            .frame(width: badgeIconSize, height: badgeIconSize)
                        }
                        else {
                            ZStack {
                                Text("⊙").foregroundColor(.blue)
                                if scaleNoteNumber < exerciseBadgesList.totalBadges {
                                    if let user = Settings.shared.getCurrentUser() {
                                        if user.settings.badgeStyle == 0 {
                                            HexagramShape(size1: badgeIconSize, offset: offset, color: c).opacity(scaleNoteNumber < exerciseBadgesList.totalBadges  ? 1 : 0)
                                        }
                                        else {
                                            Image(self.imageName(imageSet: user.settings.badgeStyle, n: scaleNoteNumber))
                                                .resizable()
                                                .frame(width: imWidth)
                                        }
                                    }
                                }
                            }
                            .frame(width: badgeIconSize, height: badgeIconSize)
                        }
                    }
                }
                .padding()
                Text("")
                    .onChange(of: exerciseBadgesList.totalBadges, {
                    verticalOffset = -50
                    rotationAngle = 0
                })
            }
            
            // ✅ Button in Top-Right Corner
            Button(action: {
                onClose()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding() // Space from edges
        }

        .onAppear() {
            self.handType = KeyboardType.right //scale.hand == 2 ? 0 : scale.hand
            let divider = max(scale.getScaleNoteCount(), 16)
            self.badgeIconSize = UIScreen.main.bounds.size.width / (Double(divider) * 1.7)
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

struct BadgeInformationPanel : View {
    let user:User
    let msg:String
    let imageName:String
    @Binding var badgeImageRotationAngle:Double
    
    var body: some View {
        VStack {
            HStack {
                Text(msg)
                    .padding()
                    .foregroundColor(.blue)
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .title3 : .title2)
                //.opacity(exerciseState.statePublished == .wonAndFinished ? 1 : 0)
                    .zIndex(1) // Keeps it above other views
                
                ///Practice chart badge position is based on exercise state
                ///State goes to won (when enough points) and then .wonAndFinished at end of exercise or user does "stop"
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: UIScreen.main.bounds.height * 0.04)
                //                    .offset(x: getBadgeOffset(state: exerciseState.statePublished).0,
                //                            y: getBadgeOffset(state: exerciseState.statePublished).1)
                    .rotationEffect(Angle(degrees: self.badgeImageRotationAngle))
                    .animation(.easeInOut(duration: 1), value: self.badgeImageRotationAngle)
                    .padding()
//                    .onChange(of: exerciseState.statePublished) { _ in
//                        withAnimation(.easeInOut(duration: 1)) {
//                            if exerciseState.statePublished == .exerciseWon {
//                                badgeImageRotationAngle += 360
//                            }
//                        }
//                    }
            }
            .frame(maxWidth: UIScreen.main.bounds.size.width * 0.8)
            .frame(height: UIScreen.main.bounds.size.height * 0.07)
            .background(user.settings.getKeyboardColor()) //opacity(0.9)
            .cornerRadius(20)
            .shadow(radius: 10)
            Text("")
        }
    }
}

