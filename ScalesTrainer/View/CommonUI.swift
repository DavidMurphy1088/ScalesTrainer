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

struct AppButtonStyle: ButtonStyle {
    let trim: Bool
    let color: Color

    // The color parameter defaults to blue if not provided.
    init(trim: Bool, color: Color = .blue) {
        self.trim = trim
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, trim ? 8 : 24)
            .padding(.vertical, trim ? 4 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: .gray.opacity(0.3), radius: configuration.isPressed ? 1 : 3, x: 0, y: 2)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

extension Button {
    func appButtonStyle(trim: Bool = false, color: Color = .blue) -> some View {
        self.buttonStyle(AppButtonStyle(trim: trim, color: color))
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

//struct OutlinedStyleView: ViewModifier {
//    let opacity:Double
//    let color:Color
//    func body(content: Content) -> some View {
//        let compact = UIDevice.current.userInterfaceIdiom == .phone
//        content
//            .background(color)
//            .cornerRadius(compact ? 6 : 12) ///👹
//            .overlay(
//                RoundedRectangle(cornerRadius: compact ? 6 : 12)
//                    .stroke(Color.gray, lineWidth: compact ? 1 : 2)
//            )
//            ///y > 0 means shadow from above
//            .shadow(color: Color.black.opacity(opacity), radius: compact ? 2 : 8, x: 0, y: compact ? 2 : 4)
//    }
//}

struct OutlinedStyleView: ViewModifier {
    let shadowOpacity: Double
    let color: Color
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    func body(content: Content) -> some View {
        let isCompact = horizontalSizeClass == .compact
        
        // Scale values based on size class
        let cornerRadius = isCompact ? 9.0 : 12.0
        let strokeWidth = isCompact ? 1.0 : 2.0
        let shadowRadius = isCompact ? 2.0 : 8.0
        let shadowOffset = isCompact ? 2.0 : 4.0
        
        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .shadow(
                        color: Color.black.opacity(shadowOpacity),
                        radius: shadowRadius,
                        x: 0,
                        y: shadowOffset
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray, lineWidth: strokeWidth)
            )
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
    func outlinedStyleView(shadowOpacity:Double = 0.3, color:Color = Color.white) -> some View {
        modifier(OutlinedStyleView(shadowOpacity: shadowOpacity, color: color))
    }
    
    func fancyTextStyle() -> some View {
        modifier(FancyTextStyle())
    }

}

