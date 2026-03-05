# How JazzShed Thinks About Points

> A musician's guide to what the app is actually listening for — and why.

---

## The Core Idea

JazzShed doesn't score you like a theory exam. It scores you like a bandmate who's really listening.

The system knows what chord is playing, what beat you're on, and what note you just played. From there, it asks a series of musical questions — the same questions a good jazz teacher would ask while listening to your solo:

1. **Does this note belong here?** (harmonic awareness)
2. **Is there intention behind this note?** (patterns, voice leading, tension-resolution)
3. **Are you telling a story?** (phrasing, space, development, dynamics)

Every point you earn maps to one of those three layers. The deeper the musical thinking the app detects, the more points it gives.

---

## Layer 1: Does This Note Belong Here?

Every note you play gets classified against the current chord in real time:

| What you played | What the app thinks | Points |
|---|---|---|
| **Chord tone** (root, 3rd, 5th, 7th) | "They know the harmony." | +10 (x combo multiplier) |
| **Scale tone** (diatonic to the chord) | "They're in the right neighbourhood." | +5 (x combo multiplier) |
| **Chromatic passing tone** (b3, b5 — blue notes, common passing tones) | "Could be intentional — let's see what happens next." | 0 (no penalty, no points) |
| **Clashing note** (everything else, unresolved) | "That doesn't sound like it was on purpose." | -15 penalty, combo breaks |

### Why it works this way

Jazz is full of "wrong" notes that are actually right. A b9 over a major chord sounds terrible in isolation, but it's the bread and butter of bebop when it resolves down by half step to the root. The app knows this.

**The combo counter only breaks on genuinely clashing notes that don't resolve.** Chromatic approaches, blue notes, enclosures, and intentional tension never break your combo — even if the individual note isn't "in the chord." If you approach a chord tone from a half step away and land on it, the app sees that as good jazz, not a mistake.

The philosophy is **generous, not punitive**. The app would rather miss a mistake than punish a legitimate musical choice.

---

## Layer 2: Vocabulary — Are You Speaking the Language?

This is where JazzShed gets interesting. Beyond individual note quality, the app is constantly scanning your playing for **jazz vocabulary patterns** — the melodic devices that experienced improvisers use to navigate harmony.

Think of it like language fluency. Knowing individual words (chord tones) is one thing. Stringing them into idiomatic phrases is another level entirely.

### What the app listens for

The pattern library has 80+ detectable devices across six style categories. Here's how they break down:

#### Bebop Language (the largest category)
- **Enclosures** — approaching a chord tone from above and below before landing on it. The app detects single chromatic enclosures, diatonic enclosures, double chromatic enclosures, and extended (triple) enclosures. It checks that you land on a chord tone on a strong beat.
- **Chromatic approaches** — half-step approaches from above or below into chord tones. Single, double, and extended chromatic runs that resolve.
- **Bebop scale runs** — the app knows the bebop dominant, major, and Dorian scales (the 8-note scales with the added chromatic passing tone). It checks whether your chord tones land on downbeats — the whole point of the bebop scale.
- **Digital patterns** — 1-2-3-5, 5-4-3-2, 1-3-5-7, and other scale-degree cells. The app detects these relative to the current chord, so they work in any key.
- **ii-V-I lines** — the app knows when a ii-V-I is happening in the chord chart and checks whether your line outlines each chord, with guide tone voice leading across the changes.
- **Guide tone lines** — smooth 3rd-to-7th voice leading across chord boundaries. The app tracks whether your notes at chord changes are the 3rds and 7ths, and whether they move by step.
- **Diminished patterns** — diminished arpeggios, half-whole and whole-half diminished scale runs, passing diminished chords.
- **Tritone substitution lines** — playing over the bII7 instead of V7, with chromatic resolution to the tonic.

#### Blues Language
- **Blue notes** — the app detects b3, b5, and b7 used over major/dominant chords, and gives bonus points for major/minor 3rd mixing (the "blues curl").
- **Blues scale and pentatonic runs** — both minor and major pentatonic passages.
- **Call and response** — two phrases of similar shape where the second "answers" the first.
- **Grace notes and bends** — very short notes a half step below a target (crushed notes), and pitch trajectories that start below and bend up.

