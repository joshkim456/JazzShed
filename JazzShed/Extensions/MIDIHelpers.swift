import Foundation

enum MIDIHelpers {
    /// Note names in chromatic order (sharps only for simplicity)
    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Converts a frequency in Hz to the nearest MIDI note number.
    /// A4 = 440 Hz = MIDI 69
    static func frequencyToMIDI(_ frequency: Float) -> Int {
        guard frequency > 0 else { return 0 }
        let midiFloat = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
        return Int(round(midiFloat))
    }

    /// Converts a MIDI note number to frequency in Hz.
    static func midiToFrequency(_ midiNote: Int) -> Float {
        Float(440.0 * pow(2.0, Double(midiNote - 69) / 12.0))
    }

    /// Returns the note name (e.g. "C#") for a MIDI note number.
    static func noteName(for midiNote: Int) -> String {
        let index = ((midiNote % 12) + 12) % 12
        return noteNames[index]
    }

    /// Returns the octave for a MIDI note number.
    static func octave(for midiNote: Int) -> Int {
        (midiNote / 12) - 1
    }

    /// Returns a full note label like "C#4" for a MIDI note number.
    static func noteLabel(for midiNote: Int) -> String {
        "\(noteName(for: midiNote))\(octave(for: midiNote))"
    }

    /// Returns the pitch class (0-11) for a MIDI note number.
    /// C=0, C#=1, D=2, ... B=11
    static func pitchClass(for midiNote: Int) -> Int {
        ((midiNote % 12) + 12) % 12
    }

    /// Semitone interval between two pitch classes (always 0-11).
    static func interval(from pc1: Int, to pc2: Int) -> Int {
        ((pc2 - pc1) % 12 + 12) % 12
    }
}
