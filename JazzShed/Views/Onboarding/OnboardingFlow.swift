import SwiftUI
import SwiftData

/// Four-step onboarding: instrument, experience, daily goal, mic check.
struct OnboardingFlow: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            JazzColors.background.ignoresSafeArea()

            VStack(spacing: 32) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i <= viewModel.currentStep ? JazzColors.gold : JazzColors.surfaceLight)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case 0: welcomeStep
                    case 1: instrumentStep
                    case 2: experienceStep
                    case 3: goalStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Continue button
                Button(action: advance) {
                    Text(viewModel.currentStep == viewModel.totalSteps - 1 ? "Start Practicing" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(JazzColors.gold)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundStyle(JazzColors.gold)

            Text("JazzShed")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

            Text("Turn every practice session into a game")
                .font(.title3)
                .foregroundStyle(JazzColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var instrumentStep: some View {
        VStack(spacing: 20) {
            Text("What do you play?")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(Instrument.allCases) { instrument in
                    Button {
                        viewModel.selectedInstrument = instrument
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(instrument.rawValue)
                                    .foregroundStyle(.white)
                                if instrument == .piano {
                                    Text("Single-note lines only")
                                        .font(.caption)
                                        .foregroundStyle(JazzColors.textMuted)
                                }
                            }
                            Spacer()
                            if viewModel.selectedInstrument == instrument {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(JazzColors.gold)
                            }
                        }
                        .padding(12)
                        .background(viewModel.selectedInstrument == instrument ? JazzColors.surfaceLight : JazzColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var experienceStep: some View {
        VStack(spacing: 20) {
            Text("How long have you been playing jazz?")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            let options: [(label: String, level: Int)] = [
                ("Just starting", 1),
                ("1-3 years", 2),
                ("3-7 years", 3),
                ("7+ years", 4),
            ]

            VStack(spacing: 8) {
                ForEach(options, id: \.level) { option in
                    Button {
                        viewModel.experienceLevel = option.level
                    } label: {
                        HStack {
                            Text(option.label)
                                .foregroundStyle(.white)
                            Spacer()
                            if viewModel.experienceLevel == option.level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(JazzColors.gold)
                            }
                        }
                        .padding(12)
                        .background(viewModel.experienceLevel == option.level ? JazzColors.surfaceLight : JazzColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var goalStep: some View {
        VStack(spacing: 20) {
            Text("Set your daily goal")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            let goals: [(label: String, minutes: Int, desc: String)] = [
                ("Casual", 5, "Perfect for busy days"),
                ("Regular", 10, "A solid daily habit"),
                ("Serious", 15, "Real progress every day"),
                ("Intense", 20, "Maximum growth"),
            ]

            VStack(spacing: 8) {
                ForEach(goals, id: \.minutes) { goal in
                    Button {
                        viewModel.dailyGoalMinutes = goal.minutes
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(goal.label) — \(goal.minutes) min")
                                    .foregroundStyle(.white)
                                Text(goal.desc)
                                    .font(.caption)
                                    .foregroundStyle(JazzColors.textMuted)
                            }
                            Spacer()
                            if viewModel.dailyGoalMinutes == goal.minutes {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(JazzColors.gold)
                            }
                        }
                        .padding(12)
                        .background(viewModel.dailyGoalMinutes == goal.minutes ? JazzColors.surfaceLight : JazzColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func advance() {
        if viewModel.currentStep < viewModel.totalSteps - 1 {
            viewModel.currentStep += 1
        } else {
            viewModel.completeOnboarding(modelContext: modelContext)
            onComplete()
        }
    }
}
