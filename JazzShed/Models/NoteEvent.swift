import Foundation

/// A discrete musical note detected from the audio input.
struct NoteEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let midiNote: Int
    let frequency: Float
    let amplitude: Float
    let startTime: TimeInterval
    var duration: TimeInterval
    let beat: Double?

    // Context fields — filled in by ContextEngine after detection
    var scaleDegree: Int?
    var isChordTone: Bool?
    var chordSymbol: String?

    var noteName: String {
        MIDIHelpers.noteName(for: midiNote)
    }

    var noteLabel: String {
        MIDIHelpers.noteLabel(for: midiNote)
    }

    var pitchClass: Int {
        MIDIHelpers.pitchClass(for: midiNote)
    }

    init(
        midiNote: Int,
        frequency: Float,
        amplitude: Float,
        startTime: TimeInterval,
        duration: TimeInterval = 0,
        beat: Double? = nil
    ) {
        self.id = UUID()
        self.midiNote = midiNote
        self.frequency = frequency
        self.amplitude = amplitude
        self.startTime = startTime
        self.duration = duration
        self.beat = beat
    }
}
