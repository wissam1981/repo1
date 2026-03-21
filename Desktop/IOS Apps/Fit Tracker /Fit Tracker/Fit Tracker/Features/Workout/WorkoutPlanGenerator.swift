import Foundation

// MARK: - Workout Plan Generator
// Automatically assigns the best workout strategy based on user profile inputs.
// Also factors in goal weight delta for more precise plan recommendations.

struct WorkoutPlanGenerator {
    
    /// Generates the recommended workout plan ID for a given user profile.
    ///
    /// - Parameter user: The `UserProfile` to evaluate.
    /// - Returns: The `id` of the recommended `WorkoutPlan`.
    static func generateRecommendedPlanId(for user: UserProfile) -> String {
        
        let activity = user.activityLevel
        let goal = user.goal
        
        // --- Goal Weight Biasing ---
        // Use the gap between current weight and goal weight to sharpen the recommendation.
        let currentWeight = user.weightKg
        let goalWeight = user.goalWeightKg ?? currentWeight
        let weightDelta = currentWeight - goalWeight  // positive = need to lose, negative = need to gain
        
        // Large deficit (>10 kg to lose): full-body, fat-burning focus
        if weightDelta > 10 {
            return WorkoutPlanSeeder.fullBody3Day.id
        }
        
        // Smaller deficit (5-10 kg to lose): upper/lower balanced split gives cardio + strength
        if weightDelta > 5 && goal == .lose {
            return WorkoutPlanSeeder.upperLower4Day.id
        }
        
        // Large muscle gain target (>5 kg to gain): PPL or bro split
        if weightDelta < -5 && goal == .gain {
            if activity == .veryActive {
                return WorkoutPlanSeeder.ppl6Day.id
            }
            return WorkoutPlanSeeder.broSplit5Day.id
        }
        
        // --- Activity & Goal Fallbacks ---
        
        // Scenario 1: Beginners / Light activity + weight loss
        if activity == .sedentary || activity == .light {
            if goal == .lose {
                return WorkoutPlanSeeder.fullBody3Day.id
            }
        }
        
        // Scenario 2: Advanced Muscle Gain
        if activity == .veryActive && goal == .gain {
            return WorkoutPlanSeeder.ppl6Day.id
        }
        
        // Scenario 3: Intermediate Muscle Gain
        if goal == .gain {
            return WorkoutPlanSeeder.broSplit5Day.id
        }
        
        // Scenario 4: General Fitness / Maintenance
        return WorkoutPlanSeeder.upperLower4Day.id
    }
}
