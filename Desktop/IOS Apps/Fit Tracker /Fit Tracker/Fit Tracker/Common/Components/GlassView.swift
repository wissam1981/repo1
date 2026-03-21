import SwiftUI

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(color)
                    .background({
                        let blurStyle: UIBlurEffect.Style = ThemeManager.shared.currentTheme.isLightTheme
                            ? .systemThinMaterial
                            : .systemThinMaterialDark
                        return VisualEffectView(effect: UIBlurEffect(style: blurStyle))
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }())
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                    )
            )
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

extension View {
    func glassStyle(cornerRadius: CGFloat = 24, color: Color = Color.white.opacity(0.08)) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius, color: color))
    }
}
