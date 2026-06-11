import SwiftUI

struct VitlCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(Color.white, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 10, y: 3)
    }
}

struct SheetChrome<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 38, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 18)
            content
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

struct ProgressPill: View {
    var value: Double
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.07))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 5)
    }
}

struct LockOverlay: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.vitlInk, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.vitlInk)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                Text("升级 Vitl Pro")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.vitlOrange, in: Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

struct MiniChart: View {
    enum Style {
        case line
        case bar
        case area
    }

    let values: [Double]
    var color: Color
    var style: Style

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(values.max() ?? 1, 1)
            let minValue = values.min() ?? 0
            let range = max(maxValue - minValue, 1)

            Canvas { context, size in
                switch style {
                case .bar:
                    let gap: CGFloat = 5
                    let width = (size.width - gap * CGFloat(max(values.count - 1, 0))) / CGFloat(max(values.count, 1))
                    for index in values.indices {
                        let normalized = (values[index] - minValue) / range
                        let height = size.height * CGFloat(max(normalized, 0.08))
                        let rect = CGRect(x: CGFloat(index) * (width + gap), y: size.height - height, width: width, height: height)
                        context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(color))
                    }
                case .line, .area:
                    var path = Path()
                    for index in values.indices {
                        let x = CGFloat(index) / CGFloat(max(values.count - 1, 1)) * size.width
                        let y = size.height - CGFloat((values[index] - minValue) / range) * (size.height - 8) - 4
                        if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    if style == .area {
                        var area = path
                        area.addLine(to: CGPoint(x: size.width, y: size.height))
                        area.addLine(to: CGPoint(x: 0, y: size.height))
                        area.closeSubpath()
                        context.fill(area, with: .linearGradient(Gradient(colors: [color.opacity(0.28), color.opacity(0.02)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                    }
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    ForEach(["周一", "周二", "周三", "周四", "周五", "周六", "今天"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .offset(y: 17)
            }
            .padding(.bottom, 16)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
