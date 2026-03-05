import SwiftUI

/// Browse and select a tune to practice.
struct TuneSelectionView: View {
    @State private var viewModel = TuneSelectionViewModel()
    @State private var selectedTune: Tune?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.filteredTunes.isEmpty {
                    ContentUnavailableView(
                        "No Tunes Found",
                        systemImage: "music.note",
                        description: Text("No tunes match your search.")
                    )
                } else {
                    ForEach(viewModel.filteredTunes) { tune in
                        Button {
                            selectedTune = tune
                        } label: {
                            tuneRow(tune)
                        }
                        .listRowBackground(JazzColors.surface)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search standards...")
            .scrollContentBackground(.hidden)
            .background(JazzColors.background)
            .navigationTitle("Tunes")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedTune) { tune in
                TuneConfigSheet(tune: tune)
            }
        }
    }

    private func tuneRow(_ tune: Tune) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tune.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)

                Text(tune.composer)
                    .font(.caption)
                    .foregroundStyle(JazzColors.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(tune.originalKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(JazzColors.gold)

                // Difficulty dots
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= tune.difficulty ? JazzColors.gold : JazzColors.surfaceLight)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Configuration sheet before starting a session.
struct TuneConfigSheet: View {
    let tune: Tune
    @Environment(\.dismiss) private var dismiss

    @State private var tempo: Int = 120
    @State private var choruses: Int = 2
    @State private var sessionViewModel: SessionViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Tune header
                VStack(spacing: 8) {
                    Text(tune.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("\(tune.originalKey) · \(tune.form) · \(tune.totalBars) bars")
                        .font(.subheadline)
                        .foregroundStyle(JazzColors.textSecondary)
                }

                // Tempo control
                VStack(spacing: 8) {
                    Text("Tempo")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)

                    HStack {
                        Button { tempo = max(60, tempo - 5) } label: {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                        }

                        Text("\(tempo) BPM")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .frame(width: 120)
                            .foregroundStyle(.white)

                        Button { tempo = min(300, tempo + 5) } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                        }
                    }
                    .foregroundStyle(JazzColors.gold)
                }

                // Choruses
                VStack(spacing: 8) {
                    Text("Choruses")
                        .font(.caption)
                        .foregroundStyle(JazzColors.textMuted)

                    HStack {
                        Button { choruses = max(1, choruses - 1) } label: {
                            Image(systemName: "minus.circle")
                                .font(.title2)
                        }

                        Text("\(choruses)")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .frame(width: 60)
                            .foregroundStyle(.white)

                        Button { choruses = min(10, choruses + 1) } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                        }
                    }
                    .foregroundStyle(JazzColors.gold)
                }

                Spacer()

                // Start button
                Button(action: startSession) {
                    Label("Play with Scoring", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(JazzColors.gold)
            }
            .padding()
            .background(JazzColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(JazzColors.textSecondary)
                }
            }
            .onAppear {
                tempo = tune.defaultTempo
            }
            .fullScreenCover(item: $sessionViewModel) { vm in
                PlaySessionFlow(viewModel: vm)
            }
        }
    }

    private func startSession() {
        let vm = SessionViewModel()
        vm.configure(tune: tune, tempo: tempo, choruses: choruses)
        sessionViewModel = vm
    }
}

/// Wraps the active session and results flow.
struct PlaySessionFlow: View {
    @Bindable var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            JazzColors.background.ignoresSafeArea()

            switch viewModel.state {
            case .idle:
                ProgressView()
                    .tint(JazzColors.gold)

            case .countdown, .playing, .paused:
                ActiveSessionView(viewModel: viewModel)

            case .finished:
                ResultsView(
                    viewModel: ResultsViewModel(session: viewModel.sessionData),
                    onPlayAgain: {
                        hasStarted = false
                        viewModel.startSession()
                    },
                    onDone: {
                        viewModel.saveSession(modelContext: modelContext)
                        dismiss()
                    }
                )
            }
        }
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            viewModel.startSession()
        }
    }
}
