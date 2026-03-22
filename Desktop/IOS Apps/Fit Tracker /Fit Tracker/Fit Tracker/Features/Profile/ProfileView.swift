import SwiftUI

// MARK: - Profile View
// User profile, settings, subscription status, and account management.

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            ThemeColors.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        
                        if let user = appState.currentUser {
                            metricsSection(user)
                        }

                        subscriptionSection
                        cloudSyncSection
                        settingsSection
                        accountSection
                    }
                    .padding(.bottom, 100) // Space for floating tab bar
                }
            
            .navigationTitle("Profile")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = appState.currentUser {
                    EditProfileView(user: user) { updatedUser in
                        appState.currentUser = updatedUser
                        Task {
                            await container.coreDataService.saveUserProfile(updatedUser)
                            try? await container.firestoreService.saveUserProfile(updatedUser)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Background Gradient
                LinearGradient(
                    colors: [ThemeColors.primary.opacity(0.4), ThemeColors.backgroundDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)

                if let user = appState.currentUser {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(ThemeColors.primary)
                            .background(Circle().fill(ThemeColors.backgroundDark))
                            .overlay(Circle().stroke(ThemeColors.backgroundDark, lineWidth: 4))
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10)

                        Text(user.displayName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)

                        Text(user.email)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: 40)
                }
            }
            
            Button {
                showEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .foregroundStyle(ThemeColors.textPrimary)
                    .background(Capsule().fill(ThemeColors.surfaceColor))
            }
            .padding(.top, 56)
        }
        .padding(.horizontal)
    }

    // MARK: - Metrics Section

    private func metricsSection(_ user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    metricCard(icon: "scalemass", label: "Weight", value: String(format: "%.1f kg", user.weightKg))
                    metricCard(icon: "heart.text.square", label: "BMI", value: String(format: "%.1f", user.bmi))
                    metricCard(icon: "ruler", label: "Height", value: "\(Int(user.heightCm)) cm")
                    metricCard(icon: "target", label: "Goal", value: user.goal.displayName)
                    metricCard(icon: "flame.fill", label: "Daily Calories", value: "\(user.targetCalories) kcal")
                    metricCard(icon: "figure.run", label: "Activity", value: user.activityLevel.displayName)
                }
                .padding(.horizontal)
            }
        }
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(ThemeColors.primary)
            
            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .frame(width: 100, height: 100, alignment: .topLeading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeColors.surfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
        )
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Button { if !subscriptionManager.isSubscribed { showPaywall = true } } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(subscriptionManager.isSubscribed
                              ? Color.yellow.opacity(0.2)
                              : ThemeColors.surfaceColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: subscriptionManager.isSubscribed ? "crown.fill" : "crown")
                        .font(.system(size: 20))
                        .foregroundStyle(subscriptionManager.isSubscribed ? .yellow : ThemeColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    if subscriptionManager.isSubscribed {
                        Text("Premium Active")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text("All features unlocked")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    } else if subscriptionManager.isTrialActive {
                        let days = subscriptionManager.trialDaysRemaining
                        Text(String(localized: "Free Trial · \(days) day\(days == 1 ? "" : "s") remaining"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text("Subscribe to unlock AI Coach, Analytics & AI Plans")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    } else {
                        Text("Trial Ended")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text("Subscribe to unlock AI Coach, Analytics & AI Plans")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }

                Spacer()

                if !subscriptionManager.isSubscribed {
                    Text("Upgrade")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        subscriptionManager.isSubscribed
                            ? LinearGradient(colors: [ThemeColors.info.opacity(0.15), ThemeColors.info.opacity(0.08)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [ThemeColors.primary.opacity(0.12), Color.orange.opacity(0.08)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                subscriptionManager.isSubscribed
                                    ? ThemeColors.info.opacity(0.2)
                                    : ThemeColors.primary.opacity(0.15),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    @State private var isSyncing = false
    @State private var lastSyncMessage: String?
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    settingsRow(icon: "paintpalette.fill", title: "Appearance")
                }
                Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        LanguageManager.shared.currentLanguage =
                            LanguageManager.shared.isArabic ? .english : .arabic
                    }
                } label: {
                    settingsRow(
                        icon: "globe",
                        title: "Language",
                        trailing: "\(LanguageManager.shared.currentLanguage.flag) \(LanguageManager.shared.currentLanguage.displayName)"
                    )
                }
                Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    settingsRow(icon: "bell.fill", title: "Notifications")
                }
                Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)

                NavigationLink {
                    UnitsSettingsView()
                } label: {
                    settingsRow(icon: "ruler", title: "Units")
                }
                Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)

                NavigationLink {
                    InstructionsView()
                } label: {
                    settingsRow(icon: "questionmark.circle.fill", title: "Instructions", showArrow: false)
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
            .padding(.horizontal)
        }
    }

    private func settingsRow(icon: String, title: String, trailing: String? = nil, showArrow: Bool = true) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(ThemeColors.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ThemeColors.textPrimary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
    
    // MARK: - Cloud Sync Section
    
    private var cloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cloud Sync")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                if subscriptionManager.isSubscribed {
                    Button {
                        Task { await syncData() }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.title2)
                                .foregroundStyle(ThemeColors.info)
                            Text("Sync Now")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(ThemeColors.textPrimary)
                            
                            Spacer()
                            
                            if isSyncing {
                                ProgressView()
                                    .controlSize(.small)
                            } else if let message = lastSyncMessage {
                                Text(message)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isSyncing)
                } else {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(ThemeColors.textPrimary)
                            .frame(width: 24)
                        Text("Cloud Sync")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ThemeColors.textPrimary)
                        
                        Spacer()
                        
                        Button("Unlock") {
                            showPaywall = true
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.backgroundDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                    }
                    
                    Text("Sync data across all your devices with Premium")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
            .padding(.horizontal)
        }
    }
    
    private func syncData() async {
        guard let user = appState.currentUser else { return }
        isSyncing = true
        lastSyncMessage = "Syncing Profile..."
        
        do {
            // 1. Sync user profile
            try await container.firestoreService.saveUserProfile(user)
            
            // Fetch all core data components asynchronously on MainActor, then dispatch saving
            let nutritionLogs = await MainActor.run { 
                container.coreDataService.fetchNutritionLogs(from: .distantPast, to: .distantFuture) 
            }
            let progressEntries = await MainActor.run { 
                container.coreDataService.fetchProgressEntries(limit: 1000) 
            }
            let workoutHistory = await MainActor.run { 
                container.coreDataService.fetchWorkoutHistory(limit: 1000) 
            }

            // 2. Sync Nutrition Logs
            lastSyncMessage = "Syncing Nutrition..."
            for log in nutritionLogs {
                try await container.firestoreService.saveNutritionLog(log, userId: user.uid)
            }
            
            // 3. Sync Progress Logs (Weigh-ins, Body Metrics)
            lastSyncMessage = "Syncing Metrics..."
            for entry in progressEntries {
                try await container.firestoreService.saveProgressEntry(entry, userId: user.uid)
            }

            // 4. Sync Workout Sessions
            lastSyncMessage = "Syncing Workouts..."
            for session in workoutHistory {
                try await container.firestoreService.saveWorkoutSession(session, userId: user.uid)
            }
            
            lastSyncMessage = "Synced ✓"
        } catch {
            lastSyncMessage = "Sync Failed"
            print("[CloudSync] Error syncing data: \(error)")
        }
        
        isSyncing = false
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            Button {
                showSignOutConfirm = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(ThemeColors.textPrimary)
                        .frame(width: 24)
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Spacer()
                }
                .padding(16)
            }
            .contentShape(Rectangle())
            .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            }

            Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 24)
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(16)
            }
            .contentShape(Rectangle())
            .confirmationDialog("Delete Account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Everything & Remove Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("⚠️ This will permanently delete ALL your data including:\n\n• Nutrition logs & food entries\n• Weight & progress history\n• Workout sessions\n• Fasting records\n• Saved preferences\n\nThis cannot be undone. If you sign up again, you will start fresh with no data.")
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func signOut() {
        do {
            try container.authService.signOut()
            appState.signOut()
        } catch {
            appState.showError("Failed to sign out.")
        }
    }

    private func deleteAccount() async {
        do {
            let uid = appState.currentUser?.uid ?? ""
            try await container.authService.deleteAccount()
            try? await container.firestoreService.deleteUserData(userId: uid)
            await wipeAllLocalData()
            appState.signOut()
        } catch {
            appState.showError("Failed to delete account: \(error.localizedDescription)")
        }
    }

    /// Wipes every local data store so a fresh sign-up starts completely clean.
    private func wipeAllLocalData() async {
        // 1. CoreData — nutrition logs, progress, workouts, fasting, food cache
        await container.coreDataService.clearAllData()

        // 2. Recipe SQLite database — cached recipes, favorites, nutrition
        RecipeDatabase.shared.clearAllData()

        // 3. UserDefaults — nuke ALL app keys (preserves system keys)
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }

        // 4. Mark a "fresh start" date so HealthKit sync ignores older entries.
        //    (Must be set AFTER removePersistentDomain clears everything.)
        UserDefaults.standard.set(Date(), forKey: "data_fresh_start_date")

        // 5. Clear URLCache (cached network images, API responses)
        URLCache.shared.removeAllCachedResponses()
    }
}

