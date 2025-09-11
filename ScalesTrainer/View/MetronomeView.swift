import SwiftUI

//struct MetronomeViewOld: View {
//    let scalesModel = ScalesModel.shared
//    @ObservedObject var metronome = Metronome.shared
//    @State var beat = 0
//    
//    var body: some View {
//        ///...delayed since relies on published state 🙄
//        Button(action: {
//            //metronome.setTicking(way: !metronome.isMetronomeTicking())
//            if metronome.statusPublished == .notStarted {
//                metronome.start(doStandby: false, doLeadIn: false, scale: nil)
//            }
//            else {
//                metronome.stop()
//            }
//        }) {
//            HStack {
//                //Text("\(beat)")
//                Image("metronome-left")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .rotation3DEffect(
//                        .degrees(metronome.tickedCountPublished % 2 == 0 ? 0 : 180),
//                        axis: (x: 0, y: 1, z: 0)
//                    )
//            }
//            .frame(width: UIScreen.main.bounds.size.width * 0.04)
//        }
//    }
//}


struct MetronomeView: View {
    let width:CGFloat
    let height:CGFloat
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = Metronome.shared
    @State var beat = 0
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    @State private var sliderValue: Double = 0.0
    let tempoDelta = 5
    let examTempo = 80
    let tempoTickCount = 20
    var lowestTempo = 0
    var highestTempo = 0
    var steps = 0
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        lowestTempo = examTempo - tempoDelta * 8
        highestTempo = examTempo + tempoDelta * 3
        steps = (highestTempo - lowestTempo) / tempoDelta
    }
    
    var body: some View {
        HStack {
            Text("")
            Image("metronome-left")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
            HStack {
                Text("♩=\(Int(self.sliderValue))")
            }
            .frame(width: UIScreen.main.bounds.size.width * 0.04)
            
            ZStack {
                Slider(value: $sliderValue, in: Double(lowestTempo)...Double(highestTempo)) //, step: 1)
                    .tint(.black)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        Capsule()
                            .fill(Color.black)
                            .frame(height: 2)              // <— thickness of the bar
                            .padding(.horizontal, 6)       // so it doesn’t run under the thumb edges
                    )
                
                HStack {
                    ForEach(0..<steps, id: \.self) { step in
                        let examTempoColor = lowestTempo + (step * tempoDelta) == examTempo
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.primary, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(examTempoColor ? Color.blue : Color.clear)
                            )
                            .frame(width: examTempoColor ? 12 : 8, height: height * 0.75)
                            .frame(maxWidth: .infinity)
//                        Rectangle()
//                            .fill(examTempo ? Color.green : Color.primary)
//                            .frame(width: examTempo ? 16 : 4, height: examTempo ? height : height * 0.4)
//                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
        
    }
}
