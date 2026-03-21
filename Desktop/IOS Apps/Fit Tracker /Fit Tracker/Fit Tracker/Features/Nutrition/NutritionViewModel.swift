import SwiftUI
import Observation

// MARK: - Nutrition View Model

@MainActor
@Observable
final class NutritionViewModel {

    // MARK: - State

    var todayLog: NutritionLog
    var selectedDate: Date = .now {
        didSet { loadLog(for: selectedDate) }
    }
    var showAddFood = false
    var selectedMealType: MealType = .breakfast
    
    // Editing state
    var entryToEdit: NutritionEntry?

    // Search state
    var searchQuery = "" {
        didSet { debouncedSearch() }
    }
    var searchResults: [FoodItem] = []
    var isSearching = false
    var searchError: String?

    // Custom food / Quick add / Scanner
    var showCustomFood = false
    var showQuickAdd = false
    var showFoodScanner = false
    var showBarcodeScanner = false
    var showBarcodeLimitPaywall = false
    var showAnalytics = false

    // AI Food Parser state
    var parsedFoodItems: [ParsedFoodItem] = []
    var isAIParsing = false
    var showParsedMealSheet = false
    var aiParseError: String?
    var showAIParseLimitPaywall = false
    private var aiParseTask: Task<Void, Never>?

    // Quick Add Form State
    var quickAddName: String = ""
    var quickAddCalories: String = ""
    var quickAddProtein: String = ""
    
    // Recent foods (Option 1)
    var recentFoods: [FoodItem] = []

    // MARK: - Dependencies

    private let nutritionService: NutritionService
    private let user: UserProfile
    private var searchTask: Task<Void, Never>?
    private var logChangeObserver: Any?

