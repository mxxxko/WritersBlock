import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

private func dynamic(light: String, dark: String) -> Color {
    Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(Color(hex: dark))
            : UIColor(Color(hex: light))
    })
}

// MARK: - App palette

extension Color {
    static let eqBackground  = dynamic(light: "FFFBF5", dark: "0C0C14")
    static let eqSurface     = dynamic(light: "FFFFFF", dark: "13131E")
    static let eqSurfaceHigh = dynamic(light: "FFF0DC", dark: "1A1A28")
    static let eqBorder      = dynamic(light: "EDD9B8", dark: "252538")
    static let eqText        = dynamic(light: "1A0800", dark: "F0EEF8")
    static let eqTextDim     = dynamic(light: "7A5C40", dark: "9896B0")
    static let eqMuted       = dynamic(light: "BCA080", dark: "55536A")
    static let eqBrandPurple = dynamic(light: "EA580C", dark: "7C3AED")
    static let eqGreen       = dynamic(light: "059669", dark: "10B981")
    static let eqAmber       = dynamic(light: "D97706", dark: "F59E0B")
    static let eqRed         = dynamic(light: "DC2626", dark: "EF4444")
    static let eqAnchorBg    = dynamic(light: "FFD9A8", dark: "1A180A")
    static let eqAnchorGold  = dynamic(light: "F97316", dark: "A07830")
    static let eqAnchorText  = dynamic(light: "7C2D12", dark: "D4A050")
}

// MARK: - Block palettes

struct BlockPalette {
    let background: Color
    let border: Color
    let text: Color

    static let all: [BlockPalette] = [
        BlockPalette(
            background: dynamic(light: "EDE9FF", dark: "130E22"),
            border:     dynamic(light: "6D28D9", dark: "7C3AED"),
            text:       dynamic(light: "4C1D95", dark: "C4B5FD")),
        BlockPalette(
            background: dynamic(light: "DCFCE7", dark: "081A10"),
            border:     dynamic(light: "059669", dark: "10B981"),
            text:       dynamic(light: "065F46", dark: "6EE7B7")),
        BlockPalette(
            background: dynamic(light: "FFE4E4", dark: "1A0808"),
            border:     dynamic(light: "DC2626", dark: "EF4444"),
            text:       dynamic(light: "991B1B", dark: "FCA5A5")),
        BlockPalette(
            background: dynamic(light: "DBEAFE", dark: "08101A"),
            border:     dynamic(light: "2563EB", dark: "3B82F6"),
            text:       dynamic(light: "1E40AF", dark: "93C5FD")),
        BlockPalette(
            background: dynamic(light: "FEF3C7", dark: "1A1000"),
            border:     dynamic(light: "D97706", dark: "F59E0B"),
            text:       dynamic(light: "92400E", dark: "FCD34D")),
        BlockPalette(
            background: dynamic(light: "FCE7F3", dark: "1A0816"),
            border:     dynamic(light: "DB2777", dark: "EC4899"),
            text:       dynamic(light: "9D174D", dark: "F9A8D4")),
        BlockPalette(
            background: dynamic(light: "CFFAFE", dark: "001818"),
            border:     dynamic(light: "0891B2", dark: "06B6D4"),
            text:       dynamic(light: "164E63", dark: "67E8F9")),
        BlockPalette(
            background: dynamic(light: "ECFCCB", dark: "0C1800"),
            border:     dynamic(light: "65A30D", dark: "84CC16"),
            text:       dynamic(light: "3F6212", dark: "BEF264")),
    ]

    static func forBlock(id: Int) -> BlockPalette { all[abs(id) % 8] }
}
