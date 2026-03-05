import Foundation
import SwiftData

@Model
final class PracticeSession {
    var tuneId: String = ""
    var tuneTitle: String = ""
    var date: Date = Date()
    var tempo: Int = 120
    var key: String = "C"
    var choruses: Int = 2
    var durationSeconds: Int = 0
    var totalScore: Int = 0
    var starRating: Int = 1
    var noteChoicePercent: Double = 0
    var vocabularyCount: Int = 0
    var maxCombo: Int = 0
    var chordToneCount: Int = 0
    var scaleToneCount: Int = 0
    var totalNotesPlayed: Int = 0

    // JSON blobs for large arrays
    var detectedPatternsData: Data?
    var noteEventsData: Data?

    init(
        tuneId: String,
        tuneTitle: String,
        tempo: Int,
        key: String,
        choruses: Int,
        durationSeconds: Int,
        totalScore: Int,
        starRating: Int,
        noteChoicePercent: Double,
        vocabularyCount: Int,
        maxCombo: Int,
        chordToneCount: Int,
        scaleToneCount: Int,
        totalNotesPlayed: Int
    ) {
        self.tuneId = tuneId
        self.tuneTitle = tuneTitle
        self.tempo = tempo
        self.key = key
        self.choruses = choruses
        self.durationSeconds = durationSeconds
        self.totalScore = totalScore
        self.starRating = starRating
        self.noteChoicePercent = noteChoicePercent
        self.vocabularyCount = vocabularyCount
        self.maxCombo = maxCombo
        self.chordToneCount = chordToneCount
        self.scaleToneCount = scaleToneCount
        self.totalNotesPlayed = totalNotesPlayed
        self.date = Date()
    }

    // MARK: - JSON Helpers

    var detectedPatterns: [PatternDetection] {
        get {
            guard let data = detectedPatternsData else { return [] }
            return (try? JSONDecoder().decode([PatternDetection].self, from: data)) ?? []
        }
        set {
            detectedPatternsData = try? JSONEncoder().encode(newValue)
        }
    }

    var noteEvents: [NoteEvent] {
        get {
            guard let data = noteEventsData else { return [] }
            return (try? JSONDecoder().decode([NoteEvent].self, from: data)) ?? []
        }
        set {
            noteEventsData = try? JSONEncoder().encode(newValue)
        }
    }
}
