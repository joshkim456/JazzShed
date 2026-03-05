import Foundation
import SwiftData

/// Manages practice streak tracking.
/// A streak is maintained by practicing at least 5 minutes on consecutive days.
struct StreakManager {
    static let minimumSessionSeconds = 300 // 5 minutes

    /// Updates the user's streak based on a completed session.
    /// Call this after persisting a PracticeSession.
    static func updateStreak(user: UserProfile, sessionDuration: Int) {
        guard sessionDuration >= minimumSessionSeconds else { return }

        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = user.lastPracticeDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysBetween == 0 {
                // Already practiced today — no streak change
                return
            } else if daysBetween == 1 {
                // Consecutive day — increment streak
                user.currentStreak += 1
            } else {
                // Streak broken — reset
                user.currentStreak = 1
            }
        } else {
            // First ever practice
            user.currentStreak = 1
        }

        user.lastPracticeDate = today
        if user.currentStreak > user.longestStreak {
            user.longestStreak = user.currentStreak
        }
    }

    /// Returns the streak flame level for visual display.
    static func flameLevel(for streak: Int) -> FlameLevel {
        switch streak {
        case 365...:  return .legendary
        case 100..<365: return .blazing
        case 30..<100:  return .burning
        case 7..<30:    return .warming
        case 1..<7:     return .spark
        default:         return .none
        }
    }

    enum FlameLevel {
        case none, spark, warming, burning, blazing, legendary

        var icon: String {
            switch self {
            case .none:      return ""
            case .spark:     return "flame"
            case .warming:   return "flame.fill"
            case .burning:   return "flame.fill"
            case .blazing:   return "flame.fill"
            case .legendary: return "flame.fill"
            }
        }

        var color: String {
            switch self {
            case .none:      return "6B6B80"
            case .spark:     return "F0A500"
            case .warming:   return "E8833A"
            case .burning:   return "E85D3A"
            case .blazing:   return "E83A3A"
            case .legendary: return "D4A373"
            }
        }
    }
}
