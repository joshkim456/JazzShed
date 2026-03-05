import Foundation
import SwiftData

@Model
final class UserProfile {
    var instrument: String = "Alto Saxophone"
    var experienceLevel: Int = 1                // 1-4
    var dailyGoalMinutes: Int = 10
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPracticeDate: Date?
    var totalXP: Int = 0
    var totalPracticeSeconds: Int = 0
    var createdAt: Date = Date()

    // Settings
    var gamificationMode: String = "full"       // "full" or "minimal"
    var hapticFeedbackEnabled: Bool = true
    var audioFeedbackEnabled: Bool = false

    init(instrument: String = "Alto Saxophone", experienceLevel: Int = 1, dailyGoalMinutes: Int = 10) {
        self.instrument = instrument
        self.experienceLevel = experienceLevel
        self.dailyGoalMinutes = dailyGoalMinutes
        self.createdAt = Date()
    }
}
