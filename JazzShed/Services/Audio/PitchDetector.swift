import AVFoundation
import Accelerate
import Foundation
import Observation

/// Real-time monophonic pitch detector using the YIN autocorrelation algorithm.
///
/// Captures audio via AVAudioEngine's input tap, accumulates samples in a ring buffer
/// with 75% overlap, and runs YIN pitch estimation on each 4096-sample analysis window.
/// This replaces AudioKit's PitchTap for better piano detection accuracy.
@Observable
final class PitchDetector {
    @ObservationIgnored private var audioEngine: AVAudioEngine?

    // Ring buffer: accumulate 1024-sample chunks, analyze 4096-sample windows
    @ObservationIgnored private let analysisSize = 4096
    @ObservationIgnored private let hopSize: UInt32 = 1024
    @ObservationIgnored private var ringBuffer: [Float] = []
    @ObservationIgnored private var ringWriteIndex = 0
    @ObservationIgnored private var samplesAccumulated = 0

    // YIN parameters
    @ObservationIgnored private let yinThreshold: Float = 0.15
    @ObservationIgnored private let minFrequency: Float = 50    // Hz — below lowest common jazz note
    @ObservationIgnored private let maxFrequency: Float = 4200  // Hz — above top of piano
    @ObservationIgnored private var sampleRate: Float = 44100

    private(set) var isTracking = false
    private(set) var currentFrequency: Float = 0
    private(set) var currentAmplitude: Float = 0
    private(set) var currentMIDINote: Int = 0
    private(set) var currentNoteName: String = "-"

    /// Callback fired on each pitch frame.
    /// Parameters: (frequency, amplitude, midiNote)
    var onPitchDetected: ((Float, Float, Int) -> Void)?

    /// Minimum RMS amplitude to consider a valid signal (filters noise).
    let amplitudeThreshold: Float = 0.02

    func start() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let hwFormat = inputNode.inputFormat(forBus: 0)
        guard hwFormat.channelCount > 0 else {
            throw PitchDetectorError.noMicrophoneInput
        }
        sampleRate = Float(hwFormat.sampleRate)

        // Silence output — we only analyze, don't route mic to speakers
        engine.mainMixerNode.outputVolume = 0

