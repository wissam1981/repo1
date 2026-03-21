import SwiftUI

// MARK: - Fasting View
// Main fasting timer screen with protocol selection and history.

struct FastingView: View {
    @Environment(DependencyContainer.self) private var container
    @State private var viewModel: FastingViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    fastingContent(vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Fasting")
            .onAppear {
                if viewModel == nil {
                    viewModel = FastingViewModel(coreDataService: container.coreDataService)
                }
            }
        }
    }

    // MARK: - Content

    private func fastingContent(_ vm: FastingViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timer Ring
                timerRing(vm)

                // Controls
                controlsSection(vm)

                // Stats
                statsSection(vm)

                // History
                if !vm.completedSessions.isEmpty {
                    historySection(vm)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Timer Ring

    private func timerRing(_ vm: FastingViewModel) -> some View {
        let _ = vm.timerRefresh  // Force re-evaluation

        return ZStack {
            // Background ring with glow
            Circle()
                .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 20)
                .frame(width: 250, height: 250)
                .shadow(color: ThemeColors.primary.opacity(0.15), radius: 20)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(vm.progressFraction))
                .stroke(
                    AngularGradient(
                        colors: [ThemeColors.primary, ThemeColors.error, ThemeColors.primary],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: vm.progressFraction)
                .shadow(color: ThemeColors.primary.opacity(0.4), radius: 15)

            // Center text
            VStack(spacing: 8) {
                if vm.isActive {
                    Text(vm.elapsedText)
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .contentTransition(.numericText())

                    Text("remaining: \(vm.remainingText)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(vm.targetHoursText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text("Ready to fast")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Controls

    private func controlsSection(_ vm: FastingViewModel) -> some View {
        VStack(spacing: 16) {
            if vm.isActive {
                Button {
                    Task {
                        await vm.stopFast()
                    }
                } label: {
                    Text("End Fast")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(ThemeColors.error)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                // Protocol picker
                Picker("Protocol", selection: Binding(
                    get: { vm.selectedProtocol },
                    set: { vm.selectedProtocol = $0 }
                )) {
                    ForEach(FastingProtocol.allCases, id: \.self) { proto in
                        Text(proto.displayName).tag(proto)
                    }
                }
                .pickerStyle(.segmented)
                
                // Custom hours slider
                if vm.selectedProtocol == .custom {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Custom Duration")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(vm.customHours))h")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(ThemeColors.primary)
                        }
                        Slider(
                            value: Binding(
                                get: { vm.customHours },
                                set: { vm.customHours = $0 }
                            ),
                            in: 1...36,
                            step: 1
                        )
                        .tint(ThemeColors.primary)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(ThemeColors.surfaceColor))
                }

                Button {
                    Task {
                        await vm.startFast()
                    }
                } label: {
                    Text("Start Fast")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(ThemeColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Stats

    private func statsSection(_ vm: FastingViewModel) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statCard(label: "Completed", value: "\(vm.totalFastsCompleted)", icon: "checkmark.circle.fill", color: ThemeColors.success)
                statCard(label: "Avg Duration", value: String(format: "%.1fh", vm.averageDurationHours), icon: "clock.fill", color: ThemeColors.primary)
                statCard(label: "Streak", value: "\(vm.currentStreakDays)d", icon: "flame.fill", color: ThemeColors.error)
            }
            
            // Weekly fasting calendar
            weeklyCalendar(vm)
        }
    }
    
    // MARK: - Weekly Calendar
    
    private func weeklyCalendar(_ vm: FastingViewModel) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekDays = (0..<7).map { offset in
            calendar.date(byAdding: .day, value: -6 + offset, to: today)!
        }
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("This Week")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    let hasFast = vm.completedSessions.contains { session in
                        calendar.isDate(session.startedAt, inSameDayAs: day)
                    }
                    let isToday = calendar.isDateInToday(day)
                    
                    VStack(spacing: 6) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            Circle()
                                .fill(hasFast ? ThemeColors.success : ThemeColors.surfaceColor)
                                .frame(width: 36, height: 36)
                            
                            if hasFast {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Text(day, format: .dateTime.day())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(isToday ? ThemeColors.primary : .clear, lineWidth: 2)
                                .frame(width: 38, height: 38)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(ThemeColors.surfaceColor))
    }

    private func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(ThemeColors.surfaceColor))
    }

    // MARK: - History

    private func historySection(_ vm: FastingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)

            ForEach(vm.completedSessions.prefix(20)) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.startedAt, style: .date)
                            .font(.subheadline)
                        Text("\(Int(session.targetHours))h \(session.type.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(session.formattedElapsed)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(session.isCompleted ? ThemeColors.success : ThemeColors.primary)

                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(session.isCompleted ? ThemeColors.success : ThemeColors.primary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(ThemeColors.surfaceColor))
            }
        }
    }
}
