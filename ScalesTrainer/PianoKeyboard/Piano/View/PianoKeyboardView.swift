
import SwiftUI
import UIKit

public struct PianoKeyboardView : View {
    @ObservedObject var scalesModel: ScalesModel
    @ObservedObject private var viewModel: PianoKeyboardViewModel
    var style = ClassicStyle() //T

    public init(scalesModel:ScalesModel, viewModel: PianoKeyboardViewModel) {// //, //= PianoKeyboardViewModel()) {
        self.scalesModel = scalesModel
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                //Warning - Anything added here screws up touch handliong 😡
                //Text("Key:\(scalesModel.scale.key.getName())").padding().commonFrameStyle(backgroundColor: .yellow, borderColor: .red)
                ZStack(alignment: .top) {
                    
                    style.layout(viewModel: viewModel, geometry: geometry)
                    TouchesView(viewModel: viewModel)
                }
                .background(.black)
            }
        }
    }
}

