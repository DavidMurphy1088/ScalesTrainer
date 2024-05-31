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
        //sfKeyWidthMultiplier: CGFloat = 0.55,
        sfKeyWidthMultiplier: CGFloat = 0.65,
        sfKeyHeightMultiplier: CGFloat = 0.60,
        //sfKeyHeightMultiplier: CGFloat = 0.70,

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
    
    public func hiliteKeyColor(_ down: Bool) -> Color {
        return down ? Color(red: 0.4, green: 0.6, blue: 0.4) : Color(red: 0.6, green: 0.9, blue: 0.6)
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

    func getKeyStatusColor(_ keyModel:PianoKeyModel) -> Color {
        let scalesModel = ScalesModel.shared
        var color:Color
        let fullOpacity = 0.4
        let halfOpacity = 0.4

        if keyModel.scaleNoteState != nil {
            if scalesModel.selectedDirection == 0 {
                color = keyModel.keyClickedState.tappedTimeAscending == nil ? Color.yellow.opacity(fullOpacity) :  Color.green.opacity(halfOpacity)
            }
            else {
                color = keyModel.keyClickedState.tappedTimeDescending == nil ? Color.yellow.opacity(halfOpacity) :  Color.green.opacity(halfOpacity)
            }
        }
        else {
            if scalesModel.selectedDirection == 0 {
                color = keyModel.keyClickedState.tappedTimeAscending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
            }
            else {
                color = keyModel.keyClickedState.tappedTimeDescending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
            }
        }
        return color
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
            let playingMidiRadius = naturalWidth * 0.5
            
            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                guard key.isNatural else {
                    continue
                }
                let keyModel = viewModel.pianoKeyModel[index]

                let rect = CGRect(
                    origin: CGPoint(x: xpos, y: 0),
                    size: CGSize(width: naturalWidth, height: height)
                )
                
                let path = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: rect)
                
                let gradient = Gradient(colors: [
                    keyModel.hilightKey ? hiliteKeyColor(key.touchDown) : naturalColor(key.touchDown),
                    Color(red: 1, green: 1, blue: 1),
                ])
                
                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 0.0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 1.0)
                ))
                
                /// ----------- Note name ----------
                if scalesModel.showFingers {
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
                    if keyModel.scaleNoteState != nil {
                        color = .green
                    }
                    else {
                        color = .red
                    }
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: 3)
                }
                
                ///----------- Note status -----------
                let width = playingMidiRadius * 1.1
                let x = rect.origin.x + rect.width / 2.0 - width/CGFloat(2)
                let y = rect.origin.y + rect.height * 0.805 - width/CGFloat(2)
                ///Show finger break only outside practice or record
                //if [.recordingScale, .recordingScaleWithData].contains(scalesModel.runningProcess) {
                if scalesModel.result != nil {
                    let color = getKeyStatusColor(key)
                    let backgroundRect = CGRect(x: x, y: y, width: width, height: width)
                    context.fill(Path(ellipseIn: backgroundRect), with: .color(color))
                }
                
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        let point = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        context.draw(
                            Text(String(scaleNote.finger)).foregroundColor(scaleNote.fingerSequenceBreak ? Color.orange : Color.blue)
                                .font(.title).bold(),
                            at: point
                        )
//                        if scaleNote.fingerSequenceBreak {
//                            let width = rect.width * 0.1
//                            for w in [width, 0 - width] {
//                                let point1 = CGPoint(x: point.x + CGFloat(w), y: point.y)
//                                let point2 = CGPoint(x: point.x + CGFloat(2*w), y: point.y)
//                                context.stroke(
//                                    Path { path in
//                                        path.move(to: point1)
//                                        path.addLine(to: point2)
//                                    },
//                                    with: .color(.blue),
//                                    lineWidth: 2
//                               )
//                            }
//                        }
                    }
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
                let keyModel = viewModel.pianoKeyModel[index]
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
                    sharpFlatColor(key.touchDown),
                    keyModel.hilightKey ? hiliteKeyColor(key.touchDown) : naturalColor(key.touchDown),
                    
                ])
                
                context.fill(pathInset, with: .linearGradient(
                    gradientInset,
                    startPoint: CGPoint(x: rect.width / 2.0, y: 0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height)
                ))

                ///------------- Note name -----
                if scalesModel.showFingers {
                    if key.finger.count > 0 {
                        context.draw(
                            Text(key.name).font(labelFont).foregroundColor(.white),
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
                    if keyModel.scaleNoteState != nil {
                        color = .green
                    }
                    else {
                        color = .red
                    }
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: 3)
                }
                
                ///----------- Note Status-----------
                //if scalesModel.appMode == .practicingMode || scalesModel.appMode == .none {
                if scalesModel.result != nil {
                    let width = playingMidiRadius * 1.0
                    let x = rect.origin.x + rect.width / 2.0 - (width/CGFloat(2) * 1.0 )
                    let y = rect.origin.y + rect.height * 0.80 - width/CGFloat(2)

                    let color = getKeyStatusColor(key)
                    let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                    context.fill(Path(ellipseIn: backgroundRect), with: .color(color))
                }
                
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        let point = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)

                        //if !scalesModel.showStaff {
                            if false {
                                ///White background for finger number on a black key
                                ///23May dropped and instead make black keys less black
                                if key.scaleNoteState != nil {
                                    let edge = rect.width * 0.05
                                    let col = Color.white.opacity(0.8) //scaleNote.fingerSequenceBreak ? Color.yellow.opacity(0.6) :
                                    let width = rect.width - 2 * edge
                                    let backgroundRect = CGRect(x: rect.origin.x + edge, y: point.y - width / 2.0 + 1, width: width, height: width)
                                    context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                                }
                            }
                            context.draw(
                                Text(String(scaleNote.finger)).foregroundColor(scaleNote.fingerSequenceBreak ? Color.orange : Color.blue)
                                    .font(.title).bold(),
                                at: point
                            )
                        //}
                        ///Draw a midline thru the finger number to indicate a finger break
//                        if scaleNote.fingerSequenceBreak {
//                            let width = rect.width * 0.2
//                            for w in [width, 0 - width] {
//                                let point1 = CGPoint(x: point.x + CGFloat(w), y: point.y)
//                                let point2 = CGPoint(x: point.x + CGFloat(2*w), y: point.y)
//                                    context.stroke(
//                                        Path { path in
//                                            path.move(to: point1)
//                                            path.addLine(to: point2)
//                                        },
//                                        with: .color(.blue),
//                                        lineWidth: 2
//                                   )
//                            }
//                        }
                    }

                }
                
                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }
        }
    }
}
