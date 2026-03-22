import SwiftUI

struct AuraFloatingNavBar: View {
    @Binding var selectedTab: TabRoute
    let onQuickAction: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(for: .home)
            tabButton(for: .nutrition)
            
            // Center "Log" Action
            Button(action: onQuickAction) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.primaryGradient)
                        .frame(width: 54, height: 54)
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .offset(y: -22) // High floating effect
            .frame(maxWidth: .infinity)
            
            tabButton(for: .workout)
            tabButton(for: .profile)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .glassStyle(
            cornerRadius: 32,
            color: ThemeManager.shared.currentTheme.isLightTheme
                ? Color.white.opacity(0.95)
                : Color.white.opacity(0.12)
        )
        .shadow(color: ThemeColors.surfaceShadow, radius: 8, x: 0, y: -2)
        .padding(.horizontal, 20)
    }
    
    private func tabButton(for route: TabRoute) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = route
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: route.systemImage)
                    .font(.system(size: 20, weight: selectedTab == route ? .bold : .medium))
                    .foregroundStyle(selectedTab == route ? ThemeColors.primary : ThemeColors.textSecondary)

                Text(route.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selectedTab == route ? ThemeColors.primary : ThemeColors.textSecondary)

                if selectedTab == route {
                    Circle()
                        .fill(ThemeColors.primary)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
