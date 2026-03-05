import Foundation
import SwiftData

@Model
final class Achievement {
    var achievementId: String = ""
    var earnedDate: Date = Date()

    init(achievementId: String) {
        self.achievementId = achievementId
        self.earnedDate = Date()
    }
}
