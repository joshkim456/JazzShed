import Foundation
import SwiftData

/// Tracks a learned lick/pattern with spaced repetition schedule.
@Model
final class VocabularyItem {
    var lickId: String = ""
    var patternId: String = ""
    var learnedDate: Date = Date()
    var lastReviewDate: Date?
    var nextReviewDate: Date = Date()
    var reviewIntervalDays: Int = 1
    var timesReviewed: Int = 0
    var successCount: Int = 0

    init(lickId: String, patternId: String) {
        self.lickId = lickId
        self.patternId = patternId
        self.learnedDate = Date()
        self.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    var successRate: Double {
        guard timesReviewed > 0 else { return 0 }
        return Double(successCount) / Double(timesReviewed)
    }

    var isDueForReview: Bool {
        Date() >= nextReviewDate
    }

    /// Advances the spaced repetition schedule after a successful review.
    /// Schedule: 1 → 3 → 7 → 14 → 30 days
    func markReviewed(success: Bool) {
        timesReviewed += 1
        lastReviewDate = Date()

        if success {
            successCount += 1
            let intervals = [1, 3, 7, 14, 30]
            let currentIndex = intervals.firstIndex(of: reviewIntervalDays) ?? 0
            let nextIndex = min(currentIndex + 1, intervals.count - 1)
            reviewIntervalDays = intervals[nextIndex]
        } else {
            // Reset to 1 day on failure
            reviewIntervalDays = 1
        }

        nextReviewDate = Calendar.current.date(byAdding: .day, value: reviewIntervalDays, to: Date()) ?? Date()
    }
}
