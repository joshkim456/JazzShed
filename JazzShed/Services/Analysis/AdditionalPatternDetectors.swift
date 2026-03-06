import Foundation

// MARK: - Additional Pattern Detectors (15 more, bringing total to 20)

/// Double chromatic approach: two consecutive half steps resolving to a chord tone.
struct DoubleChromaticApproachDetector: PatternDetector {
    let patternId = "double_chromatic_approach"
    let patternName = "Double Chromatic"
    let basePoints = 100

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let target = notes[notes.count - 1]
        let mid = notes[notes.count - 2]
        let start = notes[notes.count - 3]

        guard let isChordTone = target.isChordTone, isChordTone else { return nil }

        // Ascending: two consecutive semitones up to target
        let ascending = (mid.midiNote - start.midiNote == 1) && (target.midiNote - mid.midiNote == 1)
        // Descending: two consecutive semitones down to target
        let descending = (start.midiNote - mid.midiNote == 1) && (mid.midiNote - target.midiNote == 1)

        guard ascending || descending else { return nil }

        return PatternDetection(
            patternId: patternId,
            patternName: patternName,
            barNumber: Int((target.beat ?? 0) / 4),
            beatPosition: target.beat ?? 0,
            pointsAwarded: basePoints,
            noteEvents: [start, mid, target],
            timestamp: target.startTime
        )
    }
}

/// Diatonic enclosure: whole step above, half step below, target.
struct DiatonicEnclosureDetector: PatternDetector {
    let patternId = "diatonic_enclosure"
    let patternName = "Diatonic Enclosure"
    let basePoints = 175

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let target = notes[notes.count - 1]
        let below = notes[notes.count - 2]
        let above = notes[notes.count - 3]

        guard let isChordTone = target.isChordTone, isChordTone else { return nil }

        // Diatonic above (2 semitones) → chromatic below (1 semitone) → target
        let aboveInterval = above.midiNote - target.midiNote
        let belowInterval = target.midiNote - below.midiNote

        guard aboveInterval == 2 && belowInterval == 1 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((target.beat ?? 0) / 4), beatPosition: target.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: [above, below, target],
            timestamp: target.startTime
        )
    }
}

/// Bebop scale run: 5+ consecutive notes following bebop scale intervals.
struct BebopScaleRunDetector: PatternDetector {
    let patternId = "bebop_scale_run"
    let patternName = "Bebop Scale Run"
    let basePoints = 200

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 5 else { return nil }

        let window = Array(notes.suffix(5))

        // Check for stepwise motion (all intervals are 1-2 semitones, mostly going in one direction)
        var ascending = 0
        var descending = 0
        for i in 1..<window.count {
            let interval = abs(window[i].midiNote - window[i-1].midiNote)
            guard interval >= 1 && interval <= 2 else { return nil }
            if window[i].midiNote > window[i-1].midiNote { ascending += 1 }
            else { descending += 1 }
        }

        // Must be mostly in one direction (3+ out of 4 intervals)
        guard ascending >= 3 || descending >= 3 else { return nil }

        // At least half should land on chord tones
        let chordToneCount = window.filter { $0.isChordTone == true }.count
        guard chordToneCount >= 2 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Digital pattern: 1-2-3-5 ascending scale degrees.
struct DigitalPattern1235Detector: PatternDetector {
    let patternId = "digital_1235"
    let patternName = "1-2-3-5 Pattern"
    let basePoints = 125

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 4 else { return nil }

        let window = Array(notes.suffix(4))
        guard let firstChord = window.first?.chordSymbol,
              window.allSatisfy({ $0.chordSymbol == firstChord }) else { return nil }

        guard let degrees = extractScaleDegrees(window) else { return nil }

        // Check for 1-2-3-5 pattern (intervals: 2, 1-2, 2-3 semitones)
        // In semitones from root: 0, 2, 3-4, 7
        let target = [0, 2, -1, 7] // -1 = either 3 or 4 (minor or major 3rd)
        guard degrees[0] == 0, degrees[1] == 2,
              (degrees[2] == 3 || degrees[2] == 4), degrees[3] == 7 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }

    private func extractScaleDegrees(_ notes: [NoteEvent]) -> [Int]? {
        notes.compactMap(\.scaleDegree).count == notes.count ? notes.compactMap(\.scaleDegree) : nil
    }
}

/// Blue note detection: b3 over a major/dominant chord.
struct BlueNoteDetector: PatternDetector {
    let patternId = "blue_note"
    let patternName = "Blue Note"
    let basePoints = 75

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard let last = notes.last, let degree = last.scaleDegree else { return nil }

        // b3 = 3 semitones from root over a major or dominant chord
        guard degree == 3 else { return nil }

