

import SwiftUI
import SwiftUI

public protocol KeyboardStyle {
    associatedtype Layout: View

    var naturalKeySpace: CGFloat { get }
    func naturalColor(_ down: Bool) -> Color
    func sharpFlatColor(_ down: Bool) -> Color
    func labelColor(_ noteNumber: Int) -> Color
    func layout(viewModel: PianoKeyboardViewModel, geometry: GeometryProxy) -> Layout
}

public struct ClassicStyle: KeyboardStyle {
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
        down ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.9, green: 0.9, blue: 0.9)
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

    public func layout(viewModel: PianoKeyboardViewModel, geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let xg = geometry.frame(in: .global).origin.x
            let yg = geometry.frame(in: .global).origin.y

            // Natural keys
            let cornerRadius = width * cornerRadiusMultiplier
            let naturalWidth = naturalKeyWidth(width, naturalKeyCount: viewModel.naturalKeyCount, space: naturalKeySpace)
            let naturalXIncr = naturalWidth + naturalKeySpace
            var xpos: CGFloat = 0.0
            
            for (index, key) in viewModel.keys.enumerated() {
                guard key.isNatural else {
                    continue
                }

                let rect = CGRect(
                    origin: CGPoint(x: xpos, y: 0),
                    size: CGSize(width: naturalWidth, height: height)
                )
                //print(index, key.noteNumber, key.keyIndex, key.name)
                let path = RoundedCornersShape(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
                    .path(in: rect)

                let gradient = Gradient(colors: [
                    naturalColor(key.touchDown),
                    Color(red: 1, green: 1, blue: 1),
                ])

                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.width / 2.0, y: 0),
                    endPoint: CGPoint(x: rect.width / 2.0, y: rect.height)
                ))

                if viewModel.showLabels {
                    let color = Color.black //key.name.prefix(1) == "C" ? labelColor : .clear
                    if key.finger.count > 0 {
                        context.draw(
                            Text(key.name).font(labelFont).foregroundColor(color),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.70)
                        )
                        
                        context.draw(
                            //Text(key.finger).font(.title.bold()).foregroundColor(Color.green),
                            Text(key.finger).foregroundColor(Color.green).font(.title).bold(),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.90)
                        )

                        if key.midiState.isPlayingMidi {
                            var innerContext = context
                            let rad = rect.height * 0.05
                            let w = 2.0 * rad
                            let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - rad,
                                               y: rect.origin.y + rect.height * 0.80 - rad, width: w, height: w)
                            if let image = UIImage(systemName: "star") {
                                let drawingImage = Image(uiImage: image)
                                context.draw(drawingImage, in: frame)
                            }
                        }
                        
                        if key.fingerSequenceBreak {
                            var innerContext = context
                            let rad = rect.height * 0.05
                            let w = 2.0 * rad
                            let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - rad, y: rect.origin.y + rect.height * 0.90 - rad, width: w, height: w)
                            
                            innerContext.stroke(
                                Path(ellipseIn: frame),
                                with: .color(.green),
                                lineWidth: 2)
                            var innerContext1 = context
                            innerContext1.opacity = 0.3
                            innerContext1.fill(Path(ellipseIn: frame), with: .color(.yellow))
                        }
                    }
                }

                xpos += naturalXIncr

                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }

            // Sharps/Flat keys
            let sfKeyWidth = naturalWidth * sfKeyWidthMultiplier
            let sfKeyHeight = height * sfKeyHeightMultiplier
            xpos = 0.0

            for (index, key) in viewModel.keys.enumerated() {
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
                
                if viewModel.showLabels {
                    if key.finger.count > 0 {
                        let color = Color.white //key.name.prefix(1) == "C" ? labelColor : .clear
                        
                        context.draw(
                            Text(key.name).font(labelFont).foregroundColor(color),
                            //at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.88)
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.50)
                            
                        )
                        
                        let rad = rect.height * 0.08
                        let w = 2.0 * rad
                        let frame = CGRect(x: rect.origin.x + rect.width / 2.0 - rad, y: rect.origin.y + rect.height * 0.75 - rad, width: w, height: w)
                        
                        if key.fingerSequenceBreak {
                            var innerContext = context
                            var innerContext1 = context
                            innerContext1.opacity = 0.8
                            innerContext1.fill(Path(ellipseIn: frame), with: .color(.yellow))

                            innerContext.stroke(
                                Path(ellipseIn: frame),
                                with: .color(.green),
                                lineWidth: 2)
                        }
                        else {
                            var innerContext = context
                            var innerContext1 = context
                            innerContext1.opacity = 0.6
                            innerContext1.fill(Path(ellipseIn: frame), with: .color(.white))

//                            innerContext.stroke(
//                                Path(ellipseIn: frame),
//                                with: .color(.white),
//                                lineWidth: 2)
                        }
                        context.draw(
                            Text(key.finger).foregroundColor(Color.green).font(.title).bold(),
                            at: CGPoint(x: rect.origin.x + rect.width / 2.0, y: rect.origin.y + rect.height * 0.75)
                        )
                    }
                }

                viewModel.keyRects[index] = rect.offsetBy(dx: xg, dy: yg)
            }
        }
    }
}
