import SwiftUI

//struct CodableColor: Codable {
//    var red: Double
//    var green: Double
//    var blue: Double
//    var alpha: Double
//    
//    init(_ color: Color) {
//        let uiColor = UIColor(color)
//        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
//        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
//        self.red = Double(r) / 255.0
//        self.green = Double(g) / 255.0
//        self.blue = Double(b) / 255.0
//        self.alpha = 1.0 //Double(a)
//    }
//    
//    func getColor() -> Color {
//        return Color(red: red, green: green, blue: blue) //, opacity: alpha)
//        //return .blue
//    }
//}

// =========== Toolbar =======

struct CommonToolbarModifier: ViewModifier {
    let title: String
    let titleMustShow: Bool?
    let helpMsg: String
    let onBack: (() -> Void)?
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        if let titleMustShow = titleMustShow {
                            if titleMustShow {
                                Text(title)
                                    .font(compact ? .title3 : .title)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ToolbarNameTitleView(screenName: title, helpMsg: helpMsg)
                        .padding(.vertical, 0)
                }
            }
            .toolbarBackground(Figma.backgroundGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar) //leftmost navigation back label
    }
}

extension View {
    func commonToolbar(
        title: String,
        titleMustShow: Bool? = nil,
        helpMsg: String,
        onBack: (() -> Void)? = nil
    ) -> some View {
        self.modifier(CommonToolbarModifier(
            title: title,
            titleMustShow: titleMustShow,
            helpMsg: helpMsg,
            onBack: onBack
        ))
        //.background(Figma.backgroundGreen)
    }
}

//========== Figma

class FigmaColors {
    static let shared = FigmaColors()
    var primaryColors:[(String, Color)] = []
    var colorShades:[(String, Color)] = []
    func makeColor(red: Int, green: Int, blue: Int) -> Color {
        return Color(
            .sRGB,
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0,
            opacity: 1.0
        )
    }
    init() {
        primaryColors.append(("purple", makeColor(red: 62, green: 42, blue: 80)))
        primaryColors.append(("pink  ", makeColor(red: 255, green: 83, blue: 108)))
        primaryColors.append(("orange", makeColor(red: 250, green: 162, blue: 72)))
        primaryColors.append(("green", makeColor(red: 156, green: 215, blue: 98)))
        primaryColors.append(("blue", makeColor(red: 98, green: 202, blue: 215)))
        colorShades.append(("green", makeColor(red: 196, green: 231, blue: 161)))
        colorShades.append(("blue", makeColor(red: 161, green: 223, blue: 100)))
    }
    
    func color(_ name: String) -> Color {
        if let match = primaryColors.first(where: { $0.0.lowercased().trimmingCharacters(in: .whitespaces) == name.lowercased().trimmingCharacters(in: .whitespaces) }) {
            return match.1
        }
        return .clear
    }
    
    func allColorNames() -> [String] {
        return primaryColors.map { $0.0.trimmingCharacters(in: .whitespaces) }
    }
}

class Figma {
    static let background = Color(rgbHex: "#FEFEFE")
    static let red = Color(red: 255, green: 83, blue: 108, opacity: 1.0)
    static let orange = Color(red: 250, green: 162, blue: 72, opacity: 1.0)
    static let green = Color(red: 156, green: 215, blue: 98, opacity: 1.0)
    static let blue = Color(red: 98, green: 202, blue: 215, opacity: 1.0)
    static let backgroundGreen = FigmaColors.shared.colorShades[0].1.opacity(0.2)
                                       
    struct AppButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(background)
        }
    }
    static func colorFromRGB(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
    static func getHandImage(scale:Scale) -> Image? {
        if scale.hands.count < 1 {
            return nil
        }
        if scale.hands.count > 1 {
            return Image("figma_hand_together")
        }
        if scale.hands[0] == 0 {
            return Image("figma_hand_right")
        }
        else {
            return Image("figma_hand_left")
        }
    }
}

extension Color {
    init(rgbHex: String) {
        var hex = rgbHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 3 {
            // Convert shorthand hex (e.g., F90 → FF9900)
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct FigmaNavLink<Label: View, Destination: View>: View {
    var destination: Destination
    var label: () -> Label
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    init(
        destination: Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.destination = destination
        self.label = label
    }

    var body: some View {
        let font:Font = compact ? .body : .title2
        if compact {
            NavigationLink(destination: destination) {
                label()
                .font(font)
                .foregroundColor(.black)
                .padding(6)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 2)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.9), lineWidth: 1)
                    }
                )
            }
        }
        else {
            NavigationLink(destination: destination) {
                label()
                .font(font)
                .foregroundColor(.black)
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 2)
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    }
                )
            }
        }
        
    }
}

