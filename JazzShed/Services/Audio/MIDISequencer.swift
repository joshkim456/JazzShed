import AVFoundation
import Foundation

/// Generates MIDI events from a chord chart and style patterns.
/// Drives AVAudioUnitSampler nodes for bass, drums, and piano in real time.
///
/// Architecture: The sequencer runs a DispatchSourceTimer on a dedicated high-priority
/// serial queue at ~10ms resolution. Each bar, it pre-computes all events (with random
/// pattern selection) and advances a cursor to fire them precisely. Note-offs are
/// scheduled on the same audio queue, avoiding main-thread dependency entirely.
final class MIDISequencer {
    struct ChordSlot {
        let root: Int          // Pitch class 0-11 (C=0)
        let quality: String    // "maj7", "min7", "7", "min7b5", "dim7"
        let startBeat: Double  // Absolute beat position in the chart
        let durationBeats: Double
    }

    // External sampler references (set by BackingTrackPlayer)
    var bassSampler: AVAudioUnitSampler?
    var drumSampler: AVAudioUnitSampler?
    var pianoSampler: AVAudioUnitSampler?

    private var chordSlots: [ChordSlot] = []
    private var tempo: Double = 120
    private var isPlaying = false
    private var choruses: Int = 1

    // Timing — DispatchSourceTimer on a dedicated audio queue
    private let audioQueue = DispatchQueue(label: "com.jazzshed.midi-sequencer", qos: .userInteractive)
    private var timerSource: DispatchSourceTimer?
    private var startTime: TimeInterval = 0
    private var totalBeats: Double = 0

    // Event cursor — pre-computed events for current bar
    private struct ScheduledEvent {
        let beat: Double  // Absolute beat position
        let fire: () -> Void
    }
    private var barEvents: [ScheduledEvent] = []
    private var eventCursor: Int = 0
    private var currentBarIndex: Int = -1  // Tracks which bar we've generated events for

    // Bass octave: MIDI note for bass sounds (octave 2-3)
    private let bassOctave: Int = 2
    // Piano base MIDI for rootless voicings (C3 = 48)
    private let pianoBaseMIDI: Int = 48

    // Voice leading state — average MIDI pitch of previous voicing
    private var previousVoicingCentroid: Double?

    /// Loads a chord chart for playback.
    func loadChart(slots: [ChordSlot], tempo: Double, choruses: Int = 1) {
        self.chordSlots = slots
        self.tempo = tempo
        self.choruses = choruses
        if let last = slots.last {
            self.totalBeats = (last.startBeat + last.durationBeats) * Double(choruses)
        }
    }

    func start() {
        guard !chordSlots.isEmpty else { return }
        startTime = ProcessInfo.processInfo.systemUptime
        currentBarIndex = -1
        barEvents = []
        eventCursor = 0
        previousVoicingCentroid = nil
        isPlaying = true
        startTimer()
    }

    /// Resumes playback from a saved beat position by backdating startTime.
    func resume(fromBeat beat: Double) {
        startTime = ProcessInfo.processInfo.systemUptime - (beat * 60.0 / tempo)
        currentBarIndex = -1  // Force re-generation of bar events
        barEvents = []
        eventCursor = 0
        isPlaying = true
        startTimer()
    }

    private func startTimer() {
        timerSource?.cancel()
        let source = DispatchSource.makeTimerSource(queue: audioQueue)
        source.schedule(deadline: .now(), repeating: .milliseconds(10))
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        timerSource = source
        source.resume()
    }

    func stop() {
        isPlaying = false
        timerSource?.cancel()
        timerSource = nil
        allNotesOff()
    }

    /// Returns the current beat position (0-based).
    var currentBeat: Double {
        guard isPlaying else { return 0 }
        let elapsed = ProcessInfo.processInfo.systemUptime - startTime
        return (elapsed * tempo) / 60.0
    }

    /// Returns true if playback is complete.
    var isComplete: Bool {
        currentBeat >= totalBeats
    }

    private func tick() {
        let beat = currentBeat
        guard beat < totalBeats else {
            stop()
            return
        }

        // Which bar are we in? (0-based, 4 beats per bar)
        let barIndex = Int(beat / 4.0)

        // Generate events for this bar if we haven't already
        if barIndex != currentBarIndex {
            currentBarIndex = barIndex
            generateBarEvents(barIndex: barIndex)
        }

        // Advance cursor and fire all events whose time has passed
        while eventCursor < barEvents.count {
            let event = barEvents[eventCursor]
            if beat >= event.beat {
                event.fire()
                eventCursor += 1
            } else {
                break  // Future events — wait
            }
        }
    }

    // MARK: - Timing Humanization

    /// Returns a small beat offset for timing feel.
    /// bias: ms ahead(−) or behind(+) the grid. range: max random jitter in ms.
    private func humanizedBeatOffset(bias: Double = 0, range: Double = 15) -> Double {
        let msOffset = Double.random(in: -range...range) + bias
        return msOffset / 1000.0 * (tempo / 60.0)
    }

    // MARK: - Bar Event Generation

