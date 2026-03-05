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

        // 3 frames of the same note (meets 3-frame stability threshold)
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
