import Foundation

/// Defines rhythmic and melodic templates for backing track generation.
/// Each style pattern describes how bass, drums, and comping behave per bar.
/// The sequencer randomly picks a variant each bar for musical variety.
enum SwingStyle {
    /// A walking bass note event within a bar.
    struct BassNote {
        let beat: Double      // Beat position (1-based: 1.0, 2.0, 3.0, 4.0)
        let degree: Int       // Scale degree relative to chord root (0 = root, 7 = fifth, etc.)
        let velocity: UInt8   // MIDI velocity
        let isApproach: Bool  // If true, use chromatic approach to next chord root
    }

    /// A drum hit within a bar.
    struct DrumHit {
        let beat: Double
        let note: UInt8       // GM drum map note
        let velocity: UInt8
    }

    /// A comping chord voicing hit.
    struct CompHit {
        let beat: Double
        let velocity: UInt8
    }

    // MARK: - GM Drum Map constants
    static let kickDrum: UInt8 = 36
    static let snareDrum: UInt8 = 38
    static let crossStick: UInt8 = 37
    static let closedHiHat: UInt8 = 42
    static let openHiHat: UInt8 = 46
    static let rideCymbal: UInt8 = 51
    static let rideBell: UInt8 = 53
    static let crashCymbal: UInt8 = 49

    // MARK: - Walking Bass Variants

    /// 4 walking bass patterns — all quarter notes (beats 1-4), varying the middle notes.
    static let bassVariants: [[BassNote]] = [
        // 1. Root → 5th → Root → Approach (original)
        [
            BassNote(beat: 1.0, degree: 0, velocity: 100, isApproach: false),
            BassNote(beat: 2.0, degree: 7, velocity: 90, isApproach: false),
            BassNote(beat: 3.0, degree: 0, velocity: 95, isApproach: false),
            BassNote(beat: 4.0, degree: 0, velocity: 85, isApproach: true),
        ],
        // 2. Root → 3rd → 5th → Approach
        [
            BassNote(beat: 1.0, degree: 0, velocity: 100, isApproach: false),
            BassNote(beat: 2.0, degree: 3, velocity: 90, isApproach: false),
            BassNote(beat: 3.0, degree: 7, velocity: 95, isApproach: false),
            BassNote(beat: 4.0, degree: 0, velocity: 85, isApproach: true),
        ],
        // 3. Root → 5th → 3rd → Approach
        [
            BassNote(beat: 1.0, degree: 0, velocity: 100, isApproach: false),
            BassNote(beat: 2.0, degree: 7, velocity: 90, isApproach: false),
            BassNote(beat: 3.0, degree: 3, velocity: 95, isApproach: false),
            BassNote(beat: 4.0, degree: 0, velocity: 85, isApproach: true),
        ],
        // 4. Root → 4th → 5th → Approach
        [
            BassNote(beat: 1.0, degree: 0, velocity: 100, isApproach: false),
            BassNote(beat: 2.0, degree: 4, velocity: 90, isApproach: false),
            BassNote(beat: 3.0, degree: 7, velocity: 95, isApproach: false),
            BassNote(beat: 4.0, degree: 0, velocity: 85, isApproach: true),
        ],
    ]

    // MARK: - Swing Drum Variants

    /// Base ride cymbal swing pattern shared by all drum variants.
    private static let ridePattern: [DrumHit] = [
        DrumHit(beat: 1.0,   note: rideCymbal, velocity: 100),
        DrumHit(beat: 2.0,   note: rideCymbal, velocity: 90),
        DrumHit(beat: 2.667, note: rideCymbal, velocity: 70),  // Swing eighth
        DrumHit(beat: 3.0,   note: rideCymbal, velocity: 95),
        DrumHit(beat: 4.0,   note: rideCymbal, velocity: 90),
        DrumHit(beat: 4.667, note: rideCymbal, velocity: 70),  // Swing eighth
    ]

    /// Hi-hat foot on 2 & 4, shared by all drum variants.
    private static let hiHatPattern: [DrumHit] = [
        DrumHit(beat: 2.0, note: closedHiHat, velocity: 80),
        DrumHit(beat: 4.0, note: closedHiHat, velocity: 80),
    ]

