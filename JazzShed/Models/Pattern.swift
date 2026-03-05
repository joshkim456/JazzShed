import Foundation

/// Metadata for a detectable jazz vocabulary pattern.
struct Pattern: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let tier: Difficulty
    let basePoints: Int
    let category: String       // e.g. "bebop", "blues", "modal", "general"
}
