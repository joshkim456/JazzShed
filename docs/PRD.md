# Product Requirements Document: JazzShed

> *Gamifying jazz practice through real-time audio detection and vocabulary scoring*

**Working Title:** JazzShed (alternatives: ChopShop, BopQuest, The Woodshed)
**Author:** joshkim456
**Date:** 2026-03-04
**Status:** Draft v1

---

## 1. Vision

**One-liner:** Duolingo meets iReal Pro — a practice app that listens to your jazz solo, identifies the vocabulary you're using, and turns every practice session into a game.

**The problem:** Jazz improvisation is one of the hardest skills to develop because feedback is delayed (you don't know if you're improving until months later), practice is unstructured (most players don't know what to work on), and progress is invisible (there's no metric for "getting better at jazz"). Meanwhile, apps like Duolingo have proven that gamification transforms tedious daily practice into an addictive habit. No app does this for jazz improvisation.

**The opportunity:** iReal Pro is the industry standard practice tool used at Berklee, Musicians Institute, and by jazz musicians worldwide. It generates excellent backing tracks but has zero intelligence — it doesn't know what you're playing, provides no feedback, has no gamification, and no structured curriculum. There's a massive gap between "play along with a backing track" and "get better at jazz." JazzShed fills that gap.

---

## 2. Target Users

| Persona | Description | Needs |
|---------|-------------|-------|
| **The Student** | High school / university jazz student (16-25). Taking lessons, in a combo, wants to keep up with peers. | Structure, clear progression, knows what to practice |
| **The Hobbyist** | Adult amateur (25-55). Played in school, picked it back up. Practices 15-30 min/day. | Motivation to stay consistent, feel like they're progressing |
| **The Aspiring Pro** | Serious player (18-30). Transcribing, gigging, wants to expand vocabulary. | Deep analysis, advanced patterns, vocabulary tracking |

**Primary instrument focus (MVP):** Monophonic instruments — saxophone, trumpet, clarinet, flute, trombone, voice. (Polyphonic instruments like piano/guitar require different detection approaches — future expansion.)

---

## 3. Core Feature Set

### 3.1 Real-Time Audio Detection

The app listens through the device microphone while a backing track plays. It converts audio into a stream of note events (pitch, onset time, duration) using pitch detection algorithms.

**How it works:**
1. **Audio Input** → Microphone captures the player's instrument
2. **Pitch Detection** → YIN or McLeod Pitch Method algorithm converts audio to MIDI-like note events (pitch in Hz → nearest semitone, onset time, duration, confidence)
3. **Quantization** → Align detected notes to a rhythmic grid (8th notes, triplets, 16ths) relative to the backing track tempo. This is critical — the app needs to know *where* in the bar each note falls
4. **Context Engine** → Knows the current chord, beat position, and bar number from the chord chart. Converts absolute pitches to scale degrees relative to the current chord root
5. **Pattern Matcher** → Slides a window over the note stream and matches against the jazz vocabulary pattern library
6. **Scorer** → Assigns points based on detected patterns, harmonic awareness, and musical context

**Key technical constraint:** The backing track must play through the speaker/headphones while the mic listens to the live instrument. On iOS, this means routing audio carefully — the mic should only capture the instrument, not the backing track. Headphones solve this naturally (player hears backing through headphones, mic picks up only the instrument). This should be the recommended setup.

### 3.2 Jazz Vocabulary Pattern Library

The core of the app. A database of detectable jazz language patterns, each defined as:
- A sequence of intervals/scale degrees relative to the current chord
- Rhythmic constraints (e.g., must resolve on a strong beat)
- Harmonic context requirements (e.g., only valid over dominant chords)
- Point value, difficulty tier, and genre tags

See **Section 5** for the full taxonomy.

### 3.3 Genre Modes

Users select a jazz genre/style before a session. This determines which pattern pool is active and what gets scored:

| Genre Mode | Description | Active Pattern Pool |
|------------|-------------|-------------------|
| **Bebop** | Charlie Parker, Dizzy, Bud Powell era | Enclosures, chromatic approaches, bebop scale runs, digital patterns, ii-V-I licks, diminished patterns |
| **Blues** | Blues-based jazz, BB King to Cannonball | Blue notes, call and response, blues scale runs, turnaround licks, mixolydian vocabulary |
| **Modal** | Miles, Coltrane (sheets of sound era), Herbie | Quartal melodies, pentatonic superimposition, horizontal playing, pedal point lines |
| **Post-Bop** | Modern jazz, Shorter, Hancock, Woody Shaw | Side-slipping, triad pairs, intervallic lines, altered dominant vocab, Coltrane changes |
| **Standards / Swing** | Great American Songbook, classic jazz | Guide tone lines, turnaround vocabulary, swing phrasing, rhythm changes patterns |
| **Latin / Bossa** | Jobim, Getz, Latin jazz | Anticipated rhythms, chord tone targeting, syncopated phrasing |
| **All Styles** | Everything active | Full pattern library — maximum scoring potential but also maximum complexity |

### 3.4 Gamification System

#### Points & XP
- Each detected pattern earns its base point value (50-500 pts based on complexity)
- Session XP earned from total points, with multipliers:
  - **Combo multiplier:** 8 consecutive "good" notes → 2x, 16 → 3x, 32 → 4x. Resets on clashing notes
  - **Streak multiplier:** 1.5x after 7 consecutive practice days, 2x after 30 days
  - **Discomfort multiplier:** 1.25x for practicing in unfamiliar keys or above comfortable tempos
  - **Vocabulary bonus:** Using a lick you've previously learned in the skill tree during a live solo earns bonus points

#### Streaks
- Daily streak maintained by any practice activity (minimum 5 minutes)
- Visual flame icon that grows/changes color at milestones (7, 30, 100, 365)
- Streak freeze: earn one per week through consistent practice (not purchasable)
- Practice buddy streaks with friends (shared streak resets if either misses a day)

#### Achievements (Jazz-Specific)
Vocabulary badges:
- "First Words" — Learn your first 10 licks
- "Conversational" — 50 licks in vocabulary
- "Fluent" — 100+ licks memorized and reviewed
- "Encyclopedic" — 250+ licks across all categories

Harmonic badges:
- "ii-V-I Initiate" — Play ii-V-I patterns in all 12 keys
- "Rhythm Changes" — Complete a full chorus of rhythm changes
- "Giant Steps" — Survive Coltrane changes at 120+ BPM
- "Cherokee" — Navigate Cherokee at tempo

Style badges:
- "Bebop Scholar," "Modal Explorer," "Blues Authority," "Monk-ish"

Consistency badges:
- "Woodshedder" — 100 total hours of practice
- "All Keys" — First lick transposed to all 12 keys
- "Iron Ears" — 50 ear training exercises completed

#### Skill Tree
Five-level progression mirroring the real learning path of a jazz musician:

```
Level 1: Foundations
  ├── Major scales & modes
  ├── Basic chord tones (1-3-5-7)
  ├── Simple ii-V-I patterns
  └── Blues scale vocabulary

Level 2: Core Vocabulary
  ├── Bebop scales
  ├── Approach notes (chromatic, diatonic, double)
  ├── Enclosures
  └── Turnaround patterns (I-vi-ii-V)

Level 3: Intermediate
  ├── Tritone substitution vocabulary
  ├── Minor ii-V-i patterns
  ├── Rhythmic displacement
  └── Guide tone lines

Level 4: Advanced
  ├── Pentatonic superimposition
  ├── Coltrane patterns (1-2-3-5 cells)
  ├── Diminished scale patterns
  └── Altered dominant vocabulary

Level 5: Mastery
  ├── Giant Steps / Coltrane changes
  ├── Side-slipping / outside playing
  ├── Metric modulation patterns
  └── Personal voice development
```

Each node contains 3-5 licks to learn, ear training exercises, application exercises over tunes, and a spaced repetition review schedule.

#### Daily Challenges
- **"The Shed"** — Daily challenge that changes every day (e.g., "play a ii-V-I lick in F minor at 140 BPM")
- **"The Jam"** — Free play with backing tracks, XP for time spent
- **"The Ear"** — Ear training: interval recognition, chord quality identification, transcription
- **"The Workout"** — Technique builder: scales, arps, patterns in all keys
- **"The Gig"** — Performance mode: play through a set list (3-5 tunes), scored holistically

#### Leagues
Weekly XP-based competition (Duolingo-style):
- 10 tiers: Bronze → Silver → Gold → Platinum → Diamond
- 30 users per league, reshuffled weekly
- Top performers promote, bottom demote

### 3.5 Post-Solo Analysis

