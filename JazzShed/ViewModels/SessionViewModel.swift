import Foundation
import Observation
import SwiftData

/// Drives the active play session, wiring together the audio pipeline and analysis engine.
///
/// Data flow: Mic → PitchDetector → NoteSegmenter → ContextEngine.enrich()
///          → PatternMatcher → ScoreEngine → UI
@Observable
@MainActor
final class SessionViewModel: Identifiable {
    let id = UUID()
    // MARK: - Session State

    enum SessionState: Equatable {
        case idle
        case countdown(Int)     // Number of beat circles filled so far (0...N)
        case playing
        case paused
        case finished
    }

    private(set) var state: SessionState = .idle
    private(set) var tune: Tune?
    private(set) var tempo: Int = 120
    private(set) var choruses: Int = 2

    // Pause/resume tracking
    private var pausedAtBeat: Double = 0
    private var pauseStartTime: TimeInterval = 0

    // MARK: - Audio

    private let audioEngine = AudioEngineService()
    private let pitchDetector = PitchDetector()
    private let noteSegmenter = NoteSegmenter()
    let backingPlayer = BackingTrackPlayer()

    // MARK: - Analysis

    private let contextEngine = ContextEngine()
    private let patternMatcher = PatternMatcher()
    let scoreEngine = ScoreEngine()

    // MARK: - UI State

    private(set) var enrichedNotes: [NoteEvent] = []
    private(set) var recentPatterns: [PatternDetection] = []
    private(set) var currentBeat: Double = 0
    private(set) var currentChordSymbol: String = ""
    private(set) var currentBarNumber: Int = 0
    private(set) var currentChorus: Int = 1
    private(set) var elapsedSeconds: Int = 0
    private(set) var error: String?

    // Live note display
    enum NoteDisplayQuality {
        case chordTone, scaleTone, chromatic, clashing, none
    }
    private(set) var liveNoteName: String = "-"
    private(set) var liveNoteQuality: NoteDisplayQuality = .none

    // Pattern popup display
    private(set) var activePopup: PatternDetection?
    private var popupTimer: Timer?

    // Beat update timer
    private var beatTimer: Timer?

    // Session timing
    private var sessionStartSystemTime: TimeInterval = 0

    // MARK: - Configuration

    func configure(tune: Tune, tempo: Int, choruses: Int) {
        self.tune = tune
        self.tempo = tempo
        self.choruses = choruses

        // Load tune into context engine
        contextEngine.loadTune(tune, choruses: choruses)
    }

    // MARK: - Session Lifecycle

    func startSession() {
        guard let tune else { return }

        // Request mic permission + configure audio session
        Task {
            let granted = await audioEngine.requestMicrophonePermission()
            guard granted else {
                error = "Microphone permission required"
                return
            }

            audioEngine.configureSession()

            // Setup backing track
            backingPlayer.setup()
            do {
                try backingPlayer.loadSoundFont(named: "GeneralUser_GS")
            } catch {
                // Continue without sound font — backing will be silent
                self.error = "No SoundFont: backing track will be silent"
            }

            // Run countdown
            await runCountdown()

            // Wire audio pipeline
            wireAudioPipeline()

            // Start pitch detection
            do {
                try pitchDetector.start()
            } catch {
                self.error = "Pitch detection error: \(error.localizedDescription)"
                return
            }

            // Start backing track
            let slots = tune.toMIDISlots()
            do {
                try backingPlayer.play(slots: slots, tempo: Double(tempo), choruses: choruses)
            } catch {
                self.error = "Backing track error: \(error.localizedDescription)"
            }

            // Start beat update timer
            startBeatTimer()

            state = .playing
        }
    }

    func pauseSession() {
        // Save beat position before stopping (currentBeat returns 0 when not playing)
        pausedAtBeat = backingPlayer.currentBeat
        pauseStartTime = ProcessInfo.processInfo.systemUptime

        state = .paused
        pitchDetector.stop()
        backingPlayer.stop()
        beatTimer?.invalidate()
    }

