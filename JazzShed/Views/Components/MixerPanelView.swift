import SwiftUI

/// Collapsible mixer panel with per-instrument volume sliders.
/// Binds directly to BackingTrackPlayer's volume properties for real-time control.
struct MixerPanelView: View {
    @Bindable var player: BackingTrackPlayer
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline)
                    Text("Mixer")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(isExpanded ? JazzColors.gold : JazzColors.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(JazzColors.surface)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal)
            .padding(.vertical, 4)

            // Slider panel
            if isExpanded {
                VStack(spacing: 10) {
                    sliderRow(icon: "bass.clef", label: "Bass", value: $player.bassVolume)
                    sliderRow(icon: "drum.fill", label: "Drums", value: $player.drumsVolume)
                    sliderRow(icon: "pianokeys", label: "Piano", value: $player.pianoVolume)

                    Divider()
                        .background(JazzColors.textMuted)

                    sliderRow(
                        icon: "waveform.path",
                        label: "Reverb",
                        value: Binding(
                            get: { player.reverbMix / 100 },
                            set: { player.reverbMix = $0 * 100 }
                        )
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(JazzColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func sliderRow(icon: String, label: String, value: Binding<Float>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(JazzColors.textSecondary)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(JazzColors.textSecondary)
                .frame(width: 42, alignment: .leading)

            Slider(value: value, in: 0...1)
                .tint(JazzColors.gold)

            Text("\(Int(value.wrappedValue * 100))%")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(JazzColors.textMuted)
                .frame(width: 34, alignment: .trailing)
        }
    }
}