After each solo/session, a breakdown screen shows:
- **Overall Score:** Letter grade (A+ through F) or star rating (1-5)
- **Note Choice:** % of notes that were harmonically strong (chord tones, scale tones, resolved chromatic approaches)
- **Rhythmic Feel:** Swing ratio analysis, beat placement
- **Vocabulary Usage:** Number of learned patterns applied in context
- **Space & Phrasing:** Appropriate use of rests, phrase length variety
- **Timeline View:** Horizontal bar of the full solo, color-coded by quality. Tap any section to replay
- **Highlights:** "Best moment: bars 17-20 — great use of tritone sub vocabulary over the bridge"
- **Areas for Growth:** Actionable suggestions based on weaknesses

### 3.6 Progress Visualization

- **Practice Heatmap:** GitHub-style contribution graph showing practice days/intensity over the year
- **Tune Library:** Grid of all standards, color-coded by mastery (red → yellow → green → gold)
- **Vocabulary Web:** Radial chart showing strength across categories (blues, bebop, modal, etc.)
- **Tempo Tracker:** Line graph showing comfortable tempo increasing over time
- **Key Coverage Map:** 12-slice pie chart exposing key-practice imbalance (most players over-practice Bb and Eb)
- **Weekly Reports:** Automated summaries comparing periods ("Your ii-V-I vocabulary expanded by 4 new patterns this week")

### 3.7 Backing Tracks & Chord Charts

- Scrolling chord chart synced to backing track (like iReal Pro, but with gamification overlay)
- Tempo control with real-time speed adjustment
- Loop specific measures for focused practice
- Transposition to any key
- Multiple backing track styles per tune (swing, bossa, ballad, etc.)
- Chord chart library: start with 50 essential standards, expandable

---

## 4. Spaced Repetition System

The app uses spaced repetition to ensure learned vocabulary sticks:

- A lick played correctly: doesn't reappear for 1 day, then 3 days, then 7, then 14, then 30
- A lick played incorrectly: reappears within the same session
- Review sessions surface "fading" vocabulary before it's forgotten
- Biggest point bonuses for successful 7-day and 30-day recalls (not immediate performance)
- Schedule follows: Day 1 → Day 3 → Day 7 → Day 14 → Day 30

This replaces the Anki flashcards many jazz musicians already use for lick memorization, with the advantage that you're actually *playing* the patterns, not just reading them.

---

## 5. Jazz Vocabulary Taxonomy

### 5.1 Bebop Language

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Enclosure (Simple)** | Approach target from chromatic above + chromatic below (or reverse) | 3-note group: half step above target, half step below target, target note — where target is a chord tone on a strong beat | 150 | Beginner |
| **Enclosure (Double)** | Diatonic above → chromatic above → chromatic below → target | 4-note group with specific interval pattern resolving to chord tone | 200 | Intermediate |
| **Chromatic Approach (Below)** | Single chromatic note leading up to a chord tone | Half step below a chord tone, chord tone on strong beat | 75 | Beginner |
| **Chromatic Approach (Above)** | Single chromatic note leading down to a chord tone | Half step above a chord tone, chord tone on strong beat | 75 | Beginner |
| **Double Chromatic Approach** | Two chromatic notes approaching target from one direction | Two consecutive half steps resolving to chord tone | 100 | Beginner |
| **Bebop Scale Run** | Running the bebop dominant/major scale so chord tones land on downbeats | 5+ consecutive notes following bebop scale intervals with chord tones aligned to strong beats | 200 | Intermediate |
| **Digital Pattern (1-2-3-5)** | Classic ascending scale-degree pattern | Notes matching scale degrees 1-2-3-5 relative to current chord | 125 | Beginner |
| **Digital Pattern (other)** | Variants: 1-3-5-7, 3-5-7-9, 5-4-3-2, etc. | Notes matching specified scale-degree sequences relative to chord | 125-175 | Beginner-Intermediate |
| **ii-V-I Lick** | Multi-bar phrase outlining a ii-V-I progression | Sequence spans chord changes, uses chord tones of each chord, resolves on I | 300 | Intermediate |
| **Arpeggio Over Changes** | Outlining chord tones through clean arpeggiation | 4+ notes that are all chord tones (1-3-5-7) of the current chord | 100 | Beginner |
| **Tritone Sub Line** | Playing over the tritone substitution of a dominant chord | Notes matching the scale of the tritone sub (bII7) over a V7 chord, resolving to I | 350 | Advanced |
| **Guide Tone Line** | Smooth voice leading through 3rds and 7ths across chord changes | On each chord change, note played is the 3rd or 7th, and moves by step or common tone to the next chord's 3rd or 7th | 250 | Intermediate |
| **Diminished Arpeggio Pattern** | Using dim7 arpeggios over dominant chords | 4 notes forming a diminished 7th arpeggio (minor 3rd intervals) over a dominant chord | 200 | Intermediate |
| **Whole-Half Diminished Run** | Playing the W-H diminished scale over a dim chord | 5+ notes following alternating whole-half step intervals | 250 | Intermediate |
| **Half-Whole Diminished Run** | Playing the H-W (dominant diminished) scale over a dom7 | 5+ notes following alternating half-whole step intervals over a dominant chord | 250 | Intermediate |
| **Honeysuckle Rose Motive** | 5-#5-6 or 5-6-1 pattern | Specific scale-degree sequence detected | 125 | Beginner |
| **Cry Me a River Motive** | Descending 1-7-6-5 pattern | Specific descending scale-degree sequence | 125 | Beginner |
| **Parker-style 3rd-to-5th Chromatic** | Chromatic movement from the 3rd up to the 5th | Chromatic ascending line spanning a major 3rd starting on the chord's 3rd | 175 | Intermediate |
| **Bebop Turnaround** | Standard I-vi-ii-V vocabulary | Phrase spanning 4 chords with appropriate chord tones at each change | 350 | Intermediate |
| **Passing Diminished** | Chromatic passing diminished chord between diatonic chords | Diminished arpeggio used as chromatic connector between two diatonic chord tones | 200 | Intermediate |
| **5-4-3-2 Building Block** | Classic bebop descending cell (4-8 notes) | Descending pattern balancing stepwise and intervallic motion from the 5th | 150 | Beginner |

