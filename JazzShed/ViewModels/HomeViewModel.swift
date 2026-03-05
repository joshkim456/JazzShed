import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var user: UserProfile?
    var recentSessions: [PracticeSession] = []
    var weeklySessionCount = 0
    var weeklyPracticeMinutes = 0
    var weeklyPatternCount = 0

    func load(modelContext: ModelContext) {
        // Load user
        let userDescriptor = FetchDescriptor<UserProfile>()
        user = try? modelContext.fetch(userDescriptor).first

        // Load recent sessions
        var sessionDescriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 5
        recentSessions = (try? modelContext.fetch(sessionDescriptor)) ?? []

        // Weekly stats
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let allSessions = (try? modelContext.fetch(FetchDescriptor<PracticeSession>())) ?? []
        let weeklySessions = allSessions.filter { $0.date >= weekAgo }

        weeklySessionCount = weeklySessions.count
        weeklyPracticeMinutes = weeklySessions.reduce(0) { $0 + $1.durationSeconds } / 60
        weeklyPatternCount = weeklySessions.reduce(0) { $0 + $1.vocabularyCount }
    }

    var streakFlame: StreakManager.FlameLevel {
        StreakManager.flameLevel(for: user?.currentStreak ?? 0)
    }

    var dailyGoalProgress: Double {
        guard let user, user.dailyGoalMinutes > 0 else { return 0 }
        let todaySessions = recentSessions.filter {
            Calendar.current.isDateInToday($0.date)
        }
        let todayMinutes = todaySessions.reduce(0) { $0 + $1.durationSeconds } / 60
        return min(Double(todayMinutes) / Double(user.dailyGoalMinutes), 1.0)
    }
}
