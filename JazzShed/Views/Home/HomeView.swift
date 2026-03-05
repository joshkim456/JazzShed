import SwiftUI
import SwiftData

/// Main home screen with streak, daily progress, recent tunes, and weekly stats.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak + daily goal
                    streakSection

                    // Recent tunes
                    recentTunesSection

                    // Weekly stats
                    weeklyStatsSection
                }
                .padding()
            }
            .background(JazzColors.background)
            .navigationTitle("JazzShed")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.load(modelContext: modelContext)
            }
        }
    }

    private var streakSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Streak
                HStack(spacing: 8) {
                    if viewModel.streakFlame != .none {
                        Image(systemName: viewModel.streakFlame.icon)
                            .foregroundStyle(Color(hex: viewModel.streakFlame.color))
                    }
                    Text("\(viewModel.user?.currentStreak ?? 0) day streak")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                // XP
                Text("\(viewModel.user?.totalXP ?? 0) XP")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(JazzColors.gold)
            }

            // Daily goal progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Daily Goal")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)
                    Spacer()
                    Text("\(Int(viewModel.dailyGoalProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(JazzColors.surfaceLight)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(JazzColors.gold)
                            .frame(width: geo.size.width * viewModel.dailyGoalProgress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recentTunesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT SESSIONS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            if viewModel.recentSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(JazzColors.textMuted)
                    Text("No sessions yet. Start your first practice!")
                        .font(.subheadline)
                        .foregroundStyle(JazzColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentSessions, id: \.tuneId) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.tuneTitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            Text("\(session.tempo) BPM")
                                .font(.caption)
                                .foregroundStyle(JazzColors.textMuted)
                        }

                        Spacer()

                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= session.starRating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(star <= session.starRating ? JazzColors.gold : JazzColors.textMuted)
                            }
                        }
                    }
                    .padding(10)
                    .background(JazzColors.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THIS WEEK")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            HStack(spacing: 16) {
                statBadge(value: "\(viewModel.weeklySessionCount)", label: "Sessions")
                statBadge(value: "\(viewModel.weeklyPracticeMinutes)m", label: "Practice")
                statBadge(value: "\(viewModel.weeklyPatternCount)", label: "Patterns")
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(JazzColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
