import SwiftUI

/// The core gameplay screen — displays during an active play session.
/// Shows scrolling chord chart, score, combo, and pattern popups.
struct ActiveSessionView: View {
    @Bindable var viewModel: SessionViewModel

    var body: some View {
        ZStack {
            JazzColors.background.ignoresSafeArea()

            if case .idle = viewModel.state {
                EmptyView()
            } else if case .finished = viewModel.state {
                EmptyView() // Navigation handles transition to results
            } else {
                // Session content is always rendered during countdown/playing/paused
                // so the layout doesn't shift when countdown disappears
                sessionContent

                // Translucent countdown overlay
                if case .countdown(let filled) = viewModel.state {
                    JazzColors.background.opacity(0.7)
                        .ignoresSafeArea()
                    countdownView(filled)
                }
            }
        }
        .statusBarHidden(viewModel.state != .idle)
    }

    // MARK: - Countdown

    private func countdownView(_ filledCount: Int) -> some View {
        let total = viewModel.countInBeats
        return VStack(spacing: 24) {
            HStack(spacing: 16) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < filledCount ? JazzColors.gold : JazzColors.surfaceLight)
                        .frame(width: 20, height: 20)
                        .animation(.easeInOut(duration: 0.15), value: filledCount)
                }
            }

            if let tune = viewModel.tune {
                Text(tune.title)
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("\(viewModel.tempo) BPM")
                    .foregroundStyle(JazzColors.textSecondary)
            }
        }
    }

    // MARK: - Session Content

    private var sessionContent: some View {
        VStack(spacing: 0) {
            // Top bar: tune info + session controls
            sessionHeader

            // Score + Combo
            scoreBar

            // Chord chart
            if let tune = viewModel.tune {
                ChordChartView(
                    tune: tune,
                    currentBeat: viewModel.currentBeat,
                    beatsPerChorus: viewModel.beatsPerChorus
                )
            }

            // Pattern popup area
            patternPopupArea

            // Progress bar
            progressBar

            // Mixer
            MixerPanelView(player: viewModel.backingPlayer)

            // Controls
            SessionControlsView(viewModel: viewModel)
        }
    }

    private var sessionHeader: some View {
        HStack {
            Button(action: { viewModel.endSession() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(JazzColors.textSecondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.tune?.title ?? "")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(viewModel.tempo) BPM  ·  Chorus \(viewModel.currentChorus)")
                    .font(.caption)
                    .foregroundStyle(JazzColors.textMuted)
            }

            Spacer()

            // Elapsed time
            Text(formatTime(viewModel.elapsedSeconds))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(JazzColors.textMuted)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(JazzColors.surface)
    }

    private var scoreBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.caption2)
                    .foregroundStyle(JazzColors.textMuted)
                Text("\(viewModel.scoreEngine.totalScore)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Multiplier
            if viewModel.scoreEngine.multiplier > 1.0 {
                Text("\(Int(viewModel.scoreEngine.multiplier))x")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(JazzColors.goldBright)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(JazzColors.gold.opacity(0.2))
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("COMBO")
                    .font(.caption2)
                    .foregroundStyle(JazzColors.textMuted)
                HStack(spacing: 4) {
                    Text("\(viewModel.scoreEngine.comboCount)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(comboColor)
                        .contentTransition(.numericText())
                    if viewModel.scoreEngine.comboCount >= 8 {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(comboColor)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: viewModel.scoreEngine.totalScore)
        .animation(.easeInOut(duration: 0.2), value: viewModel.scoreEngine.comboCount)
    }

    private var comboColor: Color {
        switch viewModel.scoreEngine.comboCount {
        case 32...:  return JazzColors.accent
        case 16..<32: return JazzColors.goldBright
        case 8..<16:  return JazzColors.gold
        default:       return .white
        }
    }

    private var patternPopupArea: some View {
        ZStack {
            if let popup = viewModel.activePopup {
                PatternPopupView(detection: popup)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(height: 50)
        .animation(.easeInOut(duration: 0.3), value: viewModel.activePopup?.id)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = viewModel.totalBeats > 0
                ? viewModel.currentBeat / viewModel.totalBeats
                : 0

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(JazzColors.surfaceLight)

                RoundedRectangle(cornerRadius: 2)
                    .fill(JazzColors.gold)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Pattern popup notification.
struct PatternPopupView: View {
    let detection: PatternDetection

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .foregroundStyle(JazzColors.goldBright)

            Text(detection.patternName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text("+\(detection.pointsAwarded)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(JazzColors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(JazzColors.surface.opacity(0.95))
        .clipShape(Capsule())
        .shadow(color: JazzColors.gold.opacity(0.3), radius: 8)
    }
}

/// Session control buttons at the bottom.
struct SessionControlsView: View {
    @Bindable var viewModel: SessionViewModel

    private var isPaused: Bool {
        viewModel.state == .paused
    }

    var body: some View {
        HStack(spacing: 32) {
            Button(action: {
                if isPaused {
                    viewModel.resumeSession()
                } else {
                    viewModel.pauseSession()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.caption2)
                }
                .foregroundStyle(isPaused ? JazzColors.gold : JazzColors.textSecondary)
            }

            Button(action: { viewModel.endSession() }) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                    Text("End")
                        .font(.caption2)
                }
                .foregroundStyle(JazzColors.accent)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(JazzColors.surface)
    }
}
