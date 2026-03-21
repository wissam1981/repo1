import SwiftUI

// MARK: - Daily Challenge Widget

struct DailyChallengeWidget: View {
    @Bindable var viewModel: DailyChallengeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            
            // MARK: Header
            HStack {
                Text("Daily Goals")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    viewModel.showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(ThemeColors.primary)
                        .padding(6)
                        .background(ThemeColors.primary.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            // MARK: List
            if viewModel.challenges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.largeTitle)
                        .foregroundStyle(ThemeColors.surfaceColor)
                        .padding(.bottom, 4)
                        
                    Text("No goals set for today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                    Button {
                        viewModel.showAddSheet = true
                    } label: {
                        Text("Add a Goal")
                            .font(.caption.bold())
                            .foregroundStyle(ThemeColors.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor.opacity(0.4)))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.challenges) { challenge in
                        challengeRow(challenge)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(ThemeColors.surfaceColor.opacity(0.7)))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $viewModel.showAddSheet) {
            NewChallengeSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Row View
    
    @ViewBuilder
    private func challengeRow(_ challenge: DailyChallenge) -> some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.toggleCompletion(for: challenge)
                }
            } label: {
                Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(challenge.isCompleted ? ThemeColors.primary : .secondary)
            }
            .buttonStyle(.plain)
            
            Text(challenge.title)
                .font(.subheadline)
                .fontDesign(.rounded)
                .strikethrough(challenge.isCompleted, color: .secondary)
                .foregroundStyle(challenge.isCompleted ? .secondary : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(challenge.isCompleted ? ThemeColors.surfaceColor.opacity(0.4) : ThemeColors.surfaceColor)
        )
        // Context menu to delete
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteChallenge(challenge)
                }
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
    }
}
