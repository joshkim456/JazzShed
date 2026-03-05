import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var users: [UserProfile]
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlow {
                    showOnboarding = false
                }
            } else {
                mainTabView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !hasCheckedOnboarding {
                hasCheckedOnboarding = true
                showOnboarding = users.isEmpty
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TuneSelectionView()
                .tabItem {
                    Label("Tunes", systemImage: "music.note.list")
                }

            SkillTreeView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(JazzColors.gold)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, PracticeSession.self])
}
