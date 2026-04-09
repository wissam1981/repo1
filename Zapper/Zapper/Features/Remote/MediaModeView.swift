import SwiftUI

struct MediaModeView: View {
    var viewModel: RemoteViewModel

    private var media: MediaInfo? { viewModel.tvState.mediaInfo }
    private var isPlaying: Bool { viewModel.tvState.playbackState == .playing }

    var body: some View {
        VStack(spacing: 0) {
            nowPlayingCard
                .padding(.horizontal, 24)

            progressBar
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Spacer()

            HStack(spacing: 16) {
                playbackCluster

                VolumeSlider(
                    volume: .init(
                        get: { viewModel.tvState.volume },
                        set: { _ in }
                    ),
                    isMuted: viewModel.tvState.isMuted,
                    onVolumeUp: { viewModel.sendCommand(.volumeUp) },
                    onVolumeDown: { viewModel.sendCommand(.volumeDown) },
                    onMute: { viewModel.sendCommand(.mute) }
                )
                .frame(height: 220)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(
            RadialGradient(
                colors: [ZapperTheme.Colors.primaryContainer.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        )
    }

    private var nowPlayingCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A1A2E), Color(hex: 0x16213E), Color(hex: 0x0F3460)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(16 / 9, contentMode: .fit)

            LinearGradient(
                colors: [.clear, ZapperTheme.Colors.surface.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 4) {
                Text(media?.subtitle ?? "4K Ultra HD • 5.1")
                    .font(ZapperTheme.Typography.label(10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(ZapperTheme.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ZapperTheme.Colors.primaryContainer.opacity(0.3))
                            .overlay(Capsule().stroke(ZapperTheme.Colors.primary.opacity(0.2), lineWidth: 1))
                    )

                Text(media?.title ?? "Not Playing")
                    .font(ZapperTheme.Typography.headline(28, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(24)
        }
        .shadow(radius: 20)
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ZapperTheme.Colors.surfaceContainerHigh)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [ZapperTheme.Colors.primaryContainer, ZapperTheme.Colors.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatTime(media?.position))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                Spacer()
                Text("-\(formatTime(remaining))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
            }
        }
    }

    private var playbackCluster: some View {
        VStack(spacing: 16) {
            HStack {
                Button { viewModel.sendCommand(.seekBackward(seconds: 10)) } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .jewelButton()

                Button { viewModel.sendCommand(.seekForward(seconds: 10)) } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .jewelButton()
            }

            Button {
                viewModel.sendCommand(.playPause)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(ZapperTheme.Colors.onPrimaryContainer)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ZapperTheme.Colors.primary, ZapperTheme.Colors.primaryContainer],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: ZapperTheme.Colors.primaryContainer.opacity(0.3), radius: 12)
            }
            .jewelButton()

            HStack(spacing: 32) {
                Image(systemName: "captions.bubble")
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant.opacity(0.4))
                Image(systemName: "speedometer")
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant.opacity(0.4))
            }
        }
        .padding(24)
        .glassPanel()
        .frame(maxWidth: .infinity)
    }

    private var progress: CGFloat {
        guard let duration = media?.duration, duration > 0,
              let position = media?.position else { return 0 }
        return CGFloat(position / duration)
    }

    private var remaining: TimeInterval? {
        guard let duration = media?.duration, let position = media?.position else { return nil }
        return duration - position
    }

    private func formatTime(_ interval: TimeInterval?) -> String {
        guard let interval else { return "--:--" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