struct FigmaButton: View {
    var action: () -> Void
    let text:String
    let imageName1:String?
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 16
    let roundRadius = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 12.0
    let vertPadding = UIDevice.current.userInterfaceIdiom == .phone ? 2.0 : 12.0
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    init(_ text:String, imageName1:String? = nil, action: @escaping () -> Void) {
        self.action = action
        self.text = text
        self.imageName1 = imageName1
    }

    var body: some View {
        Button(action: action) {
            HStack {
                HStack {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.black)
                    if let image = imageName1 {
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconSize)   // matches text size
                    }
                }
                .padding(.vertical, vertPadding)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: roundRadius).stroke(Color.black.opacity(compact ? 0.5 : 1.0), lineWidth: 1)
                )
                .figmaRoundedBackground(fillColor: .white, opacity: 1.0)
            }
        }
    }
}

struct FigmaButtonWithLabel<Label: View>: View {
    var label: () -> Label
    var action: () -> Void
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    init(@ViewBuilder label: @escaping () -> Label, action: @escaping () -> Void) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .foregroundColor(.black)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 1)
                )
                .figmaRoundedBackground(fillColor: .white, opacity: 1.0)
        }
    }
}

struct RoundedBackgroundModifier: ViewModifier {
    var fillColor: Color = .gray
    var opacityValue: Double = 1.0
    let radius = UIDevice.current.userInterfaceIdiom == .phone ? 12.0 : 12.0
    let shadowOffset = 2.0
    let border:Bool
    //let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func body(content: Content) -> some View {
        content
//            .background(
//                RoundedRectangle(cornerRadius: radius).fill(fillColor.opacity(opacityValue)))
//            .background(
//                RoundedRectangle(cornerRadius: radius).stroke(Color.red, lineWidth: border ? 2 : 0))//.offset(y: -4)
            .background(
                ZStack {
                    //shadow box
                    if border {
                        RoundedRectangle(cornerRadius: radius).fill(Figma.colorFromRGB(62, 42, 80)).offset(y: 4)
                            .blur(radius: 0) // set >0 if you want soft shadow
                    }
                    //opaque over shadow in case the top color has opacity < 1.0
                    RoundedRectangle(cornerRadius: radius).fill(Color.white)
                    RoundedRectangle(cornerRadius: radius).fill(fillColor.opacity(opacityValue))
                }
                .background(
                    RoundedRectangle(cornerRadius: radius).stroke(Color.black, lineWidth: border ? 1 : 0)
                )
            )
    }
}

extension View {
    func figmaRoundedBackground(fillColor: Color = Figma.colorFromRGB(236, 234, 238),
                                opacity opacityValue: Double = 1.0) -> some View {
        self.modifier(RoundedBackgroundModifier(fillColor: fillColor, opacityValue: opacityValue, border: false))
    }
    func figmaRoundedBackgroundWithBorder(fillColor: Color = Figma.colorFromRGB(236, 234, 238),
                                opacity opacityValue: Double = 1.0) -> some View {
        self.modifier(RoundedBackgroundModifier(fillColor: fillColor, opacityValue: opacityValue, border: true))
    }
}

//=============== End of Figma ==============

///Equivalent of Swiftui Color.green for canvas drawing
//let AppGreen = Color(red: 0.20392156, green: 0.7803921, blue: 0.349019607)
//Red: 0.20392156862745098, Green: 0.7803921568627451, Blue: 0.34901960784313724, Alpha: 1.0
//let AppOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

class UIGlobals {
    static let shared = UIGlobals()
//    func getBackground1() -> String {
//        let r = Int.random(in: 0...10)
//        return "app_background_\(r)"
//    }
    
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

/// ================ Title view at the top of every nav stack =================

struct ToolbarTitleHelpView: View {
    let helpMessage:String
    
    var body: some View {
        VStack(spacing: 15) {
            Text(helpMessage.count == 0 ? "Some help message...." : helpMessage)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
        }
        .padding()
        .padding()
        .background(FigmaColors().color("green"))
    }
}

struct ToolbarNameTitleView: View {
    let screenName: String
    let helpMsg: String
    @ObservedObject var viewManager = ViewManager.shared
    @State var showHelp = false
    
    let circleWidth = UIDevice.current.userInterfaceIdiom == .phone ? 35.0 : 35.0
    func firstLetter(user:String) -> String {
        guard let first = user.first else {
            return ""
        }
        return first.uppercased() 
    }
    
