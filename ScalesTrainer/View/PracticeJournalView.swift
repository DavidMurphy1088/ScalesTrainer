import SwiftUI

struct PracticeJournalView: View {
    let scaleGroup:ScaleGroup = ScalesModel.shared.selectedScaleGroup
    let scaleGroupTitle:String = ScalesModel.shared.selectedScaleGroup.name

    let days = ["Mon","Tue","Wed ","Thu","Fri","Sat", "Sun"]
    let color = Color(red: 0.1, green: 0.7, blue: 0.2)
    
//    func getColor(day:String) -> Color {
//        PracticeScale.dayNum += 1
//        if PracticeScale.dayNum % 3 == 0 {
//            return Color.gray
//        }
//        return Color.blue
//    }
    
    func WeekDaysView() -> some View {
        HStack {
            ForEach(days, id: \.self) { day in
                Text(" "+day+" ")
                    //.padding()
                    //.background(getColor(day: day))
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(3)
            }
        }
    }

    var body: some View {
        ZStack {
            let width = UIScreen.main.bounds.width * 0.9
            let height = UIScreen.main.bounds.height * 0.8
            let barHeight = height * 0.010
            let barWidth = width * 0.8
            Image(UIGlobals.shared.screenImageBackground)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            VStack {
                Text("Your Practice Scales for \(scaleGroupTitle)").bold().padding().commonFrameStyle(backgroundColor: .white)
                    .frame(width: width)
                List {
                    ForEach(Array(self.scaleGroup.scales.enumerated()), id: \.element.id) { index, practiceJournalScale in
                        VStack {
                            HStack {
                                Text("\(practiceJournalScale.getName()) ♩=90").padding()
                                ///Text("Practice Days")
                                WeekDaysView().padding()
//                                Button("Practice Scale") {
//                                    ScalesView()
//                                }.padding()
                                Spacer()
                                NavigationLink(destination: ScalesView(practiceJournalScale: practiceJournalScale)) {
                                    Text("Practice Scale").foregroundColor(.blue)
                                }
                                .frame(width: width * 0.2)
                            }
                            VStack {
                                HStack {
                                    Text("Progress")
                                    ZStack {
                                        Rectangle()
                                            .stroke(Color.gray, lineWidth: 1)
                                            .frame(width: barWidth, height: barHeight)
                                        HStack {
                                            Rectangle()
                                                .fill(Color.green)
                                                .frame(width: barWidth * 0.33 * practiceJournalScale.completePercentage, height: barHeight)
                                            Spacer()
                                        }
                                    }
                                }
                                //.frame(width: barWidth, height: barHeight)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
                .commonFrameStyle(backgroundColor: .white)
                .frame(width: width, height: height)
            }
        }
    }
}
