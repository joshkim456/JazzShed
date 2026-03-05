# App Flow Document: JazzShed

> *Screen-by-screen user journey and interaction design*

---

## 1. First-Time User Experience (Onboarding)

```
┌─────────────────────┐
│   Welcome Screen     │
│                      │
│   🎵 JazzShed       │
│                      │
│  "Turn every         │
│   practice session   │
│   into a game"       │
│                      │
│  [Get Started]       │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  What do you play?   │
│                      │
│  ○ Saxophone         │
│  ○ Trumpet           │
│  ○ Trombone          │
│  ○ Clarinet          │
│  ○ Flute             │
│  ○ Voice             │
│  ○ Other             │
│                      │
│  [Continue]          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  How long have you   │
│  been playing jazz?  │
│                      │
│  ○ Just starting     │
│  ○ 1-3 years         │
│  ○ 3-7 years         │
│  ○ 7+ years          │
│                      │
│  (Sets initial       │
│   skill tree level)  │
│                      │
│  [Continue]          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Set your daily goal │
│                      │
│  ○ Casual (5 min)    │
│  ○ Regular (10 min)  │
│  ○ Serious (15 min)  │
│  ○ Intense (20 min)  │
│                      │
│  [Continue]          │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Mic Check           │
│                      │
│  "Plug in headphones │
│   and play a few     │
│   notes so we can    │
│   hear you"          │
│                      │
│  [Listening...]      │
│                      │
│  ✓ We can hear you!  │
│  Detected: Bb4, C5.. │
│                      │
│  [Start Practicing]  │
└────────┬────────────┘
         │
         ▼
      Home Screen
```

**Design notes:**
- Onboarding takes < 60 seconds
- Mic check is critical — validates the detection works before the user plays anything
- Experience level determines where in the skill tree the user starts (beginners at Level 1, experienced players at Level 2-3)
- Daily goal feeds into the streak system

---

## 2. Home Screen

```
┌─────────────────────────────────────┐
│  JazzShed                    ⚙️     │
├─────────────────────────────────────┤
│                                     │
│  🔥 12 day streak          142 XP   │
│  ████████░░░░  Daily goal: 7/15min  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  TODAY'S CHALLENGE                  │
│  ┌─────────────────────────────┐   │
│  │  "Enclosures over Autumn    │   │
│  │   Leaves at 120 BPM"       │   │
│  │                     25 XP   │   │
│  │              [Start]        │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  CONTINUE PRACTICING                │
│  ┌──────────┐  ┌──────────┐       │
│  │ Autumn   │  │ Blue     │       │
│  │ Leaves   │  │ Bossa    │       │
│  │ ★★★☆☆   │  │ ★★☆☆☆   │       │
│  └──────────┘  └──────────┘       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  SKILL TREE PROGRESS               │
│  Level 2: Core Vocabulary           │
│  ████████░░░░░░  62% complete       │
│  Next: Enclosures (3 licks left)    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  WEEKLY STATS                       │
│  Sessions: 5  |  Time: 1h 23m      │
│  Patterns: 47 |  Best: ★★★★☆      │
│                                     │
└─────────────────────────────────────┘

Tab Bar:
[ 🏠 Home ] [ 🎵 Play ] [ 📚 Learn ] [ 📊 Stats ] [ 👤 Profile ]
```

**Interactions:**
- Tapping the daily challenge goes directly to a pre-configured play session
- "Continue Practicing" shows recently played tunes sorted by last played
- Skill tree progress is a quick-access link to the Learn tab
- Weekly stats update in real time

---

## 3. Play Screen — Tune Selection

```
┌─────────────────────────────────────┐
│  ← Back        PLAY         🔍     │
├─────────────────────────────────────┤
│                                     │
│  GENRE MODE: [Bebop ▼]             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  FAVORITES                          │
│  ┌──────────────────────────────┐  │
│  │ Autumn Leaves     Gm  ★★★☆☆│  │
│  │ All The Things    Ab  ★★☆☆☆│  │
│  │ Blue Bossa        Cm  ★★★★☆│  │
│  └──────────────────────────────┘  │
│                                     │
│  ALL STANDARDS                      │
│  ┌──────────────────────────────┐  │
│  │ A  All Of Me         C      │  │
│  │ A  All The Things    Ab     │  │
│  │ A  Autumn Leaves     Gm     │  │
│  │ B  Beautiful Love    Dm     │  │
│  │ B  Blue Bossa        Cm     │  │
│  │ B  Blues For Alice   F      │  │
│  │ C  Cherokee          Bb     │  │
│  │ C  Confirmation      F      │  │
│  │ D  Donna Lee         Ab     │  │
│  │ ...                         │  │
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**On tune selection → Configuration overlay:**

```
┌─────────────────────────────────────┐
│  AUTUMN LEAVES                      │
│  Gm (original key)                  │
├─────────────────────────────────────┤
│                                     │
│  Key:   [Gm ▼]  (transpose)        │
│  Tempo: [◀ 120 BPM ▶]              │
│  Style: [Swing ▼] [Bossa] [Ballad] │
│  Choruses: [◀ 2 ▶]                 │
│                                     │
│  Genre Scoring: Bebop               │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  PLAY WITH SCORING   ▶     │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │  FREE PLAY (no scoring)     │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 4. Play Screen — Active Session (Core Gameplay)

