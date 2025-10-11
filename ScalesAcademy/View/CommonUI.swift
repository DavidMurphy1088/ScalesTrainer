import SwiftUI
///------------- Fonts ------------
///Set that the user has chosen Medium in accessibility settings — and don’t allow them to change it

struct FixedDynamicTypeSizeModifier: ViewModifier {
    let size: DynamicTypeSize   // e.g. .medium, .large, .xLarge, etc.

    func body(content: Content) -> some View {
        content.dynamicTypeSize(size)   // Forces this size; ignores system changes
    }
}

extension View {
    /// Locks Dynamic Type to a single size app- or view-wide.
    func lockDynamicTypeSize(_ size: DynamicTypeSize = .medium) -> some View {
        modifier(FixedDynamicTypeSizeModifier(size: size))
    }
}

// --------------- Toolbar ---------------

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
            .toolbarBackground(FigmaColors.shared.getColor1("CommonToolbarModifier", "blue",5), for: .navigationBar)
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
    }
}

//--------------- Figma ---------------

class FigmaColors {
    static let shared = FigmaColors()
    static let appBackground = Color("#FEFEFE")
    class FColor {
        let name:String
        let color:Color
        let colorHex:String
        let shade:Int
        init(_ name:String, _ colorHex:String, _ shade:Int) {
            self.name = name
            self.colorHex = colorHex
            self.shade = shade
            self.color = FigmaColors.colorFromHex(colorHex)
        }
        
    }
    
    var colors:[FColor] = []
    var green = Color.clear
    var blue = Color.clear
    let userDisplayOpacity = 0.8
    var purple = Color.clear
    
    private init() {
        ///See Jennifer's brand guidelines colors and shades. Using shade index = 2 in 0,1,2
        ///shade 0 is direct from colour palette, shade > 0 are J's shades
        ///shade 1 -> 6 makes the colours lighter
        ///
        colors.append(FColor("pink", "#FF536C", 0))
        colors.append(FColor("orange", "#FAA248", 0))
        colors.append(FColor("green", "#9CD762", 0))
        colors.append(FColor("blue", "#62CAD7", 0))
        
        colors.append(FColor("green", "#72A144", 1))
        colors.append(FColor("green", "#8CC258", 2))
        colors.append(FColor("green", "#9CD762", 3))
        colors.append(FColor("green", "#B0DF81", 4))
        colors.append(FColor("green", "#C4E7A1", 5))
        colors.append(FColor("green", "#D7EFC0", 6))
        colors.append(FColor("green", "#F5FBEF", 7))

        colors.append(FColor("blue", "#4BA0AA", 1))
        colors.append(FColor("blue", "#58B6C2", 2))
        colors.append(FColor("blue", "#62CAD7", 3))
        colors.append(FColor("blue", "#81D5DF", 4))
        colors.append(FColor("blue", "#A1DFE7", 5))
        colors.append(FColor("blue", "#C0EAEF", 6))
        colors.append(FColor("blue", "#EFFAFB", 7))

        ///Purples come too dark and look like black
//        colors.append(FColor("purple", "#251930", 1))
//        colors.append(FColor("purple", "#322240", 2))
//        colors.append(FColor("purple", "#3E2A50", 3))
//        colors.append(FColor("purple", "#513F62", 4))
//        colors.append(FColor("purple", "#786A85", 5))
//        colors.append(FColor("purple", "#C5BFCB", 6))
//        colors.append(FColor("purple", "#ECEAEE", 7))
        
        colors.append(FColor("pink", "#993241", 1))
        colors.append(FColor("pink", "#CC4256", 2))
        colors.append(FColor("pink", "#FF536C", 3))
        colors.append(FColor("pink", "#FF7589", 4))
        colors.append(FColor("pink", "#FF98A7", 5))
        colors.append(FColor("pink", "#FFCBD3", 6))
        colors.append(FColor("pink", "#FFEEF0", 7))
        
        colors.append(FColor("orange", "#C8823A", 1))
        colors.append(FColor("orange", "#E19241", 2))
        colors.append(FColor("orange", "#FAA248", 3))
        colors.append(FColor("orange", "#FBB56D", 4))
        colors.append(FColor("orange", "#FCC791", 5))
        colors.append(FColor("orange", "#FDDAB6", 6))
        colors.append(FColor("orange", "#FFF6ED", 7))
        
        //primaryColors.append(("purple", makeColor(red: 62, green:42, blue: 80))) ?/Comes as black 👹
        
        self.green = getColor1("getglobalgreen", "green")
        ///J Figma for blue shades is WRONG RGB 👹 for blue shade 5
        self.blue = getColor1("getglobalblue", "blue", 6)
        self.purple = FColor("purple", "#786A85", 5).color
    }
    