        // Initialize ring buffer
        ringBuffer = [Float](repeating: 0, count: analysisSize)
        ringWriteIndex = 0
        samplesAccumulated = 0

        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: hwFormat.sampleRate,
            channels: 1,
            interleaved: false
        )!

        inputNode.installTap(onBus: 0, bufferSize: hopSize, format: recordingFormat) {
            [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }

        try engine.start()
        self.audioEngine = engine
        isTracking = true
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isTracking = false
        currentFrequency = 0
        currentAmplitude = 0
        currentMIDINote = 0
        currentNoteName = "-"
    }

    // MARK: - Audio Buffer Handling

    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Copy samples into ring buffer
        for i in 0..<frameCount {
            ringBuffer[ringWriteIndex] = channelData[i]
            ringWriteIndex = (ringWriteIndex + 1) % analysisSize
            samplesAccumulated += 1
        }

        // Need at least one full window before analyzing
        guard samplesAccumulated >= analysisSize else { return }

        // Linearize ring buffer into contiguous analysis frame
        var frame = [Float](repeating: 0, count: analysisSize)
        let firstPart = analysisSize - ringWriteIndex
        if firstPart > 0 {
            frame[0..<firstPart] = ringBuffer[ringWriteIndex..<analysisSize]
        }
        if ringWriteIndex > 0 {
            frame[firstPart..<analysisSize] = ringBuffer[0..<ringWriteIndex]
        }

        // RMS amplitude check
        var rms: Float = 0
        vDSP_rmsqv(frame, 1, &rms, vDSP_Length(analysisSize))

        guard rms > amplitudeThreshold else {
            Task { @MainActor in
                self.processResult(frequency: 0, amplitude: rms)
            }
            return
        }

        // Run YIN on raw samples (no windowing — YIN's difference function assumes stationary signal)
        let frequency = yinEstimate(frame)

        Task { @MainActor in
            self.processResult(frequency: frequency, amplitude: rms)
        }
    }

    // MARK: - YIN Algorithm

    /// Estimates the fundamental frequency of a windowed audio frame using YIN.
    ///
    /// Steps:
    /// 1. Difference function d(τ) via autocorrelation
    /// 2. Cumulative mean normalized difference d'(τ)
    /// 3. Absolute threshold search for first dip below `yinThreshold`
    /// 4. Parabolic interpolation for sub-sample accuracy
    private func yinEstimate(_ frame: [Float]) -> Float {
        let halfWindow = analysisSize / 2

        // Lag range from frequency bounds
        let minLag = max(1, Int(sampleRate / maxFrequency))
        let maxLag = min(halfWindow - 1, Int(sampleRate / minFrequency))
        guard minLag < maxLag else { return 0 }

        // Step 1 & 2: Compute difference function with cumulative mean normalization
        var diff = [Float](repeating: 0, count: halfWindow)
        var cumulativeSum: Float = 0

        // Energy of the first block (for incremental update)
        var energy1: Float = 0
        vDSP_dotpr(frame, 1, frame, 1, &energy1, vDSP_Length(halfWindow))

        var energy2: Float = energy1

        diff[0] = 1.0 // d'(0) = 1 by convention

        frame.withUnsafeBufferPointer { framePtr in
            let base = framePtr.baseAddress!

            for tau in 1..<halfWindow {
                // Incremental energy update for energy2(τ) = Σ_{j=τ}^{τ+W-1} x[j]²
                // energy2(τ) = energy2(τ-1) - x[τ-1]² + x[τ-1+W]²
                let outgoing = frame[tau - 1]
                let incoming = frame[tau - 1 + halfWindow]
                energy2 = energy2 - outgoing * outgoing + incoming * incoming

                // Cross-correlation at lag tau
                var crossCorr: Float = 0
                vDSP_dotpr(base, 1, base.advanced(by: tau), 1, &crossCorr, vDSP_Length(halfWindow))

                // Difference function: d(τ) = energy1 + energy2 - 2 * crossCorr
                let d = energy1 + energy2 - 2 * crossCorr
                diff[tau] = d

                // Cumulative mean normalized difference: d'(τ) = d(τ) * τ / sum(d(1)...d(τ))
                cumulativeSum += d
                if cumulativeSum > 0 {
                    diff[tau] = d * Float(tau) / cumulativeSum
                } else {
                    diff[tau] = 1.0
                }
            }
        }

        // Step 3: Absolute threshold — find first dip below threshold in valid lag range
        var bestLag = -1
        for tau in minLag...maxLag {
            if diff[tau] < yinThreshold {
                // Walk forward to find the local minimum in this dip
                var localMin = tau
                while localMin + 1 <= maxLag && diff[localMin + 1] < diff[localMin] {
                    localMin += 1
                }
                bestLag = localMin
                break
            }
        }

        // Fallback: if no dip below threshold, find global minimum in range
        if bestLag < 0 {
            var minVal: Float = .greatestFiniteMagnitude
            for tau in minLag...maxLag {
                if diff[tau] < minVal {
                    minVal = diff[tau]
                    bestLag = tau
                }
            }
            // Only use fallback if it's reasonably good
            if minVal > 0.5 { return 0 }
        }

        guard bestLag > 0 else { return 0 }

        // Step 4: Parabolic interpolation for sub-sample accuracy
        let refinedLag = parabolicInterpolation(diff: diff, tau: bestLag, maxLag: maxLag)

        guard refinedLag > 0 else { return 0 }
        return sampleRate / refinedLag
    }

    /// Parabolic interpolation around the minimum of the difference function.
    /// Returns a refined (sub-sample) lag estimate.
    private func parabolicInterpolation(diff: [Float], tau: Int, maxLag: Int) -> Float {
        guard tau > 0, tau < maxLag else {
            return Float(tau)
        }

        let s0 = diff[tau - 1]
        let s1 = diff[tau]
        let s2 = diff[tau + 1]

        let denominator = 2.0 * s1 - s2 - s0
        guard abs(denominator) > 1e-10 else {
            return Float(tau)
        }

        let adjustment = (s2 - s0) / (2.0 * denominator)
        return Float(tau) + adjustment
    }

    // MARK: - Result Processing

    @MainActor
    private func processResult(frequency: Float, amplitude: Float) {
        currentFrequency = frequency
        currentAmplitude = amplitude

        guard frequency > 20, frequency < 8000 else {
            currentMIDINote = 0
            currentNoteName = "-"
            onPitchDetected?(0, amplitude, 0)
            return
        }

        let midi = MIDIHelpers.frequencyToMIDI(frequency)
        currentMIDINote = midi
        currentNoteName = MIDIHelpers.noteLabel(for: midi)

        onPitchDetected?(frequency, amplitude, midi)
    }

}

enum PitchDetectorError: LocalizedError {
    case noMicrophoneInput

    var errorDescription: String? {
        switch self {
        case .noMicrophoneInput:
            return "No microphone input available. Please check your audio settings."
        }
    }
}
