import Foundation

// MARK: - Tab Route

enum TabRoute: Int, CaseIterable, Hashable {
    case home      = 0
    case nutrition = 1
    case scan      = 2
    case workout   = 3
    case profile   = 4

    var title: String {
        switch self {
        case .home:      return String(localized: "Home")
        case .nutrition: return String(localized: "Nutrition")
        case .scan:      return ""
        case .workout:   return String(localized: "Workout")
        case .profile:   return String(localized: "Profile")
        }
    }

    var systemImage: String {
        switch self {
        case .home:      return "house.fill"
        case .nutrition: return "fork.knife"
        case .scan:      return ""
        case .workout:   return "dumbbell.fill"
        case .profile:   return "person.fill"
        }
    }
}