    init(user: UserProfile, nutritionService: NutritionService) {
        self.user = user
        self.nutritionService = nutritionService
        self.todayLog = nutritionService.fetchTodayLog()

        // Listen for external changes (e.g. recipe logging from RecipeDetailViewModel)
        logChangeObserver = NotificationCenter.default.addObserver(
            forName: .nutritionLogDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refresh()
            }
        }
    }

    // MARK: - Targets

    var targetCalories: Int { user.targetCalories }
    var targetProteinG: Int { user.targetProteinG }
    var targetCarbsG: Int { user.targetCarbsG }
    var targetFatG: Int { user.targetFatG }

    // MARK: - Progress

    var caloriesConsumed: Int { Int(todayLog.totalCalories) }
    var caloriesRemaining: Int { max(0, targetCalories - caloriesConsumed) }
    var calorieProgress: Double { todayLog.calorieProgress(target: targetCalories) }

    // MARK: - Meals

    func entries(for mealType: MealType) -> [NutritionEntry] {
        todayLog.entries.filter { $0.mealType == mealType }
    }

    func mealCalories(for mealType: MealType) -> Int {
        Int(entries(for: mealType).reduce(0) { $0 + $1.calories })
    }

    // MARK: - Load

    func loadLog(for date: Date) {
        todayLog = nutritionService.fetchLog(for: date)
    }

    func refresh() {
        loadLog(for: selectedDate)
    }

    func openAddFood(for mealType: MealType) {
        self.selectedMealType = mealType
        self.searchQuery = ""
        self.searchResults = []
        self.recentFoods = nutritionService.fetchRecentFoods(userId: user.uid)
        self.showAddFood = true
    }

    // MARK: - Add Entry

    func addEntry(food: FoodItem, quantity: Double, mealType: MealType) async {
        let entry = NutritionEntry(from: food, quantity: quantity, mealType: mealType)
        var log = todayLog
        await nutritionService.addEntry(entry, to: &log)
        todayLog = log

        // Force refresh from CoreData to ensure UI is in sync
        refresh()

        // Record food frequency for smart search ranking
        FoodFrequencyTracker.recordFood(food.name)

        // Cache USDA and Custom foods locally for offline reuse
        if food.source == .usda || food.isCustom {
            Task { await nutritionService.cacheFoodItem(food) }
        }

        // Sync to Firestore in the background
        Task {
            await nutritionService.syncToFirestore(log, userId: user.uid)
        }

        // Notify other ViewModels (like HomeViewModel) to refresh
        NotificationCenter.default.post(name: .nutritionLogDidChange, object: nil)
    }

    func logRecipe(_ recipe: Recipe, mealType: MealType) async {
        var log = todayLog
        for entry in recipe.ingredients {
            var newEntry = entry
            newEntry.id = UUID().uuidString
            newEntry.loggedAt = Date()
            newEntry.mealType = mealType
            await nutritionService.addEntry(newEntry, to: &log)
        }
        todayLog = log
        
        Task {
            await nutritionService.syncToFirestore(log, userId: user.uid)
        }
    }

    // MARK: - Analytics

    func fetchWeeklyLogs() async -> [NutritionLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let logs = nutritionService.fetchLogs(from: sevenDaysAgo, to: endOfDay)
        
        // Fill missing days with empty logs for the chart
        var result: [NutritionLog] = []
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: sevenDaysAgo)!
            if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
                result.append(existing)
            } else {
                result.append(NutritionLog(date: day))
            }
        }
        return result
    }

    // MARK: - Quick Add Calories (Option 3)

    func submitQuickAddCalories() async {
        guard let cal = Double(quickAddCalories), cal > 0 else { return }
        let prot = Double(quickAddProtein) ?? 0
        let name = quickAddName.trimmingCharacters(in: .whitespaces).isEmpty ? "Quick Add" : quickAddName
        
        let food = FoodItem(
            id: UUID().uuidString,
            name: name,
            brandName: nil,
            barcode: nil,
            fdcId: nil,
            servingSizeG: 1,
            servingUnit: "serving",
            calories: cal,
            proteinG: prot,
            carbsG: 0,
            fatG: 0,
            fiberG: 0,
            sugarG: 0,
            sodiumMg: 0,
            isVerified: false,
            isCustom: true,
            source: .custom
        )
        
        await addEntry(food: food, quantity: 1, mealType: selectedMealType)
        
        // Reset state
        showQuickAdd = false
        quickAddName = ""
        quickAddCalories = ""
        quickAddProtein = ""

        NotificationCenter.default.post(name: .nutritionLogDidChange, object: nil)
    }

    // MARK: - Remove Entry

    func removeEntry(_ entry: NutritionEntry) async {
        var log = todayLog
        await nutritionService.removeEntry(id: entry.id, from: &log)
        todayLog = log

        Task {
            await nutritionService.syncToFirestore(log, userId: user.uid)
        }
        
        NotificationCenter.default.post(name: .nutritionLogDidChange, object: nil)
    }

    // MARK: - Update Entry

    func updateEntry(_ entry: NutritionEntry, newQuantity: Double, newMealType: MealType) async {
        // Linearly scale macros based on the new quantity vs old quantity
        let ratio = entry.servingQuantity > 0 ? newQuantity / entry.servingQuantity : 1.0
        
        var updatedEntry = entry
        updatedEntry.servingQuantity = newQuantity
        updatedEntry.mealType = newMealType
        updatedEntry.calories = entry.calories * ratio
        updatedEntry.proteinG = entry.proteinG * ratio
        updatedEntry.carbsG = entry.carbsG * ratio
        updatedEntry.fatG = entry.fatG * ratio
        updatedEntry.fiberG = entry.fiberG * ratio
        
        var log = todayLog
        await nutritionService.updateEntry(updatedEntry, in: &log)
        todayLog = log
        
        Task {
            await nutritionService.syncToFirestore(log, userId: user.uid)
        }
    }

    // MARK: - Water

    func addWater(ml: Double) async {
        var log = todayLog
        log.waterMl += ml
        // Clamp to positive
        log.waterMl = max(0, log.waterMl)
        await nutritionService.saveLog(log)
        todayLog = log
        
        Task {
            await nutritionService.syncToFirestore(log, userId: user.uid)
        }
    }

    // MARK: - Debounced Search

    private func debouncedSearch() {
        searchTask?.cancel()

        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            searchResults = []
            searchError = nil
            isSearching = false
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func performSearch(query: String) async {
        isSearching = true
        searchError = nil

        do {
            guard !Task.isCancelled else { return }
            
            // Perform the offline, bilingual database search
            let results = try await nutritionService.searchFoods(query: query)
            
            guard !Task.isCancelled else { return }
            
            searchResults = results
            isSearching = false
            
        } catch is CancellationError {
            // Ignore cancellation
        } catch {
            guard !Task.isCancelled else { return }
            searchResults = []
            searchError = error.localizedDescription
            isSearching = false
        }
    }

    func retrySearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else { return }
        searchTask = Task { @MainActor in
            await performSearch(query: query)
        }
    }
    
    // MARK: - AI Food Parsing

    func parseWithAI(isPremium: Bool) {
        // Check usage limit
        guard AIFoodParserUsageTracker.canParse(isPremium: isPremium) else {
            showAIParseLimitPaywall = true
            return
        }

        // Cancel any in-flight parse
        aiParseTask?.cancel()

        aiParseTask = Task { @MainActor in
            isAIParsing = true
            aiParseError = nil

            do {
                guard !Task.isCancelled else { return }
                let parser = AIFoodParserService()
                let results = try await parser.parseMeal(
                    description: searchQuery,
                    nutritionService: nutritionService
                )
                guard !Task.isCancelled else { return }

                parsedFoodItems = results
                AIFoodParserUsageTracker.recordParse()
                isAIParsing = false
                showParsedMealSheet = true

            } catch is CancellationError {
                // Ignore
            } catch {
                guard !Task.isCancelled else { return }
                aiParseError = error.localizedDescription
                isAIParsing = false
            }
        }
    }

    func logAllParsedItems(mealType: MealType) async {
        for item in parsedFoodItems {
            let food = item.toFoodItem()
            // loggingQuantity returns grams — addEntry expects grams for the quantity parameter
            let quantity = item.loggingQuantity
            await addEntry(food: food, quantity: quantity, mealType: mealType)
        }
        parsedFoodItems = []
        showParsedMealSheet = false
    }

    // MARK: - Barcode Scanner Handling
    
    func handleBarcodeScan(code: String, isPremium: Bool = false) {
        showBarcodeScanner = false

        // Enforce barcode scan limit for non-premium (trial) users
        if !BarcodeScanUsageTracker.canScan(isPremium: isPremium) {
            showBarcodeLimitPaywall = true
            return
        }

        searchQuery = code
        isSearching = true
        searchError = nil

        Task { @MainActor in
            // Use the unified NutritionService to lookup the barcode
            if let result = await nutritionService.searchByBarcode(code) {
                BarcodeScanUsageTracker.recordScan()
                self.searchResults = [result]
                self.isSearching = false
            } else {
                self.searchResults = []
                self.searchError = "Barcode \(code) not found in database."
                self.isSearching = false
            }
        }
    }

    // MARK: - Current Meal (time-based)

    var currentMealType: MealType {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<11:  return .breakfast
        case 11..<15: return .lunch
        case 15..<17: return .snack
        case 17..<22: return .dinner
        default:       return .snack
        }
    }

    // MARK: - Recent Entries for Quick Re-log

    /// Returns the most recent unique entries for a given meal type from the past 7 days.
    func recentEntriesForMeal(_ mealType: MealType) -> [NutritionEntry] {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        let recentLogs = nutritionService.fetchLogs(from: sevenDaysAgo, to: .now)

        var seen = Set<String>()
        var results: [NutritionEntry] = []

        let allEntries = recentLogs
            .flatMap { $0.entries }
            .filter { $0.mealType == mealType }
            .sorted { $0.loggedAt > $1.loggedAt }

        for entry in allEntries {
            // Skip entries already in today's log for this meal
            let alreadyLogged = todayLog.entries.contains { $0.foodItemId == entry.foodItemId && $0.mealType == mealType }
            guard !alreadyLogged, !seen.contains(entry.foodItemId) else { continue }
            seen.insert(entry.foodItemId)
            results.append(entry)
            if results.count >= 3 { break }
        }

        return results
    }

    // MARK: - Quick Re-log

    func quickRelog(_ entry: NutritionEntry) async {
        var newEntry = entry
        newEntry.id = UUID().uuidString
        newEntry.loggedAt = Date()
        var log = todayLog
        await nutritionService.addEntry(newEntry, to: &log)
        todayLog = log
        Task { await nutritionService.syncToFirestore(log, userId: user.uid) }
        NotificationCenter.default.post(name: .nutritionLogDidChange, object: nil)
    }

    // MARK: - Presentation Helpers
}