This is the most important screen in the app. It's what the user sees while playing their solo.

```
┌─────────────────────────────────────┐
│  ✕  Autumn Leaves  120BPM  Chorus 1│
├─────────────────────────────────────┤
│                                     │
│  SCORE: 2,450        COMBO: 24 🔥  │
│  ████ 3x multiplier                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │   Cm7       F7       BbΔ7  │   │
│  │   /  /  /  / | /  /  /  / ││   │
│  │                             │   │
│  │  [EbΔ7]    Am7b5    D7alt  │   │
│  │   /  /  /  / | /  /  /  / ││   │
│  │                             │   │
│  │   Gm7       Gm7            │   │
│  │   /  /  /  / | /  /  /  / ││   │
│  │                             │   │
│  └─────────────────────────────┘   │
│       ▲ current chord highlighted   │
│                                     │
├─────────────────────────────────────┤
│  DETECTED:                          │
│  ┌─────────────────────────────┐   │
│  │ ✦ Enclosure! +150          │   │  ← Pattern popups
│  │ ✦ Guide Tone +250          │   │     (fade after 1.5s)
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│  Bar: [████████░░░░░░░░] 12/32     │
│                                     │
│  [⏸ Pause]  [🔁 Loop]  [⏹ End]   │
└─────────────────────────────────────┘
```

**Real-time behavior:**
- **Chord chart scrolls** in sync with the backing track. Current chord is highlighted (gold border/background)
- **Score** updates in real-time as patterns are detected
- **Combo counter** increments with each "good" note. Visual intensity increases with combo (subtle glow at 2x, stronger at 3x, pulsing at 4x)
- **Pattern popups** appear briefly when a vocabulary pattern is detected — show pattern name and points earned, then fade out. Positioned so they don't block the chord chart
- **Progress bar** shows position within the tune
- **Loop button** lets you loop the current 4/8 bars for focused practice

**Visual feedback for note quality (subtle, peripheral):**
- Chord tones → brief green flash on the chord symbol
- Scale tones → no visual (neutral, expected)
- Detected pattern → gold popup with pattern name + points
- Clashing note → brief amber pulse on chord symbol (not red — jazz is forgiving)

**Audio feedback:**
- Optional subtle click/tick on detected patterns (can be disabled)
- Haptic pulse on pattern detection (iOS Taptic Engine)

---

## 5. Play Screen — Minimal Mode

For experienced players who want the utility without the gamification:

```
┌─────────────────────────────────────┐
│  ✕  Autumn Leaves  120BPM  Ch. 1   │
├─────────────────────────────────────┤
│                                     │
│   Cm7       F7       BbΔ7   EbΔ7  │
│   /  /  /  / | /  /  /  / | ...   │
│                                     │
│  [Am7b5]    D7alt     Gm7          │
│   /  /  /  / | /  /  /  / | ...   │
│                                     │
│   Cm7       F7       BbΔ7   EbΔ7  │
│   /  /  /  / | /  /  /  / | ...   │
│                                     │
│                                     │
│  Bar: [████████░░░░] 12/32         │
│  [⏸]     [🔁]     [⏹]            │
└─────────────────────────────────────┘
```

Just a chord chart and backing track. Like iReal Pro but within the app. Toggle with a single tap. Detection still runs in the background for post-session analysis, but no visual feedback during playing.

---

## 6. Results Screen (Post-Solo Analysis)

Appears after completing a solo (or tapping "End"):

