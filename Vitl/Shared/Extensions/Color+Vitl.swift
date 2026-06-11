import SwiftUI

extension Color {
    static let vitlBackground = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    static let vitlInk = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let vitlGreen = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let vitlBlue = Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    static let vitlTeal = Color(red: 48 / 255, green: 176 / 255, blue: 199 / 255)
    static let vitlOrange = Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255)
    static let vitlRed = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)
    static let vitlPurple = Color(red: 94 / 255, green: 92 / 255, blue: 230 / 255)

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

struct VitlEnergyStyle: Equatable {
    let label: String
    let emoji: String
    let color: Color
    let uiColor: UInt32

    static func style(for score: Int) -> VitlEnergyStyle {
        switch score {
        case 80...100:
            return .init(label: "状态极佳", emoji: "🔥", color: .vitlGreen, uiColor: 0x4ADE80)
        case 60...79:
            return .init(label: "状态良好", emoji: "⚡", color: Color(hex: 0x22C55E), uiColor: 0x22C55E)
        case 40...59:
            return .init(label: "状态一般", emoji: "😊", color: .vitlOrange, uiColor: 0xFB923C)
        case 20...39:
            return .init(label: "状态偏低", emoji: "💧", color: Color(hex: 0xF97316), uiColor: 0xF97316)
        default:
            return .init(label: "需要休息", emoji: "😴", color: .vitlRed, uiColor: 0xEF4444)
        }
    }
}
