import SwiftUI

// MARK: - Fasting Quick Card
// Quick access card for the fasting feature on the home dashboard.

struct FastingQuickCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(ThemeColors.primary)
                
                Text("Fast")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(ThemeColors.textPrimary)
                
                Text("Manage Timer")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ThemeColors.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