```
┌─────────────────────────────────────┐
│        SOLO COMPLETE!               │
│                                     │
│        ★ ★ ★ ★ ☆                   │
│        Score: 4,280                 │
│        Personal Best: 5,120         │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  BREAKDOWN                          │
│  ┌──────────────────────────┐      │
│  │ Note Choice      ████░ 82%│     │
│  │ Rhythmic Feel    ███░░ 71%│     │
│  │ Vocabulary       ████░ 78%│     │
│  │ Space/Phrasing   ██░░░ 55%│     │
│  │ Range/Dynamics   ███░░ 68%│     │
│  └──────────────────────────┘      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  VOCABULARY DETECTED                │
│  ┌──────────────────────────┐      │
│  │ Enclosure (Simple)    x4 │      │
│  │ Chromatic Approach    x7 │      │
│  │ ii-V-I Lick          x2 │      │
│  │ Guide Tone Line      x1 │      │
│  │ Bebop Scale Run      x3 │      │
│  │ Digital Pattern       x5 │      │
│  └──────────────────────────┘      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  TIMELINE                           │
│  [▓▓▓░▓▓▓▓▓░░▓▓▓▓▓▓▓░▓▓▓▓▓▓░▓▓]  │
│   A1        A2       B        A3   │
│                                     │
│  Tap any section to replay          │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  HIGHLIGHTS                         │
│  "Strong use of enclosures in the   │
│   A sections. Your bridge (bars     │
│   17-24) was your best moment —     │
│   great guide tone movement."       │
│                                     │
│  AREAS FOR GROWTH                   │
│  "Try incorporating more space      │
│   between phrases. Your phrasing    │
│   was very continuous — rests give   │
│   your lines room to breathe."      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Play Again]  [Try Different Tune] │
│  [Share Score]                       │
│                                     │
└─────────────────────────────────────┘
```

**Timeline interaction:**
- Color intensity = quality (darker green = more patterns detected)
- Tapping a section shows the chord changes for those bars and replays the backing track from that point
- Shows which specific patterns were detected at which bar

---

## 7. Learn Screen (Skill Tree)

```
┌─────────────────────────────────────┐
│  ← Back         LEARN               │
├─────────────────────────────────────┤
│                                     │
│  YOUR PATH                          │
│                                     │
│  ✅ Level 1: Foundations            │
│  │   ✅ Major Scales & Modes       │
│  │   ✅ Basic Chord Tones          │
│  │   ✅ Simple ii-V-I Patterns     │
│  │   ✅ Blues Scale Vocabulary      │
│  │                                  │
│  🔓 Level 2: Core Vocabulary       │
│  │   ✅ Bebop Scales               │
│  │   🔵 Approach Notes ●●●○○      │
│  │      └→ 3 licks learned,        │
│  │         2 remaining              │
│  │   🔒 Enclosures                 │
│  │   🔒 Turnaround Patterns       │
│  │                                  │
│  🔒 Level 3: Intermediate          │
│  🔒 Level 4: Advanced              │
│  🔒 Level 5: Mastery               │
│                                     │
└─────────────────────────────────────┘
```

**Tapping a skill node → Skill Detail:**

```
┌─────────────────────────────────────┐
│  ← Back    APPROACH NOTES           │
├─────────────────────────────────────┤
│                                     │
│  Progress: ●●●○○ (3/5 licks)       │
│                                     │
│  CONCEPT                            │
│  "Approach notes are chromatic or   │
│   diatonic notes that lead into a   │
│   chord tone, creating tension      │
│   that resolves. They're the glue   │
│   that makes bebop lines flow."     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  LICKS                              │
│                                     │
│  1. ✅ Chromatic Below (C→Db→D)    │
│     Last reviewed: 2 days ago       │
│     Next review: tomorrow           │
│                                     │
│  2. ✅ Chromatic Above (C→B→C)     │
│     Last reviewed: today            │
│     Next review: 3 days             │
│                                     │
│  3. ✅ Double Chromatic (Eb→D→Db→C)│
│     Last reviewed: 5 days ago       │
│     ⚠️ Due for review!             │
│                                     │
│  4. 🔵 Diatonic Above              │
│     [Practice This]                 │
│                                     │
│  5. 🔒 Combined Approach           │
│     (Complete #4 to unlock)         │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  EXERCISES                          │
│  [Practice lick in all 12 keys]     │
│  [Apply over Autumn Leaves]         │
│  [Ear Training: Identify approach]  │
│                                     │
└─────────────────────────────────────┘
```

**Tapping "Practice This" on a lick → Lick Practice Screen:**

