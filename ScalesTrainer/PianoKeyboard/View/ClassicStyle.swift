import SwiftUI
import SwiftUI

public struct ClassicStyle {
    let name:String
    let sfKeyWidthMultiplier: CGFloat
    let sfKeyHeightMultiplier: CGFloat
    let sfKeyInsetMultiplier: CGFloat
    let cornerRadiusMultiplier: CGFloat
    let labelColor: Color
    let keyColor: Color
    let hand:Int
    let scale:Scale
    let plainStyle:Bool
    let blackNoteFingerNumberHeight:Double
    var noteToHilight:Int?
    
    public let naturalKeySpace: CGFloat

    public init(
        name:String,
        scale:Scale,
        hand:Int,
        plainStyle:Bool,
        sfKeyWidthMultiplier: CGFloat = 0.65,
        sfKeyHeightMultiplier: CGFloat = 0.60,
        sfKeyInsetMultiplier: CGFloat = 0.15,
        cornerRadiusMultiplier: CGFloat = 0.008,
        labelColor: Color = .blue, //.gray
        keyColor:Color
    ) {
        self.hand = hand
        self.name = name
        self.sfKeyWidthMultiplier = sfKeyWidthMultiplier
        self.sfKeyHeightMultiplier = sfKeyHeightMultiplier
        self.sfKeyInsetMultiplier = sfKeyInsetMultiplier
        self.cornerRadiusMultiplier = cornerRadiusMultiplier
        if plainStyle {
            self.naturalKeySpace = 1
            let hand = scale.hands[0]
            noteToHilight = scale.getMinMax(handIndex: hand).0
        }
        else {
            //self.naturalKeySpace = scale.octaves > 1 ? 2 : 3
            self.naturalKeySpace = 1
        }
        self.labelColor = labelColor
        self.keyColor = keyColor
        self.scale = scale
        self.plainStyle = plainStyle
        self.blackNoteFingerNumberHeight = 0.50 //: 0.50
    }