### 5.2 Blues Language

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Blue Note (b3)** | Using the minor 3rd over a major chord | b3 scale degree detected over a major or dominant chord | 75 | Beginner |
| **Blue Note (b5)** | The "blue fifth" — b5 over any chord | b5 scale degree in a melodic context | 75 | Beginner |
| **Blue Note (b7)** | Dominant 7th flavor over a major context | b7 used melodically over a major chord | 75 | Beginner |
| **Major/Minor 3rd Mixing** | Alternating between major and minor 3rd (the "blues curl") | Both b3 and natural 3 appearing within a short window over the same chord | 150 | Beginner |
| **Blues Scale Run** | Pentatonic minor + b5 scale pattern | 5+ consecutive notes fitting the blues scale | 100 | Beginner |
| **Call and Response** | Melodic question followed by a related answer phrase | Two phrases of similar length and contour within 2-4 bars, second phrase a variation of the first | 250 | Intermediate |
| **Turnaround Lick (Blues)** | Standard blues turnaround vocabulary (last 2 bars) | Recognized pattern over I-IV-I-V in the final bars | 200 | Intermediate |
| **Grace Note / Crush** | Quick chromatic grace note into a target | Very short note (< 1/16th) a half step below target, followed immediately by target | 75 | Beginner |
| **Shuffle Phrasing** | Triplet-based rhythmic feel with swung 8ths | Consistent triplet subdivision detected in note onsets | 100 | Beginner |
| **Pentatonic Run** | Clean pentatonic scale passage | 5+ notes fitting minor or major pentatonic scale | 75 | Beginner |
| **Blues Riff / Repeated Figure** | Short repeated melodic figure (characteristic of blues) | Same 3-5 note pattern detected 2+ times within 4 bars | 150 | Beginner |

### 5.3 Modal Jazz Language

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Quartal Melody** | Line built on 4th intervals | 3+ notes separated by perfect 4ths (5 semitones) | 200 | Intermediate |
| **Pentatonic Superimposition** | Using a pentatonic from a different scale degree than expected | Pentatonic pattern where the root is not the chord root (e.g., D pentatonic over Cmaj7) | 300 | Advanced |
| **Horizontal Playing** | Staying in one scale across multiple chord changes | Same scale used for 4+ bars ignoring chord changes (valid in modal context) | 150 | Intermediate |
| **Pedal Point Line** | Returning to the same note repeatedly while melody moves around it | One note appears 3+ times within a phrase with other notes moving around it | 175 | Intermediate |
| **Lydian #4 Emphasis** | Highlighting the #4 in a Lydian context | #4 scale degree played prominently (on a strong beat or repeated) over a major chord | 150 | Intermediate |
| **So What Voicing** | Quartal voicing pattern (the iconic modal sound) | 4ths stacked: specific interval pattern of 4-4-4-3 (or inversion) | 200 | Intermediate |
| **Dorian Color Tone** | Emphasizing the natural 6 over a minor chord | Natural 6th degree on strong beats over a minor chord (distinguishing Dorian from Aeolian) | 125 | Intermediate |
| **Wide Interval Leap** | Leaps of a 5th or greater (Coltrane-influenced) | Two consecutive notes 7+ semitones apart in an intentional melodic context | 175 | Intermediate |

