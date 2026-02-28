import SwiftUI

extension Color {
    init(hexValue: UInt32, alpha: Double = 1.0) {
        let r = Double((hexValue & 0xFF0000) >> 16) / 255.0
        let g = Double((hexValue & 0x00FF00) >> 8) / 255.0
        let b = Double(hexValue & 0x0000FF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
