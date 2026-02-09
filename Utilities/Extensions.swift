import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension Color {
    static let obsidianBlack = Color(hex: "#0A0A0A")
    static let charcoalGrey = Color(hex: "#1C1C1E")
    static let stealthWhite = Color.white.opacity(0.05)
    static let softRose = Color(hex: "#FFD1DC")
    static let freshLime = Color(hex: "#E2F1AF")
    static let skyBlue = Color(hex: "#ADE8F4")
    static let lavenderPurple = Color(hex: "#D6BCFA")
    static let softTerracotta = Color(hex: "#F6AD55")
}
