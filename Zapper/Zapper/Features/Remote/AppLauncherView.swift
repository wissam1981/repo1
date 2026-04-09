import SwiftUI

struct AppLauncherView: View {
    var viewModel: RemoteViewModel
    @State private var searchText = ""

    private var favorites: [TVApp] {
        viewModel.installedApps.filter(\.isFavorite)
    }

    private var filteredApps: [TVApp] {
        if searchText.isEmpty {
            return viewModel.installedApps
        }
        return viewModel.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                searchBar
                    .padding(.horizontal, 24)

                if !favorites.isEmpty {
                    favoritesSection
                }

                allAppsSection
                    .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
            TextField("Search apps...", text: $searchText)
                .font(ZapperTheme.Typography.body(14))
                .foregroundStyle(ZapperTheme.Colors.onSurface)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ZapperTheme.Colors.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorites")
                    .font(ZapperTheme.Typography.headline(22, weight: .heavy))
                    .foregroundStyle(ZapperTheme.Colors.onSurface)
                Spacer()
                Text("PINNED")
                    .font(ZapperTheme.Typography.label(10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(ZapperTheme.Colors.primary.opacity(0.6))
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favorites) { app in
                        favoriteCard(app)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func favoriteCard(_ app: TVApp) -> some View {
        Button {
            viewModel.launchApp(app)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: iconForApp(app))
                    .font(.title)
                    .foregroundStyle(ZapperTheme.Colors.secondary)
                    .frame(width: 48, height: 48)
                    .background(ZapperTheme.Colors.surfaceContainerHighest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(app.name)
                    .font(ZapperTheme.Typography.label(12, weight: .semibold))
                    .foregroundStyle(ZapperTheme.Colors.onSurface)
            }
            .frame(width: 140, height: 100)
            .glassPanel(cornerRadius: 16)
        }
        .jewelButton()
    }

    private var allAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Apps")
                .font(ZapperTheme.Typography.headline(22, weight: .heavy))
                .foregroundStyle(ZapperTheme.Colors.onSurface)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredApps) { app in
                    appGridItem(app)
                }
            }
        }
    }

    private func appGridItem(_ app: TVApp) -> some View {
        Button {
            viewModel.launchApp(app)
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(ZapperTheme.Colors.surfaceContainerHighest.opacity(0.6))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: iconForApp(app))
                            .font(.title)
                            .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.1), lineWidth: 1)
                    )

                Text(app.name)
                    .font(ZapperTheme.Typography.label(12))
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                    .lineLimit(1)
            }
        }
        .jewelButton()
        .contextMenu {
            Button(app.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                // Toggle favorite — future enhancement
            }
        }
    }

    private func iconForApp(_ app: TVApp) -> String {
        switch app.id {
        case let id where id.contains("netflix"): return "play.rectangle"
        case let id where id.contains("youtube"): return "play.circle"
        case let id where id.contains("spotify"): return "music.note"
        case let id where id.contains("disney"): return "sparkles.tv"
        case let id where id.contains("amazon"): return "play.tv"
        case let id where id.contains("hbo"): return "diamond"
        default: return "app"
        }
    }
}
