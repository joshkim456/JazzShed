import SwiftUI
import SwiftData

/// Vertical skill tree showing all levels and nodes with progress indicators.
struct SkillTreeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SkillTreeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.levels) { level in
                        levelSection(level)
                    }
                }
                .padding()
            }
            .background(JazzColors.background)
            .navigationTitle("Learn")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.loadProgress(modelContext: modelContext)
            }
        }
    }

    private func levelSection(_ level: SkillTreeData.Level) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Level header
            HStack {
                Text("Level \(level.id)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(JazzColors.gold)
                    .tracking(1.5)

                Text(level.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                // Level progress
                let completedCount = level.nodes.filter {
                    viewModel.progress(for: $0.id)?.isCompleted == true
                }.count
                Text("\(completedCount)/\(level.nodes.count)")
                    .font(.caption)
                    .foregroundStyle(JazzColors.textMuted)
            }

            // Nodes
            ForEach(level.nodes) { node in
                NavigationLink(destination: SkillNodeDetailView(node: node, viewModel: viewModel)) {
                    skillNodeRow(node)
                }
                .disabled(viewModel.progress(for: node.id)?.status == "locked")
            }
        }
    }

    private func skillNodeRow(_ node: SkillTreeData.SkillNode) -> some View {
        let progress = viewModel.progress(for: node.id)
        let isLocked = progress?.status == "locked"

        return HStack(spacing: 12) {
            Image(systemName: viewModel.statusIcon(for: node.id))
                .font(.title3)
                .foregroundStyle(Color(hex: viewModel.statusColor(for: node.id)))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(node.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isLocked ? JazzColors.textMuted : .white)

                if let p = progress, p.totalLicks > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<p.totalLicks, id: \.self) { i in
                            Circle()
                                .fill(i < p.licksCompleted ? JazzColors.gold : JazzColors.surfaceLight)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }

            Spacer()

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(JazzColors.textMuted)
            }
        }
        .padding(12)
        .background(isLocked ? JazzColors.surface.opacity(0.5) : JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Detail view for a skill tree node — concept explanation, lick list, exercises.
struct SkillNodeDetailView: View {
    let node: SkillTreeData.SkillNode
    let viewModel: SkillTreeViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress
                if let progress = viewModel.progress(for: node.id) {
                    HStack(spacing: 4) {
                        ForEach(0..<progress.totalLicks, id: \.self) { i in
                            Circle()
                                .fill(i < progress.licksCompleted ? JazzColors.gold : JazzColors.surfaceLight)
                                .frame(width: 12, height: 12)
                        }
                        Spacer()
                        Text("\(progress.licksCompleted)/\(progress.totalLicks) licks")
                            .font(.caption)
                            .foregroundStyle(JazzColors.textMuted)
                    }
                }

                // Concept explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONCEPT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(JazzColors.gold)
                        .tracking(1.5)

                    Text(node.conceptExplanation)
                        .font(.subheadline)
                        .foregroundStyle(JazzColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(JazzColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Licks
                VStack(alignment: .leading, spacing: 12) {
                    Text("LICKS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(JazzColors.gold)
                        .tracking(1.5)

                    ForEach(Array(node.licks.enumerated()), id: \.element.id) { index, lick in
                        let isCompleted = index < (viewModel.progress(for: node.id)?.licksCompleted ?? 0)
                        let isNext = index == (viewModel.progress(for: node.id)?.licksCompleted ?? 0)

                        NavigationLink(destination: LickPracticeView(
                            lick: lick,
                            nodeId: node.id,
                            viewModel: viewModel
                        )) {
                            lickRow(lick: lick, index: index + 1, isCompleted: isCompleted, isNext: isNext)
                        }
                        .disabled(!isCompleted && !isNext)
                    }
                }
            }
            .padding()
        }
        .background(JazzColors.background)
        .navigationTitle(node.title)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func lickRow(lick: SkillTreeData.Lick, index: Int, isCompleted: Bool, isNext: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : (isNext ? "circle" : "lock.fill"))
                .foregroundStyle(isCompleted ? JazzColors.success : (isNext ? JazzColors.gold : JazzColors.textMuted))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(index). \(lick.title)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isCompleted || isNext ? .white : JazzColors.textMuted)

                Text(lick.description)
                    .font(.caption)
                    .foregroundStyle(JazzColors.textSecondary)
            }

            Spacer()

            if isNext {
                Text("Practice")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(JazzColors.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(JazzColors.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(JazzColors.surfaceLight.opacity(isCompleted || isNext ? 1 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