    func resumeSession() {
        guard case .paused = state else { return }

        // Exclude paused duration from elapsed time
        let pauseDuration = ProcessInfo.processInfo.systemUptime - pauseStartTime
        sessionStartSystemTime += pauseDuration

        // Restart pitch detection
        do {
            try pitchDetector.start()
        } catch {
            self.error = "Pitch detection error: \(error.localizedDescription)"
            return
        }

        // Resume backing track from saved position
        backingPlayer.resume(fromBeat: pausedAtBeat)

        // Restart beat timer
        startBeatTimer()

        state = .playing
    }

    func endSession() {
        pitchDetector.stop()
        backingPlayer.stop()
        beatTimer?.invalidate()
        popupTimer?.invalidate()
        audioEngine.deactivateSession()
        state = .finished
    }

    /// Creates session data for the results screen.
    var sessionData: ResultsViewModel.SessionData {
        ResultsViewModel.SessionData(
            tuneTitle: tune?.title ?? "Free Play",
            tempo: tempo,
            totalScore: scoreEngine.totalScore,
            starRating: scoreEngine.starRating,
            noteChoicePercent: scoreEngine.noteChoicePercent,
            maxCombo: scoreEngine.maxCombo,
            detectedPatterns: scoreEngine.detectedPatterns,
            enrichedNotes: enrichedNotes,
            durationSeconds: elapsedSeconds,
            chordToneCount: scoreEngine.chordToneCount,
            scaleToneCount: scoreEngine.scaleToneCount,
            chromaticCount: scoreEngine.chromaticCount,
            clashingCount: scoreEngine.clashingCount,
            totalNotesScored: scoreEngine.totalNotesScored
        )
    }

    /// Persists session to SwiftData and updates user profile.
    func saveSession(modelContext: ModelContext) {
        let session = PracticeSession(
            tuneId: tune?.id ?? "free-play",
            tuneTitle: tune?.title ?? "Free Play",
            tempo: tempo,
            key: tune?.originalKey ?? "C",
            choruses: choruses,
            durationSeconds: elapsedSeconds,
            totalScore: scoreEngine.totalScore,
            starRating: scoreEngine.starRating,
            noteChoicePercent: scoreEngine.noteChoicePercent,
            vocabularyCount: scoreEngine.detectedPatterns.count,
            maxCombo: scoreEngine.maxCombo,
            chordToneCount: scoreEngine.chordToneCount,
            scaleToneCount: scoreEngine.scaleToneCount,
            totalNotesPlayed: scoreEngine.totalNotesScored
        )
        session.detectedPatterns = scoreEngine.detectedPatterns
        session.noteEvents = enrichedNotes

        modelContext.insert(session)

        // Update user profile XP and streak
        let descriptor = FetchDescriptor<UserProfile>()
        if let user = try? modelContext.fetch(descriptor).first {
            user.totalXP += scoreEngine.totalScore
            user.totalPracticeSeconds += elapsedSeconds
            StreakManager.updateStreak(user: user, sessionDuration: elapsedSeconds)
        }

        try? modelContext.save()
    }

    // MARK: - Chord Chart Data

    /// Returns the flattened chord list for UI display.
    var chordTimeline: [ContextEngine.ChordAtBeat] {
        contextEngine.allChords
    }

    var totalBeats: Double {
        contextEngine.totalBeats
    }

    var beatsPerChorus: Double {
        contextEngine.beatsPerChorus
    }

    // MARK: - Private

    /// Number of count-in beats (time signature numerator).
    var countInBeats: Int {
        tune?.timeSignature.first ?? 4
    }

    private func runCountdown() async {
        let beatDuration = 60.0 / Double(tempo)
        let total = countInBeats

        // Show empty circles first (filled = 0)
        state = .countdown(0)
        try? await Task.sleep(for: .seconds(beatDuration))

        // Fill circles one at a time, synced to BPM
        for i in 1...total {
            state = .countdown(i)
            try? await Task.sleep(for: .seconds(beatDuration))
        }
    }

