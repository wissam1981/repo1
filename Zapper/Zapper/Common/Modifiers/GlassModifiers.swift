import SwiftUI

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = ZapperTheme.Dimensions.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(hex: 0x1F1F25, opacity: 0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            .mask(
                                LinearGradient(
                                    colors: [.white, .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
            )
    }
}

struct JewelButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(JewelButtonStyle())
    }
}

struct JewelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AmbientGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 120

    func body(content: Content) -> some View {
        content.background(
            Circle()
                .fill(color.opacity(0.15))
                .blur(radius: radius)
        )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = ZapperTheme.Dimensions.cardCornerRadius) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius))
    }

    func jewelButton() -> some View {
        modifier(JewelButtonModifier())
    }

    func ambientGlow(_ color: Color = ZapperTheme.Colors.primaryContainer, radius: CGFloat = 120) -> some View {
        modifier(AmbientGlowModifier(color: color, radius: radius))
    }
}
