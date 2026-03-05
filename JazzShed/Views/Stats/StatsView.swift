import SwiftUI
import SwiftData

/// Stats dashboard with practice heatmap and session history.
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    summarySection

                    // Practice heatmap
                    heatmapSection

                    // Session history
                    historySection
                }
                .padding()
            }
            .background(JazzColors.background)
            .navigationTitle("Stats")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.load(modelContext: modelContext)
            }
        }
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(value: "\(viewModel.totalSessions)", label: "Sessions", icon: "music.note.list")
            summaryCard(value: String(format: "%.1fh", viewModel.totalPracticeHours), label: "Practice", icon: "clock")
            summaryCard(value: "\(viewModel.totalPatterns)", label: "Patterns", icon: "sparkle")
        }
    }

    private func summaryCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(JazzColors.gold)

            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .foregroundStyle(JazzColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRACTICE HEATMAP")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            PracticeHeatmapView(data: viewModel.heatmapData)
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SESSION HISTORY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            if viewModel.sessions.isEmpty {
                Text("No sessions yet.")
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textSecondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.sessions.prefix(20), id: \.tuneId) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.tuneTitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)

                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(JazzColors.textMuted)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(session.totalScore) pts")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(JazzColors.gold)

                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= session.starRating ? "star.fill" : "star")
                                        .font(.system(size: 8))
                                        .foregroundStyle(star <= session.starRating ? JazzColors.gold : JazzColors.textMuted)
                                }
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
}

/// GitHub-style practice heatmap using a simple grid.
struct PracticeHeatmapView: View {
    let data: [[Int]] // 7 rows (days) x 12 columns (weeks)

    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Day labels
            VStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { day in
                    Text(dayLabels[day])
                        .font(.system(size: 8))
                        .foregroundStyle(JazzColors.textMuted)
                        .frame(width: 12, height: 14)
                }
            }

            // Grid
            ForEach(0..<12, id: \.self) { week in
                VStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { day in
                        let minutes = day < data.count && week < data[day].count ? data[day][week] : 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(minutes: minutes))
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
    }

    private func heatColor(minutes: Int) -> Color {
        switch minutes {
        case 0:      return JazzColors.surfaceLight
        case 1..<5:  return JazzColors.gold.opacity(0.25)
        case 5..<15: return JazzColors.gold.opacity(0.5)
        case 15..<30: return JazzColors.gold.opacity(0.75)
        default:      return JazzColors.gold
        }
    }
}
