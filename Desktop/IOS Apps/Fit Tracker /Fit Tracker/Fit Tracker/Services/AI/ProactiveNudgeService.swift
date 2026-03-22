import Foundation
import UserNotifications

// MARK: - Proactive Nudge Service
// Manages scheduling and cancelling of local notifications based on user behavior.

actor ProactiveNudgeService {
    
    static let shared = ProactiveNudgeService()
    
    private let center = UNUserNotificationCenter.current()
    
    // Identifiers
    private let missingLunchId = "missing_lunch_nudge"
    private let lowWaterId = "low_water_nudge"
    private let missingDinnerId = "missing_dinner_nudge"

    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func checkAuthorization() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling Strategy: Schedule & Cancel
    // The most reliable way to handle these on iOS without relying on unpredictable Background Fetch
    // is to schedule the notifications for specific times every day when the app goes into the background
    // OR when a meal is logged. 
    // If the condition is MET (e.g., lunch is logged), we CANCEL the scheduled notification.
    
    /// Schedules daily nudges. Call this when the app is launched or enters the background.
    func scheduleDailyNudges(lunchLogged: Bool, dinnerLogged: Bool, waterMl: Double, targetWaterMl: Double) async {
        let _ud = UserDefaults.standard
        let isEnabled = _ud.object(forKey: "reminder_proactive_nudges") == nil ? true : _ud.bool(forKey: "reminder_proactive_nudges")
        
        guard isEnabled else {
            cancelAllNudges()
            return
        }
        
        let authStatus = await checkAuthorization()
        guard authStatus == .authorized || authStatus == .provisional else { return }
        
        // 1. Missing Lunch (e.g., 2:30 PM)
        if !lunchLogged {
            await scheduleNotification(
                id: missingLunchId,
                title: "Fuel Up!",
                body: "It's past 2:00 PM. Have you had lunch yet? Log it to stay on track.",
                hour: 14,
                minute: 30
            )
        } else {
            cancelNudge(id: missingLunchId)
        }
        
        // 2. Low Water (e.g., 4:00 PM) - If under 50% of target
        let halfTarget = max(targetWaterMl * 0.5, 1000) // Fallback to 1L if target is 0
        if waterMl < halfTarget {
            await scheduleNotification(
                id: lowWaterId,
                title: "Hydration Check",
                body: "You're running low on water today! Grab a glass.",
                hour: 16,
                minute: 0
            )
        } else {
            cancelNudge(id: lowWaterId)
        }
        
        // 3. Missing Dinner (e.g., 8:00 PM)
        if !dinnerLogged {
            await scheduleNotification(
                id: missingDinnerId,
                title: "Dinner Time?",
                body: "Don't forget to log your dinner and close out your daily rings.",
                hour: 20,
                minute: 0
            )
        } else {
            cancelNudge(id: missingDinnerId)
        }
    }
    
    // MARK: - Direct Cancellations
    
    func cancelLunchNudge() {
        cancelNudge(id: missingLunchId)
    }
    
    func cancelDinnerNudge() {
        cancelNudge(id: missingDinnerId)
    }
    
    func cancelWaterNudge() {
        cancelNudge(id: lowWaterId)
    }
    
    func cancelAllNudges() {
        center.removePendingNotificationRequests(withIdentifiers: [missingLunchId, lowWaterId, missingDinnerId])
    }
    
    // MARK: - Helpers
    
    private func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int) async {
        // Prevent stacking duplicates by removing existing
        center.removePendingNotificationRequests(withIdentifiers: [id])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Ensure the time hasn't passed today. If it has, schedule for tomorrow.
        let now = Date()
        let calendar = Calendar.current
        if let scheduledDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now), scheduledDate < now {
           // Time has passed, no need to schedule for today (or schedule for tomorrow by removing the date check if daily repeating is desired)
           // If we want it to repeat daily:
           // The trigger below repeats daily at that time anyway.
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("Successfully scheduled nudge: \(id) at \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("Failed to schedule nudge \(id): \(error.localizedDescription)")
        }
    }
    
    private func cancelNudge(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
