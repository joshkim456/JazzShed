import SwiftUI
import SwiftData

@main
struct JazzShedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
                UserProfile.self,
                PracticeSession.self,
                VocabularyItem.self,
                SkillNodeProgress.self,
                Achievement.self,
            ])
    }
}
