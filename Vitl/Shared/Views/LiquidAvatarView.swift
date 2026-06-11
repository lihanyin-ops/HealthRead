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
        let avatar = avatarShape(in: CGRect(x: offsetX, y: offsetY, width: 100 * scale, height: 110 * scale))
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

        context.stroke(avatar, with: .color(skinColor(for: avatarType).opacity(0.42)), lineWidth: 1.4)
        drawFace(context: context, rect: CGRect(x: offsetX, y: offsetY, width: 100 * scale, height: 110 * scale))
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
        case .woman:
            path.addEllipse(in: CGRect(x: rect.minX + 35 * s, y: rect.minY + 1 * s, width: 30 * s, height: 34 * s))
            path.addRoundedRect(in: CGRect(x: rect.minX + 17 * s, y: rect.minY + 38 * s, width: 66 * s, height: 58 * s), cornerSize: CGSize(width: 18 * s, height: 18 * s))
        case .alien:
            path.addEllipse(in: CGRect(x: rect.minX + 28 * s, y: rect.minY - 2 * s, width: 44 * s, height: 44 * s))
            path.addRoundedRect(in: CGRect(x: rect.minX + 28 * s, y: rect.minY + 40 * s, width: 44 * s, height: 56 * s), cornerSize: CGSize(width: 14 * s, height: 14 * s))
        case .monster:
            path.move(to: point(34, 8)); path.addLine(to: point(28, -3)); path.addLine(to: point(40, 7)); path.closeSubpath()
            path.move(to: point(66, 8)); path.addLine(to: point(72, -3)); path.addLine(to: point(60, 7)); path.closeSubpath()
            path.addEllipse(in: CGRect(x: rect.minX + 28 * s, y: rect.minY, width: 44 * s, height: 40 * s))
            path.addRoundedRect(in: CGRect(x: rect.minX + 15 * s, y: rect.minY + 38 * s, width: 70 * s, height: 58 * s), cornerSize: CGSize(width: 14 * s, height: 14 * s))
        case .dog:
            path.addEllipse(in: CGRect(x: rect.minX + 22 * s, y: rect.minY - 4 * s, width: 18 * s, height: 28 * s))
            path.addEllipse(in: CGRect(x: rect.minX + 60 * s, y: rect.minY - 4 * s, width: 18 * s, height: 28 * s))
            fallthrough
        case .man:
            path.addEllipse(in: CGRect(x: rect.minX + 34 * s, y: rect.minY, width: 32 * s, height: 36 * s))
            path.addRoundedRect(in: CGRect(x: rect.minX + 20 * s, y: rect.minY + 38 * s, width: 60 * s, height: 58 * s), cornerSize: CGSize(width: 13 * s, height: 13 * s))
        case .cat:
            path.move(to: point(30, 8)); path.addLine(to: point(22, -4)); path.addLine(to: point(40, 7)); path.closeSubpath()
            path.move(to: point(70, 8)); path.addLine(to: point(78, -4)); path.addLine(to: point(60, 7)); path.closeSubpath()
            path.addEllipse(in: CGRect(x: rect.minX + 32 * s, y: rect.minY + 2 * s, width: 36 * s, height: 34 * s))
            path.addRoundedRect(in: CGRect(x: rect.minX + 20 * s, y: rect.minY + 38 * s, width: 60 * s, height: 58 * s), cornerSize: CGSize(width: 13 * s, height: 13 * s))
        }
        return path
    }

    private func drawFace(context: GraphicsContext, rect: CGRect) {
        let s = rect.width / 100
        let eyeColor = avatarType == .alien ? Color.black : Color.black.opacity(0.45)
        let left = CGRect(x: rect.minX + 39 * s, y: rect.minY + 16 * s, width: 4 * s, height: 5 * s)
        let right = CGRect(x: rect.minX + 57 * s, y: rect.minY + 16 * s, width: 4 * s, height: 5 * s)
        context.fill(Path(ellipseIn: left), with: .color(eyeColor))
        context.fill(Path(ellipseIn: right), with: .color(eyeColor))
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
