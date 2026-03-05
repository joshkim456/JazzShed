import Foundation
import Observation

/// Manages scoring, combo multiplier, and session statistics during gameplay.
///
/// Scoring philosophy:
/// - Honest and demanding — jazz improvisation is hard and the score should reflect that.
/// - Chord tones and scale tones earn points. Chromatic tones are neutral (no points, no penalty).
/// - Clashing notes are penalised: points deducted and combo broken.
/// - Combo only builds on chord tones and scale tones.
@Observable
final class ScoreEngine {
    private(set) var totalScore: Int = 0
    private(set) var comboCount: Int = 0
    private(set) var maxCombo: Int = 0
    private(set) var multiplier: Double = 1.0
    private(set) var detectedPatterns: [PatternDetection] = []

    // Note quality tracking
    private(set) var chordToneCount: Int = 0
    private(set) var scaleToneCount: Int = 0
    private(set) var chromaticCount: Int = 0
    private(set) var clashingCount: Int = 0
    private(set) var totalNotesScored: Int = 0

    // Track last few notes for resolution detection
    private var recentNotes: [NoteEvent] = []
    private let resolutionWindow = 3  // Check last N notes for resolution

    // Per-note point values
    private let chordTonePoints = 10
    private let scaleTonePoints = 5
    private let clashingPenalty = 15

    /// Combo multiplier thresholds.
    private let comboThresholds: [(count: Int, multiplier: Double)] = [
        (32, 4.0),
        (16, 3.0),
        (8, 2.0),
    ]

    /// Process a new enriched note event for scoring.
    func processNote(_ note: NoteEvent) {
        totalNotesScored += 1
        recentNotes.append(note)
        if recentNotes.count > 10 { recentNotes.removeFirst() }

        let quality = classifyNote(note)

        switch quality {
        case .chordTone:
            chordToneCount += 1
            totalScore += Int(Double(chordTonePoints) * multiplier)
            incrementCombo()
        case .scaleTone:
            scaleToneCount += 1
            totalScore += Int(Double(scaleTonePoints) * multiplier)
            incrementCombo()
        case .chromatic:
            chromaticCount += 1
            // Neutral — no points, no penalty, no combo change.
            // Chromatic notes might be approaches; we wait and see.
        case .clashing:
            // Check if previous "clashing" notes resolved
            if checkResolution(note) {
                // Resolved into a chord tone — count as chromatic approach
                chromaticCount += 1
            } else {
                clashingCount += 1
                totalScore = max(0, totalScore - clashingPenalty)
                resetCombo()
            }
        }
    }

    /// Process a detected pattern — adds points with multiplier.
    func processPattern(_ detection: PatternDetection) {
        let points = Int(Double(detection.pointsAwarded) * multiplier)
        totalScore += points
        detectedPatterns.append(detection)
    }

    /// Percentage of notes that were harmonically strong (chord + scale tones).
    var noteChoicePercent: Double {
        guard totalNotesScored > 0 else { return 0 }
        return Double(chordToneCount + scaleToneCount) / Double(totalNotesScored) * 100
    }

    /// Star rating (1-5) based on note choice percentage and unique patterns.
    var starRating: Int {
        let noteScore = noteChoicePercent
        let uniquePatterns = Set(detectedPatterns.map(\.patternId)).count
        let patternBonus = min(Double(uniquePatterns) * 1.5, 10.0)
        let combined = noteScore + patternBonus

        switch combined {
        case 95...:  return 5
        case 80..<95: return 4
        case 65..<80: return 3
        case 45..<65: return 2
        default:      return 1
        }
    }

    func reset() {
        totalScore = 0
        comboCount = 0
        maxCombo = 0
        multiplier = 1.0
        detectedPatterns = []
        chordToneCount = 0
        scaleToneCount = 0
        chromaticCount = 0
        clashingCount = 0
        totalNotesScored = 0
        recentNotes = []
    }

    // MARK: - Private

    private enum NoteQuality {
        case chordTone, scaleTone, chromatic, clashing
    }

    private func classifyNote(_ note: NoteEvent) -> NoteQuality {
        guard let isChordTone = note.isChordTone,
              let scaleDegree = note.scaleDegree else {
            // No context available — don't reward unknown notes
            return .chromatic
        }

        if isChordTone {
            return .chordTone
        }

        // Check if it's a scale tone for the current chord
        if let chordSymbol = note.chordSymbol,
           let quality = parseQuality(from: chordSymbol),
           quality.scaleTones.contains(scaleDegree) {
            return .scaleTone
        }

        // Only b3 (blue note) and b6 are common jazz chromatic tones
        let commonChromaticDegrees = [3, 8] // b3, b6
        if commonChromaticDegrees.contains(scaleDegree) {
            return .chromatic
        }

        return .clashing
    }

    private func parseQuality(from symbol: String) -> ChordQuality? {
        // Extract quality portion from chord symbol like "Cm7", "F7", "BbΔ7"
        // This is a simplified parser — the ContextEngine provides the real data
        for quality in ChordQuality.allCases {
            if symbol.hasSuffix(quality.symbol) {
                return quality
            }
        }
        return .dominant7 // Safe default
    }

    /// Checks if the current note resolves a previous chromatic/tension note.
    private func checkResolution(_ currentNote: NoteEvent) -> Bool {
        guard recentNotes.count >= 2,
              let currentIsChordTone = currentNote.isChordTone,
              currentIsChordTone else { return false }

        // Only counts as resolution if the previous note was within 2 semitones
        // (i.e. a chromatic approach, not a random clash that happens to precede a chord tone)
        let prev = recentNotes[recentNotes.count - 2]
        let interval = abs(currentNote.midiNote - prev.midiNote)
        return interval <= 2
    }

    private func incrementCombo() {
        comboCount += 1
        if comboCount > maxCombo {
            maxCombo = comboCount
        }
        updateMultiplier()
    }

    private func resetCombo() {
        comboCount = 0
        multiplier = 1.0
    }

    private func updateMultiplier() {
        for threshold in comboThresholds {
            if comboCount >= threshold.count {
                multiplier = threshold.multiplier
                return
            }
        }
        multiplier = 1.0
    }
}
