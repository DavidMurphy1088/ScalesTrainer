import SwiftUI
import SwiftUI

public struct ClassicStyle {
    let sfKeyWidthMultiplier: CGFloat
    let sfKeyHeightMultiplier: CGFloat
    let sfKeyInsetMultiplier: CGFloat
    let cornerRadiusMultiplier: CGFloat
    let labelFont: Font
    let labelColor: Color
    let keyColor: Color
    let hand:Int
    
    public let naturalKeySpace: CGFloat

    public init(
        hand:Int,
        sfKeyWidthMultiplier: CGFloat = 0.65,
        sfKeyHeightMultiplier: CGFloat = 0.60,
        sfKeyInsetMultiplier: CGFloat = 0.15,
        cornerRadiusMultiplier: CGFloat = 0.008,
        naturalKeySpace: CGFloat = 3,
        labelFont: Font = .title3.bold(),
        labelColor: Color = .blue, //.gray
        keyColor:Color
    ) {
        self.hand = hand
        self.sfKeyWidthMultiplier = sfKeyWidthMultiplier
        self.sfKeyHeightMultiplier = sfKeyHeightMultiplier
        self.sfKeyInsetMultiplier = sfKeyInsetMultiplier
        self.cornerRadiusMultiplier = cornerRadiusMultiplier
        self.naturalKeySpace = naturalKeySpace
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.keyColor = keyColor
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
    
    private func getKeyStatusColor(key:PianoKeyModel) -> Color {
        let fullOpacity = 0.4
        let halfOpacity = 0.4
        let scalesModel = ScalesModel.shared
        var color:Color = Color.clear
        if key.scale.getStateForMidi(handIndex: hand, midi: key.midi, scaleSegment: scalesModel.selectedScaleSegment) != nil {
            ///Key is in the scale
            if scalesModel.selectedScaleSegment == 0 {
                color = key.keyWasPlayedState.tappedTimeAscending == nil ? Color.yellow.opacity(fullOpacity) :  Color.green.opacity(halfOpacity)
            }
            else {
                color = key.keyWasPlayedState.tappedTimeDescending == nil ? Color.yellow.opacity(halfOpacity) :  Color.green.opacity(halfOpacity)
            }
        }
        else {
            ///Key was not in the scale
            if scalesModel.selectedScaleSegment == 0 {
                color = key.keyWasPlayedState.tappedTimeAscending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
            }
            else {
                color = key.keyWasPlayedState.tappedTimeDescending == nil ? Color.clear.opacity(halfOpacity) :  Color.red.opacity(halfOpacity)
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
                if index >= viewModel.pianoKeyModel.count {
                    continue
                }
                let keyModel = viewModel.pianoKeyModel[index]

                let rect = CGRect(
                    origin: CGPoint(x: xpos, y: 0),
                    size: CGSize(width: naturalWidth, height: height)
                )
                
                let path = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: rect)
                
                ///Hilight the key if in following keys mode
                let gradient = Gradient(colors: [
                    keyModel.hilightFollowingKey ? hiliteKeyColor(key.touchDown) : naturalColor(key.touchDown),
                    //Color(red: middle * 0.6, green: middle, blue: middle),
                    keyColor,
                    Color(red: 1, green: 1, blue: 1),
                ])
                
                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 0.0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height * 1.0)
                ))
                
                if key.midi == 60 {
                    let circleRadius = 15
                    let circle = CGRect(x: Int(rect.midX) - circleRadius * 2,
                                        y: 6,
                                        width: circleRadius * 2,
                                        height: circleRadius * 2)
                    context.fill(Path(ellipseIn: circle), with: .color(.white))
                    context.stroke(Path(ellipseIn: circle), with: .color(.blue), lineWidth: 2)
                    context.draw(
                        Text("C").font(labelFont).foregroundColor(.blue),
                        at: CGPoint(x: rect.origin.x + (rect.width / 2.0) - CGFloat(circleRadius), y: 20)
                    )
                }
                
