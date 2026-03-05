import SwiftUI

/// Circular progress ring indicator.
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    init(progress: Double, lineWidth: CGFloat = 4, size: CGFloat = 40) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(JazzColors.surfaceLight, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(JazzColors.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}
