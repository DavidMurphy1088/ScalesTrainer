import SwiftUI

struct ScalesLibraryView: View {
    @State var typeIndexMajor:Int = 0
    @State var rootIndexMajor:Int = 0
    @State var motionIndex:Int = 0

    @State var typesMajor:[String] = []
    @State var scaleMotions:[String] = []
    @State var rootsMajor:[String] = ["A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭"]

    @State var typeIndexMinor:Int = 0
    @State var rootIndexMinor:Int = 0
    @State var typesMinor:[String] = []
    @State var rootsMinor:[String] = ["A", "B♭", "B", "C", "C#", "D", "E♭", "E", "F", "F#", "G", "G#"]
    
    @State var hands:[String] = ["Right Hand", "Left Hand", "Hands Together"]
    @State var indexHands:Int = 0
    
    @State var octaves:[String] = ["1", "2", "3","4"]
    @State var indexOctave:Int = 0

    init() {
    }
    
    func setModelScale(major:Bool) -> Scale {
        let scale:Scale
        let scaleType:ScaleType
        let hands:[Int]
        let tempo = 90
        
        if self.indexHands == 2 {
            hands = [0,1]
        }
        else {
            hands = [self.indexHands]
        }
        
        if major {
            switch typeIndexMajor {
            case 0:
                scaleType = .major
            case 1:
                scaleType = .arpeggioMajor
            case 2:
                scaleType = .arpeggioDominantSeventh
            case 3:
                scaleType = .arpeggioMajorSeventh
            case 4:
                scaleType = .brokenChordMajor
            case 5:
                scaleType = .chromatic
            default:
                scaleType = .major
            }
            
            let scaleMotion:ScaleMotion
            switch motionIndex {
            case 0:
                scaleMotion = .similarMotion
            default:
                scaleMotion = .contraryMotion
            }
            
            scale = Scale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMajor]), scaleType: scaleType, scaleMotion: scaleMotion,
                          octaves: self.indexOctave+1, hands: hands, minTempo: tempo, dynamicTypes: [.mf], articulationTypes: [.legato])
        }
        else {
            switch typeIndexMinor {
            case 0:
                scaleType = .naturalMinor
            case 1:
                scaleType = .harmonicMinor
            case 2:
                scaleType = .melodicMinor
            case 3:
                scaleType = .arpeggioMinor
            case 4:
                scaleType = .arpeggioDiminished
            case 5:
                scaleType = .arpeggioMinorSeventh
            case 6:
                scaleType = .arpeggioDiminishedSeventh
            case 7:
                scaleType = .arpeggioHalfDiminished
            case 8:
                scaleType = .brokenChordMinor

            default:
                scaleType = .harmonicMinor
            }
            
            let scaleMotion:ScaleMotion
            switch motionIndex {
            case 0:
                scaleMotion = .similarMotion
            default:
                scaleMotion = .contraryMotion
            }
            scale = Scale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMinor]), scaleType: scaleType, scaleMotion: scaleMotion, octaves: self.indexOctave+1,
                          hands: hands, minTempo: tempo, dynamicTypes: [.mf], articulationTypes: [.legato])
        }
        ScalesModel.shared.setScaleByRootAndType(scaleRoot: scale.scaleRoot, scaleType: scale.scaleType,
                                                 scaleMotion: scale.scaleMotion, minTempo: tempo, octaves: scale.octaves, hands: scale.hands,
                                                 dynamicTypes: [.mf], articulationTypes: [.legato], ctx: "Library")
        return scale
    }
    
    var body: some View {
        NavigationView {
            VStack {
                //TitleView(screenName: "Pick Any Scale").commonFrameStyle()
                Text("Scales Library")
                    .font(.title2)
                    .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleDark)
                VStack {
                    VStack {
                        Text("Major Scales").font(.title).padding()
                        HStack {
                            Text("Scale:").font(.title2).padding()
                            Picker("Select Value", selection: $rootIndexMajor) {
                                ForEach(rootsMajor.indices, id: \.self) { index in
                                    Text("\(rootsMajor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Type:").font(.title2).padding()
                            Picker("Select Value", selection: $typeIndexMajor) {
                                ForEach(typesMajor.indices, id: \.self) { index in
                                    Text("\(typesMajor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Motion:").font(.title2).padding()
                            Picker("Select Value", selection: $motionIndex) {
                                ForEach(scaleMotions.indices, id: \.self) { index in
                                    Text("\(scaleMotions[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Hand:").font(.title2).padding()
                            Picker("Select Value", selection: $indexHands) {
                                ForEach(hands.indices, id: \.self) { index in
                                    Text("\(hands[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Octaves:").font(.title2).padding()
                            Picker("Select Value", selection: $indexOctave) {
                                ForEach(octaves.indices, id: \.self) { index in
                                    Text("\(octaves[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        let scale = setModelScale(major: true)
                        NavigationLink(destination: ScalesView(practiceChartCell: nil)) {
                            HStack {
                                let name = scale.getScaleName(handFull: true) + " " + scale.getScaleAttributes(showTempo: false)
                                Text("  \(name)  ").font(.title2).padding()
                            }
                            .hilighted(backgroundColor: .blue)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            let _ = setModelScale(major: true)
                        })
                    }
                    .commonFrameStyle(backgroundColor: Color.white)
                    .padding()
                    
                    VStack {
                        Text("Minor Scales").font(.title).padding()
                        HStack {
                            Text("Scale:").font(.title2).padding()
                            Picker("Select Value", selection: $rootIndexMinor) {
                                ForEach(rootsMinor.indices, id: \.self) { index in
                                    Text("\(rootsMinor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Type:").font(.title2).padding()
                            Picker("Select Value", selection: $typeIndexMinor) {
                                ForEach(typesMinor.indices, id: \.self) { index in
                                    Text("\(typesMinor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Motion:").font(.title2).padding()
                            Picker("Select Value", selection: $motionIndex) {
                                ForEach(scaleMotions.indices, id: \.self) { index in
                                    Text("\(scaleMotions[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Hand:").font(.title2).padding()
                            Picker("Select Value", selection: $indexHands) {
                                ForEach(hands.indices, id: \.self) { index in
                                    Text("\(hands[index])")
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Text("Octaves:").font(.title2).padding()
                            Picker("Select Value", selection: $indexOctave) {
                                ForEach(octaves.indices, id: \.self) { index in
                                    Text("\(octaves[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        let scale = setModelScale(major: false)
                        NavigationLink(destination: ScalesView(practiceChartCell: nil)) {
                            HStack {
                                //let name = scale.getScaleName(handFull: true, octaves: true)
                                let name = scale.getScaleName(handFull: true) + " " + scale.getScaleAttributes(showTempo: false)
                                Text(" \(name) ").font(.title2).padding()
                            }
                            .hilighted(backgroundColor: .blue)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            let _ = setModelScale(major: false)
                        })
                    }
                    .commonFrameStyle(backgroundColor: Color.white)
                    .padding()
                    Spacer()
                }
                .commonFrameStyle()
                .onAppear() {
                    if self.typesMinor.count == 0 {
                        for scale in ScaleType.allCases {
                            if scale.isMajor() {
                                self.typesMajor.append(scale.description)
                            }
                            else {
                                self.typesMinor.append(scale.description)
                            }
                        }
                        for scale in ScaleMotion.allCases {
                            self.scaleMotions.append(scale.description)
                        }
                        
                    }
                }
            }
            .commonFrameStyle()
            //.border(.red, width: 2)
            //.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
