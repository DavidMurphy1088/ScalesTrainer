import SwiftUI

class UIGlobals {
    static let shared = UIGlobals()

    func getBackground() -> String {
        let r = Int.random(in: 0...10)
        return "app_background_\(r)"
    }
    
    //let screenImageBackgroundOpacity = 0.5
    let screenImageBackgroundOpacity = 0.5
    let screenWidth = 0.9
}

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

struct Hilighted: ViewModifier {
    var backgroundColor: Color
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .foregroundColor(.white)
            .padding()
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
    
    func commonTitleStyle(backgroundColor: Color = .white, //Color = Color(red: 0.9, green: 0.95, blue: 1.0),
                          cornerRadius: CGFloat = 10,
                          borderColor: Color = .blue,
                          borderWidth: CGFloat = 1) -> some View {
        modifier(CommonFrameStyle(backgroundColor: backgroundColor,
                                  cornerRadius: cornerRadius,
                                  borderColor: borderColor,
                                  borderWidth: borderWidth))
    }

    func hilighted(backgroundColor: Color = .green) -> some View {
        modifier(Hilighted(backgroundColor: backgroundColor))
    }

}