#### Modal Language
- **Quartal melodies** — lines built on 4th intervals rather than 3rds. The McCoy Tyner sound.
- **Pentatonic superimposition** — using a pentatonic scale from a non-obvious root to highlight upper extensions (like D pentatonic over Cmaj7 for the 9-3-#11-13-7 sound).
- **Horizontal playing** — staying in one scale across multiple chord changes. The app awards this in modal contexts where it's musically appropriate.
- **Lydian emphasis** — highlighting the #4 over a major chord.

#### Post-Bop / Modern Language
- **Coltrane changes** — navigating major-third key cycles. The app checks that you clearly articulate each key centre.
- **Side-slipping** — deliberately shifting your line a half step out and back. The app detects the "in-out-in" shape.
- **Triad pairs** — alternating between two triads with no common tones, creating hexatonic colour.
- **Intervallic lines** — wide-interval melodies (4ths, 5ths, 6ths) rather than stepwise motion.
- **Altered dominant lines** — using the altered scale (b9, #9, #11, b13) over V7 chords, with resolution.
- **Upper structure triads** — playing a triad built on an extension of the chord (like a D major triad over C7 for the #9-#11-13 sound).

#### Swing / Standards Language
- **Swing feel** — the app analyses your onset timing to detect a ~2:1 long-short ratio on eighth notes.
- **Turnaround vocabulary** — lines that outline I-vi-ii-V progressions.
- **Chord tone targeting on strong beats** — landing on 1, 3, 5, or 7 on beats 1 and 3.
- **Tension on weak beats** — non-chord tones on 2 and 4 that resolve to chord tones.
- **Anticipated and delayed resolutions** — arriving at the next chord's tone early (beat 4) or holding tension past the change.

#### Latin / Bossa Nova
- **Anticipated rhythms** — hitting the next chord's notes an eighth note early. The defining rhythmic move in bossa nova.
- **Syncopated phrasing** — consistently emphasising off-beats.
- **Stepwise chromatic motion** — the smooth, Jobim-like half-step melodies.

### How patterns score

Patterns earn bonus points on top of the note-by-note scoring. The point values reflect musical complexity:

| Complexity | Points | Examples |
|---|---|---|
| **Foundational** | 50–75 | Single chromatic approach, blue note, grace note, swing feel |
| **Core vocabulary** | 100–150 | Enclosures, arpeggios, blues scale runs, guide tones, digital patterns |
| **Developing fluency** | 150–225 | Bebop scale runs, superimposed arpeggios, altered scale lines, motivic development |
| **Advanced** | 225–300 | Side-slipping, triad pairs, rhythmic displacement, Coltrane fragments |
| **Mastery** | 300–500 | Full Coltrane changes navigation, Giant Steps at tempo, extended motivic architecture |

The app also tracks **vocabulary diversity**. Using 10+ unique pattern types in a single session earns maximum vocabulary score. This prevents gaming the system by spamming the same enclosure shape over and over — the app wants to hear breadth, not just one trick.

---

## Layer 3: Are You Telling a Story?

The highest level of scoring goes beyond individual patterns to assess musicality — the qualities that separate a solo from a sequence of correct notes.

### Space
The app rewards **silence**. Rests of 1–4 beats between phrases earn points. A solo with 30–50% rest time (the Miles Davis zone) scores highest on phrasing density. Playing non-stop with no breathing room actually costs you points through diminishing combo returns.

### Phrase variety
The app segments your solo into phrases (separated by rests) and measures the variety of phrase lengths. Mixing short bursts (2–4 notes), medium phrases (5–10 notes), and long lines (11+) is rewarded. Monotonous phrase lengths are not.

### Motivic development
This is the big one. The app detects:
- **Exact repetition** — repeating a motif at the same pitch for emphasis.
- **Transposed repetition (sequences)** — the same interval pattern at a new pitch level. Bonus points for 3+ repetitions.
- **Rhythmic repetition** — same rhythm, different notes. Shows rhythmic thinking.
- **Augmentation / diminution** — the same motif at double or half speed.
- **Inversion** — flipping the contour of a motif (ascending becomes descending).

These are the marks of a player who's composing in real time, not just running patterns.

### Range exploration
The app tracks your highest and lowest notes. Using 2+ octaves earns maximum range points. It also detects deliberate **register shifts** — leaping to a new octave for dramatic effect.

### Dynamic contrast
Through amplitude tracking, the app detects crescendos, sudden drops in volume, and overall dynamic arcs across your solo. A solo that builds to a climax and resolves scores higher than one at a flat dynamic level.

---

## The Combo System

Consecutive "good" notes (chord tones and scale tones) build a combo multiplier:

| Streak | Multiplier |
|---|---|
| 8 notes | 2x |
| 16 notes | 3x |
| 32 notes | 4x |

The combo only breaks on **genuinely clashing, unresolved notes**. Chromatic approaches, blue notes, passing tones that resolve, and any detected pattern (even one using "outside" notes) will never break your combo. The app trusts your musical intent until proven otherwise.

---

## Star Rating

After each session, you get a star rating (1–5) based on two factors:

1. **Note choice percentage** — what fraction of your notes were harmonically strong (chord tones, scale tones, or resolved chromatic approaches).
2. **Pattern bonus** — each unique pattern type detected adds 1.5 points, up to 10 patterns.

| Stars | Threshold |
|---|---|
| 5 | 95%+ |
| 4 | 80%+ |
| 3 | 65%+ |
| 2 | 45%+ |
| 1 | Below 45% |

---

## What the App Doesn't Penalise

This matters. JazzShed is built on the principle that jazz is about tension and release, not about avoiding tension. The app will **never** penalise you for:

- **Chromatic approaches that resolve** — a half step into a chord tone is good jazz, full stop.
- **Blue notes** (b3, b5, b7) — these are the soul of the music, not mistakes.
- **Intentional tension** — notes that clash momentarily but resolve within a beat or two.
- **Playing "outside"** — if the app detects a side-slip pattern (out and back), it rewards it rather than penalising the outside notes.
- **Silence** — rests are musical. The app rewards them.

The only thing that costs you points is an unresolved clashing note — a note that doesn't belong to the chord, the scale, or any detectable pattern, and doesn't resolve to something that does. Even then, the penalty is small (-15) and the main consequence is breaking your combo.

---

## The Musical Reasoning

Every scoring decision in JazzShed traces back to a simple question: *is this what a musically aware improviser would do?*

- Chord tones on strong beats = you know where you are harmonically.
- Enclosures and approaches = you're using the bebop language intentionally.
- Guide tone voice leading = you hear the chords moving and you're connecting them.
- Motivic development = you're composing, not just running scales.
- Space and dynamics = you're listening, not just playing.
- Vocabulary diversity = you have a deep well to draw from.

The goal isn't to make you play "correctly." It's to make you aware of the vocabulary you're already using, help you discover what's missing, and turn the daily grind of shedding into something that feels like a game worth playing.

---

*JazzShed scores your playing the way a supportive bandmate listens — paying attention to what you're doing right, recognising when you're reaching for something sophisticated, and only calling you out when you're genuinely lost.*