    func getColor1(_ ctx:String, _ name: String, _ shade: Int? = nil) -> Color {
        let shadeToSearch = shade == nil ? 3 : shade
        let first = colors.first {
                    $0.name.caseInsensitiveCompare(name) == .orderedSame &&
                    $0.shade == shadeToSearch
        }
        if let first = first {
            return first.color
        }
        else {
            return Color.white
        }
    }
    
    func getColorHexes(shade:Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for item in self.colors {
            if item.shade != shade {
                continue
            }
            if item.name.lowercased() == "blue" {
                continue
            }
            let lower = item.colorHex// name.lowercased()
            if seen.insert(lower).inserted {
                result.append(lower)
            }
        }
        return result
    }
    
    func getColors1(_ ctx: String, name:String?, shade:Int?) -> [Color] {
        var colors:[Color] = []
        for colorName in ["pink", "orange", "green", "blue"] {
            for colorShade in 0...6 {
                var candidateColor:Color?
                if let name = name {
                    if colorName == name {
                        candidateColor = getColor1(ctx, colorName, colorShade)
                    }
                }
                if let shade = shade {
                    if colorShade == shade {
                        candidateColor = getColor1(ctx, colorName, colorShade)
                    }
                }
                if candidateColor != nil {
                    if let name = name {
                        if colorName != name {
                            candidateColor = nil
                        }
                    }
                    if let shade = shade {
                        if colorShade != shade {
                            candidateColor = nil
                        }
                    }
                }
                if let candidateColor = candidateColor {
                    colors.append(candidateColor)
                }
            }
        }
        return colors
    }
    
    func getColorHex(_ name: String, _ shade: Int) -> String {
        let first = colors.first {
                    $0.name.caseInsensitiveCompare(name) == .orderedSame &&
                    $0.shade == shade
        }
        if let first = first {
            return first.colorHex
        }
        else {
            return ""
        }
    }
    
    static func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return Color(UIColor.clear)
        }
        
        return Color(UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
            )
        )
    }
}

class Figma {
    //
//    static let red = Color(red: 255, green: 83, blue: 108, opacity: 1.0)
//    static let orange = Color(red: 250, green: 162, blue: 72, opacity: 1.0)
//    static let green = Color(red: 156, green: 215, blue: 98, opacity: 1.0)
//    static let blue = Color(red: 98, green: 202, blue: 215, opacity: 1.0)
    //static let backgroundGreen = FigmaColors.shared.colorShades[0].1.opacity(0.2)
                                       
//    struct AppButtonStyle: ButtonStyle {
//        func makeBody(configuration: Configuration) -> some View {
//            configuration.label
//                .background(buttonBackground)
//        }
//    }
//    static func colorFromRGB(_ red: Int, _ green: Int, _ blue: Int) -> Color {
//        Color(
//            red: Double(red) / 255.0,
//            green: Double(green) / 255.0,
//            blue: Double(blue) / 255.0
//        )
//    }
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
                .FigmaButtonBackground()
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
                .FigmaButtonBackground()
        }
    }
}

struct RoundedBackgroundModifier: ViewModifier {
    var fillColor: Color = .gray
    var opacityValue: Double = 1.0
    var outlineBox:Bool = true
    let radius = UIDevice.current.userInterfaceIdiom == .phone ? 12.0 : 12.0
    let shadowOffset = 2.0
    let dropShadow:Bool
    //let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func body(content: Content) -> some View {
        content
//            .background(
//                RoundedRectangle(cornerRadius: radius).fill(fillColor.opacity(opacityValue)))
//            .background(
//                RoundedRectangle(cornerRadius: radius).stroke(Color.red, lineWidth: border ? 2 : 0))//.offset(y: -4)
            .background(
                ZStack {
                    //shadow box below colour box
                    if dropShadow {
                        let color = FigmaColors.colorFromHex("#3E2A50")
                        RoundedRectangle(cornerRadius: radius).fill(color).offset(y: 4)
                            .blur(radius: 0) // set >0 if you want soft shadow
                    }
                    //opaque over shadow in case the top color has opacity < 1.0
                    RoundedRectangle(cornerRadius: radius).fill(Color.white)
                    RoundedRectangle(cornerRadius: radius).fill(fillColor.opacity(opacityValue))
                }
                .background(
                    RoundedRectangle(cornerRadius: radius).stroke(self.outlineBox ? Color.black : Color.clear, lineWidth: dropShadow ? 1 : 0)
                )
            )
    }
}

