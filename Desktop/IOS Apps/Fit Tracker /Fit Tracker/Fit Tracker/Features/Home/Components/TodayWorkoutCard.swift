import SwiftUI

// MARK: - Today Workout Card
// Quick card showing today's planned workout or empty state.

struct TodayWorkoutCard: View {
    let hasWorkout: Bool
    let workoutName: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left Image/Icon Placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeColors.primary.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: hasWorkout ? "figure.highintensity.intervaltraining" : "plus")
                            .font(.title2)
                            .foregroundColor(ThemeColors.primary)
                    )
                
                // Titles
                VStack(alignment: .leading, spacing: 6) {
                    if hasWorkout, let name = workoutName {
                        Text(name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                            .lineLimit(1)
                        
                        // Fake data for design (would come from viewmodel)
                        HStack(spacing: 12) {
                            labelIcon("clock", text: "45 min")
                            labelIcon("flame.fill", text: "320 kcal")
                        }
                    } else {
                        Text("Add a Workout")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                        
                        Text("Keep your streak going")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Right Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(ThemeColors.surfaceColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // Helper for tiny grey data labels
    private func labelIcon(_ icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .foregroundColor(.gray)
    }
}
