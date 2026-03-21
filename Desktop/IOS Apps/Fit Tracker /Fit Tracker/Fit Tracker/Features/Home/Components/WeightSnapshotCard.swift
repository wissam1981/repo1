import SwiftUI

// MARK: - Weight Snapshot Card
// Shows current weight and change from starting weight.

struct WeightSnapshotCard: View {
    let currentWeightKg: Double
    let changeText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Top Icon
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(ThemeColors.primary)
                
                // Value
                Text(String(format: "%.1f", currentWeightKg))
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(ThemeColors.textPrimary)
                
                // Subtitle
                Text(changeText)
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