### 5.4 Post-Bop / Modern Jazz

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Coltrane Pattern (1-2-3-5)** | Giant Steps-era cell pattern | Ascending 1-2-3-5 pattern applied through major 3rd key center cycles | 350 | Advanced |
| **Side-Slipping** | Shifting a pattern up or down a half step for tension | Recognized pattern detected a half step away from expected key center, followed by resolution back | 400 | Advanced |
| **Intervallic Line** | Line built on wide intervals (4ths, 5ths, 6ths) rather than stepwise motion | Average interval between notes > 4 semitones over 5+ notes | 250 | Advanced |
| **Triad Pair** | Alternating between two adjacent triads | Two triads identified in alternating succession (e.g., C major and D major triads interleaved) | 350 | Advanced |
| **Upper Structure Triad** | Playing a triad built on an upper extension of the chord | Major or minor triad detected whose root is the 5th, b7th, 9th, or #11th of the current chord | 300 | Advanced |
| **Altered Dominant Line** | Using the altered scale (superlocrian) over a V7 | Notes fitting the altered scale (b9, #9, #11, b13) over a dominant chord, resolving to I | 350 | Advanced |
| **Lydian Dominant Line** | Using Lydian dominant (#4 over dom7) | #4 scale degree over a dominant chord in a melodic context | 250 | Advanced |
| **Hexatonic / Augmented Scale Run** | Augmented scale patterns | Notes fitting the 1-#2-3-5-#5-7 hexatonic pattern | 300 | Advanced |
| **Melodic Minor Application** | Using melodic minor from a non-obvious root | Notes fitting a melodic minor scale whose root differs from the chord root by a specific interval | 300 | Advanced |
| **Giant Steps Pattern** | Navigating major 3rd key-center cycles | Chord tones correctly outlined through Coltrane changes (keys moving by major 3rds) | 500 | Advanced |

### 5.5 Standards / Swing

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Swing 8th Feel** | Proper swing ratio in 8th note phrasing | Onset timing analysis showing ~2:1 ratio between downbeat and upbeat 8ths | 100 | Beginner |
| **Rhythm Changes Line** | Vocabulary specific to rhythm changes (I Got Rhythm) form | Pattern recognized over the specific harmonic rhythm of AABA rhythm changes | 300 | Intermediate |
| **Turnaround (I-vi-ii-V)** | Standard turnaround vocabulary | Phrase correctly outlines all 4 chords in a I-vi-ii-V | 250 | Intermediate |
| **Chord Tone on Strong Beat** | Landing on a chord tone (1, 3, 5, 7) on beats 1 or 3 | Note on beat 1 or 3 is a chord tone of the current harmony | 50 | Beginner |
| **Tension on Weak Beat** | Non-chord tone on weak beat resolving to chord tone on strong beat | Non-diatonic note on beat 2 or 4 followed by chord tone on next strong beat | 100 | Beginner |
| **Anticipated Resolution** | Resolving to the next chord's chord tone slightly early | Chord tone of the *next* chord played on beat 4 of the *current* chord | 150 | Intermediate |
| **Delayed Resolution** | Holding tension past the chord change before resolving | Non-chord tone sustained past a chord change, resolving within beat 2 | 175 | Intermediate |

### 5.6 Latin / Bossa Nova

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Anticipated Rhythm** | Playing ahead of the beat (characteristic of Latin) | Note onsets consistently 1/8th-1/16th ahead of the grid | 125 | Beginner |
| **Syncopated Chord Tone Targeting** | Hitting chord tones on the "and" of beats | Chord tones appearing on off-beats in a consistent pattern | 150 | Intermediate |
| **Stepwise Chromatic Line (Jobim)** | Smooth chromatic melody characteristic of bossa | 4+ notes moving by half step in a lyrical, unhurried rhythm | 175 | Intermediate |
| **Rhythmic Motif Repetition** | Repeating a rhythmic pattern with new pitches | Same rhythm detected twice with different notes (>50% different pitches) | 200 | Intermediate |

### 5.7 General Jazz Techniques (Cross-Genre, Always Active)

| Pattern | Description | Detection Logic | Points | Tier |
|---------|-------------|-----------------|--------|------|
| **Motivic Development** | Repeating and transforming a short motif | 3-5 note pattern detected, then a variation (transposed, inverted, augmented, or truncated) within 4-8 bars | 300 | Intermediate |
| **Rhythmic Displacement** | Shifting a melodic pattern's starting beat | Same pitch pattern detected starting on a different beat than its first appearance | 250 | Advanced |
| **Sequence** | Repeating a pattern at a different pitch level | Same interval pattern detected at 2+ pitch levels within 4 bars | 200 | Intermediate |
| **Use of Space** | Musical rest between phrases | Rest of 1+ beats between phrases (rewarding silence rather than constant playing) | 100 | Beginner |
| **Phrase Length Variety** | Mixing short and long phrases | Standard deviation of phrase lengths > threshold over a chorus | 150 | Intermediate |
| **Range Exploration** | Using the full range of the instrument | Notes spanning 2+ octaves within a chorus | 100 | Beginner |
| **Rhythmic Variety** | Mixing note durations (8ths, triplets, 16ths, long tones) | Multiple rhythmic subdivisions detected within a solo | 150 | Intermediate |
| **Dynamic Contrast** | Variation in volume/intensity | Amplitude variation exceeding a threshold across the solo | 125 | Intermediate |
| **Resolution Awareness** | Ending phrases on chord tones | Last note of a phrase is a chord tone of the current chord | 75 | Beginner |

---

## 6. Scoring Philosophy

The detection system must be **generous, not punitive**. Jazz is about tension and release — "wrong" notes are contextual. The scoring uses a probabilistic model:

| Note Type | Scoring |
|-----------|---------|
| Chord tone (1, 3, 5, 7) on strong beat | Full points |
| Scale tone on any beat | Good points |
| Chromatic approach resolving to chord/scale tone | Good points (bonus if enclosure/approach pattern detected) |
| Tension note that resolves | Neutral (no penalty, potential pattern bonus) |
| Unresolved non-diatonic note | Small penalty (breaks combo, but no point deduction) |

**The combo counter only resets on genuinely clashing notes that don't resolve** — never for chromatic approaches, blue notes, or intentional tension.

---

## 7. Tech Stack Recommendation

### Primary: Swift / SwiftUI (Native iOS)

**Why iOS native:**
- **Audio latency:** AVAudioEngine provides the lowest possible audio latency on any mobile platform. For real-time pitch detection, latency matters enormously — you need < 20ms to feel responsive
- **AudioKit:** The AudioKit library (open source, Swift-native) provides production-ready pitch detection (YIN, McLeod algorithms), audio analysis, and DSP. This is the most mature audio processing library for any mobile platform
- **Already familiar with Swift/SwiftUI** — no new language to learn
- **Practice apps are mobile-first** — phone on the music stand, headphones in, backing track playing
- **Native UI performance** — SwiftUI's animation system handles the real-time visual feedback (combo counters, note indicators, scrolling chord charts) with buttery 60fps
- **Haptic feedback** — Taptic Engine for satisfying feedback on pattern detection (subtle pulse when you nail an enclosure)

### Core Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **UI** | SwiftUI | Declarative, modern, great for complex animated interfaces |
| **Audio Input** | AVAudioEngine | Apple's low-level audio framework. Direct mic access with minimal latency |
| **Pitch Detection** | AudioKit / SoundpipeAudioKit | Open-source Swift framework with YIN and McLeod pitch detection built in. Battle-tested |
| **Backing Track Playback** | AVAudioEngine | Simultaneous playback and recording through the same audio graph |
| **Data Persistence** | SwiftData | Native Apple persistence. Stores practice history, vocabulary progress, user settings |
| **Charts / Visualization** | Swift Charts | Built-in framework for progress graphs, heatmaps, radar charts |
| **Animations** | SwiftUI + Core Animation | For real-time gameplay feedback (combo counters, pattern flash, score popups) |

### Future / Backend (Not MVP)

| Layer | Technology | Why |
|-------|-----------|-----|
| **User Accounts & Sync** | Firebase Auth + Firestore OR CloudKit | Firebase for cross-platform potential, CloudKit for Apple-native simplicity |
| **Leaderboards** | Firebase Realtime DB or GameKit | Weekly league system needs server-side state |
| **AI Style Analysis** | On-device Core ML or server-side API | Future feature: analyzing playing style patterns. Start with on-device to avoid API costs |
| **Social Features** | Firebase or custom backend | Friend system, challenges, shared streaks |
| **Chord Chart Library** | JSON files bundled + remote CDN | Start with bundled charts, allow user-created charts later |

### Alternative Stack (If Cross-Platform Becomes Priority)

| Layer | Technology |
|-------|-----------|
| **Framework** | React Native + Expo |
| **Audio** | expo-av + native audio modules (custom native bridge for pitch detection) |
| **Pitch Detection** | Native module wrapping AudioKit (iOS) / TarsosDSP (Android) |
| **UI** | React Native + Reanimated for animations |
| **Backend** | Same Firebase stack |

**Recommendation:** Start native iOS. The audio latency advantage and AudioKit ecosystem make it significantly easier to build the core detection engine. If the app proves the concept, build Android later (potentially as a React Native app that shares the UI layer but uses native audio modules).

---

## 8. MVP Scope (v1.0)

### In Scope
- [ ] Real-time pitch detection (monophonic instruments)
- [ ] Core vocabulary detection: enclosures, chromatic approaches, arpeggios, chord tone awareness, blue notes, basic patterns (15-20 patterns)
- [ ] One genre mode: **Bebop** (the most pattern-rich and algorithmically detectable)
- [ ] Backing track playback with scrolling chord chart (10 essential standards)
- [ ] Combo multiplier and session scoring
- [ ] Post-solo analysis screen (note choice %, vocabulary count, timeline view)
- [ ] Practice streak tracking
- [ ] Basic progress dashboard (practice heatmap, session history)
- [ ] Skill tree: Level 1 and Level 2 only
- [ ] Local data persistence (SwiftData)
- [ ] Tempo control

### Out of Scope (v2+)
- [ ] All genre modes (Blues, Modal, Post-Bop, Latin, Standards)
- [ ] Skill tree Levels 3-5
- [ ] Leaderboards and leagues
- [ ] Social features (friend system, challenges)
- [ ] AI-powered style analysis
- [ ] Spaced repetition system (complex scheduling logic)
- [ ] Ear training module
- [ ] User-created chord charts
- [ ] Android version
- [ ] User accounts / cloud sync
- [ ] Daily challenges

---

## 9. Future Feature: AI Style Analysis

> *Deferred to v3+ due to API costs and complexity*

The vision: after accumulating enough playing data (50+ sessions), the app builds a "style profile" of the player:
- What vocabulary do they default to? (e.g., "You lean heavily on blues vocabulary and chromatic approaches, but rarely use enclosures or tritone subs")
- What keys are they comfortable in?
- What tempos do they struggle at?
- Comparison to "style profiles" of famous players ("Your vocabulary most resembles a mix of Cannonball Adderley and Sonny Stitt")

**Implementation options:**
1. **On-device Core ML model** — Train a classifier on transcribed solos of famous players. Compare the user's pattern distribution to the training set. No API costs, but limited sophistication
2. **Server-side LLM analysis** — Send session summary data (not audio, just detected patterns and statistics) to Claude/GPT for natural-language analysis. Low data volume but requires API calls
3. **Statistical approach** — No AI needed. Just compare the user's pattern frequency distribution to a database of famous players' pattern distributions using cosine similarity. Cheapest and most elegant for v1 of this feature

**Recommendation:** Start with option 3 (statistical). Upgrade to option 2 for richer natural-language insights if users want it.

---

## 10. UI / Visual Design Direction

### Color Palette (Dark Mode Default)
Musicians practice in low-light environments. Dark mode is the only appropriate default.

- **Background:** Dark grey `#1A1A2E` (not pure black — softer on eyes)
- **Primary Accent (Gold/Amber):** `#D4A373` — warmth of brass, smoky jazz clubs, vintage vibes. For achievements, streaks, XP
- **Secondary (Deep Blue):** `#0F3460` — Kind of Blue, late-night sessions. For cards, secondary surfaces
- **Text:** Warm white `#E8E8E8`
- **Positive (Green):** `#4CAF50` at 80% saturation — correct notes, mastery
- **Alert (Soft Red):** `#E57373` — errors, streak breaks. Never harsh
- **Special (Purple):** `#7B68EE` — legendary achievements, premium

### Visual Language
- **Typography:** Clean sans-serif for UI, a jazz-flavored display font for headers (brush script or mid-century modern, used sparingly)
- **Illustrations:** Vintage jazz poster aesthetics — silhouettes, instruments, abstract musical shapes. NOT cartoony (no Duolingo owl — this app respects the player as a serious musician)
- **Animations:** Musical micro-interactions. Button presses with subtle "swing" feel. Loading states pulsing to tempo. Transitions should feel rhythmic
- **Sound design:** Tasteful audio feedback — a soft piano chord for achievements, brush sweep for transitions

### Key Screens
1. **Home** — Streak counter, daily challenge preview, XP progress, "continue practicing" button
2. **Play** — Scrolling chord chart + real-time feedback overlay (combo counter, note indicators)
3. **Results** — Post-solo breakdown with score, categories, timeline
4. **Progress** — Heatmap, tune library, vocabulary web, tempo tracker
5. **Learn** — Skill tree, individual lick practice with spaced repetition
6. **Profile** — Achievements, stats, settings

---

## 11. Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Pitch detection inaccuracy in noisy environments | High | Require headphones for backing track (mic only hears instrument). Tune detection confidence threshold. Allow manual "headphone mode" toggle |
| Pattern matching too strict (false negatives) | High | Use fuzzy matching with tolerance for slight rhythmic and pitch variations. Playtest extensively with real musicians |
| Pattern matching too loose (false positives) | Medium | Require minimum confidence score. Weight context (harmonic position, beat placement) heavily |
| Users gaming the system (playing scale runs for points) | Medium | Weight context-aware patterns much higher than simple scale runs. Diminishing returns on repeated identical patterns within a session |
| Backing track bleed into microphone | High | Headphone requirement. Potentially implement audio source separation (computationally expensive — future) |
| AudioKit dependency risk | Low | AudioKit is well-maintained, open source, and widely used. Fallback: implement YIN algorithm directly (well-documented, ~200 lines of code) |
| Gamification feeling patronizing to serious musicians | Medium | "Minimal mode" toggle that strips gamification overlay. Clean, sophisticated visual design. Jazz-appropriate tone in all copy |

---

## 12. Success Metrics

| Metric | Target (6 months post-launch) |
|--------|-------------------------------|
| Daily Active Users | 1,000+ |
| Day-7 Retention | > 40% |
| Day-30 Retention | > 20% |
| Average session length | > 10 minutes |
| Streak maintenance (7-day) | > 30% of active users |
| App Store rating | > 4.5 stars |
| Practice sessions per user per week | > 4 |

---

## Appendix A: Pattern Detection Algorithm Overview

### Pitch Detection Pipeline
1. **Audio buffer** (44.1kHz, mono) → 2048-sample frames with 75% overlap
2. **YIN algorithm** → fundamental frequency estimate (Hz) + confidence (0-1)
3. **Note onset detection** → amplitude envelope + spectral flux to detect when new notes begin
4. **Frequency → MIDI mapping** → Hz to nearest MIDI note number (A4 = 440Hz = MIDI 69)
5. **Quantization** → Snap onsets to nearest rhythmic grid position (relative to backing track tempo + time signature)
6. **Output** → Stream of `NoteEvent(pitch: Int, startBeat: Float, duration: Float, velocity: Float)`

### Pattern Matching Pipeline
1. **Context enrichment** → For each NoteEvent, compute: scale degree relative to current chord root, interval from previous note, whether it's a chord tone / scale tone / chromatic
2. **Sliding window** → For each new note, check all pattern templates against the recent note history
3. **Template matching** → Each pattern template defines: required intervals or scale degrees, length, rhythmic constraints, harmonic context. Match using tolerance thresholds
4. **Overlap resolution** → When multiple patterns match overlapping note ranges, keep the highest-scoring / longest / most specific match
5. **Score emission** → Matched patterns emit score events with point values, which feed the combo system and session totals

### Key Algorithms
- **YIN Pitch Detection** — Autocorrelation-based, ~97% accuracy for monophonic instruments at 44.1kHz with 2048-sample window
- **McLeod Pitch Method (MPM)** — Similar accuracy, better for noisy environments. AudioKit implements both
- **Beat Tracking** — Not needed if we control the backing track (we know the tempo and beat positions exactly)
