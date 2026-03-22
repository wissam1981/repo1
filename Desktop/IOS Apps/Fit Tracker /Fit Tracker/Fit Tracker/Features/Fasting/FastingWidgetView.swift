import SwiftUI

struct FastingWidgetView: View {
    @Bindable var viewModel: FastingViewModel
    @State private var waveOffset = 0.0
    
    var body: some View {
        NavigationLink(destination: FastingView()) {
            HStack(spacing: 16) {
                // Miniature ring
                ZStack {
                    Circle()
                        .stroke(ThemeColors.primary.opacity(0.15), lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    if viewModel.isActive {
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.progressFraction))
                            .stroke(
                                ThemeColors.primary,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: viewModel.progressFraction)
                    }
                    
                    Image(systemName: viewModel.isActive ? "flame.fill" : "moon.stars.fill")
                        .foregroundStyle(viewModel.isActive ? ThemeColors.error : ThemeColors.primary)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Intermittent Fasting")
                        .font(.headline)
                        .foregroundStyle(.primary) // override link color
                    
                    if viewModel.isActive {
                        Text(String(localized: "\(viewModel.elapsedText) elapsed"))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(ThemeColors.primary)
                    } else {
                        Text("Tap to start fasting")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
        }
        .buttonStyle(.plain)
        .onAppear {
            viewModel.loadSessions()
        }
    }
}
