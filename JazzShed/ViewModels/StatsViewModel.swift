import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class StatsViewModel {
    var sessions: [PracticeSession] = []
    var totalSessions = 0
    var totalPracticeHours: Double = 0
    var totalPatterns = 0
    var totalXP = 0

    // Heatmap data: last 12 weeks, 7 days each
    var heatmapData: [[Int]] = []

    func load(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []

        totalSessions = sessions.count
        totalPracticeHours = Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 3600
        totalPatterns = sessions.reduce(0) { $0 + $1.vocabularyCount }
        totalXP = sessions.reduce(0) { $0 + $1.totalScore }

        buildHeatmap()
    }

    private func buildHeatmap() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 12 weeks x 7 days
        var grid = Array(repeating: Array(repeating: 0, count: 12), count: 7)

        for session in sessions {
            let dayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: session.date), to: today).day ?? 0
            guard dayDiff >= 0 && dayDiff < 84 else { continue }

            let weekIndex = 11 - (dayDiff / 7)
            let dayOfWeek = calendar.component(.weekday, from: session.date) - 1 // 0=Sunday

            if weekIndex >= 0 && weekIndex < 12 && dayOfWeek >= 0 && dayOfWeek < 7 {
                grid[dayOfWeek][weekIndex] += session.durationSeconds / 60
            }
        }

        heatmapData = grid
    }
}
