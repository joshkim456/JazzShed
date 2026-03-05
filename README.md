# JazzShed

**Duolingo meets iReal Pro** — a gamified jazz improvisation practice app that listens to you play in real time, detects jazz vocabulary patterns, and scores your musicality.

Pick a standard, play along with a backing track, and JazzShed tells you what you're doing well, what patterns you're using, and where you can grow — like a supportive bandmate who's really listening.

## Features

### Real-Time Pitch Detection
Custom YIN autocorrelation algorithm built on Apple's Accelerate framework. Detects pitch from your microphone at ~23ms frame intervals with no external dependencies.

### Jazz-Aware Scoring
Every note is classified against the current chord in real time:
- **Chord tones** (root, 3rd, 5th, 7th) — full points
- **Scale tones** — partial points
- **Chromatic passing tones** — no penalty (the app trusts your musical intent)
- **Clashing notes** — small penalty, only if unresolved

The scoring philosophy is **generous, not punitive**. Chromatic approaches, blue notes, enclosures, and intentional tension never break your combo.

### Pattern Detection
20 vocabulary detectors that recognise jazz language in your playing:

| Category | Patterns |
|----------|----------|
| **Foundations** | Chord tone targeting, chromatic approaches, arpeggios |
| **Bebop** | Enclosures, bebop scale runs, digital patterns (1-2-3-5), guide tone lines |
| **Blues** | Blue notes, pentatonic runs |
| **Advanced** | Quartal melodies, diminished patterns, wide interval leaps, sequences |
| **Musicality** | Space/rests, tension & resolution, phrase resolution, range exploration |

### MIDI Backing Tracks
Built-in rhythm section (bass, drums, piano) driven by a MIDI sequencer with tempo-synced playback. Supports swing, bossa nova, and ballad styles. Uses the GeneralUser GS SoundFont.

### Gamification
- **Combo multiplier** — 8 consecutive good notes = 2x, 16 = 3x, 32 = 4x
- **Star ratings** (1-5) per session based on note choice quality and vocabulary diversity
- **Streak tracking** — daily practice streaks with XP rewards
- **Skill tree** — progressive unlock system from foundations to mastery
- **Achievements** — milestones for practice habits, vocabulary breadth, and performance

### 10 Bundled Standards
Autumn Leaves, Blue Bossa, All of Me, All the Things You Are, Solar, Fly Me to the Moon, Confirmation, Donna Lee, Blues for Alice, Beautiful Love — with full chord charts in a simple JSON format.

## Tech Stack

| | |
|---|---|
| **Language** | Swift 5.9, SwiftUI |
| **Target** | iOS 17.0+, Portrait only |
| **Audio** | AVAudioEngine, AVAudioUnitSampler, Accelerate (custom YIN pitch detection) |
| **Persistence** | SwiftData |
| **Architecture** | MVVM with `@Observable` / `@MainActor` ViewModels |
| **Build** | XcodeGen (`project.yml`), Xcode 16+ |
| **Dependencies** | None (no SPM packages) |

## Architecture

```
Microphone
  → PitchDetector (YIN autocorrelation, ~23ms frames)
  → NoteSegmenter (3-frame stability → discrete NoteEvents)
  → ContextEngine (beat → chord lookup, adds scale degree / chord tone info)
  → PatternMatcher (20 detectors, cooldown, overlap resolution)
  → ScoreEngine (per-note classification, combo multiplier, star rating)
  → UI (scrolling chord chart, live score, combo counter, pattern popups)
```

The backing track runs on a separate `AVAudioEngine` with three `AVAudioUnitSampler` nodes (bass, drums, piano) driven by `MIDISequencer` at tempo-synced tick resolution.

## Project Structure

```
JazzShed/
├── App/                    Entry point, SwiftData container
├── Models/                 Tune, NoteEvent, Chord, Pattern, PatternDetection
│   └── Enums/              ChordQuality (15 types), Difficulty, Instrument (8 with transposition)
├── Services/
│   ├── Audio/              PitchDetector, NoteSegmenter, BackingTrackPlayer, MIDISequencer
│   ├── Analysis/           ContextEngine, PatternMatcher, ScoreEngine
│   ├── Data/               TuneLibrary, SkillTreeData
│   └── Gamification/       StreakManager
├── ViewModels/             SessionViewModel, HomeViewModel, ResultsViewModel, etc.
├── Views/
│   ├── Play/               ActiveSessionView, ChordChartView, TuneSelectionView
│   ├── Results/            Post-session breakdown
│   ├── Home/               Dashboard with streaks and daily challenge
│   ├── Learn/              Skill tree and lick practice
│   ├── Stats/              Practice history and visualisations
│   ├── Profile/            Settings and achievements
│   └── Components/         Reusable UI (JazzButton, ProgressRing, MixerPanel)
├── Theme/                  Colours, spacing, typography (dark theme, gold accents)
├── Extensions/             MIDI helpers, Color+Hex
└── Resources/
    ├── Tunes/              10 JSON chord charts
    └── SoundFonts/         GeneralUser_GS.sf2 (~30MB)
```

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 17.0+ device or simulator

### Setup
1. Clone the repo
2. Download [GeneralUser GS SoundFont](https://schristiancollins.com/generaluser.php) and place `GeneralUser_GS.sf2` in `JazzShed/Resources/SoundFonts/`
3. Open `JazzShed.xcodeproj` in Xcode
4. Build and run on a device (microphone input requires a physical device)

> **Note:** The SoundFont file (~30MB) is excluded from the repo via `.gitignore`. The app requires it for backing track playback.

## Tests

14 tests across 3 test files using Swift Testing (`@Test` macro):
- **ChordTests** — chord tone detection, scale degrees, symbol display
- **NoteSegmenterTests** — stable note emission, jitter rejection
- **MIDIHelpersTests** — frequency/MIDI conversion, note names, intervals

```bash
xcodebuild test -scheme JazzShed -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Scoring Philosophy

JazzShed scores your playing the way a supportive bandmate listens — paying attention to what you're doing right, recognising sophisticated vocabulary, and only flagging notes that are genuinely lost.

The app **never penalises**:
- Chromatic approaches that resolve
- Blue notes (b3, b5, b7)
- Intentional tension that resolves within a beat or two
- Playing "outside" (detected side-slips are rewarded)
- Silence (rests are musical and earn points)

See [docs/scoring-philosophy.md](docs/scoring-philosophy.md) for the full breakdown.

## Roadmap

### MVP (v1.0)
- [x] Real-time pitch detection (custom YIN)
- [x] MIDI backing track engine (bass/drums/piano)
- [x] 20 pattern detectors (bebop vocabulary)
- [x] Scoring and combo system
- [x] 10 bundled standards
- [x] Full UI (Home, Play, Learn, Stats, Profile)
- [x] SwiftData persistence
- [ ] Spaced repetition scheduling
- [ ] Onboarding flow polish

### Future (v2+)
- Genre modes: Blues, Modal, Post-Bop, Standards, Latin
- Skill tree levels 3-5
- Leaderboards and social features
- Ear training module
- Cloud sync and user accounts

## License

All rights reserved.
