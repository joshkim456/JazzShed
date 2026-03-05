import Foundation
import Observation

/// Converts a stream of pitch frames into discrete NoteEvents.
///
/// Logic: A new note is confirmed when the same MIDI note is detected for
/// `stabilityFrames` frames (3 frames ≈ 69ms at 1024-sample hop / 44.1kHz),
/// tolerating up to `maxGapFrames` (1) glitch frames mid-sequence.
/// A note ends when silence is detected or the pitch changes to a new stable note.
@Observable
final class NoteSegmenter {
    /// Minimum consecutive frames at the same MIDI note to confirm a new note.
    let stabilityFrames = 3

    /// Maximum glitch frames tolerated during candidate confirmation.
    let maxGapFrames = 1

    private var candidateNote: Int = 0
    private var candidateCount: Int = 0
    private var candidateGap: Int = 0
    private var candidateFrequency: Float = 0
    private var candidateAmplitude: Float = 0

    private var activeNote: Int = 0
    private var activeNoteStartTime: TimeInterval = 0
    private var activeNoteFrequency: Float = 0
    private var activeNoteAmplitude: Float = 0

    private(set) var noteEvents: [NoteEvent] = []
    private(set) var currentNote: NoteEvent?

    /// Callback fired when a new note is confirmed.
    var onNoteStart: ((NoteEvent) -> Void)?

    /// Callback fired when a note ends (with final duration).
    var onNoteEnd: ((NoteEvent) -> Void)?

    /// The time reference (e.g. session start time) for computing note timestamps.
    var sessionStartTime: TimeInterval = 0

    /// Current tempo for beat calculation. 0 = don't calculate beats.
    var tempo: Double = 0

    /// Process a pitch frame from PitchDetector.
    /// - Parameters:
    ///   - frequency: Detected frequency (0 = silence)
    ///   - amplitude: Detected amplitude
    ///   - midiNote: MIDI note number (0 = silence)
    func processFrame(frequency: Float, amplitude: Float, midiNote: Int) {
        let now = ProcessInfo.processInfo.systemUptime

        if midiNote == 0 {
            // Silence frame — end active note if any
            endActiveNote(at: now)
            candidateNote = 0
            candidateCount = 0
            candidateGap = 0
            return
        }

        if midiNote == activeNote {
            // Same note continuing — update peak amplitude
            activeNoteAmplitude = max(activeNoteAmplitude, amplitude)
            // Update current note duration
            if var note = currentNote {
                note.duration = now - note.startTime
                currentNote = note
            }
            // Reset candidate since active note is still going
            candidateNote = 0
            candidateCount = 0
            candidateGap = 0
            return
        }

        // Different note detected
        if midiNote == candidateNote {
            candidateCount += 1
            candidateGap = 0
            candidateAmplitude = max(candidateAmplitude, amplitude)
            candidateFrequency = frequency

            if candidateCount >= stabilityFrames {
                // New note confirmed — end previous, start new
                endActiveNote(at: now)
                startNewNote(midiNote: midiNote, frequency: frequency, amplitude: candidateAmplitude, at: now)
                candidateNote = 0
                candidateCount = 0
                candidateGap = 0
            }
        } else if candidateNote != 0 && candidateGap < maxGapFrames {
            // Tolerate a glitch frame — keep candidate alive
            candidateGap += 1
        } else {
            // New candidate
            candidateNote = midiNote
            candidateCount = 1
            candidateGap = 0
            candidateFrequency = frequency
            candidateAmplitude = amplitude
        }
    }

    func reset() {
        let now = ProcessInfo.processInfo.systemUptime
        endActiveNote(at: now)
        candidateNote = 0
        candidateCount = 0
        candidateGap = 0
        noteEvents = []
        currentNote = nil
    }

    private func startNewNote(midiNote: Int, frequency: Float, amplitude: Float, at time: TimeInterval) {
        activeNote = midiNote
        activeNoteStartTime = time
        activeNoteFrequency = frequency
        activeNoteAmplitude = amplitude

        let relativeTime = time - sessionStartTime
        let beat: Double? = tempo > 0 ? (relativeTime / 60.0) * tempo : nil

        let note = NoteEvent(
            midiNote: midiNote,
            frequency: frequency,
            amplitude: amplitude,
            startTime: relativeTime,
            beat: beat
        )
        currentNote = note
        onNoteStart?(note)
    }

    private func endActiveNote(at time: TimeInterval) {
        guard activeNote != 0, var note = currentNote else {
            activeNote = 0
            return
        }

        let relativeTime = time - sessionStartTime
        note.duration = relativeTime - note.startTime
        noteEvents.append(note)
        onNoteEnd?(note)
        currentNote = nil
        activeNote = 0
    }
}
