import SwiftUI

// MARK: - Progress Dashboard View
// Weight tracking screen with chart, stats, and add-weight sheet.

struct ProgressDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var viewModel: ProgressViewModel?
    @State private var showAnalytics = false
    @State private var showAnalyticsPaywall = false

    var body: some View {
        Group {
            if let vm = viewModel {
                progressContent(vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            initViewModelIfNeeded()
        }
    }

    // MARK: - Init

    private func initViewModelIfNeeded() {
        guard viewModel == nil, let user = appState.currentUser else { return }
        viewModel = ProgressViewModel(
            user: user,
            coreDataService: container.coreDataService,
            healthKitService: container.healthKitService,
            firestoreService: container.firestoreService
        )
    }

    // MARK: - Content

    private func progressContent(_ vm: ProgressViewModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Weight summary card
                weightSummary(vm)

                // Advanced Analytics card
                advancedAnalyticsCard

                // Time range picker
                Picker("Range", selection: Binding(
                    get: { vm.selectedRange },
                    set: { vm.selectedRange = $0 }
                )) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                // Graph
                WeightGraphView(
                    entries: vm.filteredEntries,
                    targetWeight: nil
                )
                .padding(.horizontal, 16)

                // Stats
                statsGrid(vm)

                // HealthKit sync button
                Button {
                    Task { await vm.syncFromHealthKit() }
                } label: {
                    if vm.isSyncing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.horizontal)
                    } else {
                        Label("Sync from Health", systemImage: "heart.fill")
                            .font(.subheadline)
                            .foregroundStyle(.pink)
                    }
                }
                .disabled(vm.isSyncing)
                .padding(.bottom, 24)
            }
        }
        .navigationDestination(isPresented: $showAnalytics) {
            AdvancedAnalyticsView()
        }
        .sheet(isPresented: $showAnalyticsPaywall) {
            PaywallView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if subscriptionManager.isSubscribed {
                        showAnalytics = true
                    } else {
                        showAnalyticsPaywall = true
                    }
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.cyan)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.showAddWeight = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.cyan)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showAddWeight },
            set: { vm.showAddWeight = $0 }
        )) {
            WeightEntrySheet(viewModel: vm)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Weight Summary

    private func weightSummary(_ vm: ProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT WEIGHT")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", vm.latestWeight ?? vm.startWeight))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text(" kg")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("CHANGE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                    Text(vm.weightChangeText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(changeColor(vm))
                }
            }
            
            if vm.latestNote != nil || vm.nextLogDateText != nil {
                Divider()
                    .background(ThemeColors.surfaceBorder)
                
                VStack(alignment: .leading, spacing: 10) {
                    if let note = vm.latestNote {
                        Label {
                            Text(note)
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                        }
                        .foregroundStyle(ThemeColors.info.opacity(0.8))
                    }
                    
                    if let nextLog = vm.nextLogDateText {
                        Label {
                            Text(nextLog)
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "calendar")
                                .font(.caption2)
                        }
                        .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(ThemeColors.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(colors: [ThemeColors.surfaceBorder, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }

    private func changeColor(_ vm: ProgressViewModel) -> Color {
        guard let change = vm.weightChange else { return .secondary }
        if change == 0 { return .secondary }
        return change < 0 ? .green : .orange
    }

    // MARK: - Stats Grid

    private func statsGrid(_ vm: ProgressViewModel) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(label: "Lowest", value: vm.lowestWeight.map { String(format: "%.1f", $0) } ?? "-", unit: "kg")
            statCard(label: "Average", value: vm.averageWeight.map { String(format: "%.1f", $0) } ?? "-", unit: "kg")
            statCard(label: "Highest", value: vm.highestWeight.map { String(format: "%.1f", $0) } ?? "-", unit: "kg")
        }
        .padding(.horizontal, 16)
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeColors.surfaceColor))
    }

    // MARK: - Advanced Analytics Card

    private var advancedAnalyticsCard: some View {
        Button {
            if subscriptionManager.isSubscribed {
                showAnalytics = true
            } else {
                showAnalyticsPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary.opacity(0.25), .cyan.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ThemeColors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Advanced Analytics")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)

                        Text("PRO")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [ThemeColors.primary, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    Text("Calories, macros & workout trends")
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary.opacity(0.12), .cyan.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [ThemeColors.primary.opacity(0.4), .cyan.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
