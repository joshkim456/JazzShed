import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SkillTreeViewModel {
    let levels = SkillTreeData.allLevels
    var nodeProgress: [String: SkillNodeProgress] = [:]

    func loadProgress(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<SkillNodeProgress>()
        if let results = try? modelContext.fetch(descriptor) {
            nodeProgress = Dictionary(uniqueKeysWithValues: results.map { ($0.nodeId, $0) })
        }

        // Initialize any missing progress entries
        for node in SkillTreeData.allNodes {
            if nodeProgress[node.id] == nil {
                let progress = SkillNodeProgress(nodeId: node.id, totalLicks: node.licks.count)
                // First nodes of level 1 are available, rest are locked
                if node.prerequisiteNodeIds.isEmpty {
                    progress.status = "available"
                }
                modelContext.insert(progress)
                nodeProgress[node.id] = progress
            }
        }

        try? modelContext.save()
    }

    func progress(for nodeId: String) -> SkillNodeProgress? {
        nodeProgress[nodeId]
    }

    func statusIcon(for nodeId: String) -> String {
        guard let progress = nodeProgress[nodeId] else { return "lock.fill" }
        switch progress.status {
        case "completed":   return "checkmark.circle.fill"
        case "inProgress":  return "circle.dotted"
        case "available":   return "circle"
        default:            return "lock.fill"
        }
    }

    func statusColor(for nodeId: String) -> String {
        guard let progress = nodeProgress[nodeId] else { return "6B6B80" }
        switch progress.status {
        case "completed":   return "4ECCA3"
        case "inProgress":  return "D4A373"
        case "available":   return "0F3460"
        default:            return "6B6B80"
        }
    }

    func markLickCompleted(nodeId: String, modelContext: ModelContext) {
        guard let progress = nodeProgress[nodeId] else { return }
        progress.licksCompleted += 1
        progress.lastPracticedDate = Date()

        if progress.licksCompleted >= progress.totalLicks {
            progress.status = "completed"
            // Unlock dependent nodes
            unlockDependentNodes(completedNodeId: nodeId, modelContext: modelContext)
        } else {
            progress.status = "inProgress"
        }

        try? modelContext.save()
    }

    private func unlockDependentNodes(completedNodeId: String, modelContext: ModelContext) {
        for node in SkillTreeData.allNodes {
            guard node.prerequisiteNodeIds.contains(completedNodeId) else { continue }
            guard let progress = nodeProgress[node.id] else { continue }
            guard progress.status == "locked" else { continue }

            // Check if ALL prerequisites are met
            let allPrereqsMet = node.prerequisiteNodeIds.allSatisfy { prereqId in
                nodeProgress[prereqId]?.isCompleted == true
            }

            if allPrereqsMet {
                progress.status = "available"
            }
        }
    }
}