```
┌─────────────────────────────────────┐
│  ✕   DIATONIC APPROACH NOTE         │
├─────────────────────────────────────┤
│                                     │
│  LISTEN FIRST                       │
│  [▶ Play Example]                   │
│  (Audio recording of the pattern    │
│   played correctly over a chord)    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Key: C major                       │
│  Chord: CΔ7                        │
│  Pattern: D → C (2nd resolving      │
│           to root on beat 1)        │
│                                     │
│  Tempo: [◀ 80 BPM ▶]              │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  YOUR TURN                          │
│  [▶ Start Backing Track]           │
│                                     │
│  Play the diatonic approach note    │
│  over the CΔ7 chord.              │
│                                     │
│  ✓ Detected! Nice approach note.   │
│  +75 pts                            │
│                                     │
│  [Next Key: Db] [Try Again]        │
│                                     │
└─────────────────────────────────────┘
```

---

## 8. Stats Screen (Progress Dashboard)

```
┌─────────────────────────────────────┐
│           PROGRESS                   │
├─────────────────────────────────────┤
│                                     │
│  THIS WEEK                          │
│  Sessions: 6  Total: 2h 14m        │
│  Patterns detected: 89              │
│  New vocabulary: 4 licks            │
│  XP earned: 340                     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  PRACTICE HEATMAP (last 12 weeks)   │
│  Mon ░▓░▓▓░░▓▓░▓▓                 │
│  Tue ▓▓▓▓░▓▓▓░▓▓░                 │
│  Wed ░░▓▓▓░▓░▓░▓▓                 │
│  Thu ▓░░▓▓▓░▓▓░░▓                 │
│  Fri ░▓▓░░▓▓░▓▓▓░                 │
│  Sat ▓▓░▓▓░░▓░▓▓▓                 │
│  Sun ░░░▓░░▓░░▓░░                 │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  VOCABULARY WEB                     │
│          Bebop                      │
│           /\                        │
│     Blues/  \Modal                  │
│         |  ◆ |                     │
│   Latin  \  /Standards             │
│           \/                        │
│        Post-Bop                     │
│                                     │
│  (Radar chart showing relative      │
│   strength across categories)       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  KEY COVERAGE                       │
│  C ████  F ████  Bb ████████       │
│  Db ██   Gb █    B ██              │
│  ...                                │
│  (Most players over-practice Bb!)   │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  TUNE LIBRARY                       │
│  ■ ■ ■ ■ ■ ■ ■ ■ ■ ■             │
│  (Grid of all tunes, color-coded:   │
│   red=untouched, yellow=learning,   │
│   green=comfortable, gold=mastered) │
│                                     │
└─────────────────────────────────────┘
```

---

## 9. Profile Screen

```
┌─────────────────────────────────────┐
│          PROFILE                     │
├─────────────────────────────────────┤
│                                     │
│  Jazz Player                        │
│  Alto Saxophone                     │
│  Member since March 2026            │
│                                     │
│  🔥 12 day streak                  │
│  ⭐ Level 2: Core Vocabulary       │
│  🏆 14 achievements                │
│  📊 32 hours total practice        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ACHIEVEMENTS                       │
│  [First Words] [Woodshedder]       │
│  [Blues Authority] [All Keys]       │
│  [ii-V-I Initiate]                 │
│  ... [See All →]                    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  SETTINGS                           │
│  ┌──────────────────────────────┐  │
│  │ Daily Goal         15 min   │  │
│  │ Preferred Key      Concert  │  │
│  │ Instrument         Alto Sax │  │
│  │ Gamification Mode  Full     │  │
│  │ Haptic Feedback    On       │  │
│  │ Audio Feedback     Off      │  │
│  │ Dark Mode          On       │  │
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

## 10. Core User Journey Flows

### Flow A: "I have 10 minutes to practice"

```
Home → Daily Challenge → Pre-configured Play Session
  → 2 choruses of Autumn Leaves, Bebop mode, 120 BPM
  → Real-time scoring with combo multiplier
  → Results screen with breakdown
  → "Play Again" or back to Home
  → Streak maintained ✓, XP earned ✓
```

**Total time: ~8-10 minutes**

### Flow B: "I want to learn new vocabulary"

```
Home → Learn tab → Skill Tree → Select "Enclosures"
  → Read concept explanation
  → Listen to example lick
  → Practice lick over backing track
  → Detected successfully → Move to next key
  → Complete all 12 keys → Lick mastered
  → Spaced repetition schedules review
  → Back to skill tree, next lick unlocked
