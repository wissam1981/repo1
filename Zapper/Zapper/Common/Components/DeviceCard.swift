import SwiftUI

struct DeviceCard: View {
    let device: TVDevice
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ZapperTheme.Colors.surfaceContainerHighest)
                        .frame(width: 56, height: 56)
                    Image(systemName: "tv")
                        .font(.title2)
                        .foregroundStyle(ZapperTheme.Colors.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(ZapperTheme.Typography.headline(15, weight: .bold))
                        .foregroundStyle(ZapperTheme.Colors.onSurface)

                    HStack(spacing: 6) {
                        Image(systemName: "network")
                            .font(.caption2)
                            .foregroundStyle(ZapperTheme.Colors.outline)
                        Text(device.ipAddress.isEmpty ? "Discovering..." : device.ipAddress)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ZapperTheme.Colors.outlineVariant)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ZapperTheme.Colors.primary)
                    .frame(width: 32, height: 32)
                    .background(ZapperTheme.Colors.primaryContainer.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: ZapperTheme.Dimensions.cardCornerRadius)
                    .fill(ZapperTheme.Colors.surfaceContainerLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: ZapperTheme.Dimensions.cardCornerRadius)
                            .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .jewelButton()
    }
}
