import SwiftUI

class UIGlobals {
    static let shared = UIGlobals()
    func getBackground1() -> String {
        let r = Int.random(in: 0...10)
        return "app_background_\(r)"
    }
    
    let screenImageBackgroundOpacity = 0.5
    let screenWidth = 0.9
    let purpleSubHeading:Color
    let purpleHeading:Color
    
    init() {
        var shade = 9.0
        //purple = Color(red: 0.325 * shade, green: 0.090 * shade, blue: 0.286 * shade, opacity: 1.0)
        purpleSubHeading = Color(red: 232.0 / 255.0, green: 216.0 / 255.0, blue:230.0 / 255.0)
        shade = shade * 0.60
        //purpleHeading = Color(red: 0.325 * shade, green: 0.090 * shade, blue: 0.286 * shade, opacity: 1.0)
        purpleHeading = Color(red: 195.0 / 255.0, green: 152.0 / 255.0, blue: 188.0 / 255.0)
    }
}

struct BlueButtonStyle: ButtonStyle {
    let trim:Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, trim ? 8 : 24)
            .padding(.vertical, trim ? 4 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .shadow(color: .gray.opacity(0.3), radius: configuration.isPressed ? 1 : 3, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            //.animation(.spring(response: 0.3, dampingFraction: 0.7))
    }
}

extension Button {
    func blueButtonStyle(trim:Bool = false) -> some View {
        self.buttonStyle(BlueButtonStyle(trim: trim))
    }
}

/// Title view at the top of every screen
struct ScreenTitleView: View {
    @ObservedObject var viewManager = ViewManager.shared
    let screenName: String
    let showUser: Bool
    
    var body: some View {
        //VStack(spacing: 2) { // Keeps vertical space minimal
        HStack() {
            let name = screenName + String(showUser ? ": " : "")
            Text(screenName)
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if showUser {
                if let user = viewManager.titleUser {
                    Text(user.getTitle())
                        .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 0) // Keeps height minimal
        .frame(maxWidth: .infinity) // Makes it take full device width
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
//            LinearGradient(colors: [Color.yellow.opacity(0.8), Color.blue.opacity(0.6)],
//                           startPoint: .topLeading, endPoint: .bottomTrailing)
            //.edgesIgnoringSafeArea(.horizontal) // Extends background to screen edges
            //.ignoresSafeArea()
        )
        //.border(Color.green, width: 1)
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

/// Background style for sections of all screens under the screen title
struct screenBackgroundStyleView: ViewModifier {
    var cornerRadius: CGFloat
    var borderColor: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            //.frame(minWidth: 100, maxWidth: .infinity, minHeight: 10)
            //.padding() // DO NOT DELETE THIS. If deleted soem views underlap the TabView of menu items
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    //.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
//            .overlay(
//                RoundedRectangle(cornerRadius: cornerRadius)
//                    .stroke(borderColor, lineWidth: borderWidth)
//            )
            //.shadow(radius: 5) // Adds depth effect
            //.border(Color.red, width: 1)
    }
}

struct OutlinedStyleView: ViewModifier {
    let opacity:Double
    func body(content: Content) -> some View {
            content
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(opacity), radius: 8, x: 0, y: 4)
        }
}

struct FancyTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("Noteworthy-Bold", size: 24))
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(radius: 5)
            )
    }
}

extension View {
    func screenBackgroundStyle (backgroundColor: Color? = nil) -> some View {
          modifier(screenBackgroundStyleView(cornerRadius: 10, borderColor: .blue,borderWidth: 1
        ))
    }

    func hilighted(backgroundColor: Color = .green) -> some View {
        modifier(Hilighted(backgroundColor: backgroundColor))
    }
    
    ///A gray border around the view
    func outlinedStyleView(opacity:Double = 0.2) -> some View {
        modifier(OutlinedStyleView(opacity: opacity))
    }
    
    func fancyTextStyle() -> some View {
        modifier(FancyTextStyle())
    }

}