```

**Total time: ~15-20 minutes**

### Flow C: "I just want to play"

```
Home → Play tab → Select tune → Configure (key, tempo, style)
  → Choose "Free Play" (no scoring)
  → Minimal mode chord chart + backing track
  → Play as many choruses as desired
  → End → Still get results screen (detection ran in background)
  → See what vocabulary was detected (pleasant surprise)
  → Streak maintained ✓
```

**Total time: Open-ended**

### Flow D: "Review my vocabulary"

```
Home → Learn tab → "Due for Review" notification badge
  → Spaced repetition session
  → App presents licks that are fading from memory
  → Play each lick → Detected or not
  → Correct: review interval extends (1d → 3d → 7d → 14d → 30d)
  → Incorrect: review again within session
  → Session complete → XP bonus for retention
```

**Total time: ~5-10 minutes**

### Flow E: "Check my progress"

```
Home → Stats tab → Practice heatmap (consistency visible)
  → Vocabulary web (see genre strengths/weaknesses)
  → Key coverage map (discover Bb over-practice)
  → Tempo tracker (see speed improving over time)
  → Weekly report (comparison to last week)
```

**Total time: ~2-3 minutes**

---

## 11. Navigation Architecture

```
Tab Bar (persistent):
├── Home 🏠
│   ├── Daily Challenge → Play Session
│   ├── Continue Practicing → Play Session
│   └── Skill Tree Preview → Learn Tab
│
├── Play 🎵
│   ├── Genre Mode Selector
│   ├── Tune Browser (search, favorites, all)
│   │   └── Tune Configuration Sheet
│   │       └── Active Play Session
│   │           └── Results Screen
│   └── Free Play (quick start)
│
├── Learn 📚
│   ├── Skill Tree (5 levels)
│   │   └── Skill Node Detail
│   │       └── Lick Practice
│   │           └── 12-Key Drill
│   ├── Due for Review (spaced repetition)
│   └── Ear Training (future)
│
├── Stats 📊
│   ├── Weekly Overview
│   ├── Practice Heatmap
│   ├── Vocabulary Web
│   ├── Key Coverage Map
│   ├── Tempo Tracker
│   └── Tune Library Grid
│
└── Profile 👤
    ├── Achievements
    ├── Settings
    └── League Standing (future)
```

---

## 12. State Transitions & Edge Cases

### Audio Detection States
```
IDLE → LISTENING → DETECTING → SCORING
  ↑                    │           │
  └────────────────────┘           │
  (silence detected — phrase end)  │
                                   ↓
                              PATTERN_FOUND
                                   │
                                   ↓
                              SCORE_UPDATED
```

### Session Lifecycle
```
CONFIGURING → COUNTDOWN (3-2-1) → PLAYING → BETWEEN_CHORUSES → PLAYING → ENDING → RESULTS
                                     ↑                              │
                                     └──────── (loop if multiple)───┘

                                  PAUSED ←→ PLAYING (pause/resume)
```

### Edge Cases to Handle
1. **No notes detected for 30+ seconds** → Show gentle prompt: "We can't hear you — check your mic/headphones"
2. **Extremely high/low notes outside expected range** → Widen detection range based on instrument selection. Don't penalize
3. **Backing track finishes, player still soloing** → Allow finishing the phrase (3 second grace period), then show results
4. **App backgrounded during session** → Pause immediately, resume when foregrounded
5. **Phone call interrupts** → Pause session, resume after call
6. **Very fast passages (16th notes at high tempo)** → Reduce quantization resolution, accept coarser detection. Better to miss some patterns than false-positive
7. **Multiple instruments in room** → Confidence threshold. Only score notes with high pitch detection confidence (> 0.85)
8. **Player warming up before session starts** → Countdown period gives them time. First 2 bars are detection warm-up (no scoring penalty)

---

## 13. Data Model (High-Level)

```
User
  ├── instrument: String
  ├── experienceLevel: Int (1-4)
  ├── dailyGoalMinutes: Int
  ├── currentStreak: Int
  ├── longestStreak: Int
  ├── totalXP: Int
  ├── settings: Settings
  │
  ├── sessions: [Session]
  │   ├── tuneId: String
  │   ├── date: Date
  │   ├── tempo: Int
  │   ├── key: String
  │   ├── genreMode: GenreMode
  │   ├── durationSeconds: Int
  │   ├── totalScore: Int
  │   ├── starRating: Float (1-5)
  │   ├── noteChoicePercent: Float
  │   ├── vocabularyCount: Int
  │   ├── maxCombo: Int
  │   ├── detectedPatterns: [PatternDetection]
  │   │   ├── patternId: String
  │   │   ├── barNumber: Int
  │   │   ├── beatPosition: Float
  │   │   └── pointsAwarded: Int
  │   └── noteEvents: [NoteEvent]  (raw detection data)
  │
  ├── vocabulary: [VocabularyItem]
  │   ├── lickId: String
  │   ├── learnedDate: Date
  │   ├── lastReviewDate: Date
  │   ├── nextReviewDate: Date
  │   ├── reviewInterval: Int (days)
  │   ├── timesReviewed: Int
  │   └── successRate: Float
  │
  ├── skillTree: [SkillNodeProgress]
  │   ├── nodeId: String
  │   ├── status: .locked | .available | .inProgress | .completed
  │   └── licksCompleted: Int
  │
  └── achievements: [Achievement]
      ├── achievementId: String
      └── earnedDate: Date

