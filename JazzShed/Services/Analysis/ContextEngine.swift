import Foundation

/// Maps beat positions to chords and enriches NoteEvents with harmonic context.
///
/// The context engine holds a flattened, sorted chord timeline and provides
/// O(log n) lookup of the current chord at any beat position. It enriches
/// raw NoteEvents with scale degree, chord tone status, and chord symbol.
final class ContextEngine {
    struct ChordAtBeat {
        let chord: Chord
        let startBeat: Double
        let durationBeats: Double
        let barNumber: Int
    }

    private var timeline: [ChordAtBeat] = []
    private var chorusLengthBeats: Double = 0
    private var choruses: Int = 1

    /// Loads a tune's chord chart into the timeline.
    func loadTune(_ tune: Tune, choruses: Int = 1) {
        self.choruses = choruses
        let flattened = tune.flattenedChords()
        self.chorusLengthBeats = tune.totalBeats

        var barNumber = 0
        var beatsInCurrentBar: Double = 0
        let beatsPerBar: Double = Double(tune.timeSignature[0])

        timeline = flattened.map { item in
            let entry = ChordAtBeat(
                chord: item.chord,
                startBeat: item.startBeat,
                durationBeats: item.durationBeats,
                barNumber: barNumber
            )

            beatsInCurrentBar += item.durationBeats
            if beatsInCurrentBar >= beatsPerBar {
                barNumber += 1
                beatsInCurrentBar -= beatsPerBar
            }

            return entry
        }
    }

    /// Returns the chord at the given absolute beat position (handles chorus wrapping).
    func chordAt(beat: Double) -> ChordAtBeat? {
        guard !timeline.isEmpty, chorusLengthBeats > 0 else { return nil }

        // Wrap to single chorus
        let wrappedBeat = beat.truncatingRemainder(dividingBy: chorusLengthBeats)

        // Binary search
        var lo = 0, hi = timeline.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let entry = timeline[mid]
            if wrappedBeat >= entry.startBeat && wrappedBeat < entry.startBeat + entry.durationBeats {
                return entry
            } else if wrappedBeat < entry.startBeat {
                hi = mid - 1
            } else {
                lo = mid + 1
            }
        }
        return timeline.last
    }

    /// Enriches a NoteEvent with harmonic context based on its beat position.
    func enrich(_ note: inout NoteEvent) {
        guard let beat = note.beat, let context = chordAt(beat: beat) else { return }

        let pc = note.pitchClass
        note.scaleDegree = context.chord.scaleDegree(for: pc)
        note.isChordTone = context.chord.isChordTone(pc)
        note.chordSymbol = context.chord.symbol
    }

    /// Enriches a NoteEvent and returns it (for functional chaining).
    func enriched(_ note: NoteEvent) -> NoteEvent {
        var enriched = note
        enrich(&enriched)
        return enriched
    }

    /// Returns the bar number for a given beat position.
    func barNumber(at beat: Double) -> Int {
        chordAt(beat: beat)?.barNumber ?? 0
    }

    /// Returns the total number of beats in the loaded chart (including all choruses).
    var totalBeats: Double {
        chorusLengthBeats * Double(choruses)
    }

    /// Returns the number of beats in one chorus.
    var beatsPerChorus: Double {
        chorusLengthBeats
    }

    /// Returns all chords in the timeline (one chorus).
    var allChords: [ChordAtBeat] {
        timeline
    }
}
