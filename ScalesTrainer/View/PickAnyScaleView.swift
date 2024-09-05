import SwiftUI

struct PickAnyScaleView: View {
    @State var typeIndexMajor:Int = 0
    @State var rootIndexMajor:Int = 0
    @State var typesMajor:[String] = []
    @State var rootsMajor:[String] = ["A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭"]

    @State var typeIndexMinor:Int = 0
    @State var rootIndexMinor:Int = 0
    @State var typesMinor:[String] = []
    @State var rootsMinor:[String] = ["A", "B♭", "B", "C", "C#", "D", "E♭", "E", "F", "F#", "G", "G#"]
    
    @State var hands:[String] = ["Right Hand", "Left Hand", "Hands Together"]
    @State var indexHands:Int = 0
    
    @State var octaves:[String] = ["1", "2", "3","4"]
    @State var indexOctave:Int = 0

    let backgroundImage = UIGlobals.shared.getBackground()
    init() {
    }
    
    func setModelScale(major:Bool) -> Scale {
        let scale:Scale
        let scaleType:ScaleType
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
                scaleType = .contraryMotion
            case 6:
                scaleType = .chromatic
            default:
                scaleType = .major
            }
            scale = Scale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMajor]), scaleType: scaleType, 
                          octaves: self.indexOctave+1, hand: self.indexHands, minTempo: 90, dynamicType: .mf, articulationType: .legato)
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
            scale = Scale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMinor]), scaleType: scaleType, octaves: self.indexOctave+1,
                          hand: self.indexHands, minTempo: 90, dynamicType: .mf, articulationType: .legato)
        }
        ScalesModel.shared.setScale(scale: scale)
        return scale
    }
    
    var body: some View {
        ZStack {
            Image(backgroundImage)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.top)
                .opacity(UIGlobals.shared.screenImageBackgroundOpacity)
            
            VStack {
                TitleView(screenName: "")
                
                VStack {
                    VStack {
                        Text("Major Scales").font(.title).padding()
                        HStack {
                            Text("Scale Root:").font(.title2).padding()
                            Picker("Select Value", selection: $rootIndexMajor) {
                                ForEach(rootsMajor.indices, id: \.self) { index in
                                    Text("\(rootsMajor[index])")
                                }
                            }
                            .pickerStyle(.menu)

                            Text("Scale Type:").font(.title2).padding()
                            Picker("Select Value", selection: $typeIndexMajor) {
                                ForEach(typesMajor.indices, id: \.self) { index in
                                    Text("\(typesMajor[index])")
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
                        NavigationLink(destination: ScalesView()) {
                            HStack {
                                let name = scale.getScaleName(handFull: true, octaves: true, tempo: true, dynamic:false, articulation:false)
                                Text("  \(name)  ").font(.title2).padding()
                            }
                            .hilighted(backgroundColor: .blue)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            let _ = setModelScale(major: true)
                        })
                    }
                    .commonFrameStyle()
                    .padding()
                    
                    VStack {
                        Text("Minor Scales").font(.title).padding()
                        HStack {
                            Text("Scale Root:").font(.title2).padding()
                            Picker("Select Value", selection: $rootIndexMinor) {
                                ForEach(rootsMinor.indices, id: \.self) { index in
                                    Text("\(rootsMinor[index])")
                                }
                            }
                            .pickerStyle(.menu)

                            Text("Scale Type:").font(.title2).padding()
                            Picker("Select Value", selection: $typeIndexMinor) {
                                ForEach(typesMinor.indices, id: \.self) { index in
                                    Text("\(typesMinor[index])")
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
                        NavigationLink(destination: ScalesView()) {
                            HStack {
                                let name = scale.getScaleName(handFull: true, octaves: true, tempo: true, dynamic:false, articulation:false)
                                Text(" \(name) ").font(.title2).padding()
                            }
                            .hilighted(backgroundColor: .blue)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            let _ = setModelScale(major: false)
                        })
                    }
                    .commonFrameStyle()
                    .padding()
                }
                .commonFrameStyle(backgroundColor: .white)
            }
            .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth, height: UIScreen.main.bounds.height * 0.9)
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
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}
