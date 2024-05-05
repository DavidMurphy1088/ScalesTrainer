import SwiftUI
import SwiftUI

public struct ClassicStyle {
    let sfKeyWidthMultiplier: CGFloat
    let sfKeyHeightMultiplier: CGFloat
    let sfKeyInsetMultiplier: CGFloat
    let cornerRadiusMultiplier: CGFloat
    let labelFont: Font
    let labelColor: Color

    public let naturalKeySpace: CGFloat

    public init(
        //sfKeyWidthMultiplier: CGFloat = 0.65,
        sfKeyWidthMultiplier: CGFloat = 0.55,
        sfKeyHeightMultiplier: CGFloat = 0.60,
        sfKeyInsetMultiplier: CGFloat = 0.15,
        cornerRadiusMultiplier: CGFloat = 0.008,
        naturalKeySpace: CGFloat = 3,
        labelFont: Font = .title3.bold(),
        labelColor: Color = .blue //.gray
    ) {
        self.sfKeyWidthMultiplier = sfKeyWidthMultiplier
        self.sfKeyHeightMultiplier = sfKeyHeightMultiplier
        self.sfKeyInsetMultiplier = sfKeyInsetMultiplier
        self.cornerRadiusMultiplier = cornerRadiusMultiplier
        self.naturalKeySpace = naturalKeySpace
        self.labelFont = labelFont
        self.labelColor = labelColor
    }

    public func naturalColor(_ down: Bool) -> Color {
        return down ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.9, green: 0.9, blue: 0.9)
    }

    public func sharpFlatColor(_ down: Bool) -> Color {
        down ? Color(red: 0.4, green: 0.4, blue: 0.4) : Color(red: 0.5, green: 0.5, blue: 0.5)
    }

    public func labelColor(_ noteNumber: Int) -> Color {
        Color(hue: Double(noteNumber) / 127.0, saturation: 1, brightness: 0.6)
    }

    public func naturalKeyWidth(_ width: CGFloat, naturalKeyCount: Int, space: CGFloat) -> CGFloat {
        (width - (space * CGFloat(naturalKeyCount - 1))) / CGFloat(naturalKeyCount)
    }

    public func layout(repaint:Int, viewModel: PianoKeyboardModel, geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            let scalesModel = ScalesModel.shared
            let width = size.width
            let height = size.height
            let xg = geometry.frame(in: .global).origin.x
            let yg = geometry.frame(in: .global).origin.y

            // Natural keys
            let cornerRadius = width * cornerRadiusMultiplier
            let naturalWidth = naturalKeyWidth(width, naturalKeyCount: viewModel.naturalKeyCount, space: naturalKeySpace)
            let naturalXIncr = naturalWidth + naturalKeySpace
            var xpos: CGFloat = 0.0
            let resultStatusRadius = naturalWidth * 0.20
            let playingMidiRadius = naturalWidth * 0.5

            //print("=================== Canvas paint LAYOUT", PianoKeyboardModel.shared.forceRepaint1)
            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                guard key.isNatural else {
                    continue
                }

                let rect = CGRect(
                    origin: CGPoint(x: xpos, y: 0),
                    size: CGSize(width: naturalWidth, height: height)
                )

                let path = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: rect)

                let gradient = Gradient(colors: [
                    naturalColor(key.touchDown),
                    Color(red: 1, green: 1, blue: 1),
                ])

                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 0.0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 1.0)
                ))
                
                let keyModel = viewModel.pianoKeyModel[index]
                
                /// ----------- Note name ----------
                if let scaleNote = key.scaleNote {
                    if key.finger.count > 0 {
                        context.draw(
                            Text(key.name).font(labelFont).foregroundColor(.black),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: 20)
                        )
                    }
                }

                /// ----------- Playing the note ----------
                if keyModel.isPlayingMidi {
                    let innerContext = context
                    let w = playingMidiRadius + 7.0
                    let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - w/2 , y: rect.origin.y + rect.height * 0.80 - w/2,
                                       width: w, height: w)
                    let color:Color
                    if scalesModel.appMode == .displayMode {
                        if let scaleNote = key.scaleNote {
                            color = .blue
                        }
                        else {
                            color = .red
                        }
                    }
                    else {
                        color = Color(keyModel.resultStatus == .correctAscending ? .green : .red)
                    }
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: 3)
                }
                
                ///----------- Finger number -----------
                let color = Color.black //key.name.prefix(1) == "C" ? labelColor : .clear
                if key.finger.count > 0 {
                    if let scaleNote = key.scaleNote {
                        context.draw(
                            Text(String(scaleNote.finger)).foregroundColor(Color.blue)
                                .font(.title).bold(),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        )
                    }
                }
                
                ///----------- Note status -----------
                let x = rect.origin.x + rect.width / 2.0 - playingMidiRadius/CGFloat(2)
                let y = rect.origin.y + rect.height * 0.80 - playingMidiRadius/CGFloat(2)
                if scalesModel.appMode == .displayMode {
                    let col = Color.yellow.opacity(0.4)
                        if let scaleNote = key.scaleNote {
                            if scaleNote.fingerSequenceBreak {
                            let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                            context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                        }
                    }
                }
                else {
                    let col:Color = keyModel.resultStatus == .correctAscending ? Color.green.opacity(0.4) :  Color.red.opacity(0.4)
                    let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                    context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                }

                xpos += naturalXIncr
                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }

            // ==================================== Sharps/Flat keys ====================================
            
            let sfKeyWidth = naturalWidth * sfKeyWidthMultiplier
            let sfKeyHeight = height * sfKeyHeightMultiplier
            xpos = 0.0

            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                if key.isNatural {
                    xpos += naturalXIncr
                    continue
                }

                let rect = CGRect(
                    origin: CGPoint(x: xpos - (sfKeyWidth / 2.0), y: 0),
                    size: CGSize(width: sfKeyWidth, height: sfKeyHeight)
                )

                let path = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: rect)

                context.fill(path, with: .color(Color(red: 0.1, green: 0.1, blue: 0.1)))

                let inset = sfKeyWidth * sfKeyInsetMultiplier
                let insetRect = rect
                    .insetBy(dx: inset, dy: inset)
                    .offsetBy(dx: 0, dy: key.touchDown ? -(inset) : -(inset * 1.5))

                let pathInset = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius / 2.0)
                    .path(in: insetRect)

                let gradientInset = Gradient(colors: [
                    Color(red: 0.3, green: 0.3, blue: 0.3),
                    sharpFlatColor(key.touchDown),
                ])
                
                context.fill(pathInset, with: .linearGradient(
                    gradientInset,
                    startPoint: CGPoint(x: rect.width / 2.0, y: 0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height)
                ))
                
                let keyModel = viewModel.pianoKeyModel[index]
                
                ///------------- Note name -----
                let pianoKeyModel = viewModel.pianoKeyModel[index]
                if key.finger.count > 0 {
                    context.draw(
                        Text(key.name).font(labelFont).foregroundColor(.white),
                        at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: 20)
                    )
                }
                
                /// ----------- Playing the note ----------
                if keyModel.isPlayingMidi {
                    let innerContext = context
                    let w = playingMidiRadius + 7.0
                    let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - w/2 , y: rect.origin.y + rect.height * 0.80 - w/2,
                                       width: w, height: w)
                    let color:Color
                    if scalesModel.appMode == .displayMode {
                        if let scaleNote = key.scaleNote {
                            color = .blue
                        }
                        else {
                            color = .red
                        }
                    }
                    else {
                        color = Color(keyModel.resultStatus == .correctAscending ? .green : .red)
                    }
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: 3)
                }
                
                ///----------- Finger number Note Status-----------
                let color = Color.black //key.name.prefix(1) == "C" ? labelColor : .clear
                if key.finger.count > 0 {
                    if let scaleNote = key.scaleNote {
                        let x = rect.origin.x + rect.width / 2.0 - playingMidiRadius/CGFloat(2)
                        let y = rect.origin.y + rect.height * 0.80 - playingMidiRadius/CGFloat(2)
                        if scalesModel.appMode == .displayMode {
                            let col = scaleNote.fingerSequenceBreak ? Color.yellow.opacity(0.6) : Color.white.opacity(0.6)
                            let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                            context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                        }
                        else {
                            let col:Color = keyModel.resultStatus == .correctAscending ? Color.green.opacity(0.4) :  Color.red.opacity(0.4)
                            let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                            context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                        }
                        context.draw(
                            Text(String(scaleNote.finger)).foregroundColor(Color.blue)
                                .font(.title).bold(),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        )
                    }
                }

