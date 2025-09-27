
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
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
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
        let scaleName = scale.getScaleName() //scale.getScaleName(handFull: false)
        let name = scale.getScaleName(showHands: false, handFull: false)
        HStack {
            Text("").padding()
            VStack (alignment: .leading) {
                Text("")
                if !compact {
                    Text("")
                    Text("")
                }
                Text(scaleName).font(compact ? .title3 : .title2)
                    .padding()
                    .figmaRoundedBackgroundWithBorder(fillColor: titleColor)
                Text("")
                if !compact {
                    Text("")
                }
                Text("")
                Text("In the exam \(scaleName) must be played with both hands.")
                Text("However you can also practise \(name) hands separately.")
                Text("")
                if !compact {
                    Text("")
                }
                Text("")
                FigmaButton("Hands Together", action: {
                    setScaleForPractice(practiceHands: [0,1])
                    navigateToScale = true
                })
                Text("")
                HStack {
                    FigmaButton("Practise Left Hand", action: {
                        setScaleForPractice(practiceHands: [1])
                        navigateToScale = true
                    })
                    FigmaButton("Practise Right Hand", action: {
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
        .figmaRoundedBackgroundWithBorder()

        .navigationTitle("Select Hands")
        .toolbar(.hidden, for: .tabBar) // Hide the TabView
        .navigationDestination(isPresented: $navigateToScale) {
            if let scale = self.scaleToPractice {
                ScalesView(user: user, scale: scale)
            }
        }
        .commonToolbar(
            title: "Select Hands",
            helpMsg: "Choose to play hands together or practise with your left or right hand first.",
            onBack: { dismiss() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
