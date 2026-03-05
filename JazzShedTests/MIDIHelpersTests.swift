import Testing
@testable import JazzShed

@Suite("MIDIHelpers Tests")
struct MIDIHelpersTests {
    @Test("A4 = 440Hz = MIDI 69")
    func a4Frequency() {
        let midi = MIDIHelpers.frequencyToMIDI(440.0)
        #expect(midi == 69)
    }

    @Test("C4 = ~261.6Hz = MIDI 60")
    func c4Frequency() {
        let midi = MIDIHelpers.frequencyToMIDI(261.63)
        #expect(midi == 60)
    }

    @Test("MIDI to frequency round-trip")
    func roundTrip() {
        for note in 21...108 {
            let freq = MIDIHelpers.midiToFrequency(note)
            let back = MIDIHelpers.frequencyToMIDI(freq)
            #expect(back == note)
        }
    }

    @Test("Note names")
    func noteNames() {
        #expect(MIDIHelpers.noteName(for: 60) == "C")
        #expect(MIDIHelpers.noteName(for: 69) == "A")
        #expect(MIDIHelpers.noteName(for: 61) == "C#")
    }

    @Test("Note labels include octave")
    func noteLabels() {
        #expect(MIDIHelpers.noteLabel(for: 60) == "C4")
        #expect(MIDIHelpers.noteLabel(for: 69) == "A4")
        #expect(MIDIHelpers.noteLabel(for: 48) == "C3")
    }

    @Test("Pitch class")
    func pitchClass() {
        #expect(MIDIHelpers.pitchClass(for: 60) == 0) // C
        #expect(MIDIHelpers.pitchClass(for: 64) == 4) // E
        #expect(MIDIHelpers.pitchClass(for: 72) == 0) // C (octave up)
    }

    @Test("Interval calculation")
    func intervals() {
        // C to E = 4 semitones (major third)
        #expect(MIDIHelpers.interval(from: 0, to: 4) == 4)
        // E to C = 8 semitones (minor sixth)
        #expect(MIDIHelpers.interval(from: 4, to: 0) == 8)
        // G to C = 5 semitones (perfect fourth)
        #expect(MIDIHelpers.interval(from: 7, to: 0) == 5)
    }
}
