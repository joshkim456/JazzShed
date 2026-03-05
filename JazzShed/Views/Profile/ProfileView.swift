import SwiftUI
import SwiftData

/// Profile screen with user info and settings.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserProfile]
    @State private var showInstrumentPicker = false

    private var user: UserProfile? { users.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User info
                    userInfoSection

                    // Quick stats
                    quickStatsSection

                    // Settings
                    settingsSection
                }
                .padding()
            }
            .background(JazzColors.background)
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showInstrumentPicker) {
                instrumentPickerSheet
            }
        }
    }

    private var instrumentPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Instrument.allCases) { instrument in
                        Button {
                            user?.instrument = instrument.rawValue
                            try? modelContext.save()
                            showInstrumentPicker = false
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
                                if user?.instrument == instrument.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(JazzColors.gold)
                                }
                            }
                            .padding(12)
                            .background(user?.instrument == instrument.rawValue ? JazzColors.surfaceLight : JazzColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(24)
            }
            .background(JazzColors.background)
            .navigationTitle("Instrument")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showInstrumentPicker = false
                    }
                    .foregroundStyle(JazzColors.gold)
                }
            }
        }
    }

    private var userInfoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(JazzColors.gold)

            Text(user?.instrument ?? "")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            if let created = user?.createdAt {
                Text("Member since \(created.formatted(.dateTime.month(.wide).year()))")
                    .font(.caption)
                    .foregroundStyle(JazzColors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            statItem(icon: "flame.fill", value: "\(user?.currentStreak ?? 0)", label: "Streak")
            statItem(icon: "star.fill", value: "\(user?.totalXP ?? 0)", label: "XP")
            statItem(icon: "clock.fill", value: "\((user?.totalPracticeSeconds ?? 0) / 3600)h", label: "Practice")
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(JazzColors.gold)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(JazzColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(JazzColors.textMuted)
                .tracking(1.5)

            settingsRow(label: "Daily Goal", value: "\(user?.dailyGoalMinutes ?? 10) min")

            Button {
                showInstrumentPicker = true
            } label: {
                HStack {
                    Text("Instrument")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(user?.instrument ?? "")
                        .font(.subheadline)
                        .foregroundStyle(JazzColors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(JazzColors.textMuted)
                }
                .padding(.vertical, 6)
            }

            settingsRow(label: "Gamification", value: user?.gamificationMode == "full" ? "Full" : "Minimal")
            settingsRow(label: "Haptic Feedback", value: user?.hapticFeedbackEnabled == true ? "On" : "Off")
        }
        .padding()
        .background(JazzColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(JazzColors.textSecondary)
        }
        .padding(.vertical, 6)
    }
}
