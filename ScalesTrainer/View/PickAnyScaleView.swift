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
    let backgroundImage = UIGlobals.shared.getBackground()
    init() {
    }
    
    func getScale(major:Bool) -> PracticeJournalScale {
        let scale:PracticeJournalScale
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
                scaleType = .chromatic
            default:
                scaleType = .major
            }
            scale = PracticeJournalScale(scaleRoot: ScaleRoot(name: rootsMajor[rootIndexMajor]), scaleType: scaleType)
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
                
            default:
                scaleType = .major
            }
            scale = PracticeJournalScale(scaleRoot: ScaleRoot(name: rootsMinor[rootIndexMinor]), scaleType: scaleType)
        }
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
                VStack {
                    Text("Pick Any Scale").font(.title)//.foregroundColor(.blue)
                }
                .commonTitleStyle()
                VStack {
                    VStack {
                        Text("Major Scales").padding()
                        HStack {
                            Text("Scale Root:")//.padding()
                            Picker("Select Value", selection: $rootIndexMajor) {
                                ForEach(rootsMajor.indices, id: \.self) { index in
                                    Text("\(rootsMajor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Scale Type:").padding()
                            Picker("Select Value", selection: $typeIndexMajor) {
                                ForEach(typesMajor.indices, id: \.self) { index in
                                    Text("\(typesMajor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        let scale = getScale(major: true)
                        NavigationLink(destination: ScalesView(practiceJournalScale: scale)) {
                            HStack {
                                Text(" Practice Scale \(scale.getName()) ").font(.title2)
                            }
                            //.padding()
                            .hilighted(backgroundColor: .blue)
                        }
                    }
                    //.border(Color.gray)
                    .commonFrameStyle()
                    .padding()
                    
                    VStack {
                        Text("Minor Scales").padding()
                        HStack {
                            Text("Scale Root:")//.padding()
                            Picker("Select Value", selection: $rootIndexMinor) {
                                ForEach(rootsMinor.indices, id: \.self) { index in
                                    Text("\(rootsMinor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Scale Type:").padding()
                            Picker("Select Value", selection: $typeIndexMinor) {
                                ForEach(typesMinor.indices, id: \.self) { index in
                                    Text("\(typesMinor[index])")
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        let scale = getScale(major: false)
                        NavigationLink(destination: ScalesView(practiceJournalScale: scale)) {
                            HStack {
                                Text(" Practice Scale \(scale.getName()) ").font(.title2)
                            }
                            .hilighted(backgroundColor: .blue)
                        }
                    }
                    .commonFrameStyle()
                    .padding()
                }
                .commonFrameStyle(backgroundColor: .white)

            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.8)
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
    }
}
