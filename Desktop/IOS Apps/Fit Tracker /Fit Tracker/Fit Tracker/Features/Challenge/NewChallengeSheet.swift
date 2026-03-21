import SwiftUI

// MARK: - New Challenge Sheet

struct NewChallengeSheet: View {
    @Bindable var viewModel: DailyChallengeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var customTitle: String = ""

    private let predefinedChallenges = [
        "Drink 2L of water",
        "Walk 10,000 steps",
        "Read 10 pages",
        "Meditate for 10 min",
        "Sleep 8 hours",
        "Eat 5 servings of veggies"
    ]

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Custom Challenge")) {
                    HStack {
                        TextField("Enter your own goal...", text: $customTitle)
                            .submitLabel(.done)
                            .onSubmit {
                                addCustom()
                            }
                        
                        Button {
                            addCustom()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(customTitle.isEmpty ? .secondary : ThemeColors.primary)
                                .font(.title3)
                        }
                        .disabled(customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Section(header: Text("Suggestions")) {
                    ForEach(predefinedChallenges, id: \.self) { challenge in
                        Button {
                            viewModel.addChallenge(title: challenge)
                            dismiss()
                        } label: {
                            HStack {
                                Text(challenge)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus")
                                    .font(.caption.bold())
                                    .foregroundStyle(ThemeColors.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func addCustom() {
        let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        viewModel.addChallenge(title: title)
        dismiss()
    }
}