    public func naturalColor(_ down: Bool) -> Color {
        //return down ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.9, green: 0.9, blue: 0.9)
        return down ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.7, green: 0.7, blue: 0.7)
    }
    
    public func hiliteKeyColor(_ down: Bool) -> Color {
       // return down ? Color(red: 0.4, green: 0.6, blue: 0.4) : Color(red: 0.6, green: 0.9, blue: 0.6)
        //return down ? Color(red: 0.4, green: 0.8, blue: 0.4) : Color(red: 0.6, green: 0.9, blue: 0.6)
        return down ? Color(.red) : Color(.blue)
    }
    
    public func sharpFlatColor(_ down: Bool) -> Color {
        //down ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.5, green: 0.5, blue: 0.5)
        down ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.6, green: 0.6, blue: 0.6)
    }

    public func labelColor(_ noteNumber: Int) -> Color {
        Color(hue: Double(noteNumber) / 127.0, saturation: 1, brightness: 0.6)
    }

    public func naturalKeyWidth(_ width: CGFloat, naturalKeyCount: Int, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }
    
    private func getFingerColor(scaleNote:ScaleNoteState) -> Color {
        if scaleNote.keyboardColourType == .bySegment {
            let seg = scaleNote.segments[0]  % 4
            let color:Color
            switch seg {

            default:
                color = Color.blue
            }
            return color
        }
        return scaleNote.keyboardColourType == .fingerSequenceBreak ? AppOrange : Color.blue
    }
    
    func showKeyNameAndHilights(scalesModel:ScalesModel, context:GraphicsContext, keyRect:CGRect, key:PianoKeyModel, keyPath:Path, showKeyName:Bool) {
        var keyNameToShow:String? = nil
        if plainStyle {
            if [60].contains(key.midi) {
                let flashColor = Color.green//.opacity(flashOpacity)
                context.fill(keyPath, with: .color(flashColor))
                keyNameToShow = "C"
            }
            if [noteToHilight].contains(key.midi) {
                let flashColor = AppOrange//.opacity(flashOpacity)
                context.fill(keyPath, with: .color(flashColor))
            }
        }
        else {
            if showKeyName {
                if scalesModel.showFingers {
                    if key.finger.count > 0 {
                        keyNameToShow = key.getName()
                    }
                }
            }
        }
        if let keyNameToShow = keyNameToShow {
            let yPos = plainStyle ? keyRect.height * 0.80 : 20
            context.draw(
                Text(keyNameToShow)
                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption2 : .title3)
                    .foregroundColor(Color(UIColor.darkGray)),
                at: CGPoint(x: keyRect.origin.x + keyRect.width / 2.0, y: yPos)
            )
        }
        context.stroke(keyPath, with: .color(.gray), lineWidth: 1)
    }
    
    public func layout(repaint:Int, viewModel: PianoKeyboardModel, plainStyle:Bool, geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            //let user = Settings.shared.getCurrentUser() 
            let scalesModel = ScalesModel.shared
            let width = size.width
            let height = size.height
            let geometryLeftEdge = geometry.frame(in: .global).origin.x
            let geometryTopEdge = geometry.frame(in: .global).origin.y

            // Natural keys
            let cornerRadius = plainStyle ? 2 : width * cornerRadiusMultiplier
            let naturalWidth = naturalKeyWidth(width, naturalKeyCount: viewModel.naturalKeyCount, space: naturalKeySpace)
            var xpos: CGFloat = 0
            let playingMidiRadius = naturalWidth * (scale.octaves > 1 ? 0.5 : 0.3)
            
            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                guard key.isNatural else {
                    continue
                }
                if index >= viewModel.pianoKeyModel.count {
                    continue
                }
                let keyModel = viewModel.pianoKeyModel[index]

                let keyRect = CGRect(
                    origin: CGPoint(x: xpos, y: 0),
                    size: CGSize(width: naturalWidth, height: height)
                )
                
                let keyPath = RoundedCornersShape(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
                                                  radius: cornerRadius).path(in: keyRect)
                
                ///White keys colour
                ///Hilight the key if in following keys mode
                var hilightColor1:Color? = nil
                switch keyModel.hilightType {
                case .followThisNote:
                    hilightColor1 = Color(.green)
                case .middleOfKeyboard:
                    hilightColor1 = Color(.green)
                case .wasWrongNote:
                    hilightColor1 = Color(.red)
                default:
                    hilightColor1 = nil
                }

                if let hilightColor = hilightColor1 {
                    let gradientWhiteKey:Gradient = Gradient(colors: [
                        hilightColor,
                        Color.white
                    ])
                    context.fill(keyPath, with: .linearGradient(
                        gradientWhiteKey,
                        startPoint: CGPoint(x: keyRect.width / 2.0, y: keyRect.height * 0.0),
                        endPoint: CGPoint(x: keyRect.width / 2.0, y: keyRect.height * 1.0)
                    ))
                }
                else {
                    context.fill(keyPath, with: .color(Color.white))
                }
                                                         
                /// ----------- Key name and key color hilights ---------
                
                
                showKeyNameAndHilights(scalesModel: scalesModel, context: context, keyRect: keyRect, key: key, keyPath: keyPath, showKeyName: true)
                
                /// ----------- Playing the note ----------
                if keyModel.keyIsSounding {
                    let innerContext = context
                    let w = playingMidiRadius * 1.0
                    let color:Color
                    if keyModel.scaleNoteState != nil {
                        color = .green
                    }
                    else {
                        color = viewModel.hilightNotesOutsideScale ? .red : .clear
                    }
                    
                    let frame = CGRect(x: keyRect.origin.x + keyRect.width / 2.0 - w/2,
                                       y: keyRect.origin.y + keyRect.height * 0.70 - w/2,
                                       width: w, height: w)
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: keyModel.scaleNoteState != nil ? 3 : 3)
                }
                            
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        if scaleNote.finger > 0 {
                            let point = CGPoint(x: keyRect.origin.x + keyRect.width / 2.0, y: keyRect.origin.y + keyRect.height * 0.70)
                            let finger:String = scaleNote.finger > 5 ? "" : String(scaleNote.finger)
                            context.draw(
                                Text(finger).foregroundColor(self.getFingerColor(scaleNote: scaleNote))
                                    .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title).bold(),
                                at: point
                            )
                        }
                    }
                }
                //xpos += plainStyle ? 8 : naturalXIncr
                xpos += naturalWidth + naturalKeySpace
                if index < viewModel.keyRects1.count {
                    viewModel.keyRects1[index] = keyRect.offsetBy(dx: geometryLeftEdge, dy: geometryTopEdge)
                }
                
            }

            // -------------------------- Black keys ---------------------------
            
            let sfKeyWidth = naturalWidth * sfKeyWidthMultiplier
            let sfKeyHeight = height * sfKeyHeightMultiplier
            xpos = 0.0
            var handIndicatorShown = false
            
            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                if key.isNatural {
                    xpos += naturalWidth + naturalKeySpace
                    continue
                }
                if index >= viewModel.pianoKeyModel.count {
                    continue
                }
                let keyModel = viewModel.pianoKeyModel[index]
                let keyRect = CGRect(
                    origin: CGPoint(x: xpos - (sfKeyWidth / 2.0), y: 0),
                    size: CGSize(width: sfKeyWidth, height: sfKeyHeight)
                )

                let keyPath = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: keyRect)

                context.fill(keyPath, with: .color(Color(red: 0.1, green: 0.1, blue: 0.1)))

                let inset = sfKeyWidth * sfKeyInsetMultiplier
                let insetRect = keyRect
                    .insetBy(dx: inset, dy: inset)
                    .offsetBy(dx: 0, dy: key.touchDown ? -(inset) : -(inset * 1.5))

                let pathInset = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius / 2.0)
                    .path(in: insetRect)
               
                ///Black keys colour
                let hilightColor1:Color
                switch keyModel.hilightType {
                case .followThisNote:
                    //hilightColor = hiliteKeyColor(key.touchDown)
                    hilightColor1 = Color(.green)
                case .middleOfKeyboard:
                    hilightColor1 = Color(.green)
                case .wasWrongNote:
                    hilightColor1 = Color(.red)
                default:
                    hilightColor1 = naturalColor(key.touchDown)
                }

                let gradientBlackKey = Gradient(colors: [
                    hilightColor1,
                    sharpFlatColor(key.touchDown),
                    sharpFlatColor(key.touchDown),
                ])
                context.fill(pathInset, with: .linearGradient(
                    gradientBlackKey,
                    startPoint: CGPoint(x: keyRect.width / 2.0, y: 0),
                    endPoint: CGPoint(x: keyRect.width / 2.0, y: keyRect.height)
                ))
                
                ///Left or right hand indicator in left most key
                if !handIndicatorShown {
                    var handImageName:String? = nil
                    if viewModel.keyboardNumber == 1  {
                        handImageName = "hand_right_orange"
                    }
                    if viewModel.keyboardNumber == 2 {
                        handImageName = "hand_left_orange"
                    }
                    if let handImageName = handImageName {
                        let image = Image(handImageName)
                        let resolved = context.resolve(image)
                        let targetWidth: CGFloat = sfKeyWidth * 0.60
                        let originalSize = resolved.size
                        // Calculate height to maintain aspect ratio
                        let aspectRatio = originalSize.height / originalSize.width
                        let targetHeight = targetWidth * aspectRatio
                        let drawRect = CGRect(
                            x: (sfKeyWidth - targetWidth) * 0.50,
                            y: 20,
                            width: targetWidth,
                            height: targetHeight
                        )
                        context.draw(resolved, in: drawRect)
                    }
                    handIndicatorShown = true
                }
                ///------------- Key Name -----
                ///On iPhone or long scales many keys results in overlapping key names. So dont show the black key key names.
                showKeyNameAndHilights(scalesModel: scalesModel, context: context, keyRect: keyRect, key: key, keyPath: keyPath, showKeyName: scale.getScaleNoteCount() <= 24)

                if false {
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        if scale.getScaleNoteCount() <= 24 {
                            if scalesModel.showFingers {
                                if key.finger.count > 0 {
                                    context.draw(
                                        Text("\(key.getName())")
                                            .font(UIDevice.current.userInterfaceIdiom == .phone ? .caption2 : .title3)
                                            .foregroundColor(.white),
                                        at: CGPoint(x: keyRect.origin.x + keyRect.width / 2.0, y: 20)
                                    )
                                }
                            }
                        }
                    }
                }

                /// ----------- The note from the key touch is playing ----------
                if keyModel.keyIsSounding {
                    let innerContext = context
                    let diameter = playingMidiRadius * 1.0
                    let frame = CGRect(x: keyRect.origin.x + keyRect.width / 2.0 - diameter/2 ,
                                       y: keyRect.origin.y + keyRect.height * 0.50 - diameter/2,
                                       width: diameter, height: diameter)
                    let color:Color
                    if keyModel.scaleNoteState != nil {
                        color = .green
                    }
                    else {
                        color = viewModel.hilightNotesOutsideScale ? .red : .clear
                    }
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: keyModel.scaleNoteState != nil ? 3 : 3)
                }
                
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        
                        //let point = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        let point = CGPoint(x: keyRect.origin.x + keyRect.width / 2.0, y: keyRect.origin.y + keyRect.height * self.blackNoteFingerNumberHeight)
                        let finger:String = scaleNote.finger > 5 ? "" : String(scaleNote.finger)
                        if false {
                            ///White background for finger number on a black key
                            ///23May dropped and instead make black keys less black
                            if key.scaleNoteState == nil {
                                let edge = keyRect.width * 0.05
                                let col = Color.white.opacity(0.8) //scaleNote.fingerSequenceBreak ? Color.yellow.opacity(0.6) :
                                let width = keyRect.width - 2 * edge
                                let backgroundRect = CGRect(x: keyRect.origin.x + edge, y: point.y - width / 2.0 + 1, width: width, height: width)
                                context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                            }
                        }
                        context.draw(
                            Text(finger).foregroundColor(self.getFingerColor(scaleNote: scaleNote))
                                .font(UIDevice.current.userInterfaceIdiom == .phone ? .body : .title).bold(),
                            at: point
                        )
                    }
                }
                if index < viewModel.keyRects1.count {
                    viewModel.keyRects1[index] = keyRect.offsetBy(dx: geometryLeftEdge, dy: geometryTopEdge)
                }
            }
        }
    }
}
