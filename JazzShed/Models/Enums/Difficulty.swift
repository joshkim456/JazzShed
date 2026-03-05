import Foundation

enum Difficulty: Int, Codable, CaseIterable, Comparable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3

    var label: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
