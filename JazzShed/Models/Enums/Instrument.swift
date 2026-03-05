import Foundation

enum Instrument: String, Codable, CaseIterable, Identifiable {
    case altoSax = "Alto Saxophone"
    case tenorSax = "Tenor Saxophone"
    case trumpet = "Trumpet"
    case trombone = "Trombone"
    case clarinet = "Clarinet"
    case flute = "Flute"
    case voice = "Voice"
    case piano = "Piano"
    case other = "Other"

    var id: String { rawValue }

    /// Transposition interval in semitones from concert pitch.
    /// Positive = instrument sounds lower than written (player reads higher).
    var transposition: Int {
        switch self {
        case .altoSax:   return -9  // Eb instrument: written C sounds Eb (concert)
        case .tenorSax:  return -2  // Bb instrument: written C sounds Bb
        case .trumpet:   return -2  // Bb instrument
        case .clarinet:  return -2  // Bb instrument (standard)
        case .trombone:  return 0   // Concert pitch
        case .flute:     return 0   // Concert pitch
        case .voice:     return 0   // Concert pitch
        case .piano:     return 0   // Concert pitch
        case .other:     return 0
        }
    }

    /// Typical MIDI range for the instrument.
    var midiRange: ClosedRange<Int> {
        switch self {
        case .altoSax:   return 49...80  // Db3 to Ab5
        case .tenorSax:  return 44...75  // Ab2 to Eb5
        case .trumpet:   return 52...82  // E3 to Bb5
        case .trombone:  return 40...72  // E2 to C5
        case .clarinet:  return 50...84  // D3 to C6
        case .flute:     return 60...96  // C4 to C7
        case .voice:     return 48...84  // C3 to C6
        case .piano:     return 36...96  // C2 to C7 (jazz solo range)
        case .other:     return 36...96  // Wide range
        }
    }
}