    /// 4 drum pattern variants — all share ride + hi-hat base, adding kicks/snare/cross-stick.
    static let drumVariants: [[DrumHit]] = [
        // 1. Base only — clean ride + hi-hat (original)
        ridePattern + hiHatPattern,
        // 2. Base + kick on beat 1
        ridePattern + hiHatPattern + [
            DrumHit(beat: 1.0, note: kickDrum, velocity: 85),
        ],
        // 3. Base + kick on 1, ghost snare on "and" of 2
        ridePattern + hiHatPattern + [
            DrumHit(beat: 1.0, note: kickDrum, velocity: 85),
            DrumHit(beat: 2.667, note: snareDrum, velocity: 40),  // Ghost note
        ],
        // 4. Base + kick on 1, cross-stick on 4
        ridePattern + hiHatPattern + [
            DrumHit(beat: 1.0, note: kickDrum, velocity: 85),
            DrumHit(beat: 4.0, note: crossStick, velocity: 65),
        ],
    ]

    // MARK: - Piano Comping Variants

    /// 4 comping patterns varying rhythmic placement.
    static let compVariants: [[CompHit]] = [
        // 1. Beats 2 & 4 — Freddie Green (original)
        [
            CompHit(beat: 2.0, velocity: 75),
            CompHit(beat: 4.0, velocity: 75),
        ],
        // 2. Beat 2 only + anticipation on "and" of 4
        [
            CompHit(beat: 2.0, velocity: 75),
            CompHit(beat: 4.667, velocity: 70),
        ],
        // 3. Beats 1 & 3 — Charleston rhythm variation
        [
            CompHit(beat: 1.0, velocity: 70),
            CompHit(beat: 3.0, velocity: 70),
        ],
        // 4. "And" of 1 + beat 4
        [
            CompHit(beat: 1.667, velocity: 70),
            CompHit(beat: 4.0, velocity: 75),
        ],
    ]

    // MARK: - Rootless Voicings

    /// Jazz piano rootless voicings — omit the root (bass has it), include the 9th.
    /// Type A: 3rd on bottom. Type B: 7th on bottom.
    /// Intervals are semitones relative to the root.
    enum RootlessVoicing {
        /// Type A voicings (3rd on bottom): [3, 5, 7, 9]
        static let typeA: [String: [Int]] = [
            "maj7":    [4, 7, 11, 14],   // 3, 5, 7, 9
            "min7":    [3, 7, 10, 14],   // b3, 5, b7, 9
            "m7":      [3, 7, 10, 14],
            "7":       [4, 9, 10, 14],   // 3, 13, b7, 9
            "dom7":    [4, 9, 10, 14],
            "min7b5":  [3, 6, 10, 14],   // b3, b5, b7, 9
            "m7b5":    [3, 6, 10, 14],
        ]

        /// Type B voicings (7th on bottom): [7, 9, 3, 5]
        static let typeB: [String: [Int]] = [
            "maj7":    [-1, 2, 4, 7],    // 7, 9, 3, 5
            "min7":    [-2, 2, 3, 7],    // b7, 9, b3, 5
            "m7":      [-2, 2, 3, 7],
            "7":       [-2, 2, 4, 9],    // b7, 9, 3, 13
            "dom7":    [-2, 2, 4, 9],
            "min7b5":  [-2, 2, 3, 6],    // b7, 9, b3, b5
            "m7b5":    [-2, 2, 3, 6],
        ]
    }

    // MARK: - Velocity Humanization

    /// Adds random velocity variation (±10) to simulate human feel.
    static func humanize(_ velocity: UInt8, range: Int = 10) -> UInt8 {
        let offset = Int.random(in: -range...range)
        return UInt8(clamping: Int(velocity) + offset)
    }

    // MARK: - Approach Note Direction

    /// Randomly picks chromatic approach from above or below.
    static func approachDirection() -> Int {
        Bool.random() ? -1 : 1  // -1 = half step below, +1 = half step above
    }

    // MARK: - Drop-2 Voicings

    /// Converts a close-position voicing to drop-2 by dropping the 2nd-from-top note
    /// down an octave. This is the standard jazz piano voicing.
    ///
    /// Example: Cmaj7 close = [C4, E4, G4, B4] → drop-2 = [G3, C4, E4, B4]
    static func drop2(_ closeVoicing: [UInt8]) -> [UInt8] {
        guard closeVoicing.count >= 3 else { return closeVoicing }
        var result = closeVoicing
        let dropIndex = result.count - 2  // 2nd from top
        result[dropIndex] = result[dropIndex] &- 12  // Down one octave (wrapping subtraction)
        result.sort()
        return result
    }
}
