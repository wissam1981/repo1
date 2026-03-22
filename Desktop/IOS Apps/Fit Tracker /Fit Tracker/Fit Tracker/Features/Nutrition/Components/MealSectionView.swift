import SwiftUI

// MARK: - Meal Section View
// Expandable section for a single meal type showing logged entries.

struct MealSectionView: View {
    let mealType: MealType
    let entries: [NutritionEntry]
    let totalCalories: Int
    let onAdd: () -> Void
    let onEdit: (NutritionEntry) -> Void
    let onDelete: (NutritionEntry) -> Void
    var recentEntries: [NutritionEntry] = []
    var onQuickRelog: ((NutritionEntry) -> Void)?

    @State private var isExpanded: Bool
    @State private var entryToDelete: NutritionEntry?
    @State private var showDeleteConfirmation = false

    init(
        mealType: MealType,
        entries: [NutritionEntry],
        totalCalories: Int,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (NutritionEntry) -> Void,
        onDelete: @escaping (NutritionEntry) -> Void,
        recentEntries: [NutritionEntry] = [],
        onQuickRelog: ((NutritionEntry) -> Void)? = nil,
        autoExpand: Bool = false
    ) {
        self.mealType = mealType
        self.entries = entries
        self.totalCalories = totalCalories
        self.onAdd = onAdd
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.recentEntries = recentEntries
        self.onQuickRelog = onQuickRelog
        self._isExpanded = State(initialValue: autoExpand)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with colored left accent
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    // Colored accent bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(mealColor)
                        .frame(width: 4, height: 36)
                        .padding(.trailing, 12)

                    Image(systemName: mealType.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(mealColor)
                        .frame(width: 28)

                    Text(mealType.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .padding(.leading, 8)

                    Spacer()

                    Text(String(localized: "\(totalCalories) kcal"))
                        .font(.system(size: 16, weight: .semibold).monospacedDigit())
                        .foregroundStyle(mealColor.opacity(0.8))

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                // Quick re-log row
                if !recentEntries.isEmpty, let onQuickRelog {
                    quickRelogRow(entries: recentEntries, onRelog: onQuickRelog)
                }

                // Entries
                if entries.isEmpty {
                    emptyState
                } else {
                    ForEach(entries) { entry in
                        HStack(spacing: 0) {
                            Button {
                                onEdit(entry)
                            } label: {
                                FoodLogRowView(entry: entry)
                            }
                            .buttonStyle(.plain)

                            Button {
                                entryToDelete = entry
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .padding(.trailing, 16)
                                    .padding(.leading, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Add button
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(mealColor)
                        Text("Add Food")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(mealColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation, presenting: entryToDelete) { entry in
            Button("Delete", role: .destructive) {
                onDelete(entry)
            }
            Button("Cancel", role: .cancel) {}
        } message: { entry in
            Text(String(localized: "Remove \(entry.foodName) from \(mealType.displayName)?"))
        }
    }

    // MARK: - Quick Re-log Row

    private func quickRelogRow(entries: [NutritionEntry], onRelog: @escaping (NutritionEntry) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                ForEach(entries.prefix(3)) { entry in
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onRelog(entry)
                    } label: {
                        HStack(spacing: 4) {
                            Text(entry.foodName)
                                .lineLimit(1)
                            Text("\(Int(entry.calories))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(mealColor.opacity(0.1), in: Capsule())
                        .foregroundStyle(mealColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text(emptyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyMessage: String {
        switch mealType {
        case .breakfast: return "What's for breakfast?"
        case .lunch:     return "Time to log lunch!"
        case .dinner:    return "What's for dinner?"
        case .snack:     return "Any snacks today?"
        }
    }

    private var mealColor: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch:     return .yellow
        case .dinner:    return .indigo
        case .snack:     return .mint
        }
    }
}
