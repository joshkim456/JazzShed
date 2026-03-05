import SwiftUI

// MARK: - Display Model

/// A single row in the chord chart (up to 4 bars).
struct ChartRow: Identifiable {
    let id: Int
    let sectionLabel: String?
    let bars: [ChartBar]
    let isSectionStart: Bool
    let isLastRow: Bool
}

/// A single bar containing 1–2 chords.
struct ChartBar: Identifiable {
    let id: Int
    let chords: [DisplayChord]
    let startBeat: Double
    let durationBeats: Double
}

/// A chord ready for display.
struct DisplayChord {
    let symbol: String
    let beats: Double
}

// MARK: - ChordChartView

/// Scrolling chord chart styled like iReal Pro — bar lines, section labels, 4 bars per row.
struct ChordChartView: View {
    let tune: Tune
    let currentBeat: Double
    let beatsPerChorus: Double

    private let barsPerRow = 4

    var body: some View {
        let rows = buildRows()
        let currentRowID = currentRowID(in: rows)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        ChartRowView(
                            row: row,
                            wrappedBeat: wrappedBeat,
                            barsPerRow: barsPerRow
                        )
                        .id(row.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: currentRowID) { _, newID in
                if let id = newID {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(JazzColors.background)
    }

    // MARK: - Beat Tracking

    private var wrappedBeat: Double {
        guard beatsPerChorus > 0 else { return 0 }
        return currentBeat.truncatingRemainder(dividingBy: beatsPerChorus)
    }

    private func currentRowID(in rows: [ChartRow]) -> Int? {
        for row in rows {
            for bar in row.bars {
                if wrappedBeat >= bar.startBeat && wrappedBeat < bar.startBeat + bar.durationBeats {
                    return row.id
                }
            }
        }
        return nil
    }

    // MARK: - Build Display Model

    private func buildRows() -> [ChartRow] {
        var rows: [ChartRow] = []
        var rowIndex = 0
        var globalBarIndex = 0
        var beatCursor: Double = 0

        for section in tune.sections {
            var chartBars: [ChartBar] = []
            for bar in section.bars {
                let chords = bar.chords.compactMap { entry -> DisplayChord? in
                    guard let chord = entry.toChord() else { return nil }
                    return DisplayChord(symbol: chord.symbol, beats: entry.beats)
                }
                let barDuration = bar.chords.reduce(0.0) { $0 + $1.beats }
                chartBars.append(ChartBar(
                    id: globalBarIndex,
                    chords: chords,
                    startBeat: beatCursor,
                    durationBeats: barDuration
                ))
                globalBarIndex += 1
                beatCursor += barDuration
            }

            let chunks = chartBars.chunked(into: barsPerRow)
            for (chunkIndex, chunk) in chunks.enumerated() {
                let isFirstRowOfSection = chunkIndex == 0
                rows.append(ChartRow(
                    id: rowIndex,
                    sectionLabel: isFirstRowOfSection ? section.label : nil,
                    bars: chunk,
                    isSectionStart: isFirstRowOfSection,
                    isLastRow: false
                ))
                rowIndex += 1
            }
        }

        if !rows.isEmpty {
            let last = rows[rows.count - 1]
            rows[rows.count - 1] = ChartRow(
                id: last.id,
                sectionLabel: last.sectionLabel,
                bars: last.bars,
                isSectionStart: last.isSectionStart,
                isLastRow: true
            )
        }

        return rows
    }
}

// MARK: - Row View

private struct ChartRowView: View {
    let row: ChartRow
    let wrappedBeat: Double
    let barsPerRow: Int

    var body: some View {
        HStack(spacing: 0) {
            // Section label — fixed width so bars always align
            Text(row.sectionLabel ?? "")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(JazzColors.gold)
                .frame(width: 28, alignment: .trailing)
                .padding(.trailing, 2)

            // Left barline — fixed 6pt container, different content per row type
            ZStack {
                if row.isSectionStart {
                    HStack(spacing: 1.5) {
                        Rectangle().fill(JazzColors.textSecondary).frame(width: 2)
                        Rectangle().fill(JazzColors.textSecondary).frame(width: 0.5)
                    }
                } else {
                    Rectangle().fill(JazzColors.textMuted.opacity(0.6)).frame(width: 0.5)
                }
            }
            .frame(width: 6)

            // Bar slots — always barsPerRow wide for consistent layout
            ForEach(0..<barsPerRow, id: \.self) { slot in
                // Inter-bar barline (between bars, not before first)
                if slot > 0 {
                    Rectangle()
                        .fill(JazzColors.textMuted.opacity(0.6))
                        .frame(width: 0.5)
                }

                if slot < row.bars.count {
                    BarCellView(bar: row.bars[slot], wrappedBeat: wrappedBeat)
                        .frame(maxWidth: .infinity)
                } else {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }

            // Right barline — fixed 6pt container
            ZStack {
                if row.isLastRow {
                    HStack(spacing: 1.5) {
                        Rectangle().fill(JazzColors.textSecondary).frame(width: 0.5)
                        Rectangle().fill(JazzColors.textSecondary).frame(width: 2)
                    }
                } else {
                    Rectangle().fill(JazzColors.textMuted.opacity(0.6)).frame(width: 0.5)
                }
            }
            .frame(width: 6)
        }
        .frame(height: 52)
    }
}

// MARK: - Bar Cell

private struct BarCellView: View {
    let bar: ChartBar
    let wrappedBeat: Double

    private var isCurrent: Bool {
        wrappedBeat >= bar.startBeat && wrappedBeat < bar.startBeat + bar.durationBeats
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(bar.chords.enumerated()), id: \.offset) { _, chord in
                Text(chord.symbol)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(isCurrent ? JazzColors.gold : .white)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            isCurrent
                ? RoundedRectangle(cornerRadius: 4).fill(JazzColors.gold.opacity(0.15))
                : nil
        )
    }
}

// MARK: - Array Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
