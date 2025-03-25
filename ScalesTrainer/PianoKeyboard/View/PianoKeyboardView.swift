
import SwiftUI
import UIKit

public struct PianoKeyboardView : View {
    @ObservedObject var scalesModel: ScalesModel
    @ObservedObject private var viewModel: PianoKeyboardModel
    let keyColor:Color
    let miniKeyboardStyle:Bool
    var style:ClassicStyle

    public init(scalesModel:ScalesModel, viewModel: PianoKeyboardModel, keyColor:Color, miniKeyboardStyle:Bool = false) {
        self.scalesModel = scalesModel
        self.viewModel = viewModel
        self.keyColor = keyColor
        self.miniKeyboardStyle = miniKeyboardStyle
        style = ClassicStyle(name: viewModel.name, scale: scalesModel.scale, hand: viewModel.keyboardNumber - 1,
                             miniKeyboardStyle: miniKeyboardStyle, keyColor: keyColor)
    }

    public var body: some View {
        GeometryReader { geometry in
            VStack {
                ///🤚01 May - things work without a forced repaint here...
                //if viewModel.forceRepaint != -1 {
                    //.background(Color.clear) - not needed since canvas background is clear by default
                    //Text("REPAIONT \(viewModel.forceRepaint)")
                    ZStack(alignment: .top) {
                        //Warning - Anything added here screws up touch handling 😡
                        style.layout(repaint: scalesModel.forcePublish, viewModel: viewModel, miniKeyboardStyle: miniKeyboardStyle, geometry: geometry)
                        if miniKeyboardStyle == false {
                            TouchesView(viewModel: viewModel)
                        }
                    }
                //}
            }
        }
    }
//    public var body: some View {
//        Text("KEYBOARD")
//    }
}

