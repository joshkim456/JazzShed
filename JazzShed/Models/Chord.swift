import Foundation

/// A chord in a tune's chord chart.
struct Chord: Codable, Identifiable, Sendable {
    var id: String { "\(rootName)\(quality.symbol)" }

    let rootPitchClass: Int     // 0-11 (C=0, C#=1, ..., B=11)
    let quality: ChordQuality
    let durationBeats: Double   // Typically 2 or 4 in 4/4 time

    /// The root note name (e.g. "C", "F#", "Bb").
    var rootName: String {
        Self.pitchClassToName[rootPitchClass] ?? "?"
    }

    /// Display symbol like "Cm7", "F7", "BbΔ7".
    var symbol: String {
        "\(rootName)\(quality.symbol)"
    }

    /// Returns true if the given pitch class (0-11) is a chord tone.
    func isChordTone(_ pitchClass: Int) -> Bool {
        let interval = MIDIHelpers.interval(from: rootPitchClass, to: pitchClass)
        return quality.chordTones.contains(interval)
    }

    /// Returns true if the given pitch class is a scale tone (chord + passing tones).
    func isScaleTone(_ pitchClass: Int) -> Bool {
        let interval = MIDIHelpers.interval(from: rootPitchClass, to: pitchClass)
        return quality.scaleTones.contains(interval)
    }

    /// Returns the scale degree (semitone interval from root) for a pitch class.
    func scaleDegree(for pitchClass: Int) -> Int {
        MIDIHelpers.interval(from: rootPitchClass, to: pitchClass)
    }

    /// Pitch class name mapping — uses flats for jazz convention.
    static let pitchClassToName: [Int: String] = [
        0: "C", 1: "Db", 2: "D", 3: "Eb", 4: "E", 5: "F",
        6: "Gb", 7: "G", 8: "Ab", 9: "A", 10: "Bb", 11: "B"
    ]

    /// Parse a root name to pitch class.
    static func parsePitchClass(from name: String) -> Int? {
        let map: [String: Int] = [
            "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3,
            "E": 4, "Fb": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7,
            "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11, "Cb": 11
        ]
        return map[name]
    }
}
