import Foundation

/// Records a detected pattern during a session.
struct PatternDetection: Codable, Identifiable, Sendable {
    let id: UUID
    let patternId: String
    let patternName: String
    let barNumber: Int
    let beatPosition: Double
    let pointsAwarded: Int
    let noteEvents: [NoteEvent]   // The specific notes that formed this pattern
    let timestamp: TimeInterval

    init(
        patternId: String,
        patternName: String,
        barNumber: Int,
        beatPosition: Double,
        pointsAwarded: Int,
        noteEvents: [NoteEvent] = [],
        timestamp: TimeInterval = 0
    ) {
        self.id = UUID()
        self.patternId = patternId
        self.patternName = patternName
        self.barNumber = barNumber
        self.beatPosition = beatPosition
        self.pointsAwarded = pointsAwarded
        self.noteEvents = noteEvents
        self.timestamp = timestamp
    }
}
