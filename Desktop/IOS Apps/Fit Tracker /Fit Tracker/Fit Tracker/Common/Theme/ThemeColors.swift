import SwiftUI

// MARK: - Theme Colors
// Centralized color management for the app using a blue color scheme

struct ThemeColors {
    // MARK: - Primary Colors

    static var primary: Color {
        switch ThemeManager.shared.currentTheme {
        case .neonGreen: return Color(hex: "#c4f20d")
        case .oceanBlue: return Color(hex: "#0ea5e9") // Sky Blue 500
        case .sunsetOrange: return Color(hex: "#f97316") // Orange 500
        case .ironPulse: return Color(hex: "#e31b23") // Crimson
        case .cleanWhite: return Color(hex: "#0ea5e9") // Sky blue
        }
    }

    static var backgroundDark: Color {
        switch ThemeManager.shared.currentTheme {
        case .neonGreen: return Color(hex: "#1e2210")
        case .oceanBlue: return Color(hex: "#0f172a") // Slate 900
        case .sunsetOrange: return Color(hex: "#2c1910") // Dark warm brown
        case .ironPulse: return Color(hex: "#0a0a0a") // Deep Black
        case .cleanWhite: return Color(hex: "#F5F7FA") // Cool light gray
        }
    }

    /// Light background from Stitch ("background-light": "#f8f8f5")
    static let backgroundLight = Color(hex: "#f8f8f5")

    static var primaryDark: Color {
        switch ThemeManager.shared.currentTheme {
        case .neonGreen: return Color(hex: "#9fb90d")
        case .oceanBlue: return Color(hex: "#0284c7") // Sky Blue 600
        case .sunsetOrange: return Color(hex: "#ea580c") // Orange 600
        case .ironPulse: return Color(hex: "#93000d") // Dark Crimson
        case .cleanWhite: return Color(hex: "#0284c7")
        }
    }

    static var secondary: Color {
        switch ThemeManager.shared.currentTheme {
        case .neonGreen: return Color(hex: "#ecf2be")
        case .oceanBlue: return Color(hex: "#cce8f6")
        case .sunsetOrange: return Color(hex: "#fde6cd")
        case .ironPulse: return Color(hex: "#1e222e") // Slate
        case .cleanWhite: return Color(hex: "#E8F4FD") // Light blue tint
        }
    }

    // MARK: - Semantic Colors
    static var success: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#10b981")
        default: return Color(hex: "#0df28a") // Mint Green
        }
    }

    /// Bright Rose for error/negative states ("bg-rose-500" from Stitch)
    static var error: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#ef4444")
        default: return Color(hex: "#f43f5e")
        }
    }

    /// Cyan for informational elements
    static var info: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#06b6d4")
        default: return Color(hex: "#0df2d8")
        }
    }

    /// Frosted glass look for dark mode (bg-white/5)
    static var surfaceColor: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return .white
        default: return Color.white.opacity(0.1)
        }
    }

    static var surfaceBorder: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#0ea5e9").opacity(0.08)
        default: return Color.white.opacity(0.06)
        }
    }

    static var surfaceShadow: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color.black.opacity(0.06)
        default: return Color.clear
        }
    }

    // MARK: - Text Colors
    static var textPrimary: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#1a1a1a")
        default: return .white
        }
    }

    static var textSecondary: Color {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite: return Color(hex: "#767676")
        default: return .white.opacity(0.5)
        }
    }

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        switch ThemeManager.shared.currentTheme {
        case .cleanWhite:
            return LinearGradient(
                colors: [Color(hex: "#0ea5e9"), Color(hex: "#0284c7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [primary, Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Convenience Methods
    /// Get a color with custom opacity
    static func withOpacity(_ color: Color, _ opacity: Double) -> Color {
        return color.opacity(opacity)
    }

    /// Primary color with reduced opacity for backgrounds
    static var primaryBackground: Color {
        primary.opacity(0.15)
    }

    /// Success color with reduced opacity for backgrounds
    static var successBackground: Color {
        success.opacity(0.15)
    }

    /// Error color with reduced opacity for backgrounds
    static var errorBackground: Color {
        error.opacity(0.15)
    }

    /// Info color with reduced opacity for backgrounds
    static var infoBackground: Color {
        info.opacity(0.15)
    }
}
