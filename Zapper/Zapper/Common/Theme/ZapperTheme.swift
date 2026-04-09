import SwiftUI

enum ZapperTheme {
    enum Colors {
        static let surface = Color(hex: 0x131318)
        static let surfaceContainer = Color(hex: 0x1F1F25)
        static let surfaceContainerLow = Color(hex: 0x1B1B20)
        static let surfaceContainerLowest = Color(hex: 0x0E0E13)
        static let surfaceContainerHigh = Color(hex: 0x2A292F)
        static let surfaceContainerHighest = Color(hex: 0x35343A)
        static let surfaceBright = Color(hex: 0x39383E)
        static let primaryContainer = Color(hex: 0x2563EB)
        static let primary = Color(hex: 0xB4C5FF)
        static let secondary = Color(hex: 0xA4C9FF)
        static let secondaryContainer = Color(hex: 0x0267B8)
        static let error = Color(hex: 0xFFB4AB)
        static let errorContainer = Color(hex: 0x93000A)
        static let onSurface = Color(hex: 0xE4E1E9)
        static let onSurfaceVariant = Color(hex: 0xC3C6D7)
        static let onPrimaryContainer = Color(hex: 0xEEEFFF)
        static let outline = Color(hex: 0x8D90A0)
        static let outlineVariant = Color(hex: 0x434655)
        static let tertiary = Color(hex: 0xBCC7DE)
        static let tertiaryContainer = Color(hex: 0x636E83)
    }

    enum Typography {
        static let headlineFont = "Manrope"
        static let bodyFont = "Inter"

        static func headline(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .custom(headlineFont, size: size).weight(weight)
        }

        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom(bodyFont, size: size).weight(weight)
        }

        static func label(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .custom(bodyFont, size: size).weight(weight)
        }
    }

    enum Dimensions {
        static let cardCornerRadius: CGFloat = 32
        static let buttonCornerRadius: CGFloat = 16
        static let navBarCornerRadius: CGFloat = 32
        static let glassBlurRadius: CGFloat = 24
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
