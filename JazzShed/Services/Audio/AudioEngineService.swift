import AVFoundation
import Observation

/// Manages the shared AVAudioSession and coordinates audio services.
/// Configures the session for simultaneous playback (backing track) and recording (mic input).
@Observable
final class AudioEngineService {
    private(set) var isRunning = false
    private(set) var error: String?

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord allows simultaneous mic input + speaker output
            // .measurement gives flat frequency response (no EQ processing)
            // .allowBluetooth lets users use BT headphones
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            // Use a small buffer for low latency pitch detection
            try session.setPreferredIOBufferDuration(0.005)
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)
            isRunning = true
            error = nil
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func deactivateSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isRunning = false
        } catch {
            self.error = "Deactivation error: \(error.localizedDescription)"
        }
    }

    /// Requests microphone permission. Returns true if granted.
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
