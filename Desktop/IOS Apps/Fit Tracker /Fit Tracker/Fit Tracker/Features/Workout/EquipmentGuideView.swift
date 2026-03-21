import SwiftUI

// MARK: - Equipment Guide View
// A scrollable list showing standard gym equipment and their core uses.

struct EquipmentGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Gym Equipment Guide")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    Text("Reference this guide to better understand the machinery and free weights available in your gym.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(EquipmentInfo.all) { equipment in
                            EquipmentCard(equipment: equipment)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Equipment Card

private struct EquipmentCard: View {
    let equipment: EquipmentInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ThemeColors.info.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: equipment.iconName)
                        .font(.title2)
                        .foregroundStyle(ThemeColors.info)
                }
                
                Text(equipment.name)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(equipment.uses)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }
}