//                    let color = Color.white //key.name.prefix(1) == "C" ? labelColor : .clear
//
//                    if key.finger.count > 0 {
//                        if let scaleNote = key.scaleNote {
//                            let width = 40.0
//                            let col = Color.yellow.opacity(0.4)
//                            let x = rect.origin.x + rect.width / 2.0 - width/CGFloat(2)
//                            let y = rect.origin.y + rect.height * 0.75 - width/CGFloat(2)
//                            if scaleNote.fingerSequenceBreak {
//                                let backgroundRect = CGRect(x: x, y: y,
//                                                            width: width, height: width)
//                                context.fill(Path(ellipseIn: backgroundRect), with: .color(col)) // Using an ellipse here
//                            }
//                        
//                            context.draw(
//                                Text(key.finger).foregroundColor(Color.green).font(.title).bold(),
//                                at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.75)
//                            )
//                        }
//                    }
//                
//                    if viewModel.pianoKeyModel[index].isPlayingMidi {
//                        let innerContext = context
//                        let rad = rect.height * 0.05
//                        if let scaleNote = key.scaleNote {
//                            let w = 4.0 * rad
//                            let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - w/2 , y: rect.origin.y + rect.height * 0.75 - w/2, width: w, height: w)
//                            innerContext.stroke(
//                                Path(ellipseIn: frame),
//                                with: .color(.green),
//                                lineWidth: 3)
//                        }
//                        else {
//                            let w = 1.3 * rad
//                            let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - w/2 , y: rect.origin.y + rect.height * 0.80 - w/2, width: w, height: w)
//                            innerContext.fill(
//                                Path(ellipseIn: frame),
//                                with: .color(.red))//,
//                            //lineWidth: 3)
//                            
//                            innerContext.stroke(
//                                Path(ellipseIn: frame),
//                                with: .color(.red),
//                                lineWidth: 3)
//                        }
//                    }

                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }
        }
    }
}