    var body: some View {
        HStack {
            HStack {
                if viewManager.gradePublished > 0 {
                    Button(action: {
                        self.showHelp = true
                    }) {
                        Text("?")
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    .popover(isPresented: $showHelp) {
                        ToolbarTitleHelpView(helpMessage: helpMsg)
                            .presentationCompactAdaptation(.none) ///Else popover takes whoe screen on iPhone
                    }
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1, height: 50)
                    ZStack {
                        Circle()
                            .fill(User.color(from: viewManager.userColorPublished).opacity(0.5))
                            .frame(width: circleWidth, height: circleWidth)
                        Text(firstLetter(user: viewManager.userNamePublished))
                    }
                    VStack {
                        Text(viewManager.userNamePublished)
                        Text(viewManager.boardPublished + ", Grade \(viewManager.gradePublished)").font(.caption)
                    }
                }
            }
        }
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

//struct FancyTextStyle: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .font(.custom("Noteworthy-Bold", size: 24))
//            .foregroundColor(.white)
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 15)
//                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
//                                         startPoint: .topLeading, endPoint: .bottomTrailing))
//                    .shadow(radius: 5)
//            )
//    }
//}

extension View {
    func hilighted(backgroundColor: Color = .green) -> some View {
        modifier(Hilighted(backgroundColor: backgroundColor))
    }
//    func fancyTextStyle() -> some View {
//        modifier(FancyTextStyle())
//    }
}

struct ConfettiView: UIViewRepresentable {
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let compact = UIDevice.current.userInterfaceIdiom == .phone
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
            var colors: [UIColor] = []
            //= [
//                .systemRed,
//                .systemBlue,
//                .systemGreen,
//                .systemYellow,
//                .systemPurple,
//                .systemOrange,
//                .systemPink,
//                .systemTeal
//            ]
            let figmaColors = FigmaColors()
            for color in figmaColors.primaryColors {
                let c = color.1
                colors.append(UIColor(c))
            }
            
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
        //let percentage: CGFloat = 0.05
        //let percentage: CGFloat = width < 400 ? 0.05 : (width < 800 ? 0.04 : 0.04)
        let percentage: CGFloat = width < 400 ? 0.05 : (width < 800 ? 0.04 : 0.04)
        
        let size = width * percentage * 2.0
        let minSize: CGFloat = 30
        //let maxSize: CGFloat = 100
        let maxSize: CGFloat = 200
        var width = min(max(size, minSize), maxSize)
        if compact {
            width = width * 0.5
        }
        return width
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

struct SinglePickList<Item: Hashable>: View {
    let title:String
    let items: [Item]
    let initiallySelectedIndex: Int?
    let label: (Item) -> String
    let onPick: (Item, Int) -> Void
    @State private var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(items.indices, id: \.self) { i in
                        let isSelected = (selectedIndex == i)
                        Button {
                            selectedIndex = i
                            onPick(items[i], i)
                            dismiss()
                        } label: {
                            HStack {
                                Text(label(items[i])).padding(.horizontal)
                                Spacer()
//                                if isSelected {
//                                    Image(systemName: "checkmark")
//                                }
                            }
                            .padding(4)
                            //.background(FigmaColors().color(named: "green"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
            
//    var body1: some View {
//        VStack {
//            //Text(title).font(.title).padding()
//            List {
//                ForEach(items.indices, id: \.self) { i in
//                    let isSelected = (selectedIndex == i)
//                    Button {
//                        selectedIndex = i
//                        onPick(items[i], i)
//                        dismiss()
//                    } label: {
//                        HStack {
//                            Text(label(items[i])).padding(.horizontal)
//                            //Spacer()
//                            if isSelected {
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                        //.background(FigmaColors().color(named: "green"))
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//
//            Spacer()
//        }
//        //.frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.height * 0.3)
//        .onAppear {
//            if let idx = initiallySelectedIndex, items.indices.contains(idx) {
//                selectedIndex = idx
//            }
//        }
//    }
}

extension SinglePickList where Item == ScaleType {
    init(title:String,
        items: [ScaleType],
        initiallySelectedIndex: Int? = nil,
        onPick: @escaping (ScaleType, Int) -> Void) {
        self.title = title
        self.items = items
        self.initiallySelectedIndex = initiallySelectedIndex
        self.label = { $0.description }
        self.onPick = onPick
    }
}
extension SinglePickList where Item == String {
    init(title:String,
         items: [String],
         initiallySelectedIndex: Int? = nil,
         onPick: @escaping (String, Int) -> Void) {
         self.title = title
         self.items = items
         self.initiallySelectedIndex = initiallySelectedIndex
         self.label = { $0.description }
         self.onPick = onPick
    }
}
