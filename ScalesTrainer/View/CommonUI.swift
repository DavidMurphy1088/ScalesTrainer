import SwiftUI

let AppOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

///Equivalent of Swiftui Color.green for canvas drawing
//let AppGreen = Color(red: 0.20392156, green: 0.7803921, blue: 0.349019607)
//Red: 0.20392156862745098, Green: 0.7803921568627451, Blue: 0.34901960784313724, Alpha: 1.0

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

    func getUserTitle() -> String {
        var title = ""
        if let user = viewManager.publishedUser {
            title = user.getTitle()
        }
        return title
    }
    
    var body: some View {
        HStack() {
            let screenNameTitle = screenName + (getUserTitle().isEmpty ? "" : " - ")
            Text(screenNameTitle)
                .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if let user = viewManager.publishedUser {
                Text(getUserTitle())
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .title2 : .largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 0) // Keeps height minimal
        .frame(maxWidth: .infinity) // Makes it take full device width
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
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
    }
}

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
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Remove any existing emitter layers
        uiView.layer.sublayers?.removeAll(where: { $0 is CAEmitterLayer })
        
        // Delay setting up the emitter until the view's bounds are valid.
        DispatchQueue.main.async {
            guard uiView.bounds.size != .zero else { return }
            
            // Calculate confetti size based on screen width
            let screenWidth = uiView.bounds.width
            let confettiSize = calculateConfettiSize(forScreenWidth: screenWidth)
            
            print("Screen width: \(screenWidth), Confetti size: \(confettiSize)")
            
            let emitter = CAEmitterLayer()
            emitter.frame = uiView.bounds
            emitter.emitterPosition = CGPoint(x: uiView.bounds.midX, y: 0)
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: uiView.bounds.width, height: 1)
            
            // Define several colors for variety
            let colors: [UIColor] = [
                .systemRed,
                .systemBlue,
                .systemGreen,
                .systemYellow,
                .systemPurple,
                .systemOrange,
                .systemPink,
                .systemTeal
            ]
            
            // Create different emitter cells for each color
            var cells: [CAEmitterCell] = []
            
            for color in colors {
                // Create star shapes with responsive size
                if let starImage = createStarImage(size: CGSize(width: confettiSize, height: confettiSize), color: color) {
                    let cell = createEmitterCell(with: starImage, forScreenWidth: screenWidth)
                    cells.append(cell)
                }
            }
            
            // Set cells to the emitter
            emitter.emitterCells = cells
            
            // Add the emitter to the view
            uiView.layer.addSublayer(emitter)
            
            // Stop emitting after 1 second, then remove the emitter after another 1.5 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    emitter.removeFromSuperlayer()
                }
            }
        }
    }
    
    // Calculate appropriate confetti size based on screen width
    private func calculateConfettiSize(forScreenWidth width: CGFloat) -> CGFloat {
        let percentage: CGFloat = width < 400 ? 0.05 : (width < 800 ? 0.04 : 0.025)
        let size = width * percentage * 2.0
        let minSize: CGFloat = 30
        //let maxSize: CGFloat = 100
        let maxSize: CGFloat = 200
        return min(max(size, minSize), maxSize)
    }
    
    // Create a standard emitter cell with the given content image
    private func createEmitterCell(with image: UIImage?, forScreenWidth width: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image?.cgImage
        
        let scaleBase: CGFloat = width < 400 ? 0.5 : (width < 800 ? 0.4 : 0.3)
        let velocityBase: CGFloat = width < 400 ? 80 : (width < 800 ? 100 : 120)
        
        cell.birthRate = 15
        //cell.lifetime = 10.0   // Lifetime in seconds
        cell.lifetime = 5.0   // Lifetime in seconds
        cell.velocity = velocityBase
        cell.velocityRange = velocityBase * 0.4
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 3
        cell.spin = 1.5
        cell.spinRange = 1.0
        cell.scale = scaleBase
        cell.scaleRange = scaleBase * 0.4
        
        cell.yAcceleration = 40
        
        // Set alphaSpeed so the particle fades linearly to 0 over its lifetime.
        // With lifetime = 10 seconds, alphaSpeed = -1/10 = -0.1 ensures full fade.
        cell.alphaSpeed = -0.4
        
        return cell
    }
    
    // Create a star-shaped image with the given color
    private func createStarImage(size: CGSize, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outerRadius = min(size.width, size.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5
        
        color.setFill()
        
        var angle: CGFloat = -CGFloat.pi / 2  // Start at the top
        let angleIncrement = CGFloat.pi * 2 / CGFloat(points * 2)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x + outerRadius * cos(angle),
                              y: center.y + outerRadius * sin(angle)))
        
        for i in 0..<points * 2 {
            angle += angleIncrement
            let radius = i % 2 == 0 ? innerRadius : outerRadius
            path.addLine(to: CGPoint(x: center.x + radius * cos(angle),
                                     y: center.y + radius * sin(angle)))
        }
        
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