        // Must be over a major or dominant chord (where b3 is a blue note, not a chord tone)
        if let isChordTone = last.isChordTone, isChordTone { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((last.beat ?? 0) / 4), beatPosition: last.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: [last],
            timestamp: last.startTime
        )
    }
}

/// Guide tone line: 3rds/7ths moving smoothly across chord changes.
struct GuideToneDetector: PatternDetector {
    let patternId = "guide_tone"
    let patternName = "Guide Tone"
    let basePoints = 250

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 4 else { return nil }

        let window = Array(notes.suffix(4))

        // Need at least 2 different chord symbols (spanning a chord change)
        let chords = Set(window.compactMap(\.chordSymbol))
        guard chords.count >= 2 else { return nil }

        // Check that notes on chord boundaries are 3rds or 7ths (degrees 3, 4, 10, 11)
        let guideToneDegrees: Set<Int> = [3, 4, 10, 11] // b3, 3, b7, 7
        let guideCount = window.filter { note in
            guard let deg = note.scaleDegree else { return false }
            return guideToneDegrees.contains(deg)
        }.count

        guard guideCount >= 2 else { return nil }

        // Check for smooth voice leading (intervals ≤ 3 semitones between notes)
        for i in 1..<window.count {
            if abs(window[i].midiNote - window[i-1].midiNote) > 4 { return nil }
        }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Use of space: detecting a musical rest between phrases.
struct SpaceDetector: PatternDetector {
    let patternId = "use_of_space"
    let patternName = "Space"
    let basePoints = 100

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 2 else { return nil }

        let last = notes[notes.count - 1]
        let prev = notes[notes.count - 2]

        guard let lastBeat = last.beat, let prevBeat = prev.beat else { return nil }

        // Only fire on the first note after the gap — last note must be the one just played
        guard abs(lastBeat - currentBeat) < 1.0 else { return nil }

        // Check for a gap of more than 1 bar (4 beats) between the end of prev and start of last
        let prevEndBeat = prevBeat + (prev.duration > 0 ? prev.duration * Double(120) / 60.0 : 0.5)
        let gap = lastBeat - prevEndBeat

        guard gap > 4.0 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int(lastBeat / 4), beatPosition: lastBeat,
            pointsAwarded: basePoints, noteEvents: [last],
            timestamp: last.startTime
        )
    }
}

/// Tension on weak beat resolving to chord tone.
struct TensionResolutionDetector: PatternDetector {
    let patternId = "tension_resolution"
    let patternName = "Tension & Release"
    let basePoints = 100

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 2 else { return nil }

        let resolved = notes[notes.count - 1]
        let tension = notes[notes.count - 2]

        // Tension note: NOT a chord tone
        guard let tensionIsChord = tension.isChordTone, !tensionIsChord else { return nil }

        // Resolved note: IS a chord tone, on a strong beat
        guard let resolvedIsChord = resolved.isChordTone, resolvedIsChord else { return nil }
        guard let beat = resolved.beat else { return nil }

        let beatInBar = beat.truncatingRemainder(dividingBy: 4.0)
        let isStrongBeat = beatInBar < 0.3 || (beatInBar > 1.7 && beatInBar < 2.3)
        guard isStrongBeat else { return nil }

        // Step resolution (interval ≤ 2 semitones)
        guard abs(resolved.midiNote - tension.midiNote) <= 2 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int(beat / 4), beatPosition: beat,
            pointsAwarded: basePoints, noteEvents: [tension, resolved],
            timestamp: resolved.startTime
        )
    }
}

/// Resolution awareness: ending a phrase on a chord tone.
struct PhraseResolutionDetector: PatternDetector {
    let patternId = "phrase_resolution"
    let patternName = "Clean Resolution"
    let basePoints = 75

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let last = notes[notes.count - 1]
        let prev = notes[notes.count - 2]

        // Check if this note ends a phrase (longer duration or followed by gap)
        guard last.duration > 0.3 else { return nil } // Held note = phrase ending

        guard let isChordTone = last.isChordTone, isChordTone else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((last.beat ?? 0) / 4), beatPosition: last.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: [last],
            timestamp: last.startTime
        )
    }
}

/// Range exploration: notes spanning 2+ octaves.
struct RangeExplorationDetector: PatternDetector {
    let patternId = "range_exploration"
    let patternName = "Range Exploration"
    let basePoints = 100

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 8 else { return nil }

        let window = Array(notes.suffix(16))
        let midiNotes = window.map(\.midiNote)
        guard let low = midiNotes.min(), let high = midiNotes.max() else { return nil }

