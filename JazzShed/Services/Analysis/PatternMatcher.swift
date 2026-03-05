import Foundation

/// Protocol that all pattern detectors conform to.
/// Each detector examines a window of recent enriched NoteEvents
/// and returns a detection if the pattern is found.
protocol PatternDetector {
    var patternId: String { get }
    var patternName: String { get }
    var basePoints: Int { get }

    /// Checks if the pattern is present in the recent note history.
    /// Returns a detection if found, nil otherwise.
    /// - Parameters:
    ///   - notes: Recent note events (enriched with context), newest last.
    ///   - currentBeat: Current beat position in the chart.
    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection?
}

/// Coordinates all registered pattern detectors and resolves overlapping detections.
final class PatternMatcher {
    private var detectors: [PatternDetector] = []

    /// Callback fired when a pattern is detected.
    var onPatternDetected: ((PatternDetection) -> Void)?

    /// IDs of recently detected patterns to avoid rapid re-triggers.
    private var recentDetections: [(id: String, beat: Double)] = []
    private let cooldownBeats: Double = 2.0 // Minimum beats between same pattern

    init() {
        registerDefaultDetectors()
    }

    /// Registers a new pattern detector.
    func register(_ detector: PatternDetector) {
        detectors.append(detector)
    }

    /// Checks all detectors against the current note window.
    func checkPatterns(notes: [NoteEvent], currentBeat: Double) {
        // Clean up old recent detections
        recentDetections.removeAll { currentBeat - $0.beat > cooldownBeats * 2 }

        var detected: [PatternDetection] = []

        for detector in detectors {
            // Skip if this pattern was recently detected
            if recentDetections.contains(where: {
                $0.id == detector.patternId && (currentBeat - $0.beat) < cooldownBeats
            }) {
                continue
            }

            if let detection = detector.detect(in: notes, currentBeat: currentBeat) {
                detected.append(detection)
                recentDetections.append((id: detector.patternId, beat: currentBeat))
            }
        }

        // If multiple patterns detected, keep the highest-scoring one
        // (overlap resolution — prefer more specific patterns)
        if let best = detected.max(by: { $0.pointsAwarded < $1.pointsAwarded }) {
            onPatternDetected?(best)
        }
    }

    func reset() {
        recentDetections = []
    }

    // MARK: - Default Detectors

    private func registerDefaultDetectors() {
        detectors = [
            // Original 5
            ChordToneOnStrongBeatDetector(),
            ChromaticApproachBelowDetector(),
            ChromaticApproachAboveDetector(),
            SimpleEnclosureDetector(),
            ArpeggioDetector(),
            // Additional 15
            DoubleChromaticApproachDetector(),
            DiatonicEnclosureDetector(),
            BebopScaleRunDetector(),
            DigitalPattern1235Detector(),
            BlueNoteDetector(),
            GuideToneDetector(),
            SpaceDetector(),
            TensionResolutionDetector(),
            PhraseResolutionDetector(),
            RangeExplorationDetector(),
            QuartalMelodyDetector(),
            PentatonicRunDetector(),
            SequenceDetector(),
            DiminishedArpeggioDetector(),
            WideIntervalLeapDetector(),
        ]
    }
}

// MARK: - Detector Implementations

/// Detects chord tones landing on strong beats (1 or 3).
struct ChordToneOnStrongBeatDetector: PatternDetector {
    let patternId = "chord_tone_strong_beat"
    let patternName = "Chord Tone"
    let basePoints = 50

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard let last = notes.last,
              let beat = last.beat,
              let isChordTone = last.isChordTone,
              isChordTone else { return nil }

        // Check if on a strong beat (1 or 3 in 4/4)
        let beatInBar = beat.truncatingRemainder(dividingBy: 4.0)
        let isStrongBeat = beatInBar < 0.3 || (beatInBar > 1.7 && beatInBar < 2.3)

        guard isStrongBeat else { return nil }

        return PatternDetection(
            patternId: patternId,
            patternName: patternName,
            barNumber: Int(beat / 4),
            beatPosition: beat,
            pointsAwarded: basePoints,
            noteEvents: [last],
            timestamp: last.startTime
        )
    }
}

/// Detects a chromatic approach from below: half step below → chord tone.
struct ChromaticApproachBelowDetector: PatternDetector {
    let patternId = "chromatic_approach_below"
    let patternName = "Chromatic Approach ↑"
    let basePoints = 75

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 2 else { return nil }

        let target = notes[notes.count - 1]
        let approach = notes[notes.count - 2]