    /// Pre-computes all MIDI events for a single bar, sorted by beat position.
    /// Randomly selects pattern variants for bass, drums, and comping.
    private func generateBarEvents(barIndex: Int) {
        barEvents = []
        eventCursor = 0

        let barStartBeat = Double(barIndex) * 4.0

        // Pick random pattern variants for this bar
        let bassPattern = SwingStyle.bassVariants.randomElement()!
        let drumPattern = SwingStyle.drumVariants.randomElement()!
        let compPattern = SwingStyle.compVariants.randomElement()!

        // -- Bass events (laid-back feel: +5ms bias) --
        for bassNote in bassPattern {
            let rawBeat = barStartBeat + (bassNote.beat - 1.0)
            let offset = humanizedBeatOffset(bias: 5)
            let absoluteBeat = max(barStartBeat, min(rawBeat + offset, barStartBeat + 3.99))
            guard absoluteBeat < totalBeats else { continue }
            let chord = chordSlotAt(beat: rawBeat)

            // Articulation: beats 1-3 legato, beat 4 (approach) shorter
            let beatInBar = bassNote.beat
            let duration: Double = bassNote.isApproach || beatInBar == 4.0
                ? Double.random(in: 0.4...0.6)
                : Double.random(in: 0.85...0.95)

            barEvents.append(ScheduledEvent(beat: absoluteBeat) { [weak self] in
                guard let self, let chord, let sampler = self.bassSampler else { return }
                let midiNote: UInt8
                if bassNote.isApproach {
                    let nextRoot = self.nextChordRoot(after: rawBeat)
                    midiNote = self.approachNote(to: nextRoot)
                } else {
                    midiNote = self.bassMIDI(root: chord.root, degree: bassNote.degree, quality: chord.quality)
                }
                let velocity = SwingStyle.humanize(bassNote.velocity)
                sampler.startNote(midiNote, withVelocity: velocity, onChannel: 0)
                self.scheduleNoteOff(sampler: sampler, note: midiNote, channel: 0, durationBeats: duration)
            })
        }

        // -- Drum events (driving feel: -5ms bias) --
        for hit in drumPattern {
            let rawBeat = barStartBeat + (hit.beat - 1.0)
            let offset = humanizedBeatOffset(bias: -5)
            let absoluteBeat = max(barStartBeat, min(rawBeat + offset, barStartBeat + 3.99))
            guard absoluteBeat < totalBeats else { continue }

            barEvents.append(ScheduledEvent(beat: absoluteBeat) { [weak self] in
                guard let self, let sampler = self.drumSampler else { return }
                let velocity = SwingStyle.humanize(hit.velocity)
                sampler.startNote(hit.note, withVelocity: velocity, onChannel: 9)
                self.scheduleNoteOff(sampler: sampler, note: hit.note, channel: 9, durationBeats: 0.1)
            })
        }

        // -- Piano comping events (neutral timing: 0ms bias) --
        for hit in compPattern {
            let rawBeat = barStartBeat + (hit.beat - 1.0)
            let offset = humanizedBeatOffset(bias: 0)
            let absoluteBeat = max(barStartBeat, min(rawBeat + offset, barStartBeat + 3.99))
            guard absoluteBeat < totalBeats else { continue }
            let chord = chordSlotAt(beat: rawBeat)

            // Articulation: on-beat hits sustain longer, off-beat/anticipation are crisp
            let beatInBar = hit.beat
            let isOnBeat = beatInBar == 1.0 || beatInBar == 2.0 || beatInBar == 3.0 || beatInBar == 4.0
            let duration: Double = isOnBeat
                ? Double.random(in: 0.3...0.5)
                : Double.random(in: 0.2...0.3)

            barEvents.append(ScheduledEvent(beat: absoluteBeat) { [weak self] in
                guard let self, let chord, let sampler = self.pianoSampler else { return }
                let voicing = self.chordVoicing(root: chord.root, quality: chord.quality)
                let velocity = SwingStyle.humanize(hit.velocity)
                for note in voicing {
                    sampler.startNote(note, withVelocity: velocity, onChannel: 0)
                }
                self.scheduleNoteOff(sampler: sampler, notes: voicing, channel: 0, durationBeats: duration)
            })
        }

        // Sort events by beat position for cursor traversal
        barEvents.sort { $0.beat < $1.beat }
    }

    // MARK: - Note Off Scheduling

    private func scheduleNoteOff(sampler: AVAudioUnitSampler, note: UInt8, channel: UInt8, durationBeats: Double) {
        let duration = (60.0 / tempo) * durationBeats
        audioQueue.asyncAfter(deadline: .now() + duration) {
            sampler.stopNote(note, onChannel: channel)
        }
    }

    private func scheduleNoteOff(sampler: AVAudioUnitSampler, notes: [UInt8], channel: UInt8, durationBeats: Double) {
        let duration = (60.0 / tempo) * durationBeats
        audioQueue.asyncAfter(deadline: .now() + duration) {
            for note in notes {
                sampler.stopNote(note, onChannel: channel)
            }
        }
    }

    // MARK: - Chord Lookup

