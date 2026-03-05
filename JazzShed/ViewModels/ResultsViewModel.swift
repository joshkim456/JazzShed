import Foundation
import Observation

/// Computes and presents post-session analysis data.
@Observable
@MainActor
final class ResultsViewModel {
    let session: SessionData

    /// Simplified session data passed from SessionViewModel.
    struct SessionData {
        let tuneTitle: String
        let tempo: Int
        let totalScore: Int
        let starRating: Int
        let noteChoicePercent: Double
        let maxCombo: Int
        let detectedPatterns: [PatternDetection]
        let enrichedNotes: [NoteEvent]
        let durationSeconds: Int
        let chordToneCount: Int
        let scaleToneCount: Int
        let chromaticCount: Int
        let clashingCount: Int
        let totalNotesScored: Int
    }

    init(session: SessionData) {
        self.session = session
    }

    // MARK: - Computed Analysis

    /// Groups detected patterns by type with count.
    var patternSummary: [(name: String, count: Int, totalPoints: Int)] {
        var grouped: [String: (count: Int, points: Int)] = [:]
        for p in session.detectedPatterns {
            let existing = grouped[p.patternName, default: (0, 0)]
            grouped[p.patternName] = (existing.count + 1, existing.points + p.pointsAwarded)
        }
        return grouped.map { (name: $0.key, count: $0.value.count, totalPoints: $0.value.points) }
            .sorted { $0.totalPoints > $1.totalPoints }
    }

    /// Breakdown categories with percentages (for the bar chart).
    var breakdown: [(category: String, percent: Double)] {
        [
            ("Note Choice", session.noteChoicePercent),
            ("Vocabulary", vocabularyScore),
            ("Combo", comboScore),
        ]
    }

    private var vocabularyScore: Double {
        // Score based on unique patterns detected — need 10 unique for 100%
        let uniquePatterns = Set(session.detectedPatterns.map(\.patternId)).count
        return min(Double(uniquePatterns) * 10.0, 100.0)
    }

    private var comboScore: Double {
        // Score based on max combo relative to total notes
        guard session.totalNotesScored > 0 else { return 0 }
        return min(Double(session.maxCombo) / Double(session.totalNotesScored) * 100, 100)
    }

    /// Rule-based highlight text.
    var highlights: String {
        var parts: [String] = []

        if session.noteChoicePercent > 80 {
            parts.append("Excellent note choice — \(Int(session.noteChoicePercent))% of your notes were harmonically strong.")
        }

        if session.maxCombo >= 16 {
            parts.append("Impressive combo of \(session.maxCombo) — great consistency!")
        }

        let enclosureCount = session.detectedPatterns.filter { $0.patternId == "simple_enclosure" }.count
        if enclosureCount >= 3 {
            parts.append("Nice use of enclosures (\(enclosureCount) detected).")
        }

        if parts.isEmpty {
            parts.append("Keep practicing — your pattern vocabulary will grow with each session.")
        }

        return parts.joined(separator: " ")
    }

    /// Rule-based growth suggestions.
    var areasForGrowth: String {
        var parts: [String] = []

        if session.noteChoicePercent < 60 {
            parts.append("Focus on landing chord tones on strong beats — this is the foundation of strong jazz lines.")
        }

        if session.detectedPatterns.isEmpty {
            parts.append("Try incorporating some chromatic approaches and enclosures into your lines.")
        }

        if session.maxCombo < 8 {
            parts.append("Work on stringing together more harmonically consistent phrases to build your combo.")
        }

        if parts.isEmpty {
            parts.append("Great session! Try a faster tempo or less familiar key to push yourself further.")
        }

        return parts.joined(separator: " ")
    }
}
