
import SwiftUI
import Foundation
import Combine
import Accelerate
import AVFoundation

struct SelectHandForPractice: View {
    @Environment(\.dismiss) var dismiss
    let user:User
    let scale:Scale
    let titleColor:Color
    
    @State var navigateToScale = false
    let imageSize = UIScreen.main.bounds.size.width * 0.05
    @State var scaleToPractice:Scale?
    
    init(user:User, scale:Scale, titleColor:Color) {
        self.user = user
        self.scale = scale
        self.titleColor = titleColor
    }
    
    func setScaleForPractice(practiceHands:[Int]) {
        scaleToPractice = ScalesModel.shared.setScaleByRootAndType(scaleRoot: scale.scaleRoot,
                                                         scaleType: scale.scaleType,
                                                         scaleMotion: scale.scaleMotion,
                                                         minTempo: scale.minTempo, octaves: scale.octaves,
                                                         hands: practiceHands,
                                                         dynamicTypes: scale.dynamicTypes,
                                                         articulationTypes: scale.articulationTypes,
                                                         ctx: "PracticeChartHands",
                                                         scaleCustomisation:scale.scaleCustomisation)
    }
    
    var body: some View {
        let nameFull = scale.getScaleName(handFull: false)
        let name = scale.getScaleName(showHands: false, handFull: false)
        HStack {
            Text("").padding()
            VStack (alignment: .leading) {
                Text("")
                Text("")
                Text("")
                Text(nameFull).font(.title)
                    .padding()
                    .figmaRoundedBackground(fillColor: titleColor)
                Text("")
                Text("In the exam \(nameFull) must be played with both hands.")
                Text("But here you can also practise \(name) hands separately.")
                Text("")
                Text("")
                Text("")
                FigmaButton(label: {
                    VStack {
                        HStack {
                            Image("hand_left")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height:imageSize)
                            Image("hand_right")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height:imageSize)
                        }
                        Text("Practise Hands Together")
                    }
                }, action: {
                    setScaleForPractice(practiceHands: [0,1])
                    navigateToScale = true
                })
                Text("")
                HStack {
                    FigmaButton(label: {
                        VStack {
                            HStack {
                                Image("hand_left")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height:imageSize)
                            }
                            Text("Practise Left Hand")
                        }
                    }, action: {
                        setScaleForPractice(practiceHands: [1])
                        navigateToScale = true
                    })
                    FigmaButton(label: {
                        VStack {
                            HStack {
                                Image("hand_right")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height:imageSize)
                            }
                            Text("Practise Right Hand")
                        }
                    }, action: {
                        setScaleForPractice(practiceHands: [0])
                        navigateToScale = true
                    })

                }
                Text("")
                Text("")
                Text("")
            }
            //.border(.blue)
            Text("").padding()
        }
        .figmaRoundedBackground()
        //.border(.red)
        .onAppear {
            //self.scale = ScalesModel.shared.scale
        }
        .navigationDestination(isPresented: $navigateToScale) {
            if let scale = self.scaleToPractice {
                ScalesView(user: user, scale: scale)
            }
        }
        .commonToolbar(
            title: "Select Hands",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
