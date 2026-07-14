import SwiftUI

class ExerciseBadgesList : ObservableObject {
    static let shared = ExerciseBadgesList()

    @Published private(set) var totalBadgesPublished: Int = 0

    var totalBadges: Int = 0
    func setTotalBadges(_ value:Int) {
        self.totalBadges = value
        DispatchQueue.main.async {
            self.totalBadgesPublished = self.totalBadges
        }
    }
    
}

struct StarShape: View {
    var shapeSize: CGFloat
    var offset: CGFloat
    var color:Color
    
    var body: some View {
        let scale = 1.4
        Image("star")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(color)        // tint
            .frame(width: shapeSize * scale,
                height: shapeSize * scale)
            .background(Color.white)
    }
}

///The stars view for the exercise
struct ExerciseDropDownStarsView: View {
    @ObservedObject var exerciseBadgesList:ExerciseBadgesList
    @ObservedObject var viewManager = ViewManager.shared
    let user:User
    let scale:Scale
    let exerciseName:String
    let onClose: () -> Void
    @State private var starIconSize: CGFloat = 0
    @State private var offset: CGFloat = 5.0
    @State private var rotationAngle: Double = 0
    @State private var verticalOffset: CGFloat = -60
    @State var handType = KeyboardType.right
    static var nextColorCount = 0
    let starColors = FigmaColors.shared.getColors1("DropStarColors", name: nil, shade: 3)
    
    init(user:User, scale:Scale, exerciseName:String, onClose: @escaping () -> Void) {
        self.user = user
        self.exerciseBadgesList = ExerciseBadgesList.shared
        self.scale = scale
        self.exerciseName = exerciseName
        self.onClose = onClose
    }
    
    func getNextColor() -> Color {
        let cindex = ExerciseDropDownStarsView.nextColorCount % starColors.count
        let color = starColors[cindex]
        ExerciseDropDownStarsView.nextColorCount += 1
        return color
    }
    
    func getDotSpace() -> CGFloat {
        if ScalesModel.shared.scale.octaves > 1 {
            let spacing:CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4 : 10
            if ScalesModel.shared.scale.scaleType == .chromatic {
                //spacing *= 0.6
            }
            return spacing
        }
        else {
            return 10
        }
    }
    
    ///Must be smaller for lots of stars. e.g. chromatic 2 octaves
    func getStarShape(scale: Scale) -> String {
        if UIDevice.current.userInterfaceIdiom == .phone && scale.octaves > 1 && scale.scaleType == .chromatic  {
            return "·"
        }
        else {
            return "⊙"
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // Ensure button is positioned at the top-right
            VStack(spacing:0) {
                HStack(spacing: getDotSpace()) {
                    
                    let animationDuration = 0.5 //0.1
                    
                    ///Draw a place for every note in the scale. Put badges in places where the note was played
                    ForEach(0..<scale.getScaleNoteStates(handType: handType).count, id: \.self) { scaleNoteNumber in
                        if scaleNoteNumber == exerciseBadgesList.totalBadges - 1  {
                            ///Drop in the last badge awarded
                            ZStack {
                                Text(getStarShape(scale: scale)).foregroundColor(.blue)
                                if exerciseBadgesList.totalBadges > 0 {
                                    StarShape(shapeSize: starIconSize, offset: offset, color: self.getNextColor())
                                        .rotationEffect(Angle.degrees(rotationAngle))
                                        .offset(y: scaleNoteNumber == exerciseBadgesList.totalBadges - 1 ? verticalOffset : 0)
                                        .onAppear {
                                            if scaleNoteNumber == exerciseBadgesList.totalBadges - 1 {
                                                withAnimation(Animation.easeOut(duration: animationDuration)) {
                                                    rotationAngle = 360
                                                    verticalOffset = 0
                                                }
                                            }
                                        }
                                }
                            }
                            .frame(width: starIconSize, height: starIconSize)
                        }
                        else {
                            ZStack {
                                Text(getStarShape(scale: scale)).foregroundColor(.blue)
                                if scaleNoteNumber < exerciseBadgesList.totalBadges {
                                    StarShape(shapeSize: starIconSize, offset: offset,
                                              color: self.getNextColor())
                                    .opacity(scaleNoteNumber < exerciseBadgesList.totalBadges  ? 1 : 0)
                                }
                            }
                            .frame(width: starIconSize, height: starIconSize)
                        }
                    }
                    Text("XXXX").foregroundColor(.clear) ///Make sure button below does not cover last star(s)
                }
                .padding()
                .onChange(of: exerciseBadgesList.totalBadges) { old, _ in
                    rotationAngle = 0
                    verticalOffset = -60
                }
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
            var widthScale = scale.getScaleNoteCount() >= 16 ? 0.02 : 0.03
            if scale.octaves > 1 {
                if scale.scaleType == .chromatic {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        widthScale = widthScale * 0.7
                    }
                    else {
                        widthScale = widthScale * 0.5
                    }
                }
            }
            self.starIconSize = UIScreen.main.bounds.size.width * widthScale
        }
    }
}