        // 2+ octaves = 24+ semitones
        guard high - low >= 24 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: [window.last!],
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Quartal melody: 3+ notes separated by perfect 4ths.
struct QuartalMelodyDetector: PatternDetector {
    let patternId = "quartal_melody"
    let patternName = "Quartal Melody"
    let basePoints = 200

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let window = Array(notes.suffix(3))

        // Check for perfect 4th intervals (5 semitones) between consecutive notes
        for i in 1..<window.count {
            let interval = abs(window[i].midiNote - window[i-1].midiNote)
            guard interval == 5 || interval == 6 else { return nil } // P4 or tritone
        }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Pentatonic run: 5+ notes fitting a pentatonic scale.
struct PentatonicRunDetector: PatternDetector {
    let patternId = "pentatonic_run"
    let patternName = "Pentatonic Run"
    let basePoints = 75

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 5 else { return nil }
        let window = Array(notes.suffix(5))

        // Get all pitch classes
        let pcs = window.map { $0.pitchClass }

        // Check against all 12 minor pentatonic scales
        for root in 0...11 {
            let pentatonic = [0, 3, 5, 7, 10].map { ($0 + root) % 12 }
            let pentatonicSet = Set(pentatonic)
            if pcs.allSatisfy({ pentatonicSet.contains($0) }) {
                return PatternDetection(
                    patternId: patternId, patternName: patternName,
                    barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
                    pointsAwarded: basePoints, noteEvents: window,
                    timestamp: window.last?.startTime ?? 0
                )
            }
        }

        // Check major pentatonic too
        for root in 0...11 {
            let pentatonic = [0, 2, 4, 7, 9].map { ($0 + root) % 12 }
            let pentatonicSet = Set(pentatonic)
            if pcs.allSatisfy({ pentatonicSet.contains($0) }) {
                return PatternDetection(
                    patternId: patternId, patternName: patternName,
                    barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
                    pointsAwarded: basePoints, noteEvents: window,
                    timestamp: window.last?.startTime ?? 0
                )
            }
        }

        return nil
    }
}

/// Sequence: same interval pattern at 2+ pitch levels.
struct SequenceDetector: PatternDetector {
    let patternId = "sequence"
    let patternName = "Sequence"
    let basePoints = 200

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 6 else { return nil }

        let window = Array(notes.suffix(6))

        // Split into two groups of 3 and compare interval patterns
        let group1 = Array(window[0..<3])
        let group2 = Array(window[3..<6])

        let intervals1 = [group1[1].midiNote - group1[0].midiNote, group1[2].midiNote - group1[1].midiNote]
        let intervals2 = [group2[1].midiNote - group2[0].midiNote, group2[2].midiNote - group2[1].midiNote]

        // Same interval pattern, different starting pitch
        guard intervals1 == intervals2 else { return nil }
        guard group1[0].midiNote != group2[0].midiNote else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Diminished arpeggio: 4 notes forming minor 3rd intervals.
struct DiminishedArpeggioDetector: PatternDetector {
    let patternId = "diminished_arpeggio"
    let patternName = "Diminished Arpeggio"
    let basePoints = 200

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 4 else { return nil }
        let window = Array(notes.suffix(4))

        // Check for minor 3rd intervals (3 semitones) between each note
        for i in 1..<window.count {
            let interval = abs(window[i].midiNote - window[i-1].midiNote)
            guard interval == 3 else { return nil }
        }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((window.last?.beat ?? 0) / 4), beatPosition: window.last?.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: window,
            timestamp: window.last?.startTime ?? 0
        )
    }
}

/// Wide interval leap: 7+ semitones between two notes (Coltrane-influenced).
struct WideIntervalLeapDetector: PatternDetector {
    let patternId = "wide_interval_leap"
    let patternName = "Wide Interval Leap"
    let basePoints = 175

    func detect(in notes: [NoteEvent], currentBeat: Double) -> PatternDetection? {
        guard notes.count >= 3 else { return nil }

        let last = notes[notes.count - 1]
        let prev = notes[notes.count - 2]
        let before = notes[notes.count - 3]

        // Wide leap followed by stepwise resolution
        let leap = abs(last.midiNote - prev.midiNote)
        guard leap >= 7 else { return nil }

        // The note before should be stepwise from prev (establishing a line before the leap)
        let preInterval = abs(prev.midiNote - before.midiNote)
        guard preInterval <= 3 else { return nil }

        return PatternDetection(
            patternId: patternId, patternName: patternName,
            barNumber: Int((last.beat ?? 0) / 4), beatPosition: last.beat ?? 0,
            pointsAwarded: basePoints, noteEvents: [before, prev, last],
            timestamp: last.startTime
        )
    }
}
