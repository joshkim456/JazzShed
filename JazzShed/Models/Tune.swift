import Foundation

/// A jazz standard with its chord chart data.
struct Tune: Codable, Identifiable {
    let id: String
    let title: String
    let composer: String
    let originalKey: String
    let form: String              // e.g. "AABA", "Blues", "ABAC"
    let timeSignature: [Int]      // e.g. [4, 4]
    let defaultTempo: Int
    let difficulty: Int           // 1-5
    let sections: [Section]

    struct Section: Codable {
        let label: String         // e.g. "A", "B", "A2"
        let bars: [Bar]
    }

    struct Bar: Codable {
        let chords: [ChordEntry]
    }

    struct ChordEntry: Codable {
        let root: String          // e.g. "C", "Bb", "F#"
        let quality: String       // e.g. "min7", "7", "maj7"
        let beats: Double         // How many beats this chord lasts

        /// Parse into a Chord model.
        func toChord() -> Chord? {
            guard let pc = Chord.parsePitchClass(from: root),
                  let q = ChordQuality(rawValue: quality) else { return nil }
            return Chord(rootPitchClass: pc, quality: q, durationBeats: beats)
        }
    }

    /// Flattens all sections into a single list of chords with absolute beat positions.
    /// Used by the ContextEngine for real-time chord lookup.
    func flattenedChords() -> [(chord: Chord, startBeat: Double, durationBeats: Double)] {
        var result: [(chord: Chord, startBeat: Double, durationBeats: Double)] = []
        var currentBeat: Double = 0

        for section in sections {
            for bar in section.bars {
                for entry in bar.chords {
                    if let chord = entry.toChord() {
                        result.append((chord: chord, startBeat: currentBeat, durationBeats: entry.beats))
                    }
                    currentBeat += entry.beats
                }
            }
        }

        return result
    }

    /// Total number of beats in one chorus.
    var totalBeats: Double {
        var beats: Double = 0
        for section in sections {
            for bar in section.bars {
                for entry in bar.chords {
                    beats += entry.beats
                }
            }
        }
        return beats
    }

    /// Total number of bars.
    var totalBars: Int {
        sections.reduce(0) { $0 + $1.bars.count }
    }

    /// Converts to MIDISequencer chord slots for backing track playback.
    func toMIDISlots() -> [MIDISequencer.ChordSlot] {
        flattenedChords().compactMap { item in
            MIDISequencer.ChordSlot(
                root: item.chord.rootPitchClass,
                quality: item.chord.quality.rawValue,
                startBeat: item.startBeat,
                durationBeats: item.durationBeats
            )
        }
    }
}
