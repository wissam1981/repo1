import SwiftUI

struct VolumeSlider: View {
    @Binding var volume: Float
    var isMuted: Bool
    var onVolumeUp: () -> Void
    var onVolumeDown: () -> Void
    var onMute: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onVolumeUp) {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                    .padding(8)
            }
            .jewelButton()

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ZapperTheme.Colors.surfaceContainerHigh)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [ZapperTheme.Colors.primaryContainer, ZapperTheme.Colors.primary],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geo.size.height * CGFloat(isMuted ? 0 : volume))
                }
                .frame(width: 4)
                .frame(maxWidth: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newVolume = 1.0 - Float(value.location.y / geo.size.height)
                            volume = max(0, min(1, newVolume))
                        }
                )
            }

            Button(action: onVolumeDown) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                    .foregroundStyle(isMuted ? ZapperTheme.Colors.error : ZapperTheme.Colors.onSurfaceVariant)
                    .padding(8)
            }
            .jewelButton()
            .onLongPressGesture { onMute() }
        }
        .glassPanel(cornerRadius: 40)
        .frame(width: 56)
    }
}