    private func chordSlotAt(beat: Double) -> ChordSlot? {
        // Wrap beat to single chorus length for chord lookup
        let singleChorusBeats = totalBeats / Double(choruses)
        let wrappedBeat = beat.truncatingRemainder(dividingBy: singleChorusBeats)

        // Binary search for current chord
        var lo = 0, hi = chordSlots.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let slot = chordSlots[mid]
            if wrappedBeat >= slot.startBeat && wrappedBeat < slot.startBeat + slot.durationBeats {
                return slot
            } else if wrappedBeat < slot.startBeat {
                hi = mid - 1
            } else {
                lo = mid + 1
            }
        }
        return chordSlots.last
    }

    // MARK: - Bass Helpers

    private func bassMIDI(root: Int, degree: Int, quality: String) -> UInt8 {
        let semitones: Int
        switch degree {
        case 0: semitones = 0            // Root
        case 3:                           // Third — major or minor depending on quality
            let minorQualities = ["min7", "m7", "min7b5", "m7b5", "dim7", "min", "m"]
            semitones = minorQualities.contains(quality) ? 3 : 4
        case 4: semitones = 5            // Perfect fourth
        case 7: semitones = 7            // Perfect fifth
        default: semitones = degree
        }
        return UInt8(bassOctave * 12 + root + semitones)
    }

    private func approachNote(to nextRoot: Int) -> UInt8 {
        let targetMIDI = bassOctave * 12 + nextRoot
        let direction = SwingStyle.approachDirection()
        return UInt8(targetMIDI + direction)
    }

    private func nextChordRoot(after beat: Double) -> Int {
        let singleChorusBeats = totalBeats / Double(choruses)
        let wrappedBeat = beat.truncatingRemainder(dividingBy: singleChorusBeats)

        for slot in chordSlots {
            if slot.startBeat > wrappedBeat {
                return slot.root
            }
        }
        return chordSlots.first?.root ?? 0
    }

    // MARK: - Chord Voicings

    /// Returns a rootless jazz voicing with voice leading, falling back to
    /// legacy root-position/drop-2 for unsupported chord qualities.
    private func chordVoicing(root: Int, quality: String) -> [UInt8] {
        // Try rootless voicing first
        if let typeAIntervals = SwingStyle.RootlessVoicing.typeA[quality],
           let typeBIntervals = SwingStyle.RootlessVoicing.typeB[quality] {
            return rootlessVoicing(root: root, typeA: typeAIntervals, typeB: typeBIntervals)
        }
        // Fallback for unsupported qualities (dim7, triads, sus4, aug, etc.)
        return legacyVoicing(root: root, quality: quality)
    }

    /// Picks Type A or Type B rootless voicing based on voice leading proximity.
    private func rootlessVoicing(root: Int, typeA: [Int], typeB: [Int]) -> [UInt8] {
        let base = pianoBaseMIDI + root  // C3 + pitch class

        func buildVoicing(_ intervals: [Int]) -> [UInt8] {
            intervals.map { interval in
                var midi = base + interval
                // Clamp to MIDI 43–67 (F2–G4) — comfortable jazz piano comping range
                while midi < 43 { midi += 12 }
                while midi > 67 { midi -= 12 }
                return UInt8(midi)
            }
        }

        let voicingA = buildVoicing(typeA)
        let voicingB = buildVoicing(typeB)

        let centroidA = Double(voicingA.reduce(0) { $0 + Int($1) }) / Double(voicingA.count)
        let centroidB = Double(voicingB.reduce(0) { $0 + Int($1) }) / Double(voicingB.count)

        let chosen: [UInt8]
        let chosenCentroid: Double

        if let prev = previousVoicingCentroid {
            // Pick whichever type is closer to previous voicing
            if abs(centroidA - prev) <= abs(centroidB - prev) {
                chosen = voicingA
                chosenCentroid = centroidA
            } else {
                chosen = voicingB
                chosenCentroid = centroidB
            }
        } else {
            // First chord of the tune — default to Type A
            chosen = voicingA
            chosenCentroid = centroidA
        }

        previousVoicingCentroid = chosenCentroid
        return chosen
    }

    /// Legacy voicing for unsupported qualities: root-position or drop-2.
    private func legacyVoicing(root: Int, quality: String) -> [UInt8] {
        let base = pianoBaseMIDI + root
        let intervals: [Int]

        switch quality {
        case "dim7":
            intervals = [0, 3, 6, 9]      // R b3 b5 bb7
        case "min", "m":
            intervals = [0, 3, 7]          // R b3 5
        case "maj", "":
            intervals = [0, 4, 7]          // R 3 5
        case "aug", "+":
            intervals = [0, 4, 8]          // R 3 #5
        default:
            intervals = [0, 4, 7, 10]     // Default to dom7
        }

        let closeVoicing = intervals.map { UInt8(base + $0) }

        if closeVoicing.count >= 4 && Bool.random() {
            return SwingStyle.drop2(closeVoicing)
        }
        return closeVoicing
    }

    private func allNotesOff() {
        for note: UInt8 in 0...127 {
            bassSampler?.stopNote(note, onChannel: 0)
            drumSampler?.stopNote(note, onChannel: 9)
            pianoSampler?.stopNote(note, onChannel: 0)
        }
    }
}