                /// ----------- Middle C Note name ----------
                if scalesModel.showFingers {
                    if key.finger.count > 0 {
                        if key.midi != 60 {
                            context.draw(
                                Text(key.name).font(labelFont).foregroundColor(keyModel.midi == 60 ? .blue : .black),
                                //Text("X").font(labelFont).foregroundColor(keyModel.midi == 60 ? .blue : .black),
                                at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: 20)
                            )
                        }
                    }
                }
                
                /// ----------- Playing the note ----------
                if keyModel.keyIsSounding {
                    let innerContext = context
                    //let w = playingMidiRadius + 7.0
                    //let w1 = playingMidiRadius * 1.6
                    let w = playingMidiRadius * 1.0
                    let color:Color
                    if keyModel.scaleNoteState != nil {
                        color = .green
                    }
                    else {
                        color = .red
                    }
                    
                    let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - w/2,
                                       y: rect.origin.y + rect.height * 0.80 - w/2,
                                       width: w, height: w)
                    innerContext.stroke(
                        Path(ellipseIn: frame),
                        with: .color(color),
                        lineWidth: keyModel.scaleNoteState != nil ? 6 : 12)
                }
                
                ///----------- Note status -----------
                if scalesModel.resultPublished != nil {
                    let width = playingMidiRadius * 1.1
                    let x = rect.origin.x + rect.width / 2.0 - width/CGFloat(2)
                    let y = rect.origin.y + rect.height * 0.805 - width/CGFloat(2)
                    
                    let color = getKeyStatusColor(key: key)
                    let backgroundRect = CGRect(x: x, y: y, width: width, height: width)
                    context.fill(Path(ellipseIn: backgroundRect), with: .color(color))
                }
            
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        let point = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        let finger:String = scaleNote.finger > 5 ? "►" : String(scaleNote.finger)

                        context.draw(
                            Text(finger).foregroundColor(scaleNote.fingerSequenceBreak ? Color.orange : Color.blue)
                                .font(.title).bold(),
                            at: point
                        )
                    }
                }
                xpos += naturalXIncr
                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }

            // -------------------------- Sharps/Flat keys ---------------------------
            
            let sfKeyWidth = naturalWidth * sfKeyWidthMultiplier
            let sfKeyHeight = height * sfKeyHeightMultiplier
            xpos = 0.0

            for (index, key) in viewModel.pianoKeyModel.enumerated() {
                if key.isNatural {
                    xpos += naturalXIncr
                    continue
                }
                if index >= viewModel.pianoKeyModel.count {
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
                    keyModel.hilightFollowingKey ? hiliteKeyColor(key.touchDown) : naturalColor(key.touchDown),
                    sharpFlatColor(key.touchDown),
                    sharpFlatColor(key.touchDown),
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
                
                ///Hilite Middle C
                ///Draw it here (not during white key draw) to ensure it appears above the black note
//                if keyModel.midi == 61 { //}|| keyModel.midi == 64 {
//                    let circleRadius = 15
//                    let circle = CGRect(x: Int(rect.midX) - circleRadius * 2,
//                                        y: 6,
//                                        width: circleRadius * 2,
//                                        height: circleRadius * 2)
//                    context.fill(Path(ellipseIn: circle), with: .color(.white))
//                    context.stroke(Path(ellipseIn: circle), with: .color(.blue), lineWidth: 2)
//                    context.draw(
//                        Text("C").font(labelFont).foregroundColor(.blue),
//                        at: CGPoint(x: rect.origin.x + (rect.width / 2.0) - CGFloat(circleRadius), y: 20)
//                    )
//                }

                /// ----------- The note from the key touch is playiong ----------
                if keyModel.keyIsSounding {
                    let innerContext = context
                    //let w = playingMidiRadius + 7.0
                    let w = playingMidiRadius * 1.0
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
                        lineWidth: keyModel.scaleNoteState != nil ? 6 : 12)
                }
                
                ///----------- Note Status-----------
                if scalesModel.resultPublished != nil {
                    let width = playingMidiRadius * 1.0
                    let x = rect.origin.x + rect.width / 2.0 - (width/CGFloat(2) * 1.0 )
                    let y = rect.origin.y + rect.height * 0.80 - width/CGFloat(2)

                    let color = getKeyStatusColor(key: key) //getKeyStatusColor(key)
                    let backgroundRect = CGRect(x: x, y: y, width: playingMidiRadius, height: playingMidiRadius)
                    context.fill(Path(ellipseIn: backgroundRect), with: .color(color))
                }
                
                ///----------- Finger number
                if scalesModel.showFingers {
                    if let scaleNote = key.scaleNoteState {
                        let point = CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.80)
                        let finger:String = scaleNote.finger > 5 ? "►" : String(scaleNote.finger)
                        //if !scalesModel.showStaff {
                            if false {
                                ///White background for finger number on a black key
                                ///23May dropped and instead make black keys less black
                                if key.scaleNoteState == nil {
                                    let edge = rect.width * 0.05
                                    let col = Color.white.opacity(0.8) //scaleNote.fingerSequenceBreak ? Color.yellow.opacity(0.6) :
                                    let width = rect.width - 2 * edge
                                    let backgroundRect = CGRect(x: rect.origin.x + edge, y: point.y - width / 2.0 + 1, width: width, height: width)
                                    context.fill(Path(ellipseIn: backgroundRect), with: .color(col))
                                }
                            }
                            context.draw(
                                Text(finger).foregroundColor(scaleNote.fingerSequenceBreak ? Color.orange : Color.blue)
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
