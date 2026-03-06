import SwiftUI
import SwiftData

/// Practice view for a single lick — plays a single-chord backing track and detects the pattern.
struct LickPracticeView: View {
    let lick: SkillTreeData.Lick
    let nodeId: String
    let viewModel: SkillTreeViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var audioEngine = AudioEngineService()
    @State private var pitchDetector = PitchDetector()
    @State private var noteSegmenter = NoteSegmenter()
    @State private var patternMatcher = PatternMatcher()
    @State private var practiceChord: Chord?
    @State private var isListening = false
    @State private var detected = false
    @State private var detectedNote = ""
    @State private var recentNotes: [NoteEvent] = []
    @State private var statusMessage = "Play the pattern to continue"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pattern info
                VStack(spacing: 12) {
                    Text("PATTERN")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(JazzColors.textMuted)
                        .tracking(1.5)

                    Text(lick.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(lick.description)
                        .font(.subheadline)
                        .foregroundStyle(JazzColors.textSecondary)
                        .multilineTextAlignment(.center)

                    // Example notes
                    Text(lick.exampleNotes)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(JazzColors.gold)
                        .padding(12)
                        .background(JazzColors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(JazzColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Detection status
                VStack(spacing: 16) {
                    if detected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(JazzColors.success)

                        Text("Pattern detected!")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(JazzColors.success)
                    } else if isListening {
                        // Live note display
                        Text(pitchDetector.currentNoteName)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)

                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundStyle(JazzColors.textSecondary)
                    }

                    // Recent notes
                    if !recentNotes.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(recentNotes.suffix(8)) { note in
                                Text(note.noteName)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(note.isChordTone == true ? JazzColors.success.opacity(0.3) : JazzColors.surfaceLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
                .frame(minHeight: 120)
                .frame(maxWidth: .infinity)
                .padding()
                .background(JazzColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Controls
                if detected {
                    HStack(spacing: 16) {
                        Button(action: markComplete) {
                            Text("Complete")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(JazzColors.gold)

                        Button(action: tryAgain) {
                            Text("Try Again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                        .tint(JazzColors.textSecondary)
                    }
                } else {
                    Button(action: toggleListening) {
                        Label(
                            isListening ? "Stop" : "Start Listening",
                            systemImage: isListening ? "stop.circle.fill" : "mic.circle.fill"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isListening ? JazzColors.accent : JazzColors.gold)
                }
            }
            .padding()
        }
        .background(JazzColors.background)
        .navigationTitle(lick.title)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            _ = await audioEngine.requestMicrophonePermission()
        }
    }

    private func toggleListening() {
        if isListening {
            pitchDetector.stop()
            isListening = false
        } else {
            audioEngine.configureSession()
            noteSegmenter.sessionStartTime = ProcessInfo.processInfo.systemUptime
            noteSegmenter.tempo = 120
            recentNotes = []
            detected = false

            // Create practice chord from lick's root and quality
            if let quality = ChordQuality(rawValue: lick.defaultChordQuality) {
                practiceChord = Chord(rootPitchClass: lick.defaultRootPitchClass, quality: quality, durationBeats: 4)
            }

            // Set up pattern matcher once per session
            patternMatcher.onPatternDetected = { detection in
                if detection.patternId == lick.targetPatternId {
                    detected = true
                    pitchDetector.stop()
                    isListening = false
                }
            }
            patternMatcher.reset()

            pitchDetector.onPitchDetected = { freq, amp, midi, onset in
                noteSegmenter.processFrame(frequency: freq, amplitude: amp, midiNote: midi, onsetDetected: onset)
            }

            noteSegmenter.onNoteEnd = { note in
                var enrichedNote = note
                if let chord = practiceChord {
                    let pc = enrichedNote.pitchClass
                    enrichedNote.scaleDegree = chord.scaleDegree(for: pc)
                    enrichedNote.isChordTone = chord.isChordTone(pc)
                    enrichedNote.chordSymbol = chord.symbol
                }
                recentNotes.append(enrichedNote)
                checkForPattern()
            }

            do {
                try pitchDetector.start()
                isListening = true
                statusMessage = "Play the pattern..."
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func checkForPattern() {
        guard recentNotes.count >= 2 else { return }
        let currentBeat = recentNotes.last?.beat ?? 0
        patternMatcher.checkPatterns(notes: recentNotes, currentBeat: currentBeat)
    }

    private func tryAgain() {
        detected = false
        recentNotes = []
        patternMatcher.reset()
    }

    private func markComplete() {
        viewModel.markLickCompleted(nodeId: nodeId, modelContext: modelContext)
        dismiss()
    }
}
