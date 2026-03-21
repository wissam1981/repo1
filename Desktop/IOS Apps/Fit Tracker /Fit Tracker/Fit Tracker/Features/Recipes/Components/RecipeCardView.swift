import SwiftUI

// MARK: - Recipe Card View
// Compact card for the recipe grid browser with calorie badge overlay.

struct RecipeCardView: View {
    let meal: MealDetail
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image with overlays
            ZStack(alignment: .topTrailing) {
                AsyncRecipeImage(url: meal.imageURL)
                    .frame(height: 140)
                    .clipped()

                // Favorite button (top-right)
                Button(action: onFavorite) {
                    Image(systemName: meal.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(meal.isFavorite ? .red : .white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(8)
            }
            .overlay(alignment: .bottomLeading) {
                // Calorie badge (bottom-left)
                if let nutrition = meal.nutrition {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(Int(nutrition.perServingCalories)) kcal")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Cook time badge (bottom-right)
                if let mins = meal.readyInMinutes {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                        Text("\(mins) min")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(meal.name)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if let category = meal.category {
                        categoryBadge(category, color: .orange)
                    }
                    if let area = meal.area {
                        categoryBadge(area, color: ThemeColors.primary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(ThemeColors.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private func categoryBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - Async Recipe Image with placeholder

struct AsyncRecipeImage: View {
    let url: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(ThemeColors.surfaceColor)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .task {
            guard let url, image == nil else { return }
            image = try? await ImageCache.shared.image(for: url)
        }
    }
}
