import Testing
@testable import JazzShed

@Suite("NoteSegmenter Tests")
struct NoteSegmenterTests {
    @Test("Stable note produces NoteEvent")
    func stableNote() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var ended: [NoteEvent] = []
        segmenter.onNoteEnd = { ended.append($0) }

        // 3 frames of the same note (exceeds 2-frame stability threshold)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)

        // Silence ends the note
        segmenter.processFrame(frequency: 0, amplitude: 0, midiNote: 0)

        #expect(ended.count == 1)
        #expect(ended[0].midiNote == 69)
        #expect(ended[0].noteName == "A")
    }

    @Test("Unstable pitch doesn't trigger note")
    func unstablePitch() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var ended: [NoteEvent] = []
        segmenter.onNoteEnd = { ended.append($0) }

        // Four different pitches — none repeats within the glitch tolerance window
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 466, amplitude: 0.1, midiNote: 70)
        segmenter.processFrame(frequency: 494, amplitude: 0.1, midiNote: 71)
        segmenter.processFrame(frequency: 523, amplitude: 0.1, midiNote: 72)
        segmenter.processFrame(frequency: 0, amplitude: 0, midiNote: 0)

        #expect(ended.count == 0)
    }

    @Test("Single glitch frame is tolerated")
    func glitchTolerance() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var ended: [NoteEvent] = []
        segmenter.onNoteEnd = { ended.append($0) }

        // Frame 1: D4 candidate starts (count=1)
        segmenter.processFrame(frequency: 293.66, amplitude: 0.1, midiNote: 62)
        // Frame 2: D5 glitch — tolerated (gap=1, candidate stays D4)
        segmenter.processFrame(frequency: 587.33, amplitude: 0.1, midiNote: 74)
        // Frame 3: D4 again — count=2
        segmenter.processFrame(frequency: 293.66, amplitude: 0.1, midiNote: 62)
        // Frame 4: D4 again — count=3, note confirmed
        segmenter.processFrame(frequency: 293.66, amplitude: 0.1, midiNote: 62)
        // Silence ends the note
        segmenter.processFrame(frequency: 0, amplitude: 0, midiNote: 0)

        #expect(ended.count == 1)
        #expect(ended[0].midiNote == 62)
    }

    // MARK: - Onset-triggered tests

    @Test("Onset triggers immediate note transition")
    func onsetImmediateTransition() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var started: [NoteEvent] = []
        var ended: [NoteEvent] = []
        segmenter.onNoteStart = { started.append($0) }
        segmenter.onNoteEnd = { ended.append($0) }

        // Establish active A4 via normal stability path
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        #expect(started.count == 1, "A4 should be active")

        // Onset + B4 → immediate transition (no stability wait)
        segmenter.processFrame(frequency: 493.88, amplitude: 0.1, midiNote: 71, onsetDetected: true)

        #expect(ended.count == 1, "A4 should have ended")
        #expect(ended[0].midiNote == 69)
        #expect(started.count == 2, "B4 should have started")
        #expect(started[1].midiNote == 71)
    }

    @Test("Onset starts note immediately from silence")
    func onsetFromSilence() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var started: [NoteEvent] = []
        segmenter.onNoteStart = { started.append($0) }

        // Onset + A4 from silence → start immediately
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69, onsetDetected: true)

        #expect(started.count == 1, "Note should start immediately with onset")
        #expect(started[0].midiNote == 69)
    }

    @Test("Onset with same note does not split")
    func onsetSameNote() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var ended: [NoteEvent] = []
        segmenter.onNoteEnd = { ended.append($0) }

        // Establish active A4
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)

        // Onset + same A4 → should NOT split the note
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69, onsetDetected: true)

        #expect(ended.count == 0, "Same-note onset should not end the active note")
    }

    @Test("Without onset, normal 2-frame stability still required")
    func noOnsetNormalBehavior() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var started: [NoteEvent] = []
        segmenter.onNoteStart = { started.append($0) }

        // Establish active A4
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        #expect(started.count == 1)

        // Single B4 frame WITHOUT onset → should NOT transition immediately
        segmenter.processFrame(frequency: 493.88, amplitude: 0.1, midiNote: 71, onsetDetected: false)
        #expect(started.count == 1, "Without onset, one frame of different pitch should not start new note")
    }

    @Test("Reset clears state")
    func reset() {
        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)
        segmenter.processFrame(frequency: 440, amplitude: 0.1, midiNote: 69)

        segmenter.reset()

        #expect(segmenter.noteEvents.isEmpty)
        #expect(segmenter.currentNote == nil)
    }
}
