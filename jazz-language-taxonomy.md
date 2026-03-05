# Jazz Language Pattern Taxonomy
## Comprehensive Reference for Audio Analysis & Gamification

*Compiled for PRD development -- Jazz Practice App*

---

## Table of Contents

1. [Pitch Detection & Audio Analysis Foundation](#1-pitch-detection--audio-analysis-foundation)
2. [Pattern Matching Architecture](#2-pattern-matching-architecture)
3. [Bebop Language](#3-bebop-language)
4. [Blues Language](#4-blues-language)
5. [Modal Jazz Language](#5-modal-jazz-language)
6. [Post-Bop / Modern Jazz](#6-post-bop--modern-jazz)
7. [Latin / Bossa Nova](#7-latin--bossa-nova)
8. [Swing / Standards](#8-swing--standards)
9. [General Jazz Techniques (Cross-Genre)](#9-general-jazz-techniques-cross-genre)
10. [Scoring Philosophy & Point Calibration](#10-scoring-philosophy--point-calibration)

---

## 1. Pitch Detection & Audio Analysis Foundation

### 1.1 How Real-Time Pitch Detection Works

Pitch detection for monophonic instruments (saxophone, trumpet, voice, etc.) estimates the fundamental frequency (F0) of an audio signal frame by frame. The pipeline is:

```
Microphone -> Audio Buffer -> Windowed Frames -> Pitch Estimation -> MIDI Note Mapping -> Note Stream
```

**Key concepts:**
- **Frame size (window):** Typically 1024-4096 samples. Larger windows give better frequency resolution but worse time resolution (latency). At 44.1kHz, a 2048-sample window is ~46ms.
- **Hop size:** How much the window advances between frames. Typically 50% overlap (hop = window/2). Smaller hop = more frequent pitch estimates.
- **Frequency to MIDI:** `MIDI = 69 + 12 * log2(freq / 440)`. Round to nearest integer for note name, keep fractional part for intonation analysis.
- **Onset detection:** Detecting when a new note begins (attack transient). Critical for segmenting the pitch stream into discrete notes.
- **Note segmentation:** Grouping consecutive frames with the same pitch into a single "note event" with start time, duration, pitch, and amplitude.

### 1.2 Pitch Detection Algorithms

#### Time-Domain Methods

**YIN Algorithm** (de Cheveigne & Kawahara, 2002)
- Based on autocorrelation with a difference function and cumulative mean normalized difference.
- Suppresses harmonic peaks to find the true fundamental.
- Accuracy: ~96-98% on clean monophonic signals.
- Latency: Requires ~2 periods of the fundamental. For a trumpet's low Bb (233 Hz), that is ~8.6ms minimum.
- Weakness: Susceptible to octave errors (detecting half or double the actual pitch).
- Best for: Real-time applications where latency matters.

**McLeod Pitch Method (MPM)** (McLeod & Wyvill, 2005)
- Also autocorrelation-based but uses normalized square difference function (NSDF).
- Can extract pitch with as few as 2 periods, allowing smaller window sizes.
- Better pitch tracking during vibrato due to shorter effective window.
- Generally more robust than YIN for varying dynamics.

**pYIN** (Mauch & Dixon, 2014)
- Probabilistic extension of YIN.
- Uses a Hidden Markov Model (HMM) to smooth pitch estimates over time.
- Distributes the YIN threshold between 0.01 and 1.0 with beta distributions.
- More accurate than YIN but slightly higher latency due to HMM smoothing.
- Excellent for post-processing (not strictly real-time).

#### Frequency-Domain Methods

**YinFFT**
- FFT-based variant of YIN. Computes the same difference function in the frequency domain.
- Computationally faster for large window sizes.
- Same accuracy characteristics as time-domain YIN.

**Harmonic Product Spectrum (HPS)**
- Compresses the spectrum by factors of 2, 3, 4... and multiplies them together.
- The fundamental frequency will align across all compressed versions.
- Simple but less accurate than YIN/MPM. Good as a secondary check.

#### Neural Network Methods

**CREPE** (Kim et al., 2018)
- Convolutional neural network operating directly on raw waveform.
- State-of-the-art accuracy, outperforming pYIN and SWIPE.
- Pre-trained model available as open-source Python module.
- Higher computational cost -- may need GPU for real-time on mobile.
- 6 model sizes from "tiny" to "full" for latency/accuracy tradeoff.

**SPICE** (Google, 2019)
- Self-supervised model -- trained without labelled pitch data.
- Competitive with CREPE despite no ground truth labels.
- Lighter weight, potentially better for mobile deployment.

**SwiftF0** (2025)
- Only 95,842 parameters -- ~42x faster than CREPE on CPU.
- 91.80% harmonic mean at 10dB SNR (outperforms CREPE by 12+ points in noisy conditions).
- Strong candidate for real-time mobile deployment.

**BasicPitch** (Spotify)
- Designed for polyphonic pitch detection but works excellently on monophonic.
- Outputs MIDI-like note events with onset, offset, pitch, and velocity.
- Available as Python library and web demo.

### 1.3 Libraries & Frameworks

#### iOS / Swift

| Library | Language | Pitch Detection | Notes |
|---------|----------|-----------------|-------|
| **AudioKit** | Swift | PitchTap (autocorrelation-based) | Mature, MIT licensed, actively maintained (last update Dec 2025). Includes FFT, onset detection, amplitude tracking. Swift Package Manager support. |
| **Beethoven** | Swift | YIN, FFT-based | Lightweight pitch detection library built on top of AudioKit concepts. |
| **Apple vDSP / Accelerate** | Swift/ObjC | Manual FFT | Low-level but fastest on Apple silicon. Build your own detector. |
| **SoundAnalysis** | Swift | Built-in ML models | Apple's framework for audio classification. Could train custom pitch model. |

#### Cross-Platform / Python

| Library | Language | Pitch Detection | Notes |
|---------|----------|-----------------|-------|
| **Essentia** | C++ (Python bindings) | PitchYin, PitchYinFFT, PitchMelodia | Full MIR library from UPF Barcelona. Comprehensive feature extraction. |
| **aubio** | C (Python bindings) | YIN, MComb, specacf | Lightweight, battle-tested. NumPy array integration. Onset detection built in. |
| **librosa** | Python | pyin, piptrack | Standard Python audio analysis. pYIN wrapper included. |
| **CREPE** | Python (TensorFlow) | CNN-based | Highest accuracy. `pip install crepe`. |
| **BasicPitch** | Python (TensorFlow) | CNN-based | `pip install basic-pitch`. Note-level output. |

#### Android / Java

| Library | Language | Pitch Detection | Notes |
|---------|----------|-----------------|-------|
| **TarsosDSP** | Java | YIN, MPM, AMDF, Dynamic Wavelet | Pure Java, no dependencies. Android-ready JAR. Real-time capable. |

### 1.4 Recommended Architecture for This App

```
                    +------------------+
                    |   Microphone     |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Audio Buffer     |
                    | (Ring Buffer)    |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------v----------+     +------------v-----------+
    | Pitch Detection    |     | Onset Detection        |
    | (YIN / AudioKit    |     | (Energy + Spectral     |
    |  PitchTap)         |     |  Flux)                 |
    +---------+----------+     +------------+-----------+
              |                             |
              +--------------+--------------+
                             |
                    +--------v---------+
                    | Note Segmenter   |
                    | (pitch + onset   |
                    |  -> note events) |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Note Stream      |
                    | Buffer (sliding  |
                    |  window of last  |
                    |  N notes)        |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Pattern Matcher  |
                    | (see Section 2)  |
                    +--------+---------+
                             |
                    +--------v---------+
                    | Score Engine     |
                    | & UI Feedback    |
                    +-------------------+
```

**For iOS (primary target):**
- Use **AudioKit** for audio input and basic pitch detection (PitchTap).
- Supplement with a custom **YIN** or **MPM** implementation in Swift for lower latency if needed.
- Use Apple's **Accelerate** framework for FFT operations.
- Consider shipping a **CoreML** version of CREPE or SwiftF0 for highest accuracy.

---

## 2. Pattern Matching Architecture

### 2.1 The Note Event Model

Each detected note becomes a structured event:

```swift
struct NoteEvent {
    let midiPitch: Int          // 0-127
    let frequency: Double       // Hz (for microtuning/blue note detection)
    let startTime: Double       // seconds from session start
    let duration: Double        // seconds
    let amplitude: Double       // 0.0-1.0
    let intervalFromPrevious: Int?  // semitones (nil for first note)
    let scaleDegree: Int?       // relative to detected/specified key (1-12)
    let octave: Int             // MIDI octave
}
```

### 2.2 Pattern Representation

Patterns should be stored as **interval sequences** (relative) rather than absolute pitches, so they match in any key:

```swift
struct JazzPattern {
    let id: String
    let name: String
    let category: PatternCategory    // .bebop, .blues, .modal, etc.
    let intervalSequence: [Int]      // semitones between consecutive notes
    let scaleDegreeSequence: [Int]?  // optional: expected scale degrees
    let rhythmicConstraints: RhythmConstraint?  // optional timing rules
    let minNotes: Int                // minimum notes to match
    let maxNotes: Int                // maximum notes to match
    let points: Int                  // score value
    let difficulty: Difficulty       // .beginner, .intermediate, .advanced
    let tolerance: MatchTolerance    // how strictly to match
    let description: String
    let detectionHints: String       // algorithmic detection notes
}
```

### 2.3 Pattern Matching Algorithms

#### Sliding Window Exact Match
For fixed-length patterns (e.g., specific enclosure shapes):
- Maintain a sliding window of the last N note intervals.
- Compare against pattern database using interval sequences.
- Time complexity: O(W * P) where W = window size, P = number of patterns.

#### Subsequence Matching
For patterns that may be embedded within longer phrases:
- Use a modified Longest Common Subsequence (LCS) algorithm.
- Allow "skip" notes (passing tones between pattern notes).
- Score based on match percentage and continuity.

#### Dynamic Time Warping (DTW)
For rhythmically flexible patterns:
- DTW measures similarity between two temporal sequences that may vary in speed.
- Ideal for patterns where the rhythmic spacing is flexible but the pitch contour matters.
- O(NM) complexity via dynamic programming.
- Use for detecting "similar to" a known lick rather than exact matches.

#### Fuzzy Interval Matching
For approximate pattern recognition:
- Allow +/- 1 semitone tolerance on each interval.
- Useful for detecting "enclosure-like" patterns where the exact approach may vary.
- Score inversely proportional to total deviation.

#### State Machine / Grammar-Based Detection
For structural patterns (e.g., "any enclosure targeting a chord tone"):
- Define patterns as finite state machines or context-free grammars.
- States represent musical conditions (e.g., "chromatic note above target," "diatonic note below target").
- Transitions represent valid interval movements.
- Most flexible approach for detecting musical *concepts* rather than specific lick sequences.

### 2.4 Harmonic Context Awareness

The pattern matcher needs harmonic context to identify scale degrees:

```
Option A: User selects a backing track / chord chart (app provides chord changes)
Option B: User specifies key center manually
Option C: Key detection from the solo itself (harder, less reliable for short excerpts)
```

**Recommendation:** Start with Option A (backing tracks with known chord changes) for reliable detection. This lets the system know what chord is active at any moment, enabling accurate scale degree assignment.

### 2.5 The Jazzomat Precedent

The **Jazzomat Research Project** (Hochschule fur Musik Weimar) provides strong academic precedent for this work. Their Weimar Jazz Database contains 456+ manually transcribed jazz solos with annotated patterns. Klaus Frieler's taxonomy of jazz line construction atoms includes:
- Ascending/descending chromatic atoms
- Ascending/descending diatonic atoms
- Arpeggios (ascending/descending, various chord types)
- Approach patterns (single, double, triple)
- Scalar runs
- Intervallic jumps

Their MeloSpyLib (Python) provides pattern search using regular expressions over interval sequences. This validates the interval-sequence approach to pattern matching.

---

## 3. Bebop Language

### 3.1 Enclosures

#### 3.1.1 Single Chromatic Enclosure (Above-Below)
**Description:** A target chord tone is approached from one half-step above and one half-step below (or vice versa), creating a 3-note figure that "encloses" the target. The surrounding notes create tension that resolves on the target.

**Detection:**
- Look for a 3-note sequence where note 3 is a chord tone of the current harmony.
- Note 1 is 1 semitone above note 3, note 2 is 1 semitone below note 3 (or reversed).
- Interval pattern: [-2, +2] (above-below) or [+2, -2] (below-above) landing on chord tone.
- Target note should fall on a relatively strong beat (beat 1 or 3 in 4/4, or any downbeat of an eighth note pair).

**Points:** 100
**Difficulty:** Beginner

---

#### 3.1.2 Diatonic Enclosure (Above-Below)
**Description:** Same concept but the approach notes come from the prevailing scale rather than chromatically. Upper note is a diatonic step above, lower note is a half-step below (the chromatic lower neighbor is more common than diatonic lower).

**Detection:**
- 3-note figure targeting a chord tone.
- Note 1 is 1 or 2 semitones above target (diatonic step), note 2 is 1 semitone below target.
- The upper approach note must be a scale tone of the current key/mode.
- Interval pattern: [-1 or -2, +1 or +2] landing on chord tone.

**Points:** 100
**Difficulty:** Beginner

---

#### 3.1.3 Double Chromatic Enclosure
**Description:** A 4-note enclosure using two chromatic approach notes before the target. For example: two notes descending chromatically from above, then one note from below, landing on target. Creates a longer, more elaborate approach.

**Detection:**
- 4-note figure where note 4 is a chord tone.
- Notes 1-2 descend chromatically (interval -1 between them), note 3 is 1 semitone below target, note 4 is the target.
- Alternative: notes 1-2 ascend chromatically from below, note 3 from above.
- Common interval patterns: [-1, -3, +2] or [+1, +3, -2] (various permutations).

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.1.4 Triple/Extended Enclosure
**Description:** 5+ note enclosure patterns. Multiple approach notes from alternating directions, circling around the target before resolving. Highly characteristic of advanced bebop playing.

**Detection:**
- 5-6 note figure converging on a chord tone.
- Alternating direction changes (up-down-up or down-up-down) with decreasing distance to target.
- Final note is a chord tone on a strong beat.
- The "net distance" of each successive note to the target should generally decrease.

**Points:** 200
**Difficulty:** Advanced

---

### 3.2 Chromatic Approach Notes

#### 3.2.1 Single Chromatic Approach from Below
**Description:** A chord tone is preceded by the note one half-step below it. The simplest form of chromatic embellishment.

**Detection:**
- 2-note figure: interval of +1 semitone, second note is a chord tone.
- Second note on a stronger beat position than the first.

**Points:** 50
**Difficulty:** Beginner

---

#### 3.2.2 Single Chromatic Approach from Above
**Description:** A chord tone is preceded by the note one half-step above it.

**Detection:**
- 2-note figure: interval of -1 semitone, second note is a chord tone.

**Points:** 50
**Difficulty:** Beginner

---

#### 3.2.3 Double Chromatic Approach from Below
**Description:** Two consecutive chromatic notes ascending into a chord tone (e.g., A-Bb-B targeting B as the 3rd of Gmaj7).

**Detection:**
- 3-note figure: intervals [+1, +1], third note is a chord tone.

**Points:** 75
**Difficulty:** Beginner

---

#### 3.2.4 Double Chromatic Approach from Above
**Description:** Two consecutive chromatic notes descending into a chord tone.

**Detection:**
- 3-note figure: intervals [-1, -1], third note is a chord tone.

**Points:** 75
**Difficulty:** Beginner

---

#### 3.2.5 Chromatic Run to Chord Tone
**Description:** 4+ consecutive chromatic notes (ascending or descending) resolving to a chord tone. Creates strong forward motion and tension.

**Detection:**
- 4+ consecutive intervals of +1 or -1 (all same direction), final note is chord tone.
- The longer the run, the higher the score (bonus per additional chromatic note).

**Points:** 100 (base) + 25 per note beyond 4
**Difficulty:** Intermediate

---

### 3.3 Bebop Scale Runs

#### 3.3.1 Bebop Dominant Scale Run
**Description:** The Mixolydian mode with an added chromatic passing tone between the b7 and the root (ascending) or root and b7 (descending). This 8-note scale places chord tones on downbeats when played in continuous eighth notes. THE defining sound of bebop.

**Detection:**
- Detect a run of 5+ notes that fits the bebop dominant scale (1-2-3-4-5-6-b7-7).
- Key marker: the chromatic passing tone between b7 and root.
- Interval pattern for ascending run: [2, 2, 1, 2, 2, 1, 1] (whole, whole, half, whole, whole, half, half).
- Check that chord tones (1, 3, 5, b7) fall on even-numbered positions in the run (strong eighth-note positions).

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.3.2 Bebop Major Scale Run
**Description:** Major scale with chromatic passing tone between 5 and 6 (ascending). Scale: 1-2-3-4-5-#5-6-7.

**Detection:**
- Run of 5+ notes fitting: [2, 2, 1, 2, 1, 1, 2] interval pattern.
- Chromatic passing tone between 5th and 6th scale degrees.

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.3.3 Bebop Dorian Scale Run
**Description:** Dorian mode with chromatic passing tone between 3 and 4. Used over minor 7th chords. Scale: 1-2-b3-3-4-5-6-b7.

**Detection:**
- Run fitting: [2, 1, 1, 1, 2, 2, 1] interval pattern.
- Critical: the natural 3 between b3 and 4.

**Points:** 150
**Difficulty:** Intermediate

---

### 3.4 Digital Patterns

#### 3.4.1 1-2-3-5 Pattern
**Description:** A 4-note cell built from the 1st, 2nd, 3rd, and 5th scale degrees, played through chord changes. Sometimes called the "Coltrane pattern." Creates a bright, open sound. Can be sequenced through keys.

**Detection:**
- 4-note group with intervals matching [+2, +2, +3] (in major) or [+2, +1, +4] (in minor) relative to the local scale.
- Scale degree check: notes map to degrees 1, 2, 3, 5 of the current chord's scale.
- Look for repetition at different pitch levels (sequencing).

**Points:** 125
**Difficulty:** Intermediate

---

#### 3.4.2 1-2-3-4 Pattern (Scalar Tetrachord)
**Description:** Four consecutive scale degrees ascending or descending. Basic but fundamental building block.

**Detection:**
- 4 consecutive scale tones in one direction.
- Intervals all diatonic steps: combinations of [1, 2] totaling a perfect 4th span.

**Points:** 75
**Difficulty:** Beginner

---

#### 3.4.3 5-4-3-2 Pattern (Parker Descending Cell)
**Description:** Descending from 5th scale degree through 4, 3, 2. A core "atom" of bebop language identified in Charlie Parker's playing. Balances ascending and descending motion.

**Detection:**
- 4-note descending group: scale degrees 5, 4, 3, 2 of current chord.
- Intervals: descending diatonic steps (combinations of [-1, -2]).

**Points:** 100
**Difficulty:** Beginner

---

#### 3.4.4 1-3-5-7 Arpeggio Pattern
**Description:** Ascending chord tones through a seventh chord. The most basic jazz arpeggio.

**Detection:**
- 4 notes matching the chord tones of the current harmony.
- Intervals depend on chord quality:
  - Major 7: [+4, +3, +4]
  - Minor 7: [+3, +4, +3]
  - Dominant 7: [+4, +3, +3]
  - Half-diminished: [+3, +3, +4]
  - Diminished 7: [+3, +3, +3]

**Points:** 100
**Difficulty:** Beginner

---

#### 3.4.5 3-5-7-9 Upper Arpeggio
**Description:** Arpeggiating from the 3rd through 9th of a chord, outlining the upper extensions. More sophisticated than root-position arpeggios.

**Detection:**
- 4 notes matching degrees 3, 5, 7, 9 of current chord.
- Note: this creates a chord a third above the root (e.g., Em7 over Cmaj7).

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.4.6 Digital Pattern Sequences
**Description:** Any of the above 4-note cells repeated at different pitch levels, typically ascending or descending by step or by the chord progression. Shows systematic harmonic thinking.

**Detection:**
- Detect a 4-note cell, then check if a transposed version of the same cell follows within 1-2 notes.
- The transposition interval should be diatonic (scale step) or follow chord root movement.
- Award bonus points for 3+ sequential transpositions.

**Points:** 200 (for 2 repetitions) + 75 per additional repetition
**Difficulty:** Intermediate

---

### 3.5 ii-V-I Licks

#### 3.5.1 Basic ii-V-I Line
**Description:** A melodic line that clearly outlines the ii-V-I harmonic motion, with audible chord tone targeting at each change. The fundamental harmonic navigation skill in jazz.

**Detection:**
- Over a detected ii-V-I progression (requires harmonic context):
  - Notes over ii chord include the b3 and b7 of the ii chord.
  - Notes over V chord include the 3rd and b7 of the V chord.
  - Resolution to a chord tone (1, 3, or 5) of the I chord on or near beat 1.
- The b7 of ii (= 4 of key) resolving to 3 of V, and b7 of V resolving to 3 (or 1) of I = guide tone motion.

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.5.2 ii-V-I with Chromatic Embellishment
**Description:** A ii-V-I line that includes chromatic approach notes, enclosures, or passing tones while still clearly outlining the harmony.

**Detection:**
- Same as 3.5.1 but with detected enclosures or chromatic approaches (from 3.1-3.2) embedded within the line.
- Check for chromaticism density: at least 2 non-scale tones in the line.

**Points:** 250
**Difficulty:** Intermediate

---

#### 3.5.3 "Cry Me a River" Lick / Classic Bebop ii-V
**Description:** Countless specific ii-V licks have become part of the common vocabulary. These are fixed melodic sequences (specific interval patterns) that recur across many players' solos. Detecting known licks by their exact interval sequence.

**Detection:**
- Database of known ii-V-I lick interval sequences (10-20 of the most common).
- Exact interval matching with DTW tolerance of +/-1 semitone on up to 2 notes.
- Example "Cry Me a River" fragment: descending from 9 of ii through 1-b7-5-4-3 of V resolving to 1 of I.

**Points:** 200
**Difficulty:** Intermediate

---

### 3.6 Tritone Substitution Lines

#### 3.6.1 Tritone Sub Approach
**Description:** Playing a line that implies the tritone substitute of the V chord (bII7 instead of V7) before resolving to I. The line descends chromatically by half-step into the resolution. E.g., over G7 going to C, playing Db7 vocabulary (Db-F-Ab-Cb) resolving to C.

**Detection:**
- Over a V chord, detect notes that belong to the bII7 chord (a tritone away from V).
- Specifically: the root and 5th of the tritone sub will be a half-step above the target I chord's root and 5th.
- Line should resolve down by half-step to a chord tone of I.
- Key interval: the root of the tritone sub descending by semitone to the root of I.

**Points:** 200
**Difficulty:** Advanced

---

### 3.7 Guide Tone Lines

#### 3.7.1 3rd-to-7th Voice Leading
**Description:** The 3rd of one chord resolves smoothly (by step or common tone) to the 7th of the next chord, or vice versa. This is the fundamental principle of jazz voice leading. In a ii-V-I in C: F(b7 of Dm7) -> F or E(3 of G7) -> E or B(3 or 7 of Cmaj7).

**Detection:**
- At chord boundaries, check if the note played near the chord change is a 3rd or 7th of the outgoing chord, and the note on the new chord is a 3rd or 7th of the incoming chord.
- The interval between these two notes should be 0 (common tone) or +/-1 or +/-2 semitones (step).
- Track across the full progression: if guide tone voice leading is maintained over 3+ chord changes, award bonus.

**Points:** 125 (per chord change with correct voice leading), 300 bonus for 4+ consecutive
**Difficulty:** Intermediate

---

### 3.8 Diminished Patterns

#### 3.8.1 Diminished 7th Arpeggio
**Description:** Four notes each a minor third apart (e.g., B-D-F-Ab). Symmetric -- only 3 unique diminished 7th chords exist. Used as passing chords and over dominant 7th chords.

**Detection:**
- 4 notes with intervals [+3, +3, +3] or [-3, -3, -3].
- Can start on any note (symmetric, so all inversions sound equivalent).

**Points:** 100
**Difficulty:** Beginner

---

#### 3.8.2 Half-Whole Diminished Scale Run
**Description:** Alternating half-steps and whole-steps: H-W-H-W-H-W-H-W. An 8-note symmetric scale used over dominant 7th chords with b9, #9, #11, and natural 13.

**Detection:**
- 5+ note run fitting the interval pattern [1, 2, 1, 2, 1, 2, 1, 2] (ascending) or [-1, -2, ...] (descending).
- Can enter at any point in the pattern (symmetric every minor third).

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.8.3 Whole-Half Diminished Scale Run
**Description:** Alternating whole-steps and half-steps: W-H-W-H-W-H-W-H. Used over diminished 7th chords.

**Detection:**
- 5+ note run fitting [2, 1, 2, 1, 2, 1, 2, 1] interval pattern.

**Points:** 150
**Difficulty:** Intermediate

---

#### 3.8.4 Diminished Passing Chord Pattern
**Description:** A diminished 7th arpeggio used as a chromatic passing chord between two diatonic chords (e.g., Cmaj7 -> C#dim7 -> Dm7). The diminished arpeggio fills the chromatic space.

**Detection:**
- Diminished 7th arpeggio (3.8.1) detected between two chord tones of adjacent chords.
- Root of diminished chord is a half-step above or below a chord root in the progression.

**Points:** 175
**Difficulty:** Intermediate

---

### 3.9 Bird (Charlie Parker) Licks

#### 3.9.1 The "Confirmation" Opening Figure
**Description:** Arpeggiated major 7th chord ascending, then a descending scale run with chromatic passing tone. One of the most iconic bebop phrases.

**Detection:**
- Ascending arpeggio (1-3-5-7) followed by descending scale motion with at least one chromatic passing tone.
- Total figure: 7-10 notes.
- Ascending arpeggio covers at least a 7th interval, descent covers similar range.

**Points:** 250
**Difficulty:** Intermediate

---

#### 3.9.2 Chromatic 3rd-to-5th Approach
**Description:** Ascending chromatic line from the 3rd to the 5th of a chord (e.g., E-F-F#-G on Cmaj7). A signature Parker device for adding blues/chromatic color.

**Detection:**
- 4 consecutive ascending chromatic notes [+1, +1, +1] where:
  - First note is the 3rd (or b3) of the current chord.
  - Last note is the 5th of the current chord.
- Can also work descending from 5 to 3.

**Points:** 125
**Difficulty:** Intermediate

---

#### 3.9.3 The "Donna Lee" Turn Figure
**Description:** A quick turn figure (upper neighbor, target, lower neighbor, target) used as decoration. Essentially an ornamental enclosure played at speed.

**Detection:**
- 4-note group: intervals approximately [+1 or +2, -2 or -3, +1, 0 or continuation].
- Very short duration per note (sixteenth notes or faster).
- Target note repeated or held after the turn.

**Points:** 125
**Difficulty:** Intermediate

---

### 3.10 Arpeggiated Lines

#### 3.10.1 Chord Tone Soloing (Pure Arpeggio)
**Description:** Playing only or primarily chord tones (1, 3, 5, 7) of each chord change. The most basic but essential harmonic navigation.

**Detection:**
- Over a span of 4+ notes, 75%+ are chord tones of the current harmony.
- No more than 1 consecutive non-chord tone.

**Points:** 100
**Difficulty:** Beginner

---

#### 3.10.2 Superimposed Arpeggio
**Description:** Playing an arpeggio from a chord different from (but related to) the underlying harmony, creating extensions. E.g., playing Em7 arpeggio (E-G-B-D) over Cmaj7 creates the 3-5-7-9 sound.

**Detection:**
- Detect arpeggio (4 notes with intervals matching a chord quality).
- Check if the arpeggio root is NOT the root of the current chord but the arpeggio notes are all valid extensions/chord tones of the current harmony.
- Common superimpositions: iii over I, vi over IV, ii over bVII.

**Points:** 175
**Difficulty:** Intermediate

---

#### 3.10.3 Arpeggio Across Chord Changes
**Description:** A continuous arpeggio line that spans two or more chord changes, with the arpeggio choice reflecting each new chord.

**Detection:**
- Detect arpeggios over consecutive chords where the arpeggio changes to match the new harmony.
- The transition between arpeggios should be smooth (small interval at the chord boundary).

**Points:** 200
**Difficulty:** Intermediate

---

---

## 4. Blues Language

### 4.1 Blue Notes

#### 4.1.1 Flat 3rd (b3) Blue Note
**Description:** Playing the minor 3rd over a major or dominant chord. THE defining sound of the blues. In the key of C, playing Eb over C7 or Cmaj7. The tension between major and minor is the soul of blues.

**Detection:**
- Detect scale degree b3 (3 semitones above root) played over a major or dominant chord.
- Extra credit if the b3 bends/slides into the natural 3 (detect pitch glide: frequency starts at b3 and rises toward natural 3).
- Microtuning: true blue notes often sit between b3 and natural 3 (quarter-tone region). Detect pitch that is 3.0-3.8 semitones above root.

**Points:** 75
**Difficulty:** Beginner

---

#### 4.1.2 Flat 5th (b5) Blue Note
**Description:** The "blue 5th" -- a half-step below the perfect 5th. Creates a dark, tense sound. In C: Gb. Often used as a passing tone between 4 and 5.

**Detection:**
- Scale degree b5 (6 semitones above root) played over any chord.
- Especially significant when it appears between the 4th and 5th scale degrees (intervals [+1] or [-1] connecting scale degrees 4-b5-5).

**Points:** 75
**Difficulty:** Beginner

---

#### 4.1.3 Flat 7th (b7) Blue Note
**Description:** The minor 7th over a chord, foundational to dominant 7th chords and blues tonality.

**Detection:**
- Scale degree b7 (10 semitones above root). Especially note when played over a major chord context (not just dominant).

**Points:** 50
**Difficulty:** Beginner

---

#### 4.1.4 Blue Note Cluster
**Description:** Multiple blue notes used in close proximity, creating a dense blues sound. Playing b3, b5, and b7 within a short phrase.

**Detection:**
- 3+ blue notes (b3, b5, b7) within a 6-note window.
- At least 2 different blue note types present.

**Points:** 150
**Difficulty:** Intermediate

---

### 4.2 Blues Scale Usage

#### 4.2.1 Blues Scale Run
**Description:** A run using the 6-note blues scale: 1-b3-4-b5-5-b7. The quintessential blues melodic material.

**Detection:**
- 5+ consecutive notes all belonging to the blues scale of the current key.
- Must include at least one of the "blue" notes (b3, b5).
- Interval pattern contains only: [+1, +2, +3] and their negatives.
- Scale as semitone set from root: {0, 3, 5, 6, 7, 10}.

**Points:** 100
**Difficulty:** Beginner

---

#### 4.2.2 Minor Pentatonic Run
**Description:** A run using the 5-note minor pentatonic: 1-b3-4-5-b7. Foundational to blues and rock, also extensively used in jazz blues.

**Detection:**
- 5+ notes from the set {0, 3, 5, 7, 10} (semitones from root).
- No chromatic passing tones within the run.

**Points:** 75
**Difficulty:** Beginner

---

#### 4.2.3 Major Pentatonic Run
**Description:** 1-2-3-5-6. Bright, open sound. Used for contrast with minor pentatonic blues language.

**Detection:**
- 5+ notes from the set {0, 2, 4, 7, 9} (semitones from root).

**Points:** 75
**Difficulty:** Beginner

---

### 4.3 Mixolydian b3 Lines

#### 4.3.1 Major/Minor Mixture Line
**Description:** A line that freely mixes the major 3rd and minor 3rd (and sometimes major/minor 7th) within the same phrase. This is the "Mixolydian b3" or "blues-major" sound -- neither purely major nor minor.

**Detection:**
- Within an 8-note window, detect both scale degree 3 (natural) AND b3 (flat).
- The line should also include b7 (dominant quality).
- Semitone set includes both 3 and 4 semitones above root within the phrase.

**Points:** 150
**Difficulty:** Intermediate

---

### 4.4 Call and Response

#### 4.4.1 Melodic Call and Response
**Description:** A musical "conversation" where a phrase (call) is followed by a contrasting phrase (response) that answers it. The response typically mirrors the rhythm and/or contour of the call but resolves differently.

**Detection:**
- Detect two phrases separated by a rest (silence > 0.5 beats).
- Compare the two phrases:
  - Similar duration (within 50% of each other).
  - Similar rhythmic profile (onset patterns correlate).
  - Different pitch content (not an exact repetition).
  - The response "resolves" (ends on a chord tone or root) while the call may end on tension.
- This is hard to detect precisely; use contour similarity (sequence of up/down directions).

**Points:** 200
**Difficulty:** Intermediate

---

### 4.5 Turnaround Licks (Blues Context)

#### 4.5.1 Descending Chromatic Turnaround
**Description:** In the last 2 bars of a 12-bar blues, a descending chromatic line targeting the V chord. Classic: walking down from 1 through b7, 6, b6, landing on 5 for the turnaround.

**Detection:**
- In the context of bars 11-12 of a blues form (if harmonic context available).
- 4+ note descending line with at least 2 chromatic intervals.
- Resolves to scale degree 5 or 1 of the key.

**Points:** 125
**Difficulty:** Intermediate

---

#### 4.5.2 I-VI-ii-V Turnaround Lick
**Description:** A melodic line that outlines the I-VI-ii-V (or I-bVI-bII-V) turnaround progression, typically in the last 2 bars of a chorus.

**Detection:**
- Detect chord tone targeting at 4 changes within a 2-bar span.
- Each group of 2 beats contains at least one chord tone from the expected turnaround chord.

**Points:** 175
**Difficulty:** Intermediate

---

### 4.6 Grace Notes and Ornaments

#### 4.6.1 Grace Note (Crushed Note)
**Description:** A very short note (grace note) immediately before a main note, typically a half-step below. Adds blues inflection and expressiveness.

**Detection:**
- A note with duration < 50ms (or < 1/16 of the beat) immediately followed by a note 1-2 semitones higher.
- The short note's amplitude may be lower.
- In pitch detection: a very brief frequency dip just before a sustained note.

**Points:** 50
**Difficulty:** Beginner

---

#### 4.6.2 Bend/Scoop
**Description:** Starting a note below pitch and bending up to it (scoop) or bending a note upward. Fundamental blues expression.

**Detection:**
- Pitch trajectory within a single note event that starts below the target and rises.
- Detect frequency ramp: >1 semitone rise over the first 50-100ms of a note.
- Requires sub-note pitch tracking (frame-level analysis, not just note-level).

**Points:** 75
**Difficulty:** Beginner

---

### 4.7 Shuffle Phrasing

#### 4.7.1 Swing Eighth Note Feel
**Description:** Eighth notes played with a long-short pattern (approximately 2:1 ratio) rather than even. The fundamental rhythmic feel of jazz and blues.

**Detection:**
- Analyze onset timing of consecutive eighth notes.
- In swing: the "and" of each beat arrives late (closer to the third triplet than the true halfway point).
- Ratio of downbeat-eighth to upbeat-eighth duration: 1.5:1 to 2.5:1 range indicates swing.
- Compute across a 4-bar window for statistical reliability.

**Points:** 75 (consistent swing feel maintained over 4+ bars)
**Difficulty:** Beginner

---

---

## 5. Modal Jazz Language

### 5.1 Quartal Melodies

#### 5.1.1 Quartal Arpeggio (Stacked 4ths)
**Description:** Melodic figures built from stacked perfect 4ths rather than 3rds. E.g., D-G-C or E-A-D. The signature sound of McCoy Tyner and modal jazz piano. Creates an open, ambiguous, modern sound.

**Detection:**
- 3+ notes with intervals of [+5, +5] (perfect 4ths) or [+5, +6] / [+6, +5] (mix of perfect and augmented 4ths).
- Can be ascending or descending.
- Ascending: intervals of +5 or +6 between consecutive notes.
- Descending: intervals of -5 or -6.

**Points:** 150
**Difficulty:** Intermediate

---

#### 5.1.2 Quartal Melody (Horizontal)
**Description:** A longer melodic phrase constructed primarily from 4th intervals rather than stepwise motion. Contrasts with bebop's scalar/chromatic approach.

**Detection:**
- In an 8+ note phrase, 50%+ of intervals are 4ths (+/-5 or +/-6 semitones) or 5ths (+/-7).
- Few or no half-step intervals (distinguishes from bebop chromaticism).

**Points:** 200
**Difficulty:** Advanced

---

### 5.2 Pentatonic Superimposition

#### 5.2.1 Basic Pentatonic over Chord
**Description:** Playing a pentatonic scale that highlights extensions of the underlying chord. E.g., D major pentatonic (D-E-F#-A-B) over Cmaj7 yields 9-3-#11-13-7 -- all upper extensions.

**Detection:**
- Detect a pentatonic scale being played (5 notes from a pentatonic set over a phrase).
- Check if the pentatonic root is different from the chord root.
- Map the pentatonic notes to the chord and verify they create valid extensions (9, 11, 13, etc.).

**Points:** 175
**Difficulty:** Intermediate

---

#### 5.2.2 McCoy Tyner Pentatonic Sequencing
**Description:** Taking a pentatonic scale and playing it in sequences (groups of 3, 4, or 5 notes) ascending or descending through the scale. Creates the powerful, driving sound of Tyner's improvisations.

**Detection:**
- Detect a pentatonic group (3-5 notes) that repeats at different pitch levels within the pentatonic scale.
- The sequence pattern (e.g., 1-2-3, 2-3-5, 3-5-6) remains consistent.
- 3+ repetitions of the same group pattern.

**Points:** 250
**Difficulty:** Advanced

---

#### 5.2.3 Pentatonic Scale Shifting
**Description:** Abruptly switching from one pentatonic scale to another over the same chord or across chords. Creates harmonic color changes without complex chord-scale theory.

**Detection:**
- Detect pentatonic scale A for 4+ notes, then pentatonic scale B for 4+ notes.
- Scale A and B share 2 or fewer common tones (significant shift).
- Transition happens within 1-2 beats.

**Points:** 200
**Difficulty:** Advanced

---

### 5.3 Horizontal Playing (Modal Approach)

#### 5.3.1 Single Scale Extended Line
**Description:** Playing a long phrase (8+ bars) derived primarily from a single mode/scale, rather than changing scale with every chord. Emphasizes melody over harmony. The approach of Miles Davis on "Kind of Blue."

**Detection:**
- Over 8+ bars, 90%+ of notes belong to a single 7-note scale.
- Few or no chromatic alterations that would suggest chord-specific thinking.
- Phrases are longer and more rhythmically varied (not pattern-based).

**Points:** 150
**Difficulty:** Intermediate

---

#### 5.3.2 Mode-to-Mode Transition
**Description:** Shifting from one mode to another (e.g., D Dorian to Eb Dorian, as in "So What"). Clean, deliberate modal shifts rather than bebop-style modulation.

**Detection:**
- Detect scale content shifting by a specific interval at a chord change.
- All notes in phrase A belong to mode X; all notes in phrase B belong to mode Y.
- The root of mode Y is a specific interval from mode X (commonly half-step, whole-step, or minor third).

**Points:** 125
**Difficulty:** Intermediate

---

### 5.4 Coltrane Patterns (Modal Context)

#### 5.4.1 1-2-3-5 Pattern in 4ths Cycle
**Description:** The 1-2-3-5 digital pattern played through a cycle of 4ths. E.g., C-D-E-G, F-G-A-C, Bb-C-D-F... Creates the driving, spiritual intensity of later Coltrane.

**Detection:**
- Repeating 1-2-3-5 cell (intervals [+2, +2, +3] in major) where each repetition starts a perfect 4th (+5 semitones) higher than the previous.
- 3+ repetitions in cycle of 4ths.

**Points:** 250
**Difficulty:** Advanced

---

#### 5.4.2 Wide Interval Leaps (Coltrane "Sheets of Sound")
**Description:** Rapid passages with wide interval leaps (4ths, 5ths, 6ths, 7ths) rather than stepwise motion. Creates the "wall of notes" effect associated with Coltrane's middle period.

**Detection:**
- In a fast passage (16th notes or faster), 60%+ of intervals are > 4 semitones.
- Average interval size > 5 semitones over a phrase of 8+ notes.
- High note density (many notes per beat).

**Points:** 300
**Difficulty:** Advanced

---

### 5.5 Lydian Vocabulary

#### 5.5.1 Lydian Mode Line (#4 Emphasis)
**Description:** A line emphasizing the #4 (raised 4th) scale degree, giving the characteristic "bright" Lydian sound. Used over major 7th chords for added color.

**Detection:**
- Line over a major chord containing the #4 (6 semitones above root).
- The #4 should appear prominently (not just as a passing tone) -- on a relatively strong beat or held for > 1 beat.
- Other notes consistent with Lydian mode (1-2-3-#4-5-6-7).

**Points:** 125
**Difficulty:** Intermediate

---

#### 5.5.2 Lydian Chromatic Concept Line
**Description:** Based on George Russell's Lydian Chromatic Concept, where Lydian is treated as the "parent" scale. Lines exploit the natural overtone-based logic of the Lydian mode.

**Detection:**
- Extended phrase (6+ notes) using Lydian mode exclusively.
- Contains the #4 at least twice.
- Line has a "floating" quality -- avoids strong dominant-to-tonic resolution patterns.

**Points:** 175
**Difficulty:** Advanced

---

---

## 6. Post-Bop / Modern Jazz

### 6.1 Coltrane Changes

#### 6.1.1 Major Thirds Cycle Navigation
**Description:** Melodic material that navigates the "Giant Steps" substitution cycle, moving through key centers separated by major thirds (e.g., B major -> G major -> Eb major). Lines must clearly articulate each key center.

**Detection:**
- Detect 3 groups of notes, each clearly in a different key.
- The roots of the 3 keys are separated by major thirds (4 semitones): e.g., keys at 0, 4, and 8 semitones.
- Each key center is articulated by at least 1-3-5 of that key within the group.
- Very fast harmonic rhythm (2 beats per key change typical).

**Points:** 400
**Difficulty:** Advanced

---

#### 6.1.2 ii-V Pairs in Major Thirds
**Description:** Playing ii-V-I resolution in three key centers a major third apart. E.g., Am7-D7-Gmaj | F#m7-B7-Emaj | Ebm7-Ab7-Dbmaj.

**Detection:**
- Detect ii-V patterns (see 3.5.1) occurring 3 times with root movement of 4 semitones between each.
- Guide tones of each ii-V should be present.

**Points:** 450
**Difficulty:** Advanced

---

### 6.2 Side-Slipping (Chromatic Displacement)

#### 6.2.1 Half-Step Side-Slip
**Description:** Deliberately playing "outside" by shifting the entire melodic line up or down a half-step from the expected key, then resolving back. Creates dramatic tension and release.

**Detection:**
- Detect a phrase where notes suddenly shift to belong to a key 1 semitone away from the expected key.
- Duration of "outside" playing: 2-8 beats.
- Resolution: notes return to the original key, ideally targeting a strong chord tone.
- Calculate "key membership" per beat: a sudden drop from 90%+ in-key to 90%+ out-of-key, then back.

**Points:** 250
**Difficulty:** Advanced

---

#### 6.2.2 Whole-Step Side-Slip
**Description:** Same concept but shifting a whole-step. Less jarring than half-step but still clearly "outside."

**Detection:**
- Same as 6.2.1 but the displaced key is 2 semitones away.

**Points:** 225
**Difficulty:** Advanced

---

#### 6.2.3 Tension-Release Side-Slip Sequence
**Description:** Multiple side-slips in succession, creating waves of tension and release. Advanced outside playing.

**Detection:**
- 2+ side-slips detected within a 4-bar window.
- Each side-slip is followed by an "inside" resolution before the next slip.

**Points:** 350
**Difficulty:** Advanced

---

### 6.3 Intervallic Lines

#### 6.3.1 Wide Interval Melody
**Description:** Lines built primarily from intervals larger than a whole step (3rds, 4ths, 5ths, 6ths, 7ths). Creates an angular, modern sound. Associated with players like Woody Shaw, Joe Henderson.

**Detection:**
- In a phrase of 6+ notes, average interval > 3.5 semitones.
- No more than 2 consecutive stepwise intervals (prevents scalar runs from qualifying).
- Mix of ascending and descending intervals (not just an arpeggio).

**Points:** 200
**Difficulty:** Advanced

---

#### 6.3.2 Constant Interval Pattern
**Description:** A line where the same interval is repeated: e.g., all minor 3rds, all perfect 4ths. Creates a sense of geometric logic in the solo.

**Detection:**
- 4+ consecutive intervals of the same size (+/- 1 semitone tolerance).
- The repeated interval is > 2 semitones (not chromatic).

**Points:** 175
**Difficulty:** Intermediate

---

### 6.4 Triad Pairs

#### 6.4.1 Adjacent Triad Pair
**Description:** Alternating between two major or minor triads that share no common tones, creating a 6-note (hexatonic) scale. E.g., C major (C-E-G) and D major (D-F#-A) = the notes C-D-E-F#-G-A. A key device in modern jazz improvisation.

**Detection:**
- Detect two groups of 3 notes, each forming a triad (major or minor).
- The two triads share 0 common tones.
- The triads alternate: Triad A notes, then Triad B notes, then Triad A, etc.
- Notes in the phrase exclusively from the 6-note hexatonic set.

**Points:** 250
**Difficulty:** Advanced

---

#### 6.4.2 Triad Pair Sequencing
**Description:** Playing the triad pair concept in sequential patterns (ascending, descending, or in rhythmic patterns) rather than randomly alternating.

**Detection:**
- Triad pair detected (6.4.1) AND the triads are played in systematic order:
  - Ascending through inversions of A then B then A...
  - Or a consistent rhythmic grouping (3+3 or 2+2+2).
- 4+ triads in sequence.

**Points:** 300
**Difficulty:** Advanced

---

### 6.5 Hexatonic Scales

#### 6.5.1 Augmented Scale (Hexatonic 1-b3-3-5-#5-7)
**Description:** A 6-note symmetric scale alternating minor 3rds and half-steps. Contains two augmented triads. Creates a mysterious, "floating" sound.

**Detection:**
- 5+ notes from the set derived from alternating [+3, +1, +3, +1, +3, +1] intervals.
- Only 4 unique hexatonic scales exist (symmetric every major 3rd).

**Points:** 200
**Difficulty:** Advanced

---

#### 6.5.2 Whole Tone Scale Run
**Description:** All whole steps: 1-2-3-#4-#5-b7. Every note equidistant. Dreamy, unresolved sound. Only 2 unique whole tone scales exist.

**Detection:**
- 5+ consecutive notes with all intervals = +2 or -2 semitones.
- Or 5+ notes from the set {0, 2, 4, 6, 8, 10} (relative to any starting pitch).

**Points:** 125
**Difficulty:** Intermediate

---

### 6.6 Upper Structure Triads

#### 6.6.1 Triad Superimposition over Dominant
**Description:** Playing a major or minor triad whose root is a specific interval above the dominant chord root, highlighting extensions and alterations. Common upper structures over C7: Eb major (b3-5-b7 = basic chord tones), Ab major (b13-1-b3), D major (#9-#11-13), Gb major (b5-b7-b9).

**Detection:**
- Detect a major or minor triad (3 notes with intervals [+3,+4] or [+4,+3]).
- Map the triad to the current dominant chord to determine which extensions are implied.
- The triad root should NOT be the chord root (that would just be a basic arpeggio).
- Award higher points for more "distant" upper structures (bII, #IV, bVI).

**Points:** 200 (basic), 275 (altered/exotic)
**Difficulty:** Advanced

---

### 6.7 Melodic Minor Applications

#### 6.7.1 Altered Scale Line (7th mode of melodic minor)
**Description:** Playing the altered scale (Superlocrian) over a dominant 7th chord. Contains b9, #9, #11 (b5), b13. The maximum-tension dominant sound.

**Detection:**
- Over a dominant chord, notes belong to the scale built a half-step above the root in melodic minor.
- Scale degrees present include at least 2 of: b9, #9, b5/b13.
- Semitone set from dominant root: {0, 1, 3, 4, 6, 8, 10}.
- The 3rd and b7 of the dominant chord should be present (to anchor the function).

**Points:** 225
**Difficulty:** Advanced

---

#### 6.7.2 Lydian Dominant Line (4th mode of melodic minor)
**Description:** Lydian mode with a b7: 1-2-3-#4-5-6-b7. Used over dominant 7#11 chords and tritone substitutions.

**Detection:**
- Over a dominant chord, notes contain both #4 (6 semitones) and b7 (10 semitones) above root.
- Scale membership: {0, 2, 4, 6, 7, 9, 10} from root.
- Key differentiator from Mixolydian: #4 instead of natural 4.

**Points:** 200
**Difficulty:** Advanced

---

#### 6.7.3 Melodic Minor from Root
**Description:** Playing melodic minor (ascending form: 1-2-b3-4-5-6-7) over a minor chord, emphasizing the natural 7th. Creates a more modern, sophisticated minor sound than Dorian or Aeolian.

**Detection:**
- Over a minor chord context, notes include both b3 and natural 7.
- Scale set: {0, 2, 3, 5, 7, 9, 11} from root.
- The natural 7 is the distinguishing feature.

**Points:** 150
**Difficulty:** Intermediate

---

---

## 7. Latin / Bossa Nova

### 7.1 Anticipated Rhythms

#### 7.1.1 Chord Anticipation
**Description:** Arriving at the chord tone of the NEXT chord an eighth note (or more) early, on the "and" before the chord change. THE defining rhythmic characteristic of bossa nova and Latin jazz phrasing.

**Detection:**
- A note that is a chord tone of the upcoming chord, played 1 eighth note before the chord change.
- The note is then held or continued into the new chord.
- Detect by checking: is the note played in the last eighth of a chord a chord tone of the NEXT chord (not the current one)?

**Points:** 100
**Difficulty:** Beginner

---

#### 7.1.2 Syncopated Melodic Phrasing
**Description:** Melodies that consistently emphasize off-beats and "ands," creating the characteristic forward-leaning feel of Latin jazz.

**Detection:**
- Over a 4-bar window, compute the ratio of notes starting on off-beats vs. on-beats.
- If off-beat ratio > 60%, the phrasing is syncopated.
- Bonus: if the syncopation follows a consistent 2-bar rhythmic pattern (bossa clave-like).

**Points:** 125
**Difficulty:** Intermediate

---

### 7.2 Jobim-Style Melodic Characteristics

#### 7.2.1 Stepwise Melodic Motion with Extensions
**Description:** Jobim melodies characteristically move by step through chord extensions (9ths, 11ths, 13ths) rather than leaping through arpeggios. Creates a smooth, sophisticated sound.

**Detection:**
- 6+ note melody where 75%+ of intervals are stepwise (1-2 semitones).
- At least 30% of notes are chord extensions (9, 11, 13) rather than basic chord tones.
- Overall contour is smooth (few large leaps).

**Points:** 150
**Difficulty:** Intermediate

---

#### 7.2.2 Chromatic Inner Voice Movement
**Description:** A melody note sustained or repeated while an inner chromatic line moves beneath it (or implied by a single-line instrument: alternating between a pedal tone and a chromatically moving voice). Creates the harmonic sophistication of tunes like "Wave" or "How Insensitive."

**Detection:**
- Detect alternating pattern: high note (repeated) and lower note (moving chromatically).
- Pattern: A-X, A-Y, A-Z where A is constant and X-Y-Z move by half-step.
- Or the reverse: ascending chromatic line with a recurring lower pedal.

**Points:** 200
**Difficulty:** Advanced

---

### 7.3 Chord Tone Targeting (Latin Context)

#### 7.3.1 Guide Tone Targeting on Anticipated Beat
**Description:** Combining the guide tone concept (3rds and 7ths) with Latin anticipation. The guide tone arrives on the "and" before the chord change, creating both harmonic clarity and rhythmic push.

**Detection:**
- Combine criteria from 3.7.1 (guide tone voice leading) and 7.1.1 (anticipation).
- The guide tone of the new chord arrives 1 eighth note early.

**Points:** 175
**Difficulty:** Intermediate

---

#### 7.3.2 Enclosure with Latin Rhythm
**Description:** Using bebop enclosure technique but placed within Latin rhythmic phrasing -- the enclosure resolves on an anticipated beat rather than a downbeat.

**Detection:**
- Enclosure pattern (from 3.1.x) where the target note falls on an off-beat that anticipates the next chord.

**Points:** 200
**Difficulty:** Intermediate

---

---

## 8. Swing / Standards

### 8.1 Standard Licks and Vocabulary

#### 8.1.1 The "Honeysuckle Rose" Turn
**Description:** A signature figure: 5-#5-6-5 (or scale-degree equivalents). A classic swing-era melodic ornament, like a written-out trill using the chromatic note.

**Detection:**
- 4-note figure: intervals [+1, +1, -2] from a starting note that is scale degree 5.
- Or generalized: any turn figure [+1, +1, -2] or [-1, -1, +2] starting from a chord tone.

**Points:** 100
**Difficulty:** Beginner

---

#### 8.1.2 The "Lester Young" Opening
**Description:** Starting a phrase on the 9th (2nd) of the chord and descending through the chord tones. Lester Young's characteristic approach of entering phrases from "above" with a relaxed, behind-the-beat feel.

**Detection:**
- Phrase begins on scale degree 9 (2 semitones above root, up an octave context).
- Descending motion through at least 2 chord tones within the first 4-5 notes.
- Rhythmic placement: phrase starts slightly after the beat (detect late onset relative to beat grid, if available).

**Points:** 125
**Difficulty:** Intermediate

---

### 8.2 Turnaround Vocabulary

#### 8.2.1 I-VI-ii-V Turnaround Line
**Description:** A 2-bar melodic line that outlines the classic turnaround progression. Smooth voice leading through rapid chord changes.

**Detection:**
- In a 2-bar span, detect chord tone targeting at ~2-beat intervals matching a I-vi-ii-V or I-VI7-ii-V7 progression.
- Notes at each chord boundary should be chord tones of the new chord.
- Voice leading between targets should be stepwise or common-tone.

**Points:** 150
**Difficulty:** Intermediate

---

#### 8.2.2 Tritone Sub Turnaround
**Description:** Using tritone substitution in the turnaround: I-bVI7-bII7-I (instead of I-VI7-ii-V7). Creates a chromatic bass line descending in half-steps.

**Detection:**
- Over a turnaround section, detect chord tones that imply tritone-substituted chords.
- Specifically: notes implying bVI7 (instead of vi) and bII7 (instead of V).
- The melody line should have a chromatic descending character.

**Points:** 200
**Difficulty:** Advanced

---

### 8.3 Rhythm Changes Patterns

#### 8.3.1 A Section Line (I-vi-ii-V)
**Description:** A smooth eighth-note line navigating the rapid chord changes of Rhythm Changes A section. Requires clear harmonic navigation at 2-beats-per-chord tempo.

**Detection:**
- Over the A section of Rhythm Changes (if harmonic context provided), detect chord tone targeting every 2 beats.
- At least 6 of 8 chord changes have a chord tone within the 2-beat window.
- Line is predominantly eighth notes.

**Points:** 175
**Difficulty:** Intermediate

---

#### 8.3.2 B Section (Bridge) Line
**Description:** The bridge of Rhythm Changes uses a cycle-of-fifths: III7-VI7-II7-V7. Each chord lasts 2 bars. Lines here often use dominant scale material descending.

**Detection:**
- Over 8 bars with dominant chords each 2 bars.
- Each 2-bar segment contains notes consistent with a dominant chord a 4th apart from the next.
- Detect: each segment's notes belong to the Mixolydian mode of its chord root.

**Points:** 175
**Difficulty:** Intermediate

---

#### 8.3.3 Rhythm Changes Double-Time Run
**Description:** Shifting from eighth notes to sixteenth notes during Rhythm Changes, doubling the melodic activity. A common way to build energy.

**Detection:**
- Detect note density doubling: moving from ~2 notes/beat to ~4 notes/beat.
- The double-time section should last at least 2 beats.
- Notes should remain harmonically accurate (chord tone targeting maintained).

**Points:** 150
**Difficulty:** Intermediate

---

---

## 9. General Jazz Techniques (Cross-Genre)

### 9.1 Motivic Development

#### 9.1.1 Exact Repetition
**Description:** Repeating a short motif (2-6 notes) exactly, at the same pitch. Creates emphasis and coherence. Used by all great jazz improvisers.

**Detection:**
- Detect a sequence of 3-6 intervals that repeats within a 4-bar window.
- Both interval sequence AND absolute pitches match.
- Separation between occurrences: 0-8 beats.

**Points:** 100
**Difficulty:** Beginner

---

#### 9.1.2 Transposed Repetition (Sequence)
**Description:** A motif repeated at a different pitch level, maintaining the same interval pattern. May follow chord roots (tonal sequence) or move by a fixed interval (real sequence).

**Detection:**
- Detect a sequence of 3-6 intervals that matches a previously heard pattern.
- Absolute pitches differ but interval pattern is identical (+/- 1 semitone tolerance).
- Award more points for 3+ repetitions.

**Points:** 150 (2 repetitions), +75 per additional
**Difficulty:** Intermediate

---

#### 9.1.3 Rhythmic Repetition with Pitch Variation
**Description:** Maintaining the same rhythm (onset pattern) but changing the pitches. Shows rhythmic thinking and motivic awareness.

**Detection:**
- Detect two phrases with matching onset timing patterns (within 10% tolerance on each onset) but different pitch content.
- Duration of each phrase: 3-8 notes.
- Rhythm match score: compute correlation of onset times relative to bar line.

**Points:** 175
**Difficulty:** Intermediate

---

#### 9.1.4 Augmentation / Diminution
**Description:** Playing the same pitch pattern but at double (augmentation) or half (diminution) the speed.

**Detection:**
- Detect interval pattern match where the durations are scaled by ~2x or ~0.5x.
- Interval sequence identical; duration ratios consistently ~2:1 or ~1:2.

**Points:** 250
**Difficulty:** Advanced

---

#### 9.1.5 Inversion
**Description:** Flipping the contour of a motif: ascending intervals become descending and vice versa.

**Detection:**
- Detect interval sequence where each interval is the negative of a previously heard pattern.
- E.g., motif [+2, -1, +3] is inverted as [-2, +1, -3].
- Tolerance: +/- 1 semitone on each interval.

**Points:** 250
**Difficulty:** Advanced

---

### 9.2 Rhythmic Displacement

#### 9.2.1 Beat Displacement
**Description:** Repeating a phrase but shifted by 1 or 2 beats, so it starts on a different part of the bar. Creates rhythmic tension and surprise.

**Detection:**
- Detect interval+pitch pattern match where the second occurrence starts exactly 1 or 2 beats offset from where it "should" start (relative to the bar line).
- The pattern is otherwise identical.

**Points:** 200
**Difficulty:** Advanced

---

#### 9.2.2 Half-Beat (Eighth Note) Displacement
**Description:** Shifting a phrase by one eighth note. More subtle than full-beat displacement.

**Detection:**
- Same as 9.2.1 but offset is 1 eighth note.
- Every onset in the repeated pattern is shifted by ~1/2 beat.

**Points:** 225
**Difficulty:** Advanced

---

### 9.3 Sequences

#### 9.3.1 Diatonic Sequence
**Description:** A melodic pattern repeated at each scale step. E.g., playing 1-2-3, 2-3-4, 3-4-5... ascending through the scale.

**Detection:**
- Detect a pattern of N notes that repeats, with each repetition starting one diatonic step higher (or lower).
- The contour (direction of each interval) is preserved.
- Interval magnitudes may vary by 1 semitone (due to diatonic step variation).
- 3+ repetitions required.

**Points:** 150
**Difficulty:** Intermediate

---

#### 9.3.2 Chromatic Sequence
**Description:** A pattern repeated at half-step intervals. More systematic and "outside" sounding.

**Detection:**
- Pattern repeats with each repetition exactly 1 semitone higher or lower.
- Interval pattern is identical across all repetitions (real transposition).
- 3+ repetitions.

**Points:** 200
**Difficulty:** Advanced

---

#### 9.3.3 Interval Cycle
**Description:** Moving through an interval cycle: e.g., cycle of 4ths (C-F-Bb-Eb-Ab...) or cycle of minor 3rds (C-Eb-Gb-A). Applying a pattern at each station of the cycle.

**Detection:**
- Detect a pattern repeated with root movement by a consistent interval.
- The interval between pattern roots is constant (+5, +3, +4, etc.).
- 3+ stations of the cycle traversed.

**Points:** 250
**Difficulty:** Advanced

---

### 9.4 Voice Leading

#### 9.4.1 Smooth Voice Leading (Stepwise Resolution)
**Description:** Moving between chords using the smallest possible intervals. Notes change by half-step or whole-step at chord boundaries.

**Detection:**
- At chord change points, measure the interval between the last note of the old chord and first note of the new chord.
- If this interval is <= 2 semitones for 4+ consecutive chord changes, award points.

**Points:** 125
**Difficulty:** Intermediate

---

#### 9.4.2 Common Tone Connection
**Description:** Using a note that belongs to both the outgoing and incoming chords to smooth the transition.

**Detection:**
- At a chord change, the last note of phrase A and first note of phrase B are the same pitch.
- That pitch is a chord tone or extension of both chords.

**Points:** 100
**Difficulty:** Beginner

---

### 9.5 Space and Rest Usage

#### 9.5.1 Effective Use of Silence
**Description:** Leaving intentional space (rests) between phrases. Phrasing with "breathing room" shows musical maturity and compositional thinking. Miles Davis is the master of this.

**Detection:**
- Detect rests of 2+ beats between phrases.
- Score based on rest distribution: not too uniform (mechanical) and not too random.
- A solo with 30-50% rest time scores highest (optimal phrasing density).
- Compute "rest density" = total rest time / total solo time.

**Points:** 100 (per well-placed rest of 1-4 beats), 200 bonus for optimal overall density
**Difficulty:** Beginner (concept), Intermediate (execution)

---

#### 9.5.2 Phrase Length Variety
**Description:** Varying the length of phrases -- some short (2-4 notes), some long (12+ notes). Avoids monotonous phrase lengths.

**Detection:**
- Segment the solo into phrases (separated by rests > 1 beat).
- Compute standard deviation of phrase lengths.
- Higher variety (higher standard deviation) = higher score.
- Award points if at least 3 different phrase-length categories are represented (short: 1-4 notes, medium: 5-10, long: 11+).

**Points:** 150
**Difficulty:** Intermediate

---

### 9.6 Range Exploration

#### 9.6.1 Use of Full Range
**Description:** Exploring the full range of the instrument rather than staying in a comfortable middle register.

**Detection:**
- Track the highest and lowest notes across the solo.
- Compute total range in semitones.
- Award points at thresholds:
  - 12+ semitones (1 octave): base score
  - 18+ semitones (1.5 octaves): bonus
  - 24+ semitones (2 octaves): maximum
- Also check that multiple register zones are visited, not just extremes.

**Points:** 75 (1 oct) / 150 (1.5 oct) / 250 (2+ oct)
**Difficulty:** Beginner (awareness) / Intermediate (execution)

---

#### 9.6.2 Register Shift
**Description:** Deliberately leaping to a different octave for dramatic effect. The line continues in the new register.

**Detection:**
- Detect an interval of >= 10 semitones between consecutive notes.
- The line continues (3+ notes) in the new register (doesn't immediately return).
- Especially effective when the leap targets a chord tone.

**Points:** 100
**Difficulty:** Intermediate

---

### 9.7 Dynamic Contrast

#### 9.7.1 Dynamic Build (Crescendo)
**Description:** Gradually increasing volume over a phrase or section, building intensity.

**Detection:**
- Track amplitude envelope over a phrase.
- Detect a consistent upward trend in amplitude over 4+ beats.
- Compute linear regression of amplitude; positive slope above threshold = crescendo.

**Points:** 100
**Difficulty:** Beginner

---

#### 9.7.2 Dynamic Drop (Subito Piano)
**Description:** Suddenly dropping volume for dramatic contrast.

**Detection:**
- Detect amplitude drop of > 50% between consecutive phrases (or within 1-2 beats).
- The quiet passage should sustain for at least 2 beats (not just a single soft note).

**Points:** 125
**Difficulty:** Intermediate

---

#### 9.7.3 Dynamic Contour
**Description:** Overall dynamic shape across a solo -- building to a climax and resolving, or creating waves of intensity.

**Detection:**
- Divide solo into 8-bar sections.
- Compute average amplitude of each section.
- Detect a clear arc (build -> peak -> resolution) or wave pattern.
- A solo with identifiable dynamic architecture scores higher than one with flat dynamics.

**Points:** 250 (for clear overall arc)
**Difficulty:** Advanced

---

### 9.8 Articulation

#### 9.8.1 Legato Phrasing
**Description:** Notes connected smoothly with minimal silence between them.

**Detection:**
- Measure gap between consecutive notes (end of note N to start of note N+1).
- Average gap < 10% of note duration = legato.
- Consistent legato over 6+ notes.

**Points:** 75
**Difficulty:** Beginner

---

#### 9.8.2 Staccato / Marcato Phrasing
**Description:** Short, detached notes with clear separation.

**Detection:**
- Average gap between notes > 30% of note duration.
- Consistent over 4+ notes.

**Points:** 75
**Difficulty:** Beginner

---

#### 9.8.3 Articulation Contrast
**Description:** Alternating between legato and staccato sections, creating variety and expression.

**Detection:**
- Detect at least 2 passages with contrasting articulation types within the solo.
- One passage legato (gap < 10%), another staccato (gap > 30%).

**Points:** 150
**Difficulty:** Intermediate

---

---

## 10. Scoring Philosophy & Point Calibration

### 10.1 Point Scale Design

| Range | Meaning | Examples |
|-------|---------|---------|
| 50-75 | **Foundational** -- Basic elements every jazz player should know | Single chromatic approach, blue note, grace note |
| 100-150 | **Core vocabulary** -- Standard jazz language, frequently used | Enclosures, blues scale runs, guide tones, basic arpeggios |
| 150-225 | **Developing fluency** -- More complex patterns requiring deeper knowledge | Bebop scale runs, superimposed arpeggios, motivic development, altered scales |
| 225-300 | **Advanced language** -- Sophisticated techniques requiring strong ears and theory | Side-slipping, triad pairs, Coltrane changes fragments, rhythmic displacement |
| 300-500 | **Mastery-level** -- Complex, multi-dimensional patterns showing deep musical command | Full Coltrane changes navigation, extended motivic development, dynamic architecture |

### 10.2 Difficulty Tier Mapping

**Beginner (First 6 months of jazz study)**
- Chord tone identification
- Blues scale usage
- Single chromatic approaches
- Basic arpeggios (1-3-5-7)
- Grace notes
- Swing feel
- Use of space/silence
- Minor & major pentatonics

**Intermediate (6 months - 2 years)**
- Enclosures (all types)
- Bebop scale runs
- Digital patterns and sequencing
- ii-V-I lines
- Guide tone voice leading
- Blues/major mixing (Mixolydian b3)
- Call and response
- Motivic repetition and transposition
- Basic modal playing
- Turnaround vocabulary
- Latin anticipations

**Advanced (2+ years)**
- Coltrane changes
- Side-slipping
- Triad pairs
- Altered scale / melodic minor applications
- Upper structure triads
- Rhythmic displacement
- Wide intervallic lines
- Pentatonic superimposition (advanced)
- Quartal melodic construction
- Dynamic architecture / solo form
- Motivic inversion / augmentation

### 10.3 Multiplier System

Consider these score multipliers for added depth:

| Multiplier | Condition | Value |
|-----------|-----------|-------|
| **Tempo bonus** | Pattern executed at fast tempo (200+ BPM) | 1.5x |
| **Harmonic context** | Pattern correctly targets the underlying harmony | 1.25x |
| **Musical placement** | Pattern occurs at a musically meaningful moment (phrase peak, resolution point) | 1.25x |
| **Chaining** | Multiple patterns detected within the same phrase | 1.5x per additional pattern |
| **Consistency** | Same pattern type used correctly across multiple chord changes | 1.5x |
| **Variety** | Solo contains patterns from 3+ different categories | 1.25x |

### 10.4 Anti-Patterns (Deductions)

Consider deducting points for:

| Anti-Pattern | Detection | Deduction |
|-------------|-----------|-----------|
| **Noodling** (scalewise motion with no direction) | Long passages of stepwise motion with no chord tone targeting | -50 per 4 bars |
| **Stuck in a box** (limited range) | Entire solo within 8 semitones | -100 |
| **Pattern abuse** (same lick repeated excessively) | Same interval pattern detected 4+ times without variation | -25 per repeat after 3rd |
| **Lost in changes** (wrong notes over chords) | Notes consistently clash with harmony (b9 over chord root, etc.) | -50 per 4-bar section |

---

## Appendix A: Key Detection & Scale Degree Assignment

For the pattern matcher to work, each note must be assigned a scale degree relative to the current chord. This requires:

1. **Chord progression input** (from backing track metadata or user input)
2. **Beat tracking** (to know which chord is active at any given moment)
3. **Scale degree calculation:**

```
scaleDegree = (midiNote - chordRootMidi) % 12

Mapping (semitones from root):
0  = 1 (root)
1  = b9
2  = 9
3  = b3 (or #9)
4  = 3
5  = 4 (or 11)
6  = b5 (or #4/#11)
7  = 5
8  = b6 (or #5/b13)
9  = 6 (or 13)
10 = b7
11 = 7 (major 7th)
```

## Appendix B: Research Sources & References

### Academic / Computational Musicology
- [The Jazzomat Research Project](https://jazzomat.hfm-weimar.de/) -- Weimar Jazz Database, MeloSpyLib, pattern taxonomy
- [Klaus Frieler - Constructing Jazz Lines: Taxonomy, Vocabulary, Grammar](https://jazzforschung.hfm-weimar.de/wp-content/uploads/2019/06/JazzforschungHeute2019_Frieler-Constructing-Jazz-Lines.pdf)
- [Frieler - Computational Melody Analysis](https://www.mu-on.org/frieler/docs/frieler_computational_melody_analysis_2017.pdf)
- [Inside the Jazzomat](https://schott-campus.com/wp-content/uploads/2017/11/inside_the_jazzomat_final_rev_oa4.pdf)

### Pitch Detection Algorithms
- [Pitch Detection Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Pitch_detection_algorithm)
- [YIN - A Fundamental Frequency Estimator for Speech and Music](https://www.researchgate.net/publication/11367890_YIN_A_fundamental_frequency_estimator_for_speech_and_music)
- [McLeod & Wyvill - A Smarter Way to Find Pitch (MPM)](https://www.researchgate.net/publication/230554927_A_smarter_way_to_find_pitch)
- [Interactive Exploration of McLeod's Pitch Detection](https://samyak.me/post/mcleod/)
- [CREPE - Convolutional Representation for Pitch Estimation](https://arxiv.org/abs/1802.06182)
- [SPICE - Self-supervised Pitch Estimation](https://arxiv.org/pdf/1910.11664)
- [SwiftF0 - Fast and Accurate Monophonic Pitch Detection](https://arxiv.org/html/2508.18440)
- [Fast, Accurate Pitch Detection Tools for Music Analysis - McLeod](https://www.cs.otago.ac.nz/research/publications/oucs-2008-03.pdf)
- [Pitch Detection Methods Review - Stanford CCRMA](https://ccrma.stanford.edu/~pdelac/154/m154paper.htm)

### Libraries & Frameworks
- [AudioKit - Audio Synthesis, Processing & Analysis for iOS/macOS](https://github.com/AudioKit/AudioKit)
- [AudioKit Pro - Pitch Detection Tips](https://audiokitpro.com/mdecks-audio-apps-pitch-detection/)
- [Essentia - Audio Analysis Library](https://essentia.upf.edu/)
- [aubio - Audio Labelling Library](https://aubio.org/)
- [TarsosDSP - Java Real-Time Audio Processing](https://github.com/JorenSix/TarsosDSP)
- [CREPE GitHub](https://github.com/marl/crepe)
- [sevagh/pitch-detection - Autocorrelation-based Pitch Detection](https://github.com/sevagh/pitch-detection)

### Pattern Matching
- [Dynamic Time Warping - Wikipedia](https://en.wikipedia.org/wiki/Dynamic_time_warping)
- [Time-Warped Longest Common Subsequence for Music Retrieval](https://www.researchgate.net/publication/220723177_Time-Warped_Longest_Common_Subsequence_Algorithm_for_Music_Retrieval)
- [Real-Time Pattern Recognition of Symbolic Monophonic Music](https://dl.acm.org/doi/fullHtml/10.1145/3678299.3678329)

### Jazz Theory & Vocabulary
- [Anton Schwartz - Approaches and Enclosures](https://antonjazz.com/2019/07/approaches-enclosures/)
- [Learn Jazz Standards - Enclosures in Jazz Solos](https://www.learnjazzstandards.com/blog/learning-jazz/jazz-theory/use-enclosures-jazz-solos/)
- [JazzAdvice - McCoy Tyner and the Pentatonic Scale](https://www.jazzadvice.com/lessons/mccoy-tyner-and-the-pentatonic-scale/)
- [Coltrane Changes Explained](https://www.thejazzpianosite.com/jazz-piano-lessons/jazz-chord-progressions/coltrane-changes/)
- [Giant Steps - Guide to Coltrane Changes](https://pianowithjonny.com/piano-lessons/giant-steps-a-guide-to-coltrane-changes/)
- [Triad Pairs / Hexatonic Scales Introduction](https://postmodernguitarist.wordpress.com/2014/04/18/triad-pairshexatonic-scales-introduction/)
- [Gary Campbell's Triad Pairs for Jazz](http://davidvaldez.blogspot.com/2005/10/gary-campbells-triad-pairs-for-jazz.html)
- [The Jazz Piano Site - Melodic Minor Modes](https://www.thejazzpianosite.com/jazz-piano-lessons/jazz-scales/melodic-minor-modes/)
- [Learn Jazz Standards - Melodic Minor Scale Applications](https://www.learnjazzstandards.com/blog/4-application-ons-of-the-melodic-minor-scale/)
- [Rhythm Changes Explained](https://www.thejazzpianosite.com/jazz-piano-lessons/jazz-chord-progressions/rhythm-changes/)
- [Diminished Scale Patterns - JazzAdvice](https://www.jazzadvice.com/lessons/10-diminished-patterns-for-jazz-improvisation/)
- [Guide Tones - The Complete Guide](https://pianowithjonny.com/piano-lessons/guide-tones-piano-the-complete-guide/)
- [Learn Jazz Standards - Guide Tones](https://www.learnjazzstandards.com/blog/learning-jazz/jazz-theory/use-guide-tones-navigate-chord-changes/)
- [Charlie Parker Licks Analysis](https://www.jazzguitar.be/blog/charlie-parker/)
- [50 Bebop Jazz Guitar Licks](https://www.jazzguitar.be/blog/bebop-licks/)
- [Upper Structure Triads](https://www.jazzguitar.be/blog/upper-structure-triads/)
- [Motivic Development in Jazz](https://craigbuhler.com/2022/02/28/demystifying-motivic-development/)
- [Blues Melodies and the Blues Scale - Open Music Theory](https://viva.pressbooks.pub/openmusictheory/chapter/blues-melodies-and-the-blues-scale/)
- [Blue Note - Wikipedia](https://en.wikipedia.org/wiki/Blue_note)