extension View {
    func FigmaButtonBackground(//fillColor: Color = Figma.colorFromRGB(236, 234, 238),
                                //opacity opacityValue: Double = 1.0
                                ) -> some View {
        self.modifier(RoundedBackgroundModifier(
            fillColor: .white,
            opacityValue: 1.0,
            outlineBox: true,
            dropShadow: false))
    }
    
    func figmaRoundedBackgroundWithBorder(
        fillColor: Color = FigmaColors.shared.blue,
        opacity opacityValue: Double = 1.0,
        outlineBox:Bool = true) -> some View {
            self.modifier(RoundedBackgroundModifier(fillColor: fillColor, opacityValue: opacityValue, outlineBox: outlineBox, dropShadow: true))
    }
}

//--------------- End of Figma ---------------

class UIGlobals {
    static let shared = UIGlobals()
    let screenImageBackgroundOpacity = 0.5
    let screenWidth = 0.9
    //let purpleSubHeading:Color
    //let purpleHeading:Color
    
    init() {
        var shade = 9.0
        //purple = Color(red: 0.325 * shade, green: 0.090 * shade, blue: 0.286 * shade, opacity: 1.0)
        //purpleSubHeading = Color(red: 232.0 / 255.0, green: 216.0 / 255.0, blue:230.0 / 255.0)
        shade = shade * 0.60
        //purpleHeading = Color(red: 0.325 * shade, green: 0.090 * shade, blue: 0.286 * shade, opacity: 1.0)
        //purpleHeading = Color(red: 195.0 / 255.0, green: 152.0 / 255.0, blue: 188.0 / 255.0)
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

/// --------------- Title view at the top of every nav stack ---------------

struct ToolbarTitleHelpView: View {
    let helpMessage:String
    
    var body: some View {
        VStack(spacing: 15) {
            Text(helpMessage.count == 0 ? "" : helpMessage)
                .foregroundColor(Color.white)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
        }
        .padding()
        .padding()
        .background(FigmaColors.shared.purple) //getColor1("ToolbarTitleHelp", "purple", 5))
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
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            
                    }
                    .popover(isPresented: $showHelp) {
                        ToolbarTitleHelpView(helpMessage: helpMsg)
                            //.offset(x: -50) // Negative x moves left
                            .presentationCompactAdaptation(.none) ///Else popover takes whole screen on iPhone
                    }

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 2, height: 50)
                    ZStack {
                        Circle()
                            .fill(FigmaColors.colorFromHex(viewManager.userColorPublished)
                            .opacity(FigmaColors.shared.userDisplayOpacity))
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
//struct screenBackgroundStyleView: ViewModifier {
//    var cornerRadius: CGFloat
//    var borderColor: Color
//    var borderWidth: CGFloat
//
//    func body(content: Content) -> some View {
//        content
//            //.frame(minWidth: 100, maxWidth: .infinity, minHeight: 10)
//            //.padding() // DO NOT DELETE THIS. If deleted soem views underlap the TabView of menu items
//            .background(
//                LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
//                               startPoint: .topLeading, endPoint: .bottomTrailing)
//                    //.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
//            )
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
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

//struct FancyTextStyle: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .font(.custom("Noteworthy-Bold", size: 24))
//            .foregroundColor(.white)
//            .padding()
//            .buttonBackground(
//                RoundedRectangle(cornerRadius: 15)
//                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
//                                         startPoint: .topLeading, endPoint: .bottomTrailing))
//                    .shadow(radius: 5)
//            )
//    }
//}

//extension View {
//    func hilighted(backgroundColor: Color = .green) -> some View {
//        modifier(Hilighted(backgroundColor: backgroundColor))
//    }
////    func fancyTextStyle() -> some View {
////        modifier(FancyTextStyle())
////    }
//}

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
            //var colors: [UIColor] = []
            let figmaColors = FigmaColors.shared.getColors1("Confetti", name: nil, shade: 3)
            
            // Create different emitter cells for each color
            var cells: [CAEmitterCell] = []
            
            for color in figmaColors {
                if let starImage = createStarImage(size: CGSize(width: confettiSize, height: confettiSize), color: UIColor(color)) {
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

//struct SinglePickList<Item: Hashable>: View {
struct SinglePickList<Item>: View {

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
                            //.background(FigmaColors.shared.color(named: "green"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

}
extension SinglePickList<ScaleMotion> where Item == ScaleMotion {
    init(title:String,
         items: [ScaleMotion],
         initiallySelectedIndex: Int? = nil,
         onPick: @escaping (ScaleMotion, Int) -> Void) {
         self.title = title
         self.items = items
         self.initiallySelectedIndex = initiallySelectedIndex
         self.label = { $0.descriptionShort }
         self.onPick = onPick
    }
}

extension SinglePickList<ScaleType> where Item == ScaleType {
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

extension SinglePickList<String> where Item == String {
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
