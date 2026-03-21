import SwiftUI

// MARK: - Workout Image Card
// A highly visual card component for the Workout Library, matching the Stitch AI design.
// Uses AsyncImage for backgrounds and a dark gradient for text legibility.

struct WorkoutImageCard: View {
    let plan: WorkoutPlan
    let isRecommended: Bool
    let isLocked: Bool
    let onTap: () -> Void
    
    @State private var isFavorite = false
    
    // Hardcoded placeholder URLs provided in the Stitch Mockup
    // We deterministically pick one based on the plan ID so they stay consistent
    private var placeholderImageUrl: String {
        let urls = [
            "https://lh3.googleusercontent.com/aida-public/AB6AXuCQLujVvvWFkKp68QnqdgeeGOrodnULG29lMKcSqA5F0JfMBz2Pqc3ztJE1i0qcDjcw_uPrIhzK0rLgyc6bLVAmDHLfh9SlLS1iGO0xFxnpEwfHUFmaiSkTXCrynucV67CBphAbhm66Ki30pR1RXg8Z99_dj_FqA-U7Hr-FqiieGZqixuLKcFbdBkmOCDOHx3hk-cl64oU4Px-BbHozmBalLrIyptxKfJeIIacuM6sdEm3eYOa5LT3T9OGYaZY_-7U2qMIF6dBb4hk",
            "https://lh3.googleusercontent.com/aida-public/AB6AXuC0Kjl6I_WqIDcH7R8mR9ExAt3b0dN8PlllbbuJIdE4QvfvV_FJFGxT0jlZUUBE7Qa43efZmaPHxPe2kDcIWFhwOHdT3xNj2tmGOKr38atAnmiTc0C7FrtiMKLX8gu2UXXv6b49rGDIq8ePMULPpWMoR1cz6cGWoDfpThF1UdnYSjzj1FX9OZ9l5vFRICsGt2xlU-RjHPkA_NG-C9vx43acttx3yDg4uxaRmVT0cgKoQ7w2FCd9mpo45g_4fejvnSnqpXeEq5E8gyc",
            "https://lh3.googleusercontent.com/aida-public/AB6AXuAosG7VWorSatz1Ys2My97mmGV0cLaTroqPO05cg6zqxENO_gkPBpBaQXjrpPgxP_ZxaIpegnEWMtHGGuDI_JrCzdO4sARDQ0eNFV2tbdWGLDtUDSGn8FP7LBlrFcOiFSZoY86GoxTC64E4TdGK1o-VnEWshB9xTJM2lA-70yh96sB3LkhCARQwzcD39FI_qOK4nuu5doie7M6uInvdVxCNlFECUq6lArB7IFu_4KGNi3UQwmNGUHf5mXZgyGWrwj5AITZioY7KC7s",
            "https://lh3.googleusercontent.com/aida-public/AB6AXuCdVP-tENPcY5tJc8QB-xPglHOlvFFx1S8fGOgwfWIcf_A7uFxntA04SZZ9d0tqLgljZTaJsmcAFOjYL5YC1CS14bxXcbjj1Oi-AqJub7-L0m-tr-k0DFTk_0as3n_PfP9hCoOEpTw1W73tJjzsdI6-vyINn1qfDik4hc6UidxnmaU8c81Btjzw0pBU1r-JExle1PPK7i7lLtdL3S4QzG2Z2YagPJxSt1F5gy9bijxN_bZAe7nhXWp0sqzRIa51RIZnhE66AzYvnvA"
        ]
        let idx = abs(plan.id.hashValue) % urls.count
        return urls[idx]
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Background Image & Overlays
                ZStack(alignment: .bottomLeading) {
                    // Async Image Map
                    AsyncImage(url: URL(string: placeholderImageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(ThemeColors.backgroundDark.opacity(0.5))
                            .overlay(ProgressView().tint(ThemeColors.primary))
                    }
                    .frame(height: 180)
                    .clipped()

                    // Gradient Overlay for text protection
                    LinearGradient(
                        colors: [.black.opacity(0.8), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    // Fav Button (Top Right)
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                isFavorite.toggle()
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(isFavorite ? ThemeColors.primary : .white)
                                    .padding(8)
                                    .background(.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(12)
                        }
                        Spacer()
                    }
                    
                    // Difficulty Pill (Bottom Left)
                    HStack {
                        Text(plan.difficulty.displayName)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .textCase(.uppercase)
                            .foregroundColor(difficultyTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyBgColor)
                            .cornerRadius(4)
                        
                        if isRecommended {
                            Text("Best Fit")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .textCase(.uppercase)
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 180)

                // Bottom Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                            .lineLimit(1)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .frame(height: 38, alignment: .top)
                    
                    // Stats indicators
                    HStack(spacing: 16) {
                        dataPill(icon: "calendar", text: "\(plan.daysPerWeek) days/wk")
                        dataPill(icon: "clock", text: "\(plan.estimatedDurationMin) min")
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(ThemeColors.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isRecommended ? ThemeColors.primary.opacity(0.5) : ThemeColors.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // Helpers
    private var difficultyBgColor: Color {
        switch plan.difficulty {
        case .beginner: return ThemeColors.success.opacity(0.9)
        case .intermediate: return ThemeColors.info.opacity(0.9)
        case .advanced: return ThemeColors.primary.opacity(0.9)
        }
    }
    
    private var difficultyTextColor: Color {
        switch plan.difficulty {
        case .beginner: return .black
        case .intermediate: return .black
        case .advanced: return .black
        }
    }
    
    private func dataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(ThemeColors.primary)
            Text(text)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(ThemeColors.textSecondary)
    }
}
