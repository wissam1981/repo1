import SwiftUI

struct TouchpadView: View {
    var onSwipe: (Direction) -> Void
    var onTap: () -> Void

    private let swipeThreshold: CGFloat = 40

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(ZapperTheme.Colors.surfaceContainerLowest)
                    .overlay(
                        DotGridPattern()
                            .opacity(0.1)
                            .clipShape(Circle())
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ZapperTheme.Colors.primaryContainer.opacity(0.05),
                                        .clear,
                                        ZapperTheme.Colors.secondaryContainer.opacity(0.05),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.1), lineWidth: 1)
                    )

                VStack {
                    Image(systemName: "chevron.up")
                        .font(.title3)
                        .foregroundStyle(ZapperTheme.Colors.outline.opacity(0.4))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundStyle(ZapperTheme.Colors.outline.opacity(0.4))
                }
                .padding(.vertical, size * 0.08)

                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(ZapperTheme.Colors.outline.opacity(0.4))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(ZapperTheme.Colors.outline.opacity(0.4))
                }
                .padding(.horizontal, size * 0.08)

                Button(action: onTap) {
                    Circle()
                        .fill(ZapperTheme.Colors.surfaceContainerHigh)
                        .overlay(
                            Circle()
                                .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: size * 0.28, height: size * 0.28)
                        .overlay(
                            Text("OK")
                                .font(ZapperTheme.Typography.headline(13, weight: .heavy))
                                .tracking(2)
                                .foregroundStyle(ZapperTheme.Colors.onSurface)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8)
                }
                .jewelButton()
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: swipeThreshold)
                    .onEnded { value in
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        if horizontal > vertical {
                            onSwipe(value.translation.width > 0 ? .right : .left)
                        } else {
                            onSwipe(value.translation.height > 0 ? .down : .up)
                        }
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct DotGridPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            let dotRadius: CGFloat = 1
            for x in stride(from: spacing / 2, to: size.width, by: spacing) {
                for y in stride(from: spacing / 2, to: size.height, by: spacing) {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
                        with: .color(ZapperTheme.Colors.outline)
                    )
                }
            }
        }
    }
}
