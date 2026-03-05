import AVFoundation
import Observation

/// Manages the AVAudioEngine graph for backing track playback.
/// Creates AVAudioUnitSampler nodes for bass, drums, and piano,
/// loads a GM SoundFont, and drives them via MIDISequencer.
@Observable
final class BackingTrackPlayer {
    private var audioEngine: AVAudioEngine?
    private var bassSampler: AVAudioUnitSampler?
    private var drumSampler: AVAudioUnitSampler?
    private var pianoSampler: AVAudioUnitSampler?
    private var subMixer: AVAudioMixerNode?
    private var reverb: AVAudioUnitReverb?
    private(set) var sequencer = MIDISequencer()

    private(set) var isPlaying = false
    private(set) var error: String?

    /// Per-instrument volume controls (0.0–1.0). Updating these
    /// immediately changes the sampler output for real-time mixing.
    var bassVolume: Float = 0.8 {
        didSet { bassSampler?.volume = bassVolume }
    }
    var drumsVolume: Float = 0.6 {
        didSet { drumSampler?.volume = drumsVolume }
    }
    var pianoVolume: Float = 0.5 {
        didSet { pianoSampler?.volume = pianoVolume }
    }
    var reverbMix: Float = 22 {
        didSet { reverb?.wetDryMix = reverbMix }
    }

    /// Sets up the audio engine with three sampler nodes.
    func setup() {
        let engine = AVAudioEngine()

        let bass = AVAudioUnitSampler()
        let drums = AVAudioUnitSampler()
        let piano = AVAudioUnitSampler()

        let sub = AVAudioMixerNode()
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = reverbMix

        engine.attach(bass)
        engine.attach(drums)
        engine.attach(piano)
        engine.attach(sub)
        engine.attach(reverbNode)

        // Samplers → subMixer → reverb → mainMixer
        engine.connect(bass, to: sub, format: nil)
        engine.connect(drums, to: sub, format: nil)
        engine.connect(piano, to: sub, format: nil)
        engine.connect(sub, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: engine.mainMixerNode, format: nil)

        // Set initial volumes from published properties
        bass.volume = bassVolume
        drums.volume = drumsVolume
        piano.volume = pianoVolume

        self.audioEngine = engine
        self.bassSampler = bass
        self.drumSampler = drums
        self.pianoSampler = piano
        self.subMixer = sub
        self.reverb = reverbNode

        // Wire samplers to sequencer
        sequencer.bassSampler = bass
        sequencer.drumSampler = drums
        sequencer.pianoSampler = piano
    }

    /// Loads a single SoundFont into all three samplers (convenience wrapper).
    func loadSoundFont(named fileName: String) throws {
        try loadSoundFont(bass: nil, drums: nil, piano: nil, fallback: fileName)
    }

    /// Loads per-instrument SoundFonts with a shared fallback.
    /// Pass nil for any instrument to use the fallback SF2.
    func loadSoundFont(bass: String? = nil, drums: String? = nil, piano: String? = nil, fallback: String) throws {
        func resolveURL(_ name: String?) throws -> URL {
            let fileName = name ?? fallback
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "sf2") else {
                throw BackingTrackError.soundFontNotFound(fileName)
            }
            return url
        }

        // GM Program Numbers:
        // Bass: 32 = Acoustic Bass
        // Drums: Bank 128 (percussion), program 0
        // Piano: 0 = Acoustic Grand Piano

        try bassSampler?.loadSoundBankInstrument(
            at: resolveURL(bass),
            program: 32,   // Acoustic Bass
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: 0
        )

        try drumSampler?.loadSoundBankInstrument(
            at: resolveURL(drums),
            program: 0,
            bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB),
            bankLSB: 0
        )

        try pianoSampler?.loadSoundBankInstrument(
            at: resolveURL(piano),
            program: 0,    // Acoustic Grand Piano
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: 0
        )
    }

    /// Loads a chord chart and starts playback.
    func play(slots: [MIDISequencer.ChordSlot], tempo: Double, choruses: Int = 1) throws {
        guard let engine = audioEngine else {
            throw BackingTrackError.engineNotSetup
        }

        if !engine.isRunning {
            try engine.start()
        }

        sequencer.loadChart(slots: slots, tempo: tempo, choruses: choruses)
        sequencer.start()
        isPlaying = true
    }

    func stop() {
        sequencer.stop()
        isPlaying = false
    }

    /// Resumes playback from a saved beat position.
    func resume(fromBeat beat: Double) {
        guard let engine = audioEngine else { return }
        if !engine.isRunning {
            try? engine.start()
        }
        sequencer.resume(fromBeat: beat)
        isPlaying = true
    }

    func teardown() {
        stop()
        audioEngine?.stop()
        audioEngine = nil
        subMixer = nil
        reverb = nil
    }

    /// Current beat position (for UI sync).
    var currentBeat: Double {
        sequencer.currentBeat
    }

    var isComplete: Bool {
        sequencer.isComplete
    }
}

enum BackingTrackError: LocalizedError {
    case soundFontNotFound(String)
    case engineNotSetup

    var errorDescription: String? {
        switch self {
        case .soundFontNotFound(let name):
            return "SoundFont '\(name).sf2' not found in app bundle."
        case .engineNotSetup:
            return "Audio engine not set up. Call setup() first."
        }
    }
}
