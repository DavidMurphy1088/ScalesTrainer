import SwiftUI

struct MetronomeView: View {
    let width:CGFloat
    let height:CGFloat
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = Metronome.shared
    @State var examTempo:Int = 0
    
    @State var beat = 0
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    @State private var sliderValue: Double = 0.0
    let tempoDelta = 5
    let tempoTickCount = 20
    @State var lowestTempo = 0
    @State var highestTempo = 0
    //var steps = 0
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        
    }
    
    var body: some View {
        HStack {
            Text("")
            Button(action: {
                if metronome.statusPublished == .running {
                    metronome.stop("MetronomeView stop[ button")
                }
                else {
                    metronome.start("MetronomeView start button", doLeadIn: false, scale: scalesModel.scale)
                }
            }) {
                Image(metronome.statusPublished == .running ? "metronome-hilit" : "metronome-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: height)
            }
            
            HStack {
                if scalesModel.scale.timeSignature.top % 3 == 0 {
                    let dot = "\u{00B7}"
                    Text("♩\(dot) = \(Int(self.sliderValue))")
                }
                else {
                    Text("♩=\(Int(self.sliderValue))")
                }
            }
            .frame(width: UIScreen.main.bounds.size.width * 0.08)
            
            ZStack {
                Slider(value: $sliderValue, in: Double(lowestTempo)...Double(highestTempo)) //, step: 1)
                    .tint(.black)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .onChange(of: sliderValue) { oldValue, newValue in
                        print("========== MEt Slider changed from \(oldValue) to \(newValue)")
                        metronome.currentTempo = Int(sliderValue)
                    }
                
                HStack {
                    //                    ForEach(0..<steps, id: \.self) { step in
                    //                        let examTempo = lowestTempo + (step * tempoDelta) == examTempo
                    //                        RoundedRectangle(cornerRadius: 4)
                    //                            .strokeBorder(Color.primary, lineWidth: 1)
                    //                            .background(
                    //                                RoundedRectangle(cornerRadius: 4)
                    //                                    .fill(examTempo ? Color.blue : Color.clear)
                    //                            )
                    //                            .frame(width: examTempo ? 12 : 4, height: height * 0.50)
                    //                            .frame(maxWidth: .infinity)
                    //
                    //                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear() {
            self.examTempo = scalesModel.scale.minTempo
            var highDelta = 12
            var lowDelta = 14
            let scale = scalesModel.scale
            if [ScaleType.brokenChordMajor, ScaleType.brokenChordMinor].contains(scale.scaleType)  {
                lowDelta = lowDelta / 2
                highDelta = highDelta / 2
            }
//            let user = Settings.shared.getCurrentUser("Metronome")
//            if user.boardAndGrade.board.name == "ABRSM" {
//                if [ScaleType.arpeggioMajor, .arpeggioMinor, .arpeggioDiminishedSeventh].contains(scale.scaleType)  {
//                   if user.boardAndGrade.grade == 5 {
//                       lowDelta = lowDelta / 2
//                       highDelta = highDelta / 2
//                   }
//                }
//            }
            lowestTempo = examTempo - lowDelta
            highestTempo = examTempo + highDelta
            
            //steps = (highestTempo - lowestTempo) / tempoDelta
            self.sliderValue = Double(self.examTempo)
            print("======= MVIEW onAppear", self.examTempo, self.sliderValue)
        }
    }
    
}
