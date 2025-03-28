import SwiftUI

struct MetronomeView: View {
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = Metronome.shared
    @State var beat = 0
    
    var body: some View {
        ///...delayed since relies on published state 🙄
        Button(action: {
            //metronome.setTicking(way: !metronome.isMetronomeTicking())
            if metronome.statusPublished == .notStarted {
                metronome.start(doStandby: false, doLeadIn: false, scale: nil)
            }
            else {
                metronome.stop()
            }
        }) {
            HStack {
                //Text("\(beat)")
                Image("metronome-left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotation3DEffect(
                        .degrees(metronome.tickedCountPublished % 2 == 0 ? 0 : 180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .frame(width: UIScreen.main.bounds.size.width * 0.04)
        }
    }
}
