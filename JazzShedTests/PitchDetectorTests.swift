import Testing
import Foundation
@testable import JazzShed

@Suite("PitchDetector YIN Tests")
struct PitchDetectorTests {

    /// Generate a sine wave at the given frequency.
    private func sineWave(frequency: Float, sampleRate: Float = 44100, count: Int = 4096) -> [Float] {
        (0..<count).map { i in
            sinf(2 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    // MARK: - YIN accuracy on pure tones

    @Test("YIN detects A4 (440 Hz)")
    func yinA4() {
        let detector = PitchDetector()
        let frame = sineWave(frequency: 440)
        let detected = detector.yinEstimate(frame)
        #expect(abs(detected - 440) < 5, "Expected ~440 Hz, got \(detected)")
    }

    @Test("YIN detects C4 (261.6 Hz)")
    func yinC4() {
        let detector = PitchDetector()
        let frame = sineWave(frequency: 261.63)
        let detected = detector.yinEstimate(frame)
        #expect(abs(detected - 261.63) < 5, "Expected ~261.6 Hz, got \(detected)")
    }

    @Test("YIN detects E5 (659.3 Hz)")
    func yinE5() {
        let detector = PitchDetector()
        let frame = sineWave(frequency: 659.26)
        let detected = detector.yinEstimate(frame)
        #expect(abs(detected - 659.26) < 5, "Expected ~659.3 Hz, got \(detected)")
    }

    @Test("YIN detects low Bb2 (116.5 Hz) — trumpet low register")
    func yinBb2() {
        let detector = PitchDetector()
        let frame = sineWave(frequency: 116.54)
        let detected = detector.yinEstimate(frame)
        #expect(abs(detected - 116.54) < 5, "Expected ~116.5 Hz, got \(detected)")
    }

    @Test("YIN detects high C6 (1046.5 Hz)")
    func yinC6() {
        let detector = PitchDetector()
        let frame = sineWave(frequency: 1046.5)
        let detected = detector.yinEstimate(frame)
        #expect(abs(detected - 1046.5) < 10, "Expected ~1046.5 Hz, got \(detected)")
    }

    @Test("YIN returns 0 for silence")
    func yinSilence() {
        let detector = PitchDetector()
        let frame = [Float](repeating: 0, count: 4096)
        let detected = detector.yinEstimate(frame)
        #expect(detected == 0, "Expected 0 for silence, got \(detected)")
    }

    // MARK: - Eighth notes at 130 BPM through full pipeline

    @Test("Segmenter detects eighth notes at 130 BPM")
    func eighthNotesAt130BPM() {
        let sampleRate: Float = 44100
        let bpm = 130.0
        let eighthNoteDuration = 60.0 / bpm / 2  // ~0.2308 seconds
        let framesPerNote = Int(eighthNoteDuration / (1024.0 / Double(sampleRate)))  // ~10 frames

        let detector = PitchDetector()
        detector.sampleRate = sampleRate

        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var endedNotes: [NoteEvent] = []
        segmenter.onNoteEnd = { endedNotes.append($0) }

        // Play 4 eighth notes: C4 → D4 → E4 → F4
        let frequencies: [Float] = [261.63, 293.66, 329.63, 349.23]
        let expectedMIDI = [60, 62, 64, 65]

        for (noteIndex, freq) in frequencies.enumerated() {
            for _ in 0..<framesPerNote {
                // Generate a 4096-sample sine wave and run YIN
                let frame = sineWave(frequency: freq, sampleRate: sampleRate, count: 4096)
                let detectedFreq = detector.yinEstimate(frame)
                let midi = detectedFreq > 20 ? MIDIHelpers.frequencyToMIDI(detectedFreq) : 0
                let amplitude: Float = 0.5

                segmenter.processFrame(frequency: detectedFreq, amplitude: amplitude, midiNote: midi)
            }
        }

        // Silence to end the last note
        segmenter.processFrame(frequency: 0, amplitude: 0, midiNote: 0)

        #expect(endedNotes.count == 4,
                "Expected 4 notes, got \(endedNotes.count): \(endedNotes.map { MIDIHelpers.noteLabel(for: $0.midiNote) })")

        for (i, note) in endedNotes.enumerated() {
            #expect(note.midiNote == expectedMIDI[i],
                    "Note \(i): expected MIDI \(expectedMIDI[i]), got \(note.midiNote)")
        }
    }

    // MARK: - Onset detection

    @Test("No onset on steady-state signal")
    func noOnsetOnSteadyState() {
        let detector = PitchDetector()
        detector.initializeBuffers()

        var onsetCount = 0
        // Feed 10 identical 1024-sample sine frames — should see at most 1 onset (first frame)
        for _ in 0..<10 {
            let frame = sineWave(frequency: 440, count: 1024)
            detector.totalSamplesProcessed += 1024
            if detector.detectOnset(frame[0..<1024]) {
                onsetCount += 1
            }
        }
        #expect(onsetCount <= 1, "Steady-state signal should produce at most 1 onset (first frame), got \(onsetCount)")
    }

    @Test("Onset fires on frequency change")
    func onsetOnFrequencyChange() {
        let detector = PitchDetector()
        detector.initializeBuffers()

        // Prime with 10 frames of 440 Hz to stabilize the flux history
        for _ in 0..<10 {
            let frame = sineWave(frequency: 440, count: 1024)
            detector.totalSamplesProcessed += 1024
            _ = detector.detectOnset(frame[0..<1024])
        }

        // Now switch to 880 Hz — should trigger an onset
        // Advance enough samples to clear inter-onset minimum
        detector.totalSamplesProcessed += 3000
        let newFrame = sineWave(frequency: 880, count: 1024)
        let onset = detector.detectOnset(newFrame[0..<1024])
        #expect(onset, "Expected onset when frequency changes from 440 to 880 Hz")
    }

    @Test("Segmenter detects fast sixteenth notes at 200 BPM")
    func sixteenthNotesAt200BPM() {
        let sampleRate: Float = 44100
        let bpm = 200.0
        let sixteenthNoteDuration = 60.0 / bpm / 4  // ~0.075 seconds
        let framesPerNote = Int(sixteenthNoteDuration / (1024.0 / Double(sampleRate)))  // ~3 frames

        let detector = PitchDetector()
        detector.sampleRate = sampleRate

        let segmenter = NoteSegmenter()
        segmenter.sessionStartTime = 0

        var endedNotes: [NoteEvent] = []
        segmenter.onNoteEnd = { endedNotes.append($0) }

        // Play 4 sixteenth notes: C4 → E4 → G4 → C5
        let frequencies: [Float] = [261.63, 329.63, 392.0, 523.25]
        let expectedMIDI = [60, 64, 67, 72]

        for freq in frequencies {
            for _ in 0..<framesPerNote {
                let frame = sineWave(frequency: freq, sampleRate: sampleRate, count: 4096)
                let detectedFreq = detector.yinEstimate(frame)
                let midi = detectedFreq > 20 ? MIDIHelpers.frequencyToMIDI(detectedFreq) : 0
                segmenter.processFrame(frequency: detectedFreq, amplitude: 0.5, midiNote: midi)
            }
        }

        segmenter.processFrame(frequency: 0, amplitude: 0, midiNote: 0)

        #expect(endedNotes.count == 4,
                "Expected 4 notes, got \(endedNotes.count): \(endedNotes.map { MIDIHelpers.noteLabel(for: $0.midiNote) })")

        for (i, note) in endedNotes.enumerated() {
            #expect(note.midiNote == expectedMIDI[i],
                    "Note \(i): expected MIDI \(expectedMIDI[i]), got \(note.midiNote)")
        }
    }
}