    private func wireAudioPipeline() {
        sessionStartSystemTime = ProcessInfo.processInfo.systemUptime
        noteSegmenter.sessionStartTime = sessionStartSystemTime
        noteSegmenter.tempo = Double(tempo)

        enrichedNotes = []
        recentPatterns = []
        scoreEngine.reset()
        patternMatcher.reset()

        // PitchDetector → NoteSegmenter
        pitchDetector.onPitchDetected = { [weak self] freq, amp, midi, onset in
            self?.noteSegmenter.processFrame(frequency: freq, amplitude: amp, midiNote: midi, onsetDetected: onset)
        }

        // NoteSegmenter → ContextEngine → PatternMatcher → ScoreEngine
        noteSegmenter.onNoteEnd = { [weak self] note in
            guard let self else { return }
            Task { @MainActor in
                self.processCompletedNote(note)
                self.liveNoteName = "-"
                self.liveNoteQuality = .none
            }
        }

        // Also process notes as they start (for real-time feedback)
        noteSegmenter.onNoteStart = { [weak self] note in
            guard let self else { return }
            Task { @MainActor in
                let enriched = self.contextEngine.enriched(note)
                // Update current chord display
                if let symbol = enriched.chordSymbol {
                    self.currentChordSymbol = symbol
                }
                // Update live note display
                self.liveNoteName = MIDIHelpers.noteLabel(for: enriched.midiNote)
                self.liveNoteQuality = self.classifyForDisplay(enriched)
            }
        }

        // PatternMatcher callback
        patternMatcher.onPatternDetected = { [weak self] detection in
            guard let self else { return }
            Task { @MainActor in
                self.scoreEngine.processPattern(detection)
                self.recentPatterns.append(detection)
                self.showPopup(detection)
            }
        }
    }

    private func classifyForDisplay(_ note: NoteEvent) -> NoteDisplayQuality {
        guard let isChordTone = note.isChordTone,
              let scaleDegree = note.scaleDegree else {
            return .none
        }
        if isChordTone { return .chordTone }

        // Check scale tones via chord quality
        if let chordSymbol = note.chordSymbol {
            for quality in ChordQuality.allCases {
                if chordSymbol.hasSuffix(quality.symbol),
                   quality.scaleTones.contains(scaleDegree) {
                    return .scaleTone
                }
            }
        }

        // Common chromatic passing tones (b3 blue note, b6)
        if [3, 8].contains(scaleDegree) { return .chromatic }

        return .clashing
    }

    @MainActor
    private func processCompletedNote(_ note: NoteEvent) {
        var enriched = contextEngine.enriched(note)
        enrichedNotes.append(enriched)

        // Score the note
        scoreEngine.processNote(enriched)

        // Check for patterns (using last 10 notes as window)
        let window = Array(enrichedNotes.suffix(10))
        patternMatcher.checkPatterns(notes: window, currentBeat: enriched.beat ?? currentBeat)
    }

    private func startBeatTimer() {
        beatTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateBeatPosition()
            }
        }
    }

    @MainActor
    private func updateBeatPosition() {
        guard case .playing = state else { return }

        currentBeat = backingPlayer.currentBeat
        elapsedSeconds = Int(ProcessInfo.processInfo.systemUptime - sessionStartSystemTime)

        if beatsPerChorus > 0 {
            currentChorus = Int(currentBeat / beatsPerChorus) + 1
            currentBarNumber = Int(currentBeat.truncatingRemainder(dividingBy: beatsPerChorus) / 4)
        }

        // Check if backing track finished
        if backingPlayer.isComplete {
            endSession()
        }

        // Update current chord from beat position
        if let chordContext = contextEngine.chordAt(beat: currentBeat) {
            currentChordSymbol = chordContext.chord.symbol
        }
    }

    @MainActor
    private func showPopup(_ detection: PatternDetection) {
        activePopup = detection
        popupTimer?.invalidate()
        popupTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.activePopup = nil
            }
        }
    }
}
