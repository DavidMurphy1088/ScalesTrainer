
import SwiftUI
import UIKit

public struct PianoKeyboardView<T: KeyboardStyle>: View {
    @ObservedObject private var viewModel: PianoKeyboardViewModel
    var style: T

    public init(
        viewModel: PianoKeyboardViewModel = PianoKeyboardViewModel(),
        style: T
    ) {
        self.viewModel = viewModel
        self.style = style
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                style.layout(viewModel: viewModel, geometry: geometry)
                TouchesView(viewModel: viewModel)
            }
            .background(.black)
        }
    }
}

