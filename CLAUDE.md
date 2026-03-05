# JazzShed

Duolingo meets iReal Pro — gamifies jazz improvisation practice with real-time pitch detection, harmonic analysis, and vocabulary scoring.

## Tech Stack

- **Language:** Swift 5.9, SwiftUI
- **Target:** iOS 17.0+, Portrait only
- **Persistence:** SwiftData (UserProfile, PracticeSession, Achievement, VocabularyItem, SkillNodeProgress)
- **Audio:** AVFoundation (AVAudioEngine, AVAudioUnitSampler), Accelerate (custom YIN pitch detection)
- **Architecture:** MVVM with `@Observable` / `@MainActor` ViewModels
- **Build:** XcodeGen (`project.yml`), Xcode 16+

## Project Structure

```
JazzShed/
├── App/                    JazzShedApp.swift (entry point, SwiftData container)
├── Models/                 Data types (Tune, NoteEvent, Chord, Pattern, PatternDetection)
│   └── Enums/              ChordQuality (15 types), Difficulty, Instrument (8 with transposition)
├── Services/
│   ├── Audio/              PitchDetector, NoteSegmenter, BackingTrackPlayer, MIDISequencer, StylePatterns
│   ├── Analysis/           ContextEngine, PatternMatcher, ScoreEngine, AdditionalPatternDetectors
│   ├── Data/               TuneLibrary (loads bundled JSONs), SkillTreeData
│   └── Gamification/       StreakManager
├── ViewModels/             SessionViewModel (main conductor), Home, TuneSelection, Results, Stats, SkillTree, Onboarding
├── Views/
│   ├── Play/               ActiveSessionView, ChordChartView, TuneSelectionView, DebugSessionView
│   ├── Results/            ResultsView (post-session breakdown)
│   ├── Home/               HomeView (dashboard)
│   ├── Learn/              SkillTreeView, LickPracticeView
│   ├── Stats/              StatsView
│   ├── Profile/            ProfileView
│   ├── Onboarding/         OnboardingFlow
│   └── Components/         JazzButton, ProgressRing
├── Theme/                  Colors (JazzColors), Spacing, Typography
├── Extensions/             MIDIHelpers (freq↔MIDI, note names), Color+Hex
├── Resources/
│   ├── Tunes/              10 bundled JSON chord charts (Autumn Leaves, Blue Bossa, etc.)
│   ├── SoundFonts/         GeneralUser_GS.sf2 (~30MB GM SoundFont)
│   └── Patterns/           Pattern metadata
└── docs/                   PRD.md, app-flow.md
```

## Core Audio Pipeline

```
Microphone → PitchDetector (YIN autocorrelation via Accelerate, ~23ms frames)
  → NoteSegmenter (3-frame stability threshold → discrete NoteEvents)
  → ContextEngine.enrich() (binary search beat→chord, adds scaleDegree/isChordTone)
  → PatternMatcher (20 detectors, cooldown, overlap resolution)
  → ScoreEngine (classify + score per note, combo multiplier)
  → UI (ActiveSessionView: chord chart, score, combo, pattern popups)
```

Backing track runs on a separate AVAudioEngine with 3 AVAudioUnitSampler nodes (bass/drums/piano) driven by MIDISequencer at tempo-synced tick resolution (~50ms).

## Scoring System

**Per-note points:**
- Chord tone: +10 (x multiplier) | Scale tone: +5 (x multiplier) | Chromatic: 0 | Clashing: -15 penalty + combo break

**Combo multiplier:** 8→2x, 16→3x, 32→4x

**Star rating:** noteChoicePercent + pattern bonus (unique patterns x1.5, max 10). Thresholds: 95+=5★, 80+=4★, 65+=3★, 45+=2★

**Vocabulary score:** unique pattern types x10, max 100% (need 10 unique for full marks)

**Classification:**
- Chord tones = root, 3rd, 5th, 7th of current chord
- Scale tones = diatonic to the chord's parent scale (per ChordQuality.scaleTones)
- Chromatic = b3, b6 only (blue note / common passing tones)
- Clashing = everything else; resolution check requires ≤2 semitone approach to chord tone

## Pattern Detection

20 registered detectors in PatternMatcher (see AdditionalPatternDetectors.swift):
- Basics: Chord Tone on Strong Beat, Chromatic Approach ↑/↓, Simple Enclosure, Arpeggio
- Advanced: Bebop Scale Run, Diatonic Enclosure, Double Chromatic, Digital 1-2-3-5, Blue Note
- Complex: Guide Tone, Quartal Melody, Pentatonic Run, Sequence, Diminished Arpeggio, Wide Interval Leap
- Meta: Space, Tension & Resolution, Phrase Resolution, Range Exploration

Each detector: `PatternDetector` protocol → `detect(in: [NoteEvent], currentBeat:) -> PatternDetection?`
Cooldown: 2 beats between same pattern type. Overlap: highest-scoring wins.

## Tune Format (JSON)

```json
{
  "id": "autumn-leaves",
  "title": "Autumn Leaves",
  "composer": "Joseph Kosma",
  "originalKey": "Gm",
  "form": "AABA",
  "timeSignature": [4, 4],
  "defaultTempo": 140,
  "difficulty": 2,
  "sections": [
    {
      "label": "A1",
      "bars": [
        { "chords": [{ "root": "C", "quality": "min7", "beats": 4 }] },
        { "chords": [{ "root": "G", "quality": "min7", "beats": 2 }, { "root": "C", "quality": "7", "beats": 2 }] }
      ]
    }
  ]
}
```

Sections contain bars; bars contain 1+ chords (supports half-bar changes). `Tune.toMIDISlots()` flattens to sequencer format.

## SwiftData Models

- **UserProfile:** instrument, experienceLevel, dailyGoalMinutes, streaks, totalXP, preferences
- **PracticeSession:** tuneId, score, starRating, noteChoicePercent, maxCombo, duration, JSON blobs for patterns/notes
- **Achievement, VocabularyItem, SkillNodeProgress:** gamification tracking

## Key Files for Common Tasks

| Task | Files |
|------|-------|
| Change scoring | `Services/Analysis/ScoreEngine.swift` |
| Add pattern detector | `Services/Analysis/AdditionalPatternDetectors.swift`, register in `PatternMatcher.swift` |
| Modify backing track style | `Services/Audio/StylePatterns.swift`, `MIDISequencer.swift` |
| Add a tune | `Resources/Tunes/<name>.json`, add to Xcode resources |
| Change chord chart UI | `Views/Play/ChordChartView.swift` |
| Session lifecycle | `ViewModels/SessionViewModel.swift` (main conductor) |
| Results screen | `ViewModels/ResultsViewModel.swift`, `Views/Results/ResultsView.swift` |
| Theme/colors | `Theme/Colors.swift` (JazzColors enum, dark theme) |

## Tests

14 tests across 3 files (Swift Testing `@Test` macro):
- `ChordTests` — chord tone detection, scale degrees, symbol display, pitch class parsing
- `NoteSegmenterTests` — stable note emission, jitter rejection, reset
- `MIDIHelpersTests` — frequency↔MIDI conversion, note names, intervals

Run: `xcodebuild test -scheme JazzShed -destination 'platform=iOS Simulator,name=iPhone 16'`

## Dependencies

- **GeneralUser_GS.sf2** — GM SoundFont for backing track instruments (bass program 32, drums bank 128, piano program 0)

No external SPM dependencies. Pitch detection uses custom YIN algorithm with Apple's Accelerate framework. Uses stdlib for MIDI math, JSON parsing, observation.
