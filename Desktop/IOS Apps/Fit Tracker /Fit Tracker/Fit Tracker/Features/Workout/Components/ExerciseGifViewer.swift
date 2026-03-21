import SwiftUI
import WebKit
import AVKit

// MARK: - Exercise GIF Thumbnail
// Small tappable thumbnail that shows a GIF or fallback icon.
// Tap opens the full-screen GIF popup with detailed instructions.

struct ExerciseGifThumbnail: View {
    let gifUrl: String?
    let muscleGroup: Exercise.MuscleGroup
    let exerciseName: String
    var instructions: String? = nil
    var videoURL: String? = nil
    var size: CGFloat = 52

    @State private var showPopup = false
    @State private var visualizerImage: UIImage?
    @State private var isVisualizerLoading = false

    var body: some View {
        Button {
            showPopup = true
        } label: {
            thumbnailContent
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showPopup) {
            ExerciseGifPopup(
                gifUrl: gifUrl ?? "",
                exerciseName: exerciseName,
                instructions: instructions,
                videoURL: videoURL
            )
        }
        .task {
            // Load visualizer image as fallback if not already loaded
            await loadVisualizerImage()
        }
    }

    private func loadVisualizerImage() async {
        guard visualizerImage == nil else { return }
        isVisualizerLoading = true
        defer { isVisualizerLoading = false }
        
        let hexColor = muscleHexColor
        visualizerImage = try? await MuscleVisualizerService.shared.fetchMuscleImage(for: muscleGroup, hexColor: hexColor)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let gifUrl, let url = URL(string: gifUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    fallbackIcon
                default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ThemeColors.surfaceColor)
                        .frame(width: size, height: size)
                        .overlay(ProgressView().scaleEffect(0.5))
                }
            }
        } else {
            fallbackIcon
        }
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        if let visualizerImage {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: size, height: size)

                Image(uiImage: visualizerImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.85, height: size * 0.85)
            }
            .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(muscleColor.opacity(0.15))
                    .frame(width: size, height: size)

                if isVisualizerLoading {
                    ProgressView().scaleEffect(0.5)
                } else {
                    Image(systemName: muscleIcon)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(muscleColor)
                }
            }
        }
    }

    private var muscleIcon: String {
        switch muscleGroup {
        case .chest:    return "figure.strengthtraining.traditional"
        case .back:     return "figure.rowing"
        case .legs:     return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .arms:     return "dumbbell.fill"
        case .core:     return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    private var muscleColor: Color {
        switch muscleGroup {
        case .chest:    return .red
        case .back:     return .blue
        case .legs:     return .green
        case .shoulders: return .orange
        case .arms:     return .purple
        case .core:     return .yellow
        case .fullBody: return .cyan
        }
    }

    private var muscleHexColor: String {
        switch muscleGroup {
        case .chest:    return "FF3B30" // Red
        case .back:     return "007AFF" // Blue
        case .legs:     return "34C759" // Green
        case .shoulders: return "FF9500" // Orange
        case .arms:     return "AF52DE" // Purple
        case .core:     return "FFCC00" // Yellow
        case .fullBody: return "32ADE6" // Cyan
        }
    }
}

// MARK: - Exercise GIF Popup
// Full-screen overlay showing the exercise GIF animation with name, instructions, and close button.

struct ExerciseGifPopup: View {
    let gifUrl: String
    let exerciseName: String
    let instructions: String?
    let videoURL: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Industrial background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Demonstration")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ThemeColors.primary)
                        Text(exerciseName)
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(ThemeColors.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                .padding(24)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Animation/Video area
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(ThemeColors.surfaceColor)
                                .frame(height: 380)
                            
                            if let videoStr = videoURL, let vUrl = URL(string: videoStr) {
                                VideoPlayer(player: AVPlayer(url: vUrl))
                                    .frame(height: 380)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                            } else if !gifUrl.isEmpty {
                                WebViewGIF(urlString: gifUrl)
                                    .frame(height: 380)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 60))
                                        .foregroundStyle(ThemeColors.textSecondary)
                                    Text("Animation Loading...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Instructions Section for Beginners
                        if let text = instructions, !text.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(ThemeColors.primary)
                                    Text("BEGINNER GUIDES")
                                        .font(.system(size: 13, weight: .black))
                                        .tracking(1.5)
                                        .foregroundStyle(ThemeColors.textSecondary)
                                }
                                
                                Text(text)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineSpacing(6)
                                    .foregroundStyle(ThemeColors.textPrimary)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(ThemeColors.surfaceColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Footer action
                Button { dismiss() } label: {
                    Text("GOT IT")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(ThemeColors.backgroundDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Capsule().fill(ThemeColors.primary))
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - WebView GIF Component
// Uses a minimalist WKWebView to properly play remote animated GIFs.

struct WebViewGIF: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.contentMode = .scaleAspectFit
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if URL(string: urlString) != nil {
            // Use a simple HTML wrapper to center and scale the image correctly
            let htmlContent = """
            <html>
            <head>
                <style>
                    body {
                        margin: 0;
                        padding: 0;
                        background-color: transparent;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        overflow: hidden;
                    }
                    img {
                        width: 100vw;
                        height: 100vh;
                        object-fit: contain;
                    }
                </style>
            </head>
            <body>
                <img src="\(urlString)">
            </body>
            </html>
            """
            uiView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
}
