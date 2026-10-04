import AppKit
import SwiftUI

enum Theme {
    static let background = dynamic(light: 0xF5F4EE, dark: 0x262624)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x30302E)
    static let userBubble = dynamic(light: 0xE9E6DC, dark: 0x3A3A37)
    static let textNS = nsDynamic(light: 0x1F1E1D, dark: 0xF5F4EE)
    static let text = Color(nsColor: textNS)
    static let secondary = dynamic(light: 0x73726C, dark: 0xA6A39A)
    static let border = dynamic(light: 0xE0DDD2, dark: 0x3D3D3A)
    static let code = dynamic(light: 0xEDEAE0, dark: 0x1F1E1D)
    static let accent = Color(nsColor: color(0xD97757))

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: nsDynamic(light: light, dark: dark))
    }

    private static func nsDynamic(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? color(dark) : color(light)
        }
    }

    private static func color(_ hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
