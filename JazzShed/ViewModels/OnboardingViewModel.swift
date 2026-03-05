import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class OnboardingViewModel {
    var currentStep = 0
    var selectedInstrument: Instrument = .altoSax
    var experienceLevel = 1
    var dailyGoalMinutes = 10
    var micCheckPassed = false

    let totalSteps = 4

    func completeOnboarding(modelContext: ModelContext) {
        let user = UserProfile(
            instrument: selectedInstrument.rawValue,
            experienceLevel: experienceLevel,
            dailyGoalMinutes: dailyGoalMinutes
        )
        modelContext.insert(user)
        try? modelContext.save()
    }
}