Tune
  ├── id: String
  ├── title: String
  ├── composer: String
  ├── originalKey: String
  ├── form: String (AABA, blues, etc.)
  ├── chords: [[Chord]]  (bars of chords)
  ├── availableStyles: [BackingStyle]
  └── difficulty: Int (1-5)

Pattern (vocabulary template)
  ├── id: String
  ├── name: String
  ├── description: String
  ├── genre: GenreMode
  ├── tier: .beginner | .intermediate | .advanced
  ├── basePoints: Int
  ├── intervalPattern: [Int]  (semitone intervals)
  ├── scaleDegreePattern: [Int]  (optional)
  ├── rhythmConstraints: RhythmConstraints?
  ├── harmonicContext: HarmonicContext?
  └── minConfidence: Float
```

---

## 14. Technical Architecture (Simplified)

```
┌──────────────────────────────────────────────┐
│                   SwiftUI Layer               │
│  Home │ Play │ Learn │ Stats │ Profile        │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────┴──────────────────────────┐
│              ViewModel Layer                  │
│  SessionVM │ SkillTreeVM │ StatsVM │ etc.    │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────┴──────────────────────────┐
│              Service Layer                    │
│                                               │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │ AudioEngine │  │  PatternMatcher      │  │
│  │             │  │                      │  │
│  │ AVAudio +   │→ │ NoteStream →         │  │
│  │ AudioKit    │  │ Context Enrichment → │  │
│  │ PitchDetect │  │ Template Matching →  │  │
│  │             │  │ Score Emission       │  │
│  └─────────────┘  └──────────────────────┘  │
│                                               │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │ BackingTrack│  │  SpacedRepetition    │  │
│  │ Player      │  │  Scheduler           │  │
│  └─────────────┘  └──────────────────────┘  │
│                                               │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │ ChordChart  │  │  Gamification        │  │
│  │ Engine      │  │  Engine (XP, combo,  │  │
│  │             │  │  streaks, leagues)   │  │
│  └─────────────┘  └──────────────────────┘  │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────┴──────────────────────────┐
│              Data Layer                       │
│  SwiftData (local persistence)               │
│  Sessions, Vocabulary, Progress, Tunes       │
└──────────────────────────────────────────────┘
```

---

## 15. MVP Build Order

A suggested implementation sequence:

### Phase 1: Audio Foundation (Week 1-2)
1. Set up Xcode project with SwiftUI
2. Integrate AudioKit for pitch detection
3. Build basic audio pipeline: mic input → pitch detection → note events
4. Verify detection accuracy with real instruments
5. Build backing track player (AVAudioEngine)

### Phase 2: Core Gameplay (Week 3-4)
6. Chord chart data model and scrolling view
7. Context engine (current chord awareness)
8. Pattern matcher (start with 5 patterns: chord tones, chromatic approach, enclosure, arpeggio, bebop scale run)
9. Basic scoring engine + combo multiplier
10. Active play screen with real-time feedback

### Phase 3: Results & Persistence (Week 5-6)
11. Post-solo results screen
12. SwiftData models for sessions and progress
13. Practice history tracking
14. Basic streak system

### Phase 4: Learning System (Week 7-8)
15. Skill tree UI (Level 1 + 2)
16. Lick practice screen
17. Expand pattern library to 15-20 patterns
18. Tune library (10 standards)

### Phase 5: Polish & Launch (Week 9-10)
19. Home screen with daily stats
20. Progress dashboard (heatmap, vocabulary web)
21. Settings and profile
22. Visual polish, animations, sound design
23. TestFlight beta
