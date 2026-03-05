import Testing
@testable import JazzShed

@Suite("Chord Tests")
struct ChordTests {
    @Test("Chord tone detection for Cmaj7")
    func cmaj7ChordTones() {
        let chord = Chord(rootPitchClass: 0, quality: .major7, durationBeats: 4)
        #expect(chord.isChordTone(0))   // C (root)
        #expect(chord.isChordTone(4))   // E (3rd)
        #expect(chord.isChordTone(7))   // G (5th)
        #expect(chord.isChordTone(11))  // B (7th)
        #expect(!chord.isChordTone(2))  // D (not a chord tone)
    }

    @Test("Scale degree calculation")
    func scaleDegrees() {
        let chord = Chord(rootPitchClass: 7, quality: .dominant7, durationBeats: 4) // G7
        #expect(chord.scaleDegree(for: 7) == 0)   // G = root
        #expect(chord.scaleDegree(for: 11) == 4)  // B = major 3rd
        #expect(chord.scaleDegree(for: 2) == 7)   // D = perfect 5th
        #expect(chord.scaleDegree(for: 5) == 10)  // F = minor 7th
    }

    @Test("Chord symbol display")
    func symbols() {
        let cmaj7 = Chord(rootPitchClass: 0, quality: .major7, durationBeats: 4)
        #expect(cmaj7.symbol == "C\u{0394}7") // CΔ7

        let dm7 = Chord(rootPitchClass: 2, quality: .minor7, durationBeats: 4)
        #expect(dm7.symbol == "Dm7")

        let g7 = Chord(rootPitchClass: 7, quality: .dominant7, durationBeats: 4)
        #expect(g7.symbol == "G7")
    }

    @Test("Pitch class parsing")
    func parsing() {
        #expect(Chord.parsePitchClass(from: "C") == 0)
        #expect(Chord.parsePitchClass(from: "Bb") == 10)
        #expect(Chord.parsePitchClass(from: "F#") == 6)
        #expect(Chord.parsePitchClass(from: "Ab") == 8)
    }
}
