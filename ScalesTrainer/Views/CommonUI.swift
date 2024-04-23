import SwiftUI

struct CommonFrameStyle: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var borderColor: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            //.padding()  // Apply padding to the content inside the frame
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 10)  // Set a common frame size
            .background(backgroundColor)  // Background color
            .cornerRadius(cornerRadius)  // Rounded corners
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)  // Border settings
            )
            .shadow(radius: 5)  // Optional: Add a shadow for depth
    }
}

extension View {
    func commonFrameStyle(backgroundColor: Color = .white,
                          cornerRadius: CGFloat = 10,
                          borderColor: Color = .blue,
                          borderWidth: CGFloat = 1) -> some View {
        modifier(CommonFrameStyle(backgroundColor: backgroundColor,
                                  cornerRadius: cornerRadius,
                                  borderColor: borderColor,
                                  borderWidth: borderWidth))
    }
}
