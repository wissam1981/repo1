import SwiftUI
import Observation

// MARK: - AI Coach View Model

@Observable
@MainActor
final class AICoachViewModel {

    // MARK: - State

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isTyping: Bool = false
    var errorMessage: String?
    var showSuggestions: Bool = true

    /// The currently streaming message ID (for line-by-line animation)
    var streamingMessageId: String?

    /// Weekly digest pinned message (survives daily chat resets)
    var weeklyDigestMessage: ChatMessage?

    // MARK: - Suggested Quick Prompts

    nonisolated static let suggestedPrompts: [(icon: String, text: String)] = [
        ("fork.knife", "What should I eat next?"),
        ("dumbbell.fill", "Today's workout plan"),
        ("scalemass.fill", "Am I on track today?"),
        ("flame.fill", "How to hit my protein goal?"),
        ("bed.double.fill", "Best post-workout meal"),
        ("chart.line.uptrend.xyaxis", "Review my weekly progress")
    ]

    // MARK: - Persistence Keys

    private static let chatHistoryKey = "ai_coach_chat_history"
    private static let chatDateKey = "ai_coach_chat_date"

    // MARK: - Dependencies

    private let coachService = AICoachService()
    private let user: UserProfile
    private let coreDataService: CoreDataService
    private let maxHistoryMessages = 20

    // MARK: - Initialization

    init(user: UserProfile, coreDataService: CoreDataService? = nil) {
        self.user = user
        self.coreDataService = coreDataService ?? DependencyContainer.shared.coreDataService

        // Load saved chat or start fresh
        if let savedMessages = Self.loadTodayChat() {
            messages = savedMessages
        } else {
            // New day or first time — start with greeting
            messages.append(
                ChatMessage(
                    role: .assistant,
                    content: "Hey \(user.displayName). I can see your nutrition and workout data. Ask me anything."
                )
            )
        }

        // Load weekly digest if within the Sunday-Tuesday window
        if WeeklyDigestService.isDigestWindow,
           let digest = WeeklyDigestService.loadSavedDigest() {
            weeklyDigestMessage = ChatMessage(
                role: .assistant,
                content: WeeklyDigestService.formatAsMessage(digest)
            )
        }
    }

    // MARK: - Chat Persistence

    /// Save current chat to UserDefaults
    private func saveChat() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        let today = Calendar.current.startOfDay(for: .now)
        UserDefaults.standard.set(data, forKey: Self.chatHistoryKey)
        UserDefaults.standard.set(today, forKey: Self.chatDateKey)
    }

    /// Load today's chat from UserDefaults. Returns nil if no chat or if it's a new day.
    private static func loadTodayChat() -> [ChatMessage]? {
        guard let savedDate = UserDefaults.standard.object(forKey: chatDateKey) as? Date else {
            return nil
        }

        // Check if saved chat is from today
        let today = Calendar.current.startOfDay(for: .now)
        guard Calendar.current.isDate(savedDate, inSameDayAs: today) else {
            // New day — clear old chat
            UserDefaults.standard.removeObject(forKey: chatHistoryKey)
            UserDefaults.standard.removeObject(forKey: chatDateKey)
            return nil
        }

        guard let data = UserDefaults.standard.data(forKey: chatHistoryKey),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data),
              !messages.isEmpty else {
            return nil
        }

        return messages
    }

    /// Clear saved chat (called on new day or manual reset)
    static func clearSavedChat() {
        UserDefaults.standard.removeObject(forKey: chatHistoryKey)
        UserDefaults.standard.removeObject(forKey: chatDateKey)
    }

    // MARK: - Actions

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        print("[AICoach] Sending message: \(text)")

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isTyping = true
        errorMessage = nil

        // Save after adding user message
        saveChat()

        // Capture today's nutrition snapshot
        let todayLog = coreDataService.fetchNutritionLogDomain(for: .now) ?? NutritionLog(date: .now)
        let snapshot = TodayNutritionSnapshot(from: todayLog)

        let history = Array(messages.suffix(maxHistoryMessages))
        let userCopy = user

        Task { @MainActor in
            do {
                print("[AICoach] Calling API with today's nutrition data...")
                let replyText = try await coachService.sendMessage(
                    history: history,
                    user: userCopy,
                    todaySnapshot: snapshot
                )
                print("[AICoach] Got reply: \(replyText.prefix(80))...")

                // Animate the reply line-by-line
                await streamReply(replyText)

                // Save after receiving reply
                saveChat()
            } catch {
                print("[AICoach] Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.isTyping = false
            }
        }
    }

    // MARK: - Stream Reply (line-by-line animation)

    private func streamReply(_ fullText: String) async {
        // Add an empty assistant message that we'll fill progressively
        messages.append(ChatMessage(
            role: .assistant,
            content: ""
        ))

        let lastIndex = messages.count - 1
        streamingMessageId = messages[lastIndex].id
        isTyping = false

        // Split into chunks — by sentences or line breaks for natural flow
        let chunks = splitIntoChunks(fullText)
        var accumulated = ""

        for chunk in chunks {
            accumulated += chunk

            // Update the message content
            messages[lastIndex] = ChatMessage(
                role: .assistant,
                content: accumulated,
                timestamp: messages[lastIndex].timestamp
            )
            // Preserve the ID
            messages[lastIndex] = withId(messages[lastIndex], id: streamingMessageId!)

            // Small delay between chunks for streaming effect
            try? await Task.sleep(for: .milliseconds(40))
        }

        streamingMessageId = nil
    }

    /// Split text into small chunks for streaming animation
    private func splitIntoChunks(_ text: String) -> [String] {
        var chunks: [String] = []
        var current = ""

        for char in text {
            current.append(char)

            // Emit chunk at natural break points
            if char == "\n" || char == "." || char == "!" || char == "?" || char == ":" {
                chunks.append(current)
                current = ""
            } else if current.count >= 15 {
                // Also break at word boundaries for long runs
                if char == " " {
                    chunks.append(current)
                    current = ""
                }
            }
        }

        if !current.isEmpty {
            chunks.append(current)
        }

        return chunks
    }

    /// Create a ChatMessage with a specific ID
    private func withId(_ msg: ChatMessage, id: String) -> ChatMessage {
        var copy = msg
        copy.id = id
        return copy
    }

    func sendSuggestion(_ text: String) {
        inputText = text
        sendMessage()
    }

    func clearError() {
        errorMessage = nil
    }

    func retryLastMessage() {
        guard let lastUserMsg = messages.last(where: { $0.role == .user }) else { return }
        errorMessage = nil
        inputText = lastUserMsg.content
        if let idx = messages.lastIndex(where: { $0.role == .user }) {
            messages.remove(at: idx)
        }
        sendMessage()
    }

    // MARK: - Weekly Digest

    func generateWeeklyDigest() {
        guard WeeklyDigestService.isDigestWindow, !WeeklyDigestService.hasDigestThisWeek else { return }

        let deps = DependencyContainer.shared
        let service = WeeklyDigestService(
            nutritionService: deps.nutritionService,
            coreDataService: deps.coreDataService
        )
        let userCopy = user

        Task { @MainActor in
            if let digest = await service.generateDigest(user: userCopy) {
                let formatted = WeeklyDigestService.formatAsMessage(digest)
                weeklyDigestMessage = ChatMessage(
                    role: .assistant,
                    content: formatted
                )
            }
        }
    }

    func showWeeklyDigest() {
        // The digest is shown as weeklyDigestMessage in the view
    }
}
