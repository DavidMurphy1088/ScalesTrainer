import SwiftUI

struct ScreenTitleView: View {
    @ObservedObject var viewManager = ViewManager.shared
    let screenName: String
    
    var body: some View {
        VStack {
            Text(screenName).font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title)
            HStack {
                if let user = viewManager.titleUser {
                    Text(user.getTitle()).font(.title2)
                }
            }
        }
        .commonFrameStyle(backgroundColor: UIGlobals.shared.purpleHeading)
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
    func commonFrameStyle(backgroundColor: Color = Settings.shared.getCurrentUser() == nil ? 
                          Settings.shared.getDefaultBackgroundColor() :
                          Settings.shared.getCurrentUser()!.settings.getBackgroundColor(),
                          cornerRadius: CGFloat = 10,
                          borderColor: Color = .blue,
                          borderWidth: CGFloat = 1) -> some View {

            modifier(CommonFrameStyle1(backgroundColor: backgroundColor,
                                       cornerRadius: cornerRadius,
                                       borderColor: borderColor,
                                       borderWidth: borderWidth))

//            modifier(CommonFrameStyle2(backgroundImageName: "PianoKeyboard2", opacity: 0.6, cornerRadius: 0, borderColor: .black, borderWidth: 1))
//                                      cornerRadius: cornerRadius,
//                                      borderColor: borderColor,
//                                      borderWidth: borderWidth))
//        }
    }

    func hilighted(backgroundColor: Color = .green) -> some View {
        modifier(Hilighted(backgroundColor: backgroundColor))
    }

}

struct CommonFrameStyle1: ViewModifier {
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

struct CommonFrameStyle2: ViewModifier {
    var backgroundImageName: String
    var opacity: Double
    var cornerRadius: CGFloat
    var borderColor: Color
    var borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .clipped()
                    .cornerRadius(cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
