import SwiftUI

/// Temporary debug view for Phase 1 — shows raw pitch detection data,
/// note segmentation, and lets you test the backing track player.
struct DebugSessionView: View {
    @State private var audioEngine = AudioEngineService()
    @State private var pitchDetector = PitchDetector()
    @State private var noteSegmenter = NoteSegmenter()
    @State private var backingPlayer = BackingTrackPlayer()

    @State private var micPermissionGranted = false
    @State private var isDetecting = false
    @State private var isBackingPlaying = false
    @State private var statusMessage = "Tap Start to begin"
    @State private var recentNotes: [NoteEvent] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Status
                    statusSection

                    // MARK: - Live Pitch Data
                    if isDetecting {
                        livePitchSection
                    }

                    // MARK: - Controls
                    controlsSection

                    // MARK: - Backing Track
                    backingSection

                    // MARK: - Detected Notes
                    detectedNotesSection
                }
                .padding()
            }
            .background(JazzColors.background)
            .navigationTitle("Audio Debug")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                micPermissionGranted = await audioEngine.requestMicrophonePermission()
                if !micPermissionGranted {
                    statusMessage = "Microphone permission denied"
                }
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(isDetecting ? JazzColors.success : JazzColors.textMuted)
                    .frame(width: 12, height: 12)
                Text(statusMessage)
                    .foregroundStyle(JazzColors.textSecondary)
            }
            .font(.subheadline)

            if let error = audioEngine.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(JazzColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var livePitchSection: some View {
        VStack(spacing: 12) {
            Text("Live Pitch Detection")
                .font(.headline)
                .foregroundStyle(JazzColors.gold)

            // Big note display
            Text(pitchDetector.currentNoteName)
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            // Details
            HStack(spacing: 24) {
                VStack {
                    Text("Freq")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)
                    Text(String(format: "%.1f Hz", pitchDetector.currentFrequency))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(JazzColors.textSecondary)
                }

                VStack {
                    Text("MIDI")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)
                    Text("\(pitchDetector.currentMIDINote)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(JazzColors.textSecondary)
                }

                VStack {
                    Text("Amp")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)
                    Text(String(format: "%.3f", pitchDetector.currentAmplitude))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(JazzColors.textSecondary)
                }
            }

            // Amplitude bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(amplitudeColor)
                    .frame(width: geo.size.width * CGFloat(min(pitchDetector.currentAmplitude * 5, 1.0)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 8)
            .background(JazzColors.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var amplitudeColor: Color {
        let amp = pitchDetector.currentAmplitude
        if amp > 0.15 { return JazzColors.success }
        if amp > 0.05 { return JazzColors.gold }
        return JazzColors.textMuted
    }

    private var controlsSection: some View {
        HStack(spacing: 16) {
            Button(action: toggleDetection) {
                Label(
                    isDetecting ? "Stop" : "Start",
                    systemImage: isDetecting ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(isDetecting ? JazzColors.accent : JazzColors.gold)
            .disabled(!micPermissionGranted)

            Button(action: clearNotes) {
                Label("Clear", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(JazzColors.textSecondary)
        }
    }

    private var backingSection: some View {
        VStack(spacing: 12) {
            Text("Backing Track")
                .font(.headline)
                .foregroundStyle(JazzColors.gold)

            Button(action: toggleBacking) {
                Label(
                    isBackingPlaying ? "Stop Backing" : "Play Test Backing",
                    systemImage: isBackingPlaying ? "stop.fill" : "play.fill"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(isBackingPlaying ? JazzColors.accent : JazzColors.blue)

            if isBackingPlaying {
                Text(String(format: "Beat: %.1f", backingPlayer.currentBeat))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(JazzColors.textSecondary)
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var detectedNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Detected Notes")
                    .font(.headline)
                    .foregroundStyle(JazzColors.gold)
                Spacer()
                Text("\(recentNotes.count)")
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textMuted)
            }

            if recentNotes.isEmpty {
                Text("Play your instrument to see detected notes...")
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                // Show last 20 notes, newest first
                ForEach(recentNotes.suffix(20).reversed()) { note in
                    HStack {
                        Text(note.noteLabel)
                            .font(.body.weight(.semibold).monospaced())
                            .foregroundStyle(.white)
                            .frame(width: 50, alignment: .leading)

                        Text(String(format: "%.1f Hz", note.frequency))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(JazzColors.textMuted)

                        Spacer()

                        Text(String(format: "%.0fms", note.duration * 1000))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(JazzColors.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(JazzColors.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func toggleDetection() {
        if isDetecting {
            pitchDetector.stop()
            noteSegmenter.reset()
            isDetecting = false
            statusMessage = "Stopped"
        } else {
            audioEngine.configureSession()
            noteSegmenter.sessionStartTime = ProcessInfo.processInfo.systemUptime

            // Wire pitch detector → note segmenter
            pitchDetector.onPitchDetected = { freq, amp, midi in
                noteSegmenter.processFrame(frequency: freq, amplitude: amp, midiNote: midi)
            }

            noteSegmenter.onNoteEnd = { note in
                recentNotes.append(note)
            }

            do {
                try pitchDetector.start()
                isDetecting = true
                statusMessage = "Listening..."
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func toggleBacking() {
        if isBackingPlaying {
            backingPlayer.stop()
            isBackingPlaying = false
        } else {
            // Test with a simple C major → A minor → D minor → G7 progression (4 bars)
            let testSlots: [MIDISequencer.ChordSlot] = [
                .init(root: 0, quality: "maj7", startBeat: 0, durationBeats: 4),   // Cmaj7
                .init(root: 9, quality: "min7", startBeat: 4, durationBeats: 4),   // Am7
                .init(root: 2, quality: "min7", startBeat: 8, durationBeats: 4),   // Dm7
                .init(root: 7, quality: "7", startBeat: 12, durationBeats: 4),     // G7
            ]

            backingPlayer.setup()

            // Try to load SoundFont, but backing still works without it (just no sound from samplers)
            do {
                try backingPlayer.loadSoundFont(named: "GeneralUser_GS")
            } catch {
                statusMessage = "No SoundFont loaded — backing will be silent. Add a .sf2 file to Resources/SoundFonts/"
            }

            do {
                try backingPlayer.play(slots: testSlots, tempo: 120, choruses: 2)
                isBackingPlaying = true
            } catch {
                statusMessage = "Backing error: \(error.localizedDescription)"
            }
        }
    }

    private func clearNotes() {
        recentNotes = []
        noteSegmenter.reset()
    }
}

#Preview {
    DebugSessionView()
        .preferredColorScheme(.dark)
}
