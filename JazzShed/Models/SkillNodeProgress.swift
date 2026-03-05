import Foundation
import SwiftData

/// Tracks a user's progress on a skill tree node.
@Model
final class SkillNodeProgress {
    var nodeId: String = ""
    var status: String = "locked"     // "locked", "available", "inProgress", "completed"
    var licksCompleted: Int = 0
    var totalLicks: Int = 0
    var lastPracticedDate: Date?

    init(nodeId: String, totalLicks: Int) {
        self.nodeId = nodeId
        self.totalLicks = totalLicks
    }

    var isCompleted: Bool { status == "completed" }
    var isAvailable: Bool { status == "available" || status == "inProgress" }

    var progressFraction: Double {
        guard totalLicks > 0 else { return 0 }
        return Double(licksCompleted) / Double(totalLicks)
    }
}
