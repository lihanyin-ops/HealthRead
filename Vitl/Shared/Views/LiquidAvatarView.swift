import SwiftUI
import CoreMotion

@MainActor
final class MotionTiltModel: ObservableObject {
    @Published var tiltX: Double = 0
    @Published var tiltY: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            self?.tiltX = motion.attitude.roll * 12
            self?.tiltY = motion.attitude.pitch * 8
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

struct LiquidAvatarView: View {
    let energy: Int
    var avatarType: AvatarType = .man
    var size: CGFloat = 190
    var tiltX: Double = 0
    var tiltY: Double = 0

    @State private var bubbles: [Bubble] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSinceReferenceDate
                draw(context: context, size: canvasSize, time: t)
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .center) {
            ZStack {
                ForEach(bubbles) { bubble in
                    Text(bubble.text)
                        .font(.system(size: bubble.fontSize, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.62), in: Capsule())
                        .offset(x: bubble.x, y: bubble.y)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { spawnBubbles() }
    }

    private func draw(context: GraphicsContext, size canvasSize: CGSize, time: TimeInterval) {
        let scale = min(canvasSize.width, canvasSize.height) / 110
        let offsetX = (canvasSize.width - 100 * scale) / 2
        let offsetY = (canvasSize.height - 110 * scale) / 2 + 4
        let avatarRect = CGRect(x: offsetX, y: offsetY, width: 100 * scale, height: 110 * scale)
        let avatar = avatarShape(in: avatarRect)
        let style = VitlEnergyStyle.style(for: energy)

        context.fill(avatar, with: .color(skinColor(for: avatarType).opacity(0.78)))

        var fillContext = context
        fillContext.clip(to: avatar)
        let bodyBottom = offsetY + 96 * scale
        let bodyTop = offsetY - 2 * scale
        let fillHeight = (bodyBottom - bodyTop) * CGFloat(energy) / 100
        let baseSurface = bodyBottom - fillHeight - CGFloat(tiltY) * 0.6
        let waveAmp = (2.4 + abs(tiltX) * 0.18) * scale
        let horizontalTilt = CGFloat(tiltX) * 0.25 * scale

        let liquidRect = CGRect(x: offsetX - 16 * scale, y: baseSurface - 12 * scale, width: 132 * scale, height: bodyBottom - baseSurface + 24 * scale)
        let gradient = Gradient(colors: [
            Color(hex: style.uiColor).opacity(0.72),
            Color(hex: style.uiColor),
            style.color.opacity(0.92)
        ])
        let fillPath = wavePath(
            xMin: liquidRect.minX,
            xMax: liquidRect.maxX,
            surfaceY: baseSurface,
            bottomY: bodyBottom + 8 * scale,
            amplitude: waveAmp,
            phase: time * 2.2 + tiltX * 0.05,
            tilt: horizontalTilt
        )
        fillContext.fill(fillPath, with: .linearGradient(gradient, startPoint: CGPoint(x: liquidRect.midX, y: liquidRect.minY), endPoint: CGPoint(x: liquidRect.midX, y: liquidRect.maxY)))

        let shimmerPath = wavePath(
            xMin: liquidRect.minX,
            xMax: liquidRect.maxX,
            surfaceY: baseSurface - 1.5 * scale,
            bottomY: bodyBottom + 8 * scale,
            amplitude: waveAmp * 0.65,
            phase: time * 2.8 + .pi,
            tilt: horizontalTilt * 0.6
        )
        fillContext.fill(shimmerPath, with: .color(.white.opacity(0.16)))
        fillContext.fill(Path(ellipseIn: CGRect(x: offsetX + 20 * scale, y: baseSurface + 2 * scale, width: 18 * scale, height: 10 * scale)), with: .color(.white.opacity(0.28)))

        context.stroke(avatar, with: .color(outlineColor(for: avatarType).opacity(0.46)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        drawAvatarDetails(context: context, rect: avatarRect)
    }

    private func wavePath(xMin: CGFloat, xMax: CGFloat, surfaceY: CGFloat, bottomY: CGFloat, amplitude: CGFloat, phase: Double, tilt: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: xMin, y: surfaceY))
        var x = xMin
        while x <= xMax {
            let progress = (x - xMin) / max(xMax - xMin, 1)
            let y = surfaceY + amplitude * sin(progress * .pi * 4 + phase) + (progress - 0.5) * tilt
            path.addLine(to: CGPoint(x: x, y: y))
            x += 3
        }
        path.addLine(to: CGPoint(x: xMax, y: bottomY))
        path.addLine(to: CGPoint(x: xMin, y: bottomY))
        path.closeSubpath()
        return path
    }

    private func avatarShape(in rect: CGRect) -> Path {
        let s = rect.width / 100
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        switch avatarType {
        case .man:
            path.move(to: point(50, 3))
            path.addCurve(to: point(31, 22), control1: point(39, 3), control2: point(31, 11))
            path.addCurve(to: point(39, 39), control1: point(31, 31), control2: point(34, 36))
            path.addLine(to: point(39, 43))
            path.addCurve(to: point(19, 51), control1: point(30, 44), control2: point(23, 47))
            path.addCurve(to: point(8, 82), control1: point(12, 60), control2: point(9, 70))
            path.addCurve(to: point(22, 86), control1: point(8, 88), control2: point(18, 91))
            path.addLine(to: point(27, 67))
            path.addLine(to: point(30, 103))
            path.addCurve(to: point(43, 107), control1: point(31, 110), control2: point(42, 111))
            path.addLine(to: point(49, 79))
            path.addLine(to: point(57, 107))
            path.addCurve(to: point(70, 103), control1: point(58, 111), control2: point(69, 110))
            path.addLine(to: point(73, 67))
            path.addLine(to: point(78, 86))
            path.addCurve(to: point(92, 82), control1: point(82, 91), control2: point(92, 88))
            path.addCurve(to: point(81, 51), control1: point(91, 70), control2: point(88, 60))
            path.addCurve(to: point(61, 43), control1: point(77, 47), control2: point(70, 44))
            path.addLine(to: point(61, 39))
            path.addCurve(to: point(69, 22), control1: point(66, 36), control2: point(69, 31))
            path.addCurve(to: point(50, 3), control1: point(69, 11), control2: point(61, 3))
            path.closeSubpath()
        case .woman:
            path.move(to: point(50, 0))
            path.addCurve(to: point(25, 30), control1: point(33, 1), control2: point(25, 13))
            path.addCurve(to: point(18, 49), control1: point(24, 39), control2: point(21, 45))
            path.addCurve(to: point(7, 80), control1: point(11, 58), control2: point(8, 69))
            path.addCurve(to: point(20, 85), control1: point(6, 88), control2: point(17, 91))
            path.addLine(to: point(27, 66))
            path.addCurve(to: point(21, 103), control1: point(24, 77), control2: point(22, 89))
            path.addCurve(to: point(36, 107), control1: point(22, 110), control2: point(34, 111))
            path.addLine(to: point(48, 79))
            path.addLine(to: point(64, 107))
            path.addCurve(to: point(79, 103), control1: point(66, 111), control2: point(78, 110))
            path.addCurve(to: point(73, 66), control1: point(78, 89), control2: point(76, 77))
            path.addLine(to: point(80, 85))
            path.addCurve(to: point(93, 80), control1: point(83, 91), control2: point(94, 88))
            path.addCurve(to: point(82, 49), control1: point(92, 69), control2: point(89, 58))
            path.addCurve(to: point(75, 30), control1: point(79, 45), control2: point(76, 39))
            path.addCurve(to: point(50, 0), control1: point(75, 13), control2: point(67, 1))
            path.closeSubpath()
        case .alien:
            path.move(to: point(50, -1))
            path.addCurve(to: point(20, 25), control1: point(30, 0), control2: point(18, 11))
            path.addCurve(to: point(38, 47), control1: point(22, 38), control2: point(30, 45))
            path.addLine(to: point(36, 54))
            path.addCurve(to: point(18, 72), control1: point(25, 57), control2: point(19, 63))
            path.addCurve(to: point(30, 76), control1: point(17, 80), control2: point(27, 82))
            path.addLine(to: point(34, 67))
            path.addLine(to: point(36, 103))
            path.addCurve(to: point(47, 106), control1: point(37, 109), control2: point(46, 110))
            path.addLine(to: point(50, 82))
            path.addLine(to: point(53, 106))
            path.addCurve(to: point(64, 103), control1: point(54, 110), control2: point(63, 109))
            path.addLine(to: point(66, 67))
            path.addLine(to: point(70, 76))
            path.addCurve(to: point(82, 72), control1: point(73, 82), control2: point(83, 80))
            path.addCurve(to: point(64, 54), control1: point(81, 63), control2: point(75, 57))
            path.addLine(to: point(62, 47))
            path.addCurve(to: point(80, 25), control1: point(70, 45), control2: point(78, 38))
            path.addCurve(to: point(50, -1), control1: point(82, 11), control2: point(70, 0))
            path.closeSubpath()
        case .monster:
            path.move(to: point(31, 11))
            path.addLine(to: point(26, -4))
            path.addLine(to: point(41, 7))
            path.addCurve(to: point(50, 3), control1: point(44, 4), control2: point(47, 3))
            path.addCurve(to: point(59, 7), control1: point(53, 3), control2: point(56, 4))
            path.addLine(to: point(74, -4))
            path.addLine(to: point(69, 11))
            path.addCurve(to: point(75, 27), control1: point(73, 16), control2: point(75, 21))
            path.addCurve(to: point(66, 43), control1: point(75, 35), control2: point(72, 40))
            path.addCurve(to: point(87, 60), control1: point(78, 45), control2: point(86, 50))
            path.addCurve(to: point(93, 86), control1: point(91, 68), control2: point(95, 77))
            path.addCurve(to: point(77, 89), control1: point(91, 93), control2: point(81, 94))
            path.addLine(to: point(72, 74))
            path.addLine(to: point(71, 104))
            path.addCurve(to: point(56, 107), control1: point(69, 111), control2: point(58, 111))
            path.addLine(to: point(50, 83))
            path.addLine(to: point(44, 107))
            path.addCurve(to: point(29, 104), control1: point(42, 111), control2: point(31, 111))
            path.addLine(to: point(28, 74))
            path.addLine(to: point(23, 89))
            path.addCurve(to: point(7, 86), control1: point(19, 94), control2: point(9, 93))
            path.addCurve(to: point(13, 60), control1: point(5, 77), control2: point(9, 68))
            path.addCurve(to: point(34, 43), control1: point(14, 50), control2: point(22, 45))
            path.addCurve(to: point(25, 27), control1: point(28, 40), control2: point(25, 35))
            path.addCurve(to: point(31, 11), control1: point(25, 21), control2: point(27, 16))
            path.closeSubpath()
        case .dog:
            path.move(to: point(32, 2))
            path.addCurve(to: point(22, 30), control1: point(20, 5), control2: point(18, 20))
            path.addCurve(to: point(31, 43), control1: point(25, 37), control2: point(28, 41))
            path.addCurve(to: point(20, 54), control1: point(26, 45), control2: point(22, 49))
            path.addCurve(to: point(8, 83), control1: point(12, 61), control2: point(8, 72))
            path.addCurve(to: point(22, 87), control1: point(8, 90), control2: point(18, 93))
            path.addLine(to: point(28, 70))
            path.addLine(to: point(31, 104))
            path.addCurve(to: point(43, 107), control1: point(32, 110), control2: point(42, 111))
            path.addLine(to: point(49, 83))
            path.addLine(to: point(57, 107))
            path.addCurve(to: point(69, 104), control1: point(58, 111), control2: point(68, 110))
            path.addLine(to: point(72, 70))
            path.addLine(to: point(78, 87))
            path.addCurve(to: point(92, 83), control1: point(82, 93), control2: point(92, 90))
            path.addCurve(to: point(80, 54), control1: point(92, 72), control2: point(88, 61))
            path.addCurve(to: point(69, 43), control1: point(78, 49), control2: point(74, 45))
            path.addCurve(to: point(78, 30), control1: point(72, 41), control2: point(75, 37))
            path.addCurve(to: point(68, 2), control1: point(82, 20), control2: point(80, 5))
            path.addCurve(to: point(50, 3), control1: point(62, -2), control2: point(55, 1))
            path.addCurve(to: point(32, 2), control1: point(45, 1), control2: point(38, -2))
            path.closeSubpath()
        case .cat:
            path.move(to: point(30, 10))
            path.addLine(to: point(22, -4))
            path.addLine(to: point(42, 7))
            path.addCurve(to: point(50, 4), control1: point(45, 5), control2: point(48, 4))
            path.addCurve(to: point(58, 7), control1: point(52, 4), control2: point(55, 5))
            path.addLine(to: point(78, -4))
            path.addLine(to: point(70, 10))
            path.addCurve(to: point(70, 26), control1: point(73, 15), control2: point(73, 22))
            path.addCurve(to: point(60, 42), control1: point(69, 34), control2: point(66, 39))
            path.addCurve(to: point(80, 54), control1: point(70, 44), control2: point(77, 48))
            path.addCurve(to: point(91, 79), control1: point(87, 61), control2: point(91, 70))
            path.addCurve(to: point(82, 89), control1: point(91, 86), control2: point(87, 90))
            path.addCurve(to: point(77, 74), control1: point(80, 84), control2: point(78, 79))
            path.addLine(to: point(72, 104))
            path.addCurve(to: point(58, 107), control1: point(70, 111), control2: point(60, 111))
            path.addLine(to: point(51, 83))
            path.addLine(to: point(43, 107))
            path.addCurve(to: point(29, 104), control1: point(41, 111), control2: point(31, 111))
            path.addLine(to: point(24, 74))
            path.addCurve(to: point(18, 89), control1: point(22, 79), control2: point(20, 84))
            path.addCurve(to: point(9, 79), control1: point(13, 90), control2: point(9, 86))
            path.addCurve(to: point(20, 54), control1: point(9, 70), control2: point(13, 61))
            path.addCurve(to: point(40, 42), control1: point(23, 48), control2: point(30, 44))
            path.addCurve(to: point(30, 26), control1: point(34, 39), control2: point(31, 34))
            path.addCurve(to: point(30, 10), control1: point(27, 22), control2: point(27, 15))
            path.closeSubpath()
        }
        return path
    }

    private func drawAvatarDetails(context: GraphicsContext, rect: CGRect) {
        let s = rect.width / 100
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        let ink = outlineColor(for: avatarType)
        let softInk = ink.opacity(0.58)
        let eyeColor = avatarType == .alien ? Color(hex: 0x263A2F) : Color.black.opacity(0.52)

        func stroke(_ path: Path, width: CGFloat = 1.5, color: Color? = nil) {
            context.stroke(path, with: .color(color ?? softInk), style: StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round))
        }

        func fillEllipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: Color = eyeColor) {
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + x * s, y: rect.minY + y * s, width: w * s, height: h * s)), with: .color(color))
        }

        switch avatarType {
        case .man:
            var hair = Path()
            hair.move(to: p(33, 17))
            hair.addCurve(to: p(46, 7), control1: p(34, 9), control2: p(40, 5))
            hair.addCurve(to: p(67, 19), control1: p(55, 4), control2: p(63, 10))
            hair.addCurve(to: p(55, 15), control1: p(57, 18), control2: p(54, 13))
            hair.addCurve(to: p(42, 18), control1: p(50, 12), control2: p(45, 13))
            stroke(hair, width: 2.2, color: ink.opacity(0.62))
            fillEllipse(39, 20, 4, 5)
            fillEllipse(57, 20, 4, 5)
            stroke(smilePath(points: [p(46, 31), p(51, 34), p(57, 30)]), width: 1.2)
            stroke(linePath(p(38, 53), p(62, 53)), width: 1.1)
            stroke(linePath(p(50, 80), p(50, 106)), width: 1.1)
        case .woman:
            var hair = Path()
            hair.move(to: p(28, 36))
            hair.addCurve(to: p(34, 8), control1: p(22, 20), control2: p(27, 9))
            hair.addCurve(to: p(70, 38), control1: p(54, -2), control2: p(77, 14))
            hair.addCurve(to: p(60, 25), control1: p(62, 37), control2: p(62, 30))
            hair.addCurve(to: p(38, 24), control1: p(52, 15), control2: p(44, 16))
            stroke(hair, width: 2.3, color: Color(hex: 0x6D3B66).opacity(0.6))
            fillEllipse(39, 21, 4, 5)
            fillEllipse(57, 21, 4, 5)
            stroke(smilePath(points: [p(45, 31), p(51, 35), p(58, 30)]), width: 1.2)
            stroke(linePath(p(35, 62), p(65, 62)), width: 1.1)
            stroke(linePath(p(48, 80), p(37, 106)), width: 1)
            stroke(linePath(p(54, 80), p(69, 105)), width: 1)
        case .alien:
            stroke(linePath(p(42, 5), p(36, -8)), width: 1.3, color: ink.opacity(0.5))
            stroke(linePath(p(58, 5), p(64, -8)), width: 1.3, color: ink.opacity(0.5))
            fillEllipse(33, -11, 7, 7, color: Color(hex: 0xB7F36A))
            fillEllipse(60, -11, 7, 7, color: Color(hex: 0xB7F36A))
            fillEllipse(33, 22, 10, 13, color: Color(hex: 0x253629).opacity(0.75))
            fillEllipse(57, 22, 10, 13, color: Color(hex: 0x253629).opacity(0.75))
            stroke(smilePath(points: [p(45, 38), p(50, 40), p(55, 38)]), width: 1)
            stroke(linePath(p(40, 60), p(60, 60)), width: 1)
            stroke(linePath(p(50, 82), p(50, 105)), width: 0.9)
        case .monster:
            fillEllipse(38, 21, 6, 8, color: Color(hex: 0x3B2245).opacity(0.68))
            fillEllipse(56, 21, 6, 8, color: Color(hex: 0x3B2245).opacity(0.68))
            var mouth = Path()
            mouth.move(to: p(39, 34))
            mouth.addCurve(to: p(62, 34), control1: p(45, 39), control2: p(56, 39))
            stroke(mouth, width: 1.4)
            var teeth = Path()
            teeth.move(to: p(46, 35)); teeth.addLine(to: p(49, 40)); teeth.addLine(to: p(52, 35))
            teeth.move(to: p(55, 35)); teeth.addLine(to: p(58, 39)); teeth.addLine(to: p(61, 35))
            stroke(teeth, width: 0.9, color: .white.opacity(0.72))
            stroke(linePath(p(31, 55), p(69, 55)), width: 1.2)
            stroke(linePath(p(50, 82), p(50, 106)), width: 1)
        case .dog:
            var snout = Path()
            snout.addEllipse(in: CGRect(x: rect.minX + 39 * s, y: rect.minY + 24 * s, width: 22 * s, height: 13 * s))
            stroke(snout, width: 1.2)
            fillEllipse(40, 18, 4, 5)
            fillEllipse(56, 18, 4, 5)
            fillEllipse(48, 26, 5, 4, color: Color.black.opacity(0.55))
            stroke(smilePath(points: [p(50, 30), p(46, 34), p(42, 32)]), width: 0.95)
            stroke(smilePath(points: [p(50, 30), p(55, 34), p(59, 32)]), width: 0.95)
            stroke(linePath(p(36, 55), p(64, 55)), width: 1.1)
            stroke(linePath(p(50, 83), p(50, 106)), width: 1)
        case .cat:
            fillEllipse(39, 19, 4, 6)
            fillEllipse(57, 19, 4, 6)
            fillEllipse(49, 28, 4, 3, color: Color.black.opacity(0.52))
            stroke(linePath(p(50, 31), p(50, 35)), width: 0.9)
            stroke(linePath(p(34, 29), p(22, 25)), width: 0.8)
            stroke(linePath(p(34, 33), p(22, 35)), width: 0.8)
            stroke(linePath(p(66, 29), p(78, 25)), width: 0.8)
            stroke(linePath(p(66, 33), p(78, 35)), width: 0.8)
            stroke(linePath(p(36, 57), p(64, 57)), width: 1.1)
            var tail = Path()
            tail.move(to: p(81, 76))
            tail.addCurve(to: p(98, 59), control1: p(93, 75), control2: p(101, 66))
            tail.addCurve(to: p(89, 53), control1: p(96, 54), control2: p(91, 53))
            stroke(tail, width: 2.2, color: ink.opacity(0.48))
        }
    }

    private func linePath(_ start: CGPoint, _ end: CGPoint) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }

    private func smilePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count == 3 else { return path }
        path.move(to: points[0])
        path.addQuadCurve(to: points[2], control: points[1])
        return path
    }

    private func skinColor(for avatar: AvatarType) -> Color {
        switch avatar {
        case .man: return Color(hex: 0xF5C5A3)
        case .woman: return Color(hex: 0xF9C8C8)
        case .alien: return Color(hex: 0x90EE90)
        case .monster: return Color(hex: 0xC39BD3)
        case .dog: return Color(hex: 0xD4A76A)
        case .cat: return Color(hex: 0xF5A623)
        }
    }

    private func outlineColor(for avatar: AvatarType) -> Color {
        switch avatar {
        case .man: return Color(hex: 0x7A4A35)
        case .woman: return Color(hex: 0x9E597A)
        case .alien: return Color(hex: 0x3C7E52)
        case .monster: return Color(hex: 0x765090)
        case .dog: return Color(hex: 0x8E5F2A)
        case .cat: return Color(hex: 0xA46212)
        }
    }

    private func spawnBubbles() {
        let labels = ["步数 8,234", "HRV 52ms", "睡眠 7.5h", "血氧 98%", "饮水 +250"]
        let newBubbles = (0..<5).map { index in
            Bubble(
                text: labels[index % labels.count],
                x: CGFloat.random(in: -70...70),
                y: CGFloat.random(in: -70...35),
                fontSize: CGFloat.random(in: 9...11)
            )
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            bubbles.append(contentsOf: newBubbles)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.25)) {
                bubbles.removeAll()
            }
        }
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    let text: String
    let x: CGFloat
    let y: CGFloat
    let fontSize: CGFloat
}
