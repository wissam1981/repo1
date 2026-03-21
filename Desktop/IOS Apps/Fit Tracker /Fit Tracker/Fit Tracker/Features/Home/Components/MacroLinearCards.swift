import SwiftUI

// MARK: - Macro Linear Cards (Stitch AI Redesign)
// Replaces the circular progress bubbles with thick, minimal horizontal progress bars.
// Modeled after the "Minutes" and "Avg Heart Rate" cards from the HTML design.

struct MacroLinearCards: View {
    let proteinConsumed: Int
    let proteinTarget: Int
    
    let carbsConsumed: Int
    let carbsTarget: Int
    
    let fatConsumed: Int
    let fatTarget: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Column: Protein (Primary Accent)
            LinearMacroCard(
                title: "Protein",
                consumed: proteinConsumed,
                target: proteinTarget,
                color: ThemeColors.primary,
                icon: "bolt.fill"
            )
            
            // Right Column: Carbs & Fat (Stacked)
            VStack(spacing: 16) {
                LinearMacroCard(
                    title: "Carbs",
                    consumed: carbsConsumed,
                    target: carbsTarget,
                    color: ThemeColors.info,
                    icon: "leaf.fill"
                )
                
                LinearMacroCard(
                    title: "Fat",
                    consumed: fatConsumed,
                    target: fatTarget,
                    color: ThemeColors.secondary,
                    icon: "drop.fill"
                )
            }
        }
    }
}

// MARK: - Individual Linear Card
struct LinearMacroCard: View {
    let title: String
    let consumed: Int
    let target: Int
    let color: Color
    let icon: String
    
    // Calculate progress (cap at 1.0)
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(color)
                    .padding(6)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(ThemeColors.textPrimary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(consumed)")
                    .font(.system(.title3, design: .rounded).weight(.black))
                    .foregroundColor(ThemeColors.textPrimary)
                Text("/ \(target)g")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Custom Thick Linear Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(ThemeColors.backgroundDark)
                        .frame(height: 12)
                    
                    // Progress
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                        // Add glow if progress > 0
                        .shadow(color: color.opacity(progress > 0 ? 0.3 : 0), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeColors.surfaceColor)
        .cornerRadius(16)
    }
}
