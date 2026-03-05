import SwiftUI

/// Post-solo analysis screen showing score breakdown, detected patterns, and feedback.
struct ResultsView: View {
    let viewModel: ResultsViewModel
    var onPlayAgain: () -> Void = {}
    var onDone: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Breakdown bars
                breakdownSection

                // Detected vocabulary
                vocabularySection

                // Highlights & Growth
                feedbackSection

                // Action buttons
                actionsSection
            }
            .padding()
        }
        .background(JazzColors.background)
        .navigationBarBackButtonHidden()
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("SOLO COMPLETE!")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.gold)
                .tracking(2)

            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= viewModel.session.starRating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundStyle(star <= viewModel.session.starRating ? JazzColors.gold : JazzColors.textMuted)
                }
            }

            Text("\(viewModel.session.totalScore)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                Label("\(viewModel.session.maxCombo) combo", systemImage: "flame.fill")
                Label("\(viewModel.session.detectedPatterns.count) patterns", systemImage: "sparkle")
            }
            .font(.subheadline)
            .foregroundStyle(JazzColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BREAKDOWN")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            ForEach(viewModel.breakdown, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 100, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(JazzColors.surfaceLight)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: item.percent))
                                .frame(width: geo.size.width * (item.percent / 100))
                        }
                    }
                    .frame(height: 20)

                    Text("\(Int(item.percent))%")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(JazzColors.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VOCABULARY DETECTED")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            if viewModel.patternSummary.isEmpty {
                Text("No patterns detected this session. Keep practicing!")
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.patternSummary, id: \.name) { item in
                    HStack {
                        Image(systemName: "sparkle")
                            .foregroundStyle(JazzColors.gold)
                            .font(.caption)

                        Text(item.name)
                            .font(.subheadline)
                            .foregroundStyle(.white)

                        Spacer()

                        Text("x\(item.count)")
                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                            .foregroundStyle(JazzColors.gold)

                        Text("+\(item.totalPoints)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(JazzColors.textMuted)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("HIGHLIGHTS", systemImage: "star.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(JazzColors.success)
                    .tracking(1.5)

                Text(viewModel.highlights)
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textSecondary)
                    .lineSpacing(4)
            }

            Divider().background(JazzColors.surfaceLight)

            VStack(alignment: .leading, spacing: 8) {
                Label("AREAS FOR GROWTH", systemImage: "arrow.up.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(JazzColors.warning)
                    .tracking(1.5)

                Text(viewModel.areasForGrowth)
                    .font(.subheadline)
                    .foregroundStyle(JazzColors.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: onPlayAgain) {
                Text("Play Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(JazzColors.gold)

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(JazzColors.textSecondary)
        }
    }

    // MARK: - Helpers

    private func barColor(for percent: Double) -> Color {
        switch percent {
        case 80...:   return JazzColors.success
        case 60..<80: return JazzColors.gold
        case 40..<60: return JazzColors.warning
        default:       return JazzColors.accent
        }
    }
}
