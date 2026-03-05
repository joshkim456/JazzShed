import Foundation

/// Chord quality types used in jazz harmony.
enum ChordQuality: String, Codable, CaseIterable, Sendable {
    case major7 = "maj7"
    case minor7 = "min7"
    case dominant7 = "7"
    case minor7flat5 = "min7b5"
    case diminished7 = "dim7"
    case major = "maj"
    case minor = "min"
    case augmented = "aug"
    case dominant7alt = "7alt"
    case dominant7sharp11 = "7#11"
    case minor6 = "min6"
    case major6 = "6"
    case minorMajor7 = "minMaj7"
    case suspended4 = "sus4"
    case dominant7sus4 = "7sus4"

    /// Chord tones as semitone intervals from the root.
    var chordTones: [Int] {
        switch self {
        case .major7:         return [0, 4, 7, 11]    // R 3 5 7
        case .minor7:         return [0, 3, 7, 10]    // R b3 5 b7
        case .dominant7:      return [0, 4, 7, 10]    // R 3 5 b7
        case .minor7flat5:    return [0, 3, 6, 10]    // R b3 b5 b7
        case .diminished7:    return [0, 3, 6, 9]     // R b3 b5 bb7
        case .major:          return [0, 4, 7]         // R 3 5
        case .minor:          return [0, 3, 7]         // R b3 5
        case .augmented:      return [0, 4, 8]         // R 3 #5
        case .dominant7alt:   return [0, 4, 7, 10]    // Same tones, altered extensions
        case .dominant7sharp11: return [0, 4, 7, 10]  // R 3 5 b7
        case .minor6:         return [0, 3, 7, 9]     // R b3 5 6
        case .major6:         return [0, 4, 7, 9]     // R 3 5 6
        case .minorMajor7:    return [0, 3, 7, 11]    // R b3 5 7
        case .suspended4:     return [0, 5, 7]         // R 4 5
        case .dominant7sus4:  return [0, 5, 7, 10]    // R 4 5 b7
        }
    }

    /// Available tensions/extensions as semitone intervals.
    var availableTensions: [Int] {
        switch self {
        case .major7:         return [2, 6, 9]         // 9, #11, 13
        case .minor7:         return [2, 5, 9]         // 9, 11, 13
        case .dominant7:      return [2, 5, 9]         // 9, 11, 13
        case .minor7flat5:    return [2, 5, 8]         // 9, 11, b13
        case .diminished7:    return [2, 5, 8]         // 9, 11, b13
        case .dominant7alt:   return [1, 3, 6, 8]     // b9, #9, #11, b13
        case .dominant7sharp11: return [2, 6, 9]      // 9, #11, 13
        default:              return [2]               // 9
        }
    }

    /// Scale degrees that are considered "good" (chord tones + scale tones) — semitone intervals.
    var scaleTones: [Int] {
        switch self {
        case .major7:         return [0, 2, 4, 5, 7, 9, 11]    // Ionian
        case .minor7:         return [0, 2, 3, 5, 7, 9, 10]    // Dorian
        case .dominant7:      return [0, 2, 4, 5, 7, 9, 10]    // Mixolydian
        case .minor7flat5:    return [0, 2, 3, 5, 6, 8, 10]    // Locrian
        case .diminished7:    return [0, 2, 3, 5, 6, 8, 9, 11] // WH diminished
        case .dominant7alt:   return [0, 1, 3, 4, 6, 8, 10]    // Altered
        case .dominant7sharp11: return [0, 2, 4, 6, 7, 9, 10]  // Lydian dominant
        default:              return [0, 2, 4, 5, 7, 9, 11]    // Default to major
        }
    }

    /// Display symbol for chord charts.
    var symbol: String {
        switch self {
        case .major7:          return "\u{0394}7"    // Δ7
        case .minor7:          return "m7"
        case .dominant7:       return "7"
        case .minor7flat5:     return "m7\u{266D}5"  // m7♭5
        case .diminished7:     return "\u{00B0}7"    // °7
        case .major:           return ""
        case .minor:           return "m"
        case .augmented:       return "+"
        case .dominant7alt:    return "7alt"
        case .dominant7sharp11: return "7\u{266F}11"
        case .minor6:          return "m6"
        case .major6:          return "6"
        case .minorMajor7:     return "m\u{0394}7"
        case .suspended4:      return "sus4"
        case .dominant7sus4:   return "7sus4"
        }
    }
}