        // Target must be a chord tone
        guard let isChordTone = target.isChordTone, isChordTone else { return nil }

        // Approach note must be exactly 1 semitone below target
        let interval = target.midiNote - approach.midiNote
        guard interval == 1 else { return nil }

        // Approach note should NOT be a chord tone (it's chromatic)
        if let approachIsChord = approach.isChordTone, approachIsChord { return nil }

        return PatternDetection(
            patternId: patternId,
            patternName: patternName,
            barNumber: Int((target.beat ?? 0) / 4),
            beatPosition: target.beat ?? 0,
            pointsAwarded: basePoints,
            noteEvents: [approach, target],
            timestamp: target.startTime
        )
    }
}

/// Detects a chromatic approach from above: half step above → chord tone.
struct ChromaticApproachAboveDetector: PatternDetector {
    let patternId = "chromatic_approach_above"
    let patternName = "Chromatic Approach ↓"
    let basePoints = 75

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 2 else { return nil }

        let target = notes[notes.count - 1]
        let approach = notes[notes.count - 2]

        guard let isChordTone = target.isChordTone, isChordTone else { return nil }

        // Approach from above: approach is 1 semitone higher
        let interval = approach.midiNote - target.midiNote
        guard interval == 1 else { return nil }

        if let approachIsChord = approach.isChordTone, approachIsChord { return nil }

        return PatternDetection(
            patternId: patternId,
            patternName: patternName,
            barNumber: Int((target.beat ?? 0) / 4),
            beatPosition: target.beat ?? 0,
            pointsAwarded: basePoints,
            noteEvents: [approach, target],
            timestamp: target.startTime
        )
    }
}

/// Detects a simple enclosure: note above target → note below target → target (chord tone).
struct SimpleEnclosureDetector: PatternDetector {
    let patternId = "simple_enclosure"
    let patternName = "Enclosure"
    let basePoints = 150

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let target = notes[notes.count - 1]
        let below = notes[notes.count - 2]
        let above = notes[notes.count - 3]

        // Target must be a chord tone
        guard let isChordTone = target.isChordTone, isChordTone else { return nil }

        // Pattern: above (1-2 semitones above) → below (1 semitone below) → target
        // OR: below → above → target
        let aboveInterval = above.midiNote - target.midiNote
        let belowInterval = target.midiNote - below.midiNote

        // Check above-below-target pattern
        if aboveInterval >= 1 && aboveInterval <= 2 && belowInterval == 1 {
            return PatternDetection(
                patternId: patternId,
                patternName: patternName,
                barNumber: Int((target.beat ?? 0) / 4),
                beatPosition: target.beat ?? 0,
                pointsAwarded: basePoints,
                noteEvents: [above, below, target],
                timestamp: target.startTime
            )
        }

        // Check below-above-target pattern
        let belowFirstInterval = target.midiNote - above.midiNote  // "above" is now the first note
        let aboveSecondInterval = below.midiNote - target.midiNote  // "below" is now the second note
        if belowFirstInterval == 1 && aboveSecondInterval >= 1 && aboveSecondInterval <= 2 {
            return PatternDetection(
                patternId: patternId,
                patternName: patternName,
                barNumber: Int((target.beat ?? 0) / 4),
                beatPosition: target.beat ?? 0,
                pointsAwarded: basePoints,
                noteEvents: [above, below, target],
                timestamp: target.startTime
            )
        }

        return nil
    }
}

/// Detects a 1-3-5-7 arpeggio over the current chord.
struct ArpeggioDetector: PatternDetector {
    let patternId = "arpeggio_1357"
    let patternName = "Arpeggio"
    let basePoints = 100

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 4 else { return nil }

        let last4 = Array(notes.suffix(4))

        // All 4 notes must be chord tones
        guard last4.allSatisfy({ $0.isChordTone == true }) else { return nil }

        // All must be over the same chord
        guard let firstChord = last4.first?.chordSymbol,
              last4.allSatisfy({ $0.chordSymbol == firstChord }) else { return nil }

        // Check that we have 4 distinct pitch classes (not the same note repeated)
        let pitchClasses = Set(last4.map { $0.pitchClass })
        guard pitchClasses.count >= 3 else { return nil } // Allow 3 distinct for partial arpeggios

        return PatternDetection(
            patternId: patternId,
            patternName: patternName,
            barNumber: Int((last4.last?.beat ?? 0) / 4),
            beatPosition: last4.last?.beat ?? 0,
            pointsAwarded: basePoints,
            noteEvents: last4,
            timestamp: last4.last?.startTime ?? 0
        )
    }
}
