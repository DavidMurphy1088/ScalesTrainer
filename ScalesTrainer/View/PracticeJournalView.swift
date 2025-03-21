//import SwiftUI
//
//struct PracticeJournalView: View {
//    let musicBoardGrade:MusicBoardGrade
//    @State private var navigateToScales = false
//    
//    let days = ["Mon","Tue","Wed ","Thu","Fri","Sat", "Sun"]
//    let color = Color(red: 0.1, green: 0.7, blue: 0.2)
//    enum ScaleOrder {
//        case none
//        case best
//        case worst
//    }
//    @State var ordering:ScaleOrder = .none
//    
//    init(musicBoardGrade:MusicBoardGrade) {
//        self.musicBoardGrade = musicBoardGrade
//    }
//    
//    func getName() -> String {
//        let name = Settings.shared.firstName
//        let journalName = "Practice Journal " + (name.count > 0 ? "for \(name)" : "")
//        return journalName
//    }
//    
//    func WeekDaysView() -> some View {
//        HStack {
//            ForEach(days, id: \.self) { day in
//                Text(" "+day+" ")
//                    //.padding()
//                    //.background(getColor(day: day))
//                    .background(Color.gray)
//                    .foregroundColor(.white)
//                    .cornerRadius(3)
//            }
//        }
//    }
//    
//    func getColor(progress:Double) -> Color {
//        if progress < 0.2 {
//            return AppOrange
//        }
//        if progress < 0.4 {
//            return Color.yellow
//            
//        }
//        return Color.green
//    }
//        
//    var body: some View {
//        ZStack {
//            let width = UIScreen.main.bounds.width * 0.95
//            let height = UIScreen.main.bounds.height * 0.8
//            let barHeight = height * 0.010
//            let barWidth = width * 0.6 * 0.5
//            Image(UIGlobals.shared.getBackground())
//                .resizable()
//                .scaledToFill()
//                .edgesIgnoringSafeArea(.top)
//                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
//            VStack {
//                TitleView(screenName: "")
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            self.ordering = .best
//                        }) {
//                            Text(" Show Highest Progress Scales ").hilighted(backgroundColor: .blue)
//                        }
//                        Spacer()
//                        Button(action: {
//                            self.ordering = .worst
//                        }) {
//                            Text(" Show Lowest Progress Scales ").hilighted(backgroundColor: .blue)
//                        }
//                        Spacer()
//                    }
//                    List {
//                        ForEach(Array(self.musicBoardGrade.getScales().sorted(by: { lhs, rhs in
//                            switch self.ordering {
//                            case .best:
//                                lhs.progressLH + lhs.progressRH > rhs.progressLH + lhs.progressRH
//                            case .worst:
//                                lhs.progressLH + lhs.progressRH < rhs.progressLH + lhs.progressRH
//                            default:
//                                lhs.orderIndex < rhs.orderIndex
//                            }
//                            
//                        }).enumerated()), id: \.element.id) { index, journalScale in
//                            VStack(spacing: 0) {
//                                HStack {
//                                    Text("\(journalScale.getName())\n♩=90").padding()
//                                    ///Text("Practice Days")
//                                    WeekDaysView().padding()
//                                    Spacer()
//                                    Button(action: {
//                                        let _ = ScalesModel.shared.setScaleByRootAndType(scaleRoot: journalScale.scaleRoot,
//                                                                                         scaleType: journalScale.scaleType,
//                                                                                         octaves: Settings.shared.defaultOctaves,
//                                                                                         hand: 0, ctx: "Journal")
//                                        navigateToScales = true
//                                    }) {
//                                        Text("Go to \n Scale")
//                                            .foregroundColor(.blue)
//                                            .frame(width: width * 0.2)
//                                    }
//                                    
//                                    NavigationLink(destination: ScalesView(), isActive: $navigateToScales) {
//                                    }.frame(width: width * 0.0)
//                                }
//                                VStack(spacing: 0) {
//                                    HStack {
//                                        Text("LH\nProgress")
//                                        ZStack {
//                                            Rectangle()
//                                                .stroke(Color.gray, lineWidth: 1)
//                                                .frame(width: barWidth, height: barHeight)
//                                            HStack {
//                                                Rectangle()
//                                                    .fill(getColor(progress: journalScale.progressLH))
//                                                    .frame(width: barWidth * journalScale.progressLH, height: barHeight)
//                                                Spacer()
//                                            }
//                                        }
//                                        Text("RH\nProgress")
//                                        ZStack {
//                                            Rectangle()
//                                                .stroke(Color.gray, lineWidth: 1)
//                                                .frame(width: barWidth, height: barHeight)
//                                            HStack {
//                                                Rectangle()
//                                                    .fill(getColor(progress: journalScale.progressRH))
//                                                    .frame(width: barWidth * journalScale.progressRH, height: barHeight)
//                                                Spacer()
//                                            }
//                                        }
//                                        
//                                    }
//                                    //.frame(width: barWidth, height: barHeight)
//                                }
//                                .padding()
//                            }
//                        }
//                    }
//                }
//                .commonFrameStyle(backgroundColor: .white)
//            }
//            .frame(width: width, height: height)
//        }
//    }
//}
