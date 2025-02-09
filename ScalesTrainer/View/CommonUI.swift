import SwiftUI

struct ScreenTitleView: View {
    @ObservedObject var settingsPublished = SettingsPublished.shared
    let screenName: String
    @State var user = Settings.shared.getCurrentUser()
    
    func getTitle() -> String {
        let name = screenName //Settings.shared.getCurrentUser().name //self.settingsPublished.name
//        if self.settingsPublished.name.count > 0 {
//            name += "'s "
//        }
//        name += screenName
        return name
    }

    var body: some View {
        VStack {
            Text(getTitle()).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            HStack {
                Text(user.getTitle()).font(.title2)
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading)
        .onAppear() {
            self.user = Settings.shared.getCurrentUser()
        }
    }
}

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

struct CommonFrameStyle: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var borderColor: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 10)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
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
    func commonFrameStyle(backgroundColor: Color = Settings.shared.getCurrentUser().settings.getBackgroundColor(),
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
