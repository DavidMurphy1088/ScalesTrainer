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
    //@State var imageIds:[Int] = []
    @State var handType = KeyboardType.right
    @State var starColor = Color.red
    
    init(user:User, scale:Scale, exerciseName:String, onClose: @escaping () -> Void) {
        self.user = user
        self.exerciseBadgesList = ExerciseBadgesList.shared
        self.scale = scale
        self.exerciseName = exerciseName
        self.onClose = onClose
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
            VStack(spacing:0) {

                HStack(spacing: getDotSpace()) {
                    
                    //let imWidth = CGFloat(40)
                    let animationDuration = 0.5 //0.1
                    
                    ///Draw a place for every note in the scale. Put badges in places where the note was played
                    ForEach(0..<scale.getScaleNoteStates(handType: handType).count, id: \.self) { scaleNoteNumber in
                        if scaleNoteNumber == exerciseBadgesList.totalBadges - 1  {
                            ///Drop in the last badge awarded
                            ZStack {
                                Text("⊙").foregroundColor(.blue)
                                if exerciseBadgesList.totalBadges > 0 {
                                    //let user = Settings.shared.getCurrentUser("Badges View")
                                    StarShape(shapeSize: starIconSize, offset: offset, color: self.starColor)
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
                                Text("⊙").foregroundColor(.blue)
                                if scaleNoteNumber < exerciseBadgesList.totalBadges {
                                    StarShape(shapeSize: starIconSize, offset: offset, color: self.starColor).opacity(scaleNoteNumber < exerciseBadgesList.totalBadges  ? 1 : 0)
                                }
                            }
                            .frame(width: starIconSize, height: starIconSize)
                            //.border(AppOrange)
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
            let scale = scale.getScaleNoteCount() >= 16 ? 0.02 : 0.03
            self.starIconSize = UIScreen.main.bounds.size.width * scale
//            let colorNames = FigmaColors.shared.allColorNames()
//            var colorIndex = 0
//            switch scale.scaleType {
//            case .major:
//                colorIndex = 0
//            case .harmonicMinor:
//                colorIndex = 1
//            case .melodicMinor:
//                colorIndex = 2
//            case .naturalMinor:
//                colorIndex = 3
//            case .brokenChordMinor:
//                colorIndex = 4
//           default:
//                colorIndex = 5
//            }
//            let colorName = colorNames[colorIndex % colorNames.count]
//            self.starColor = FigmaColors.shared.getColor(colorName)
            self.starColor = FigmaColors.shared.getColor(viewManager.userColorPublished).opacity(FigmaColors.shared.userDisplayOpacity)
        }
    }
}

