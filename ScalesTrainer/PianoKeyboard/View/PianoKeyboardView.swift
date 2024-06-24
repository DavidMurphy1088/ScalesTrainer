
import SwiftUI
import UIKit

public struct PianoKeyboardView : View {
    @ObservedObject var scalesModel: ScalesModel
    @ObservedObject private var viewModel: PianoKeyboardModel
    var style = ClassicStyle()

    public init(scalesModel:ScalesModel, viewModel: PianoKeyboardModel) {// //, //= PianoKeyboardViewModel()) {
        self.scalesModel = scalesModel
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                ///🤚01 May - things work without a forced repaint here...
                //Text("Repaint \(viewModel.forceRepaint1)")
                ZStack(alignment: .top) {
                    //Warning - Anything added here screws up touch handling 😡
                    style.layout(repaint: scalesModel.forcePublish, viewModel: viewModel, geometry: geometry)
                    //style.layout(viewModel: viewModel, geometry: geometry)
                    TouchesView(viewModel: viewModel)
                        //.border(Color .purple, width: 3)
                }
                //.background(.black)
                //.border(Color .black, width: 1)
            }
        }
    }
}

