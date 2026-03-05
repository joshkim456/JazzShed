import Foundation

/// Static skill tree data — defines the learning path structure.
enum SkillTreeData {
    struct Level: Identifiable {
        let id: Int
        let title: String
        let nodes: [SkillNode]
    }

    struct SkillNode: Identifiable {
        let id: String
        let title: String
        let description: String
        let conceptExplanation: String
        let licks: [Lick]
        let relatedPatternIds: [String]
        let prerequisiteNodeIds: [String]
    }

    struct Lick: Identifiable {
        let id: String
        let title: String
        let description: String
        let targetPatternId: String
        let exampleNotes: String          // Simple text representation (e.g. "C Db D E")
        let defaultChordQuality: String   // Chord to practice over
        let defaultRootPitchClass: Int    // Root pitch class (C=0, D=2, G=7, etc.)
    }

    // MARK: - Level 1: Foundations

    static let level1 = Level(id: 1, title: "Foundations", nodes: [
        SkillNode(
            id: "scales",
            title: "Major Scales & Modes",
            description: "Build fluency in all 12 major scales and common modes.",
            conceptExplanation: "Scales are the raw material of melody. In jazz, you'll use different modes (Dorian, Mixolydian, Lydian) depending on the chord type. Dorian over minor 7th, Mixolydian over dominant 7th, Ionian/Lydian over major 7th. The goal isn't to play scales up and down — it's to internalize them so deeply that you can start and end on any note.",
            licks: [
                Lick(id: "scales-1", title: "Dorian Scale", description: "Play Dorian mode ascending and descending over a minor 7th chord", targetPatternId: "chord_tone_strong_beat", exampleNotes: "D E F G A B C D", defaultChordQuality: "min7", defaultRootPitchClass: 2),
                Lick(id: "scales-2", title: "Mixolydian Scale", description: "Play Mixolydian mode over a dominant 7th chord", targetPatternId: "chord_tone_strong_beat", exampleNotes: "G A B C D E F G", defaultChordQuality: "7", defaultRootPitchClass: 7),
                Lick(id: "scales-3", title: "Ionian Scale", description: "Play Ionian (major) mode over a major 7th chord", targetPatternId: "chord_tone_strong_beat", exampleNotes: "C D E F G A B C", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
            ],
            relatedPatternIds: ["chord_tone_strong_beat"],
            prerequisiteNodeIds: []
        ),

        SkillNode(
            id: "chord-tones",
            title: "Basic Chord Tones",
            description: "Learn to target 1-3-5-7 of each chord type.",
            conceptExplanation: "Chord tones (root, 3rd, 5th, 7th) are the strongest notes you can play over any chord. They define the harmony. When you land a chord tone on a strong beat (beats 1 or 3), it sounds like you really know the changes. Start by simply arpeggiating each chord, then practice landing chord tones on downbeats while playing freely between them.",
            licks: [
                Lick(id: "ct-1", title: "Major 7th Arpeggio", description: "Arpeggiate 1-3-5-7 over major 7th chords", targetPatternId: "arpeggio_1357", exampleNotes: "C E G B", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "ct-2", title: "Minor 7th Arpeggio", description: "Arpeggiate 1-b3-5-b7 over minor 7th chords", targetPatternId: "arpeggio_1357", exampleNotes: "D F A C", defaultChordQuality: "min7", defaultRootPitchClass: 2),
                Lick(id: "ct-3", title: "Dominant 7th Arpeggio", description: "Arpeggiate 1-3-5-b7 over dominant 7th chords", targetPatternId: "arpeggio_1357", exampleNotes: "G B D F", defaultChordQuality: "7", defaultRootPitchClass: 7),
                Lick(id: "ct-4", title: "Half-Diminished Arpeggio", description: "Arpeggiate 1-b3-b5-b7 over minor 7b5 chords", targetPatternId: "arpeggio_1357", exampleNotes: "B D F A", defaultChordQuality: "min7b5", defaultRootPitchClass: 11),
            ],
            relatedPatternIds: ["arpeggio_1357", "chord_tone_strong_beat"],
            prerequisiteNodeIds: ["scales"]
        ),

        SkillNode(
            id: "ii-v-i-basic",
            title: "Simple ii-V-I Patterns",
            description: "Learn basic two-five-one patterns — the most common progression in jazz.",
            conceptExplanation: "The ii-V-I is the backbone of jazz harmony. In C major: Dm7 → G7 → Cmaj7. Learning to navigate this progression smoothly is the single most important skill in jazz improvisation. Start by playing the arpeggios of each chord in sequence, then connect them with stepwise motion. The 7th of one chord resolves down to the 3rd of the next — this is called 'guide tone voice leading'.",
            licks: [
                Lick(id: "251-1", title: "Arpeggio Connection", description: "Connect ii-V-I arpeggios with smooth voice leading", targetPatternId: "chord_tone_strong_beat", exampleNotes: "D F A C → B D F G → C E G B", defaultChordQuality: "min7", defaultRootPitchClass: 2),
                Lick(id: "251-2", title: "Scale-wise ii-V-I", description: "Descending scale line through ii-V-I", targetPatternId: "chord_tone_strong_beat", exampleNotes: "A G F E D C B C", defaultChordQuality: "min7", defaultRootPitchClass: 2),
                Lick(id: "251-3", title: "Guide Tone Line", description: "Follow the 3rds and 7ths through the progression", targetPatternId: "chord_tone_strong_beat", exampleNotes: "F C → B F → E B", defaultChordQuality: "min7", defaultRootPitchClass: 2),
            ],
            relatedPatternIds: ["chord_tone_strong_beat", "arpeggio_1357"],
            prerequisiteNodeIds: ["chord-tones"]
        ),

        SkillNode(
            id: "blues",
            title: "Blues Scale Vocabulary",
            description: "Learn blues scale patterns and blue note usage.",
            conceptExplanation: "The blues scale (1-b3-4-b5-5-b7) adds soul and grit to your playing. Blue notes — especially the b3, b5, and b7 — create tension that's deeply rooted in the blues tradition. The magic is in mixing the blues scale with the chord tones of the underlying harmony. Try bending between the b3 and natural 3, or using the b5 as a passing tone between 4 and 5.",
            licks: [
                Lick(id: "blues-1", title: "Blues Scale Run", description: "Play the blues scale ascending and descending", targetPatternId: "chord_tone_strong_beat", exampleNotes: "C Eb F Gb G Bb C", defaultChordQuality: "7", defaultRootPitchClass: 0),
                Lick(id: "blues-2", title: "b3 to 3 Curl", description: "Bend from minor 3rd to major 3rd — the classic blues sound", targetPatternId: "chord_tone_strong_beat", exampleNotes: "Eb E G", defaultChordQuality: "7", defaultRootPitchClass: 0),
                Lick(id: "blues-3", title: "Blue Fifth Passing", description: "Use the b5 as a chromatic passing tone", targetPatternId: "chromatic_approach_below", exampleNotes: "F Gb G", defaultChordQuality: "7", defaultRootPitchClass: 0),
            ],
            relatedPatternIds: ["chord_tone_strong_beat", "chromatic_approach_below"],
            prerequisiteNodeIds: ["scales"]
        ),
    ])

    // MARK: - Level 2: Core Vocabulary

    static let level2 = Level(id: 2, title: "Core Vocabulary", nodes: [
        SkillNode(
            id: "bebop-scales",
            title: "Bebop Scales",
            description: "Add the chromatic passing tone that makes chord tones land on downbeats.",
            conceptExplanation: "The bebop scale adds one chromatic note to a 7-note scale, creating an 8-note scale that naturally aligns chord tones with strong beats when played in continuous 8th notes. The bebop dominant scale adds a natural 7 to Mixolydian; the bebop major adds #5 to Ionian. This is the secret weapon of bebop players — it's why Charlie Parker's lines sound so effortlessly 'right'.",
            licks: [
                Lick(id: "bebop-1", title: "Bebop Dominant Scale", description: "Descending bebop dominant scale from the root", targetPatternId: "chord_tone_strong_beat", exampleNotes: "G F E D C B Bb A G", defaultChordQuality: "7", defaultRootPitchClass: 7),
                Lick(id: "bebop-2", title: "Bebop Scale from 3rd", description: "Start the bebop scale from the 3rd of the chord", targetPatternId: "chord_tone_strong_beat", exampleNotes: "B A G F E D C B", defaultChordQuality: "7", defaultRootPitchClass: 7),
                Lick(id: "bebop-3", title: "Bebop Major Scale", description: "Descending bebop major scale", targetPatternId: "chord_tone_strong_beat", exampleNotes: "C B Bb A G F E D C", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
            ],
            relatedPatternIds: ["chord_tone_strong_beat"],
            prerequisiteNodeIds: ["chord-tones"]
        ),

        SkillNode(
            id: "approach-notes",
            title: "Approach Notes",
            description: "Master chromatic and diatonic approaches to chord tones.",
            conceptExplanation: "Approach notes are the glue of bebop. They create momentum by leading into chord tones from a half step (chromatic) or whole step (diatonic) above or below. The approach note itself might be 'wrong' on paper — it's not a chord tone or even a scale tone — but it sounds right because it resolves immediately. Think of it like a doorbell: the note doesn't matter, it's where you end up.",
            licks: [
                Lick(id: "app-1", title: "Chromatic Below", description: "Approach a chord tone from a half step below", targetPatternId: "chromatic_approach_below", exampleNotes: "B C (targeting C over Cmaj7)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "app-2", title: "Chromatic Above", description: "Approach a chord tone from a half step above", targetPatternId: "chromatic_approach_above", exampleNotes: "Db C (targeting C over Cmaj7)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "app-3", title: "Double Chromatic", description: "Two chromatic notes approaching from below", targetPatternId: "double_chromatic_approach", exampleNotes: "A# B C (targeting C)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "app-4", title: "Diatonic Approach", description: "Approach from a scale step above", targetPatternId: "chromatic_approach_above", exampleNotes: "D C (over Cmaj7, D is the 9th)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
            ],
            relatedPatternIds: ["chromatic_approach_below", "chromatic_approach_above", "double_chromatic_approach"],
            prerequisiteNodeIds: ["bebop-scales"]
        ),

        SkillNode(
            id: "enclosures",
            title: "Enclosures",
            description: "Surround chord tones from above and below before resolving.",
            conceptExplanation: "An enclosure 'surrounds' a target chord tone by approaching from both above and below before landing on it. Simple enclosure: half step above → half step below → target (e.g., Db-B-C targeting C). This creates a moment of beautiful tension before resolution. Enclosures are one of the most recognizable sounds in bebop — once you hear them, you'll notice them everywhere in Parker, Dizzy, and Cannonball.",
            licks: [
                Lick(id: "enc-1", title: "Simple Enclosure (above first)", description: "Half step above, half step below, target", targetPatternId: "simple_enclosure", exampleNotes: "Db B C (enclosing C)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "enc-2", title: "Simple Enclosure (below first)", description: "Half step below, half step above, target", targetPatternId: "simple_enclosure", exampleNotes: "B Db C (enclosing C)", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "enc-3", title: "Enclosure to 3rd", description: "Enclose the 3rd of a minor 7th chord", targetPatternId: "simple_enclosure", exampleNotes: "Gb E F (enclosing F, 3rd of Dm7)", defaultChordQuality: "min7", defaultRootPitchClass: 2),
                Lick(id: "enc-4", title: "Enclosure to 5th", description: "Enclose the 5th of a dominant chord", targetPatternId: "simple_enclosure", exampleNotes: "Eb C# D (enclosing D, 5th of G7)", defaultChordQuality: "7", defaultRootPitchClass: 7),
            ],
            relatedPatternIds: ["simple_enclosure"],
            prerequisiteNodeIds: ["approach-notes"]
        ),

        SkillNode(
            id: "turnarounds",
            title: "Turnaround Patterns",
            description: "Navigate I-vi-ii-V turnarounds with confidence.",
            conceptExplanation: "A turnaround (I-vi-ii-V, e.g., C-Am-Dm-G7 in key of C) cycles back to the top of a form. It's the musical equivalent of a period at the end of a sentence. You'll encounter turnarounds at the end of almost every standard's A section. The key to playing turnarounds well is smooth voice leading — move the minimum distance between chord tones of each chord.",
            licks: [
                Lick(id: "turn-1", title: "Arpeggio Turnaround", description: "Arpeggiate through each chord of the turnaround", targetPatternId: "arpeggio_1357", exampleNotes: "C E G A → A C E G → D F A C → G B D F", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "turn-2", title: "Guide Tone Turnaround", description: "Follow 3rds and 7ths through the turnaround", targetPatternId: "chord_tone_strong_beat", exampleNotes: "E B → C G → F C → B F → E", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
                Lick(id: "turn-3", title: "Chromatic Turnaround", description: "Use chromatic approaches in the turnaround", targetPatternId: "chromatic_approach_below", exampleNotes: "G# A → E → Db D → F# G → B C", defaultChordQuality: "maj7", defaultRootPitchClass: 0),
            ],
            relatedPatternIds: ["chord_tone_strong_beat", "arpeggio_1357", "chromatic_approach_below"],
            prerequisiteNodeIds: ["ii-v-i-basic"]
        ),
    ])

    static let allLevels: [Level] = [level1, level2]

    /// Flat list of all skill nodes across all levels.
    static var allNodes: [SkillNode] {
        allLevels.flatMap(\.nodes)
    }

    /// Lookup a node by ID.
    static func node(id: String) -> SkillNode? {
        allNodes.first { $0.id == id }
    }
}
