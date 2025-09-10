import SwiftUI

struct MetronomeViewOld: View {
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

struct SliderWithMarkers: View {
    @State private var value: Double = 0.0
    let steps = 20  

    var body: some View {
        VStack {
            Slider(value: $value, in: 0...Double(steps - 1), step: 1)
                .padding(.horizontal)

            HStack {
                ForEach(0..<steps, id: \.self) { id in
                    let examTempo = id == Int((Double(steps) * 0.66))
                    Rectangle()
                        .fill(examTempo ? Color.green : Color.primary)
                        .frame(width: examTempo ? 10 : 2, height: examTempo ? 16 : 10)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MetronomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.defaultMinListRowHeight) var systemSpacing
    let scalesModel = ScalesModel.shared
    @ObservedObject var metronome = Metronome.shared
    @State var beat = 0
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        HStack {
            Spacer()
            Text("")
            Text("...metronome...").font(.headline).padding()
            if !compact {
                SliderWithMarkers()
            }
            Text("")
            Spacer()
            
        }
        .padding(sizeClass == .regular ? systemSpacing : 0)
        .figmaRoundedBackgroundWithBorder(fillColor: Color.white)
    }
}
