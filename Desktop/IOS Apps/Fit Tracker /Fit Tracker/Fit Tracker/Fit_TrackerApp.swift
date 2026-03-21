import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - App Entry Point

#if canImport(FirebaseCore)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Allow notifications to display while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        if identifier == "weekly_digest_reminder" {
            Task { @MainActor in
                if let appState = AppDelegate.sharedAppState {
                    appState.pendingAIAction = .weeklyDigest
                    appState.showAICoach = true
                }
            }
        }
        completionHandler()
    }

    /// Shared reference to AppState for notification handling
    @MainActor static var sharedAppState: AppState?
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // FirebaseCore is not available in this build configuration.
        // Proceed without Firebase initialization.
        return true
    }
}
#endif

@main
struct Fit_TrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            AppRootView(appState: appState, router: router, subscriptionManager: subscriptionManager)
        }
    }
}

// MARK: - App Root View Helper
struct AppRootView: View {
    let appState: AppState
    let router: AppRouter
    let subscriptionManager: SubscriptionManager
    
    @AppStorage("appTheme") private var appTheme = AppTheme.oceanBlue.rawValue
    
    var body: some View {
        RootView()
            .environment(appState)
            .environment(router)
            .environment(subscriptionManager)
            .environment(DependencyContainer.shared)
            .id(appTheme) // Redraw everything when theme changes
            .task {
                // Wire up AppState for notification tap handling
                AppDelegate.sharedAppState = appState

                // Setup daily reminders FIRST (or concurrently)
                let granted = try? await NotificationManager.shared.requestAuthorization()
                if granted == true {
                    await NotificationManager.shared.scheduleDailyReminders()
                    await NotificationManager.shared.scheduleWeeklyDigestNotification()
                }

                // Observe Firebase auth state changes in a detached task
                // so it doesn't block the rest of the .task modifier
                Task {
                    await DependencyContainer.shared.authService.observeAuthState(appState: appState)
                }
            }
            .onOpenURL { url in
                #if canImport(GoogleSignIn)
                GIDSignIn.sharedInstance.handle(url)
                #endif
            }
            .onChange(of: appState.authPhase) { _, newPhase in
                Task {
                    let container = DependencyContainer.shared
                    if newPhase == .main, let uid = appState.currentUser?.uid {
                        // Seed food database for returning users (no-op if already seeded)
                        await FoodDatabaseSeeder.seedIfNeeded(coreDataService: container.coreDataService)
                        // Start periodic dirty-record sync
                        container.syncService.startPeriodicSync(userId: uid)
                    } else {
                        container.syncService.stopPeriodicSync()
                    }
                }
            }
    }
}