// MARK: - Placeholder Settings Views

struct NotificationSettingsView: View {
    @AppStorage("reminder_daily") private var dailyReminders = true
    @AppStorage("reminder_weight") private var weightReminder = true
    @AppStorage("reminder_workout") private var workoutReminder = false
    @AppStorage("reminder_water") private var waterReminder = false
    @AppStorage("reminder_fasting") private var fastingReminder = false
    @AppStorage("reminder_proactive_nudges") private var proactiveNudges = true

    @AppStorage("reminder_breakfast_hour") private var breakfastHour = 8
    @AppStorage("reminder_breakfast_min") private var breakfastMin = 0
    @AppStorage("reminder_lunch_hour") private var lunchHour = 13
    @AppStorage("reminder_lunch_min") private var lunchMin = 0
    @AppStorage("reminder_dinner_hour") private var dinnerHour = 19
    @AppStorage("reminder_dinner_min") private var dinnerMin = 0
    @AppStorage("reminder_weight_day") private var weightDay = 2 // Monday
    @AppStorage("reminder_weight_hour") private var weightHour = 8
    @AppStorage("reminder_weight_min") private var weightMin = 0

    @State private var showTimePicker: String?

    var body: some View {
        ZStack {
            ThemeColors.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Meal Reminders
                    reminderSection(
                        title: "Meal Reminders",
                        icon: "fork.knife",
                        color: ThemeColors.primary
                    ) {
                        reminderToggle(
                            title: "Daily Meal Reminders",
                            subtitle: "Get reminded to log breakfast, lunch & dinner",
                            isOn: $dailyReminders,
                            color: ThemeColors.primary
                        )

                        if dailyReminders {
                            timeRow(label: "Breakfast", hour: breakfastHour, minute: breakfastMin, key: "breakfast")
                            timeRow(label: "Lunch", hour: lunchHour, minute: lunchMin, key: "lunch")
                            timeRow(label: "Dinner", hour: dinnerHour, minute: dinnerMin, key: "dinner")
                        }
                    }

                    // AI Smart Nudges
                    reminderSection(
                        title: "AI Smart Nudges",
                        icon: "sparkles",
                        color: ThemeColors.primary
                    ) {
                        reminderToggle(
                            title: "Proactive Nudges",
                            subtitle: "Get smart AI reminders to log missed meals or water.",
                            isOn: $proactiveNudges,
                            color: ThemeColors.primary
                        )
                    }

                    // Weight Reminder
                    reminderSection(
                        title: "Weight Tracking",
                        icon: "scalemass.fill",
                        color: ThemeColors.info
                    ) {
                        reminderToggle(
                            title: "Weekly Weight Reminder",
                            subtitle: "Get reminded to log your weight",
                            isOn: $weightReminder,
                            color: ThemeColors.info
                        )

                        if weightReminder {
                            dayPicker
                            timeRow(label: "Time", hour: weightHour, minute: weightMin, key: "weight")
                        }
                    }

                    // Other Reminders
                    reminderSection(
                        title: "Other Reminders",
                        icon: "bell.fill",
                        color: ThemeColors.success
                    ) {
                        reminderToggle(
                            title: "Water Intake",
                            subtitle: "Hourly hydration reminders during the day",
                            isOn: $waterReminder,
                            color: .cyan
                        )

                        reminderToggle(
                            title: "Workout Reminder",
                            subtitle: "Daily reminder to complete your workout",
                            isOn: $workoutReminder,
                            color: .orange
                        )

                        reminderToggle(
                            title: "Fasting Window",
                            subtitle: "Get notified when your fasting window ends",
                            isOn: $fastingReminder,
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: dailyReminders) { _, newValue in
            Task { await scheduleAll() }
        }
        .onChange(of: weightReminder) { _, newValue in
            Task { await scheduleAll() }
        }
        .onChange(of: waterReminder) { _, _ in Task { await scheduleAll() } }
        .onChange(of: workoutReminder) { _, _ in Task { await scheduleAll() } }
        .onChange(of: proactiveNudges) { _, newValue in
            if !newValue {
                Task { await ProactiveNudgeService.shared.cancelAllNudges() }
            }
        }
    }

    // MARK: - Section Container

    private func reminderSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .padding(.leading, 4)

            VStack(spacing: 1) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ThemeColors.surfaceColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Toggle Row

    private func reminderToggle(title: String, subtitle: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Time Row

    private func timeRow(label: String, hour: Int, minute: Int, key: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
            Button {
                showTimePicker = key
            } label: {
                Text(formatTime(hour: hour, minute: minute))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(ThemeColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(ThemeColors.primary.opacity(0.12))
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .sheet(isPresented: Binding(
            get: { showTimePicker == key },
            set: { if !$0 { showTimePicker = nil } }
        )) {
            TimePickerSheet(
                label: label,
                hour: bindingForHour(key),
                minute: bindingForMinute(key)
            ) {
                showTimePicker = nil
                Task { await scheduleAll() }
            }
            .presentationDetents([.height(300)])
        }
    }

    // MARK: - Day Picker

    private var dayPicker: some View {
        HStack {
            Text("Day")
                .font(.system(size: 13))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
            Picker("", selection: $weightDay) {
                Text("Mon").tag(2)
                Text("Tue").tag(3)
                Text("Wed").tag(4)
                Text("Thu").tag(5)
                Text("Fri").tag(6)
                Text("Sat").tag(7)
                Text("Sun").tag(1)
            }
            .pickerStyle(.menu)
            .tint(ThemeColors.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func formatTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }

    private func bindingForHour(_ key: String) -> Binding<Int> {
        switch key {
        case "breakfast": return $breakfastHour
        case "lunch": return $lunchHour
        case "dinner": return $dinnerHour
        case "weight": return $weightHour
        default: return .constant(8)
        }
    }

    private func bindingForMinute(_ key: String) -> Binding<Int> {
        switch key {
        case "breakfast": return $breakfastMin
        case "lunch": return $lunchMin
        case "dinner": return $dinnerMin
        case "weight": return $weightMin
        default: return .constant(0)
        }
    }

    private func scheduleAll() async {
        let manager = NotificationManager.shared
        _ = try? await manager.requestAuthorization()

        if dailyReminders {
            await manager.scheduleDailyReminders()
        }
        if weightReminder {
            await manager.scheduleWeightReminders()
        }
    }
}

// MARK: - Time Picker Sheet

private struct TimePickerSheet: View {
    let label: String
    @Binding var hour: Int
    @Binding var minute: Int
    let onDone: () -> Void

    @State private var pickerDate: Date = .now

    var body: some View {
        ZStack {
            ThemeColors.backgroundDark.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text(String(localized: "Set \(label) Time"))
                        .font(.headline)
                        .foregroundStyle(ThemeColors.textPrimary)
                    Spacer()
                    Button("Done") {
                        let cal = Calendar.current
                        hour = cal.component(.hour, from: pickerDate)
                        minute = cal.component(.minute, from: pickerDate)
                        onDone()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.primary)
                }

                DatePicker("", selection: $pickerDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            components.hour = hour
            components.minute = minute
            pickerDate = Calendar.current.date(from: components) ?? .now
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("appTheme") private var appTheme = AppTheme.oceanBlue.rawValue

    var body: some View {
        List {
            Picker("Theme", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.rawValue).tag(theme.rawValue)
                }
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("Appearance")
    }
}

struct UnitsSettingsView: View {
    @State private var useMetric = true

    var body: some View {
        List {
            Picker("Weight", selection: $useMetric) {
                Text("kg").tag(true)
                Text("lbs").tag(false)
            }
            Picker("Height", selection: $useMetric) {
                Text("cm").tag(true)
                Text("ft/in").tag(false)
            }
        }
        .navigationTitle("Units")
    }
}

