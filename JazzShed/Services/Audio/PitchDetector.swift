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

    /// Serial queue for pitch analysis — keeps work off the real-time audio thread
    @ObservationIgnored private let processingQueue = DispatchQueue(
        label: "com.jazzshed.pitch-analysis",
        qos: .userInteractive
    )

    // Ring buffer: accumulate 1024-sample chunks, analyze 4096-sample windows
    @ObservationIgnored private let analysisSize = 4096
    @ObservationIgnored private let hopSize: UInt32 = 1024
    @ObservationIgnored private var ringBuffer: [Float] = []
    @ObservationIgnored private var ringWriteIndex = 0
    @ObservationIgnored private var samplesAccumulated = 0

    // YIN parameters
    @ObservationIgnored private let yinThreshold: Float = 0.30
    @ObservationIgnored private let minFrequency: Float = 50    // Hz — below lowest common jazz note
    @ObservationIgnored private let maxFrequency: Float = 4200  // Hz — above top of piano
    @ObservationIgnored var sampleRate: Float = 44100

    // Onset detection (spectral flux) — 1024-point FFT
    @ObservationIgnored private let onsetFFTSize = 1024
    @ObservationIgnored private let onsetSpectrumSize = 512  // FFT size / 2
    @ObservationIgnored private var fftSetup: FFTSetup?
    @ObservationIgnored private var fftWindow: [Float] = []
    @ObservationIgnored private var fftInputReal: [Float] = []
    @ObservationIgnored private var fftInputImag: [Float] = []
    @ObservationIgnored private var magnitudeSpectrum: [Float] = []
    @ObservationIgnored private var logMagnitude: [Float] = []
    @ObservationIgnored private var prevLogMagnitude: [Float] = []
    @ObservationIgnored private var fluxHistory: [Float] = []
    @ObservationIgnored private var fluxWriteIndex = 0
    @ObservationIgnored private let fluxHistorySize = 50
    @ObservationIgnored private var lastOnsetSampleTime: Int = 0
    @ObservationIgnored var totalSamplesProcessed: Int = 0

    // Onset detection constants
    @ObservationIgnored private let logCompressionGamma: Float = 100
    @ObservationIgnored private let thresholdOffset: Float = 1.5
    @ObservationIgnored private let minInterOnsetSamples = 2205  // ~50ms at 44.1kHz

    // Harmonic Sum Spectrum (HSS) — octave validator for piano/instrument detection
    @ObservationIgnored private let hssHarmonics = 4
    @ObservationIgnored private var hssFFTSetup: FFTSetup?
    @ObservationIgnored private var hssWindow: [Float] = []
    @ObservationIgnored private var hssReal: [Float] = []
    @ObservationIgnored private var hssImag: [Float] = []
    @ObservationIgnored private var hssMagnitude: [Float] = []
    @ObservationIgnored private var hssLogMag: [Float] = []
    @ObservationIgnored private var hssResult: [Float] = []

    private(set) var isTracking = false
    private(set) var currentFrequency: Float = 0
    private(set) var currentAmplitude: Float = 0
    private(set) var currentMIDINote: Int = 0
    private(set) var currentNoteName: String = "-"

    /// Callback fired on each pitch frame.
    /// Parameters: (frequency, amplitude, midiNote, onsetDetected)
    var onPitchDetected: ((Float, Float, Int, Bool) -> Void)?

    /// Minimum RMS amplitude to consider a valid signal (filters noise).
    let amplitudeThreshold: Float = 0.008

    /// Initialize all buffers (ring buffer + FFT). Call before processing frames.
    /// Separated from start() so tests can init buffers without the audio engine.
    func initializeBuffers() {
        // Ring buffer
        ringBuffer = [Float](repeating: 0, count: analysisSize)
        ringWriteIndex = 0
        samplesAccumulated = 0

        // FFT setup for onset detection
        let log2n = vDSP_Length(log2(Float(onsetFFTSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))

        // Hann window (FFT needs windowing to avoid spectral leakage)
        fftWindow = [Float](repeating: 0, count: onsetFFTSize)
        vDSP_hann_window(&fftWindow, vDSP_Length(onsetFFTSize), Int32(vDSP_HANN_NORM))

        // Split complex working buffers
        fftInputReal = [Float](repeating: 0, count: onsetSpectrumSize)
        fftInputImag = [Float](repeating: 0, count: onsetSpectrumSize)

        // Magnitude spectra
        magnitudeSpectrum = [Float](repeating: 0, count: onsetSpectrumSize)
        logMagnitude = [Float](repeating: 0, count: onsetSpectrumSize)
        prevLogMagnitude = [Float](repeating: 0, count: onsetSpectrumSize)

        // Flux history ring buffer
        fluxHistory = [Float](repeating: 0, count: fluxHistorySize)
        fluxWriteIndex = 0
        lastOnsetSampleTime = 0
        totalSamplesProcessed = 0

        // HSS buffers (reuses analysisSize = 4096)
        let hssLog2n = vDSP_Length(log2(Float(analysisSize)))
        hssFFTSetup = vDSP_create_fftsetup(hssLog2n, FFTRadix(kFFTRadix2))
        hssWindow = [Float](repeating: 0, count: analysisSize)
        vDSP_hann_window(&hssWindow, vDSP_Length(analysisSize), Int32(vDSP_HANN_NORM))
        let hssSpectrumSize = analysisSize / 2
        hssReal = [Float](repeating: 0, count: hssSpectrumSize)
        hssImag = [Float](repeating: 0, count: hssSpectrumSize)
        hssMagnitude = [Float](repeating: 0, count: hssSpectrumSize)
        hssLogMag = [Float](repeating: 0, count: hssSpectrumSize)
        hssResult = [Float](repeating: 0, count: hssSpectrumSize / hssHarmonics)
    }

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

        // Initialize all buffers
        initializeBuffers()

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

        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
            fftSetup = nil
        }
        if let setup = hssFFTSetup {
            vDSP_destroy_fftsetup(setup)
            hssFFTSetup = nil
        }
    }

    // MARK: - Audio Buffer Handling

    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Copy samples into ring buffer (fast — safe on audio thread)
        for i in 0..<frameCount {
            ringBuffer[ringWriteIndex] = channelData[i]
            ringWriteIndex = (ringWriteIndex + 1) % analysisSize
            samplesAccumulated += 1
        }

        // Need at least one full window before analyzing
        guard samplesAccumulated >= analysisSize else { return }

        // Snapshot the ring buffer state for off-thread analysis
        let frame = linearizeRingBuffer()

        // Dispatch heavy analysis off the real-time audio thread
        processingQueue.async { [weak self] in
            self?.analyzeFrame(frame)
        }
    }

    /// Linearize the ring buffer into a contiguous analysis frame.
    private func linearizeRingBuffer() -> [Float] {
        var frame = [Float](repeating: 0, count: analysisSize)
        let firstPart = analysisSize - ringWriteIndex
        if firstPart > 0 {
            frame[0..<firstPart] = ringBuffer[ringWriteIndex..<analysisSize]
        }
        if ringWriteIndex > 0 {
            frame[firstPart..<analysisSize] = ringBuffer[0..<ringWriteIndex]
        }
        return frame
    }

    /// Run onset detection, RMS check, and YIN on the processing queue, then deliver result to main thread.
    private func analyzeFrame(_ frame: [Float]) {
        // Track total samples for inter-onset timing
        totalSamplesProcessed += Int(hopSize)

        // Onset detection on last 1024 samples (runs even during silence — attack may start here)
        let onsetSlice = frame[(analysisSize - onsetFFTSize)..<analysisSize]
        let onsetDetected = detectOnset(onsetSlice)

        // RMS amplitude check
        var rms: Float = 0
        vDSP_rmsqv(frame, 1, &rms, vDSP_Length(analysisSize))

        guard rms > amplitudeThreshold else {
            DispatchQueue.main.async { [weak self] in
                self?.processResult(frequency: 0, amplitude: rms, onsetDetected: onsetDetected)
            }
            return
        }

        let yinFreq = yinEstimate(frame)
        let hssFreq = hssEstimate(frame)
        let frequency = arbitrate(yinFreq: yinFreq, hssFreq: hssFreq)

        DispatchQueue.main.async { [weak self] in
            self?.processResult(frequency: frequency, amplitude: rms, onsetDetected: onsetDetected)
        }
    }

    // MARK: - Onset Detection (Spectral Flux)

    /// Detects note onsets via spectral flux on a 1024-sample slice.
    /// Internal (not private) for testability.
    /// - Parameter samples: A 1024-sample audio slice (typically the last quarter of the analysis window).
    /// - Returns: `true` if an onset was detected.
    func detectOnset(_ samples: ArraySlice<Float>) -> Bool {
        guard let setup = fftSetup, samples.count == onsetFFTSize else { return false }

        // 1. Apply Hann window
        var windowed = [Float](repeating: 0, count: onsetFFTSize)
        Array(samples).withUnsafeBufferPointer { src in
            vDSP_vmul(src.baseAddress!, 1, fftWindow, 1, &windowed, 1, vDSP_Length(onsetFFTSize))
        }

        // 2. Pack into split complex format for real FFT
        //    Even indices → real, odd indices → imaginary
        for i in 0..<onsetSpectrumSize {
            fftInputReal[i] = windowed[2 * i]
            fftInputImag[i] = windowed[2 * i + 1]
        }

        // 3. Forward real FFT
        let log2n = vDSP_Length(log2(Float(onsetFFTSize)))
        fftInputReal.withUnsafeMutableBufferPointer { realPtr in
            fftInputImag.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))

                // 4. Magnitude spectrum
                vDSP_zvabs(&splitComplex, 1, &magnitudeSpectrum, 1, vDSP_Length(onsetSpectrumSize))
            }
        }

        // 5. Log compression: log(1 + gamma * M(k))
        for k in 0..<onsetSpectrumSize {
            logMagnitude[k] = logf(1.0 + logCompressionGamma * magnitudeSpectrum[k])
        }

        // 6. Half-wave rectified spectral flux: Σ max(0, current[k] - prev[k])²
        var flux: Float = 0
        for k in 0..<onsetSpectrumSize {
            let diff = logMagnitude[k] - prevLogMagnitude[k]
            if diff > 0 {
                flux += diff * diff
            }
        }

        // Save current as previous for next frame
        prevLogMagnitude = logMagnitude

        // 7. Update flux ring buffer
        fluxHistory[fluxWriteIndex] = flux
        fluxWriteIndex = (fluxWriteIndex + 1) % fluxHistorySize

        // 8. Adaptive threshold: median + offset * mean over history
        let sortedFlux = fluxHistory.sorted()
        let median = sortedFlux[fluxHistorySize / 2]
        let mean = sortedFlux.reduce(0, +) / Float(fluxHistorySize)
        let threshold = median + thresholdOffset * mean

        // 9. Peak pick: flux > threshold AND enough time since last onset
        let elapsed = totalSamplesProcessed - lastOnsetSampleTime
        if flux > threshold && elapsed >= minInterOnsetSamples {
            lastOnsetSampleTime = totalSamplesProcessed
            return true
        }

        return false
    }

    // MARK: - YIN Algorithm

    /// Estimates the fundamental frequency of a windowed audio frame using YIN.
    ///
    /// Steps:
    /// 1. Difference function d(τ) via autocorrelation
    /// 2. Cumulative mean normalized difference d'(τ)
    /// 3. Absolute threshold search for first dip below `yinThreshold`
    /// 4. Parabolic interpolation for sub-sample accuracy
    func yinEstimate(_ frame: [Float]) -> Float {
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

    // MARK: - Harmonic Sum Spectrum (HSS)

    /// Estimates the fundamental frequency using Harmonic Sum Spectrum.
    /// Coarser than YIN but structurally immune to octave errors — harmonics
    /// are collapsed onto the fundamental via frequency-domain summation.
    /// Internal (not private) for testability.
    func hssEstimate(_ frame: [Float]) -> Float {
        let hssSpectrumSize = analysisSize / 2
        let resultSize = hssSpectrumSize / hssHarmonics
        guard let setup = hssFFTSetup, frame.count == analysisSize else { return 0 }

        // 1. Hann window
        var windowed = [Float](repeating: 0, count: analysisSize)
        frame.withUnsafeBufferPointer { src in
            vDSP_vmul(src.baseAddress!, 1, hssWindow, 1, &windowed, 1, vDSP_Length(analysisSize))
        }

        // 2. Pack into split complex and run forward FFT
        for i in 0..<hssSpectrumSize {
            hssReal[i] = windowed[2 * i]
            hssImag[i] = windowed[2 * i + 1]
        }

        let log2n = vDSP_Length(log2(Float(analysisSize)))
        hssReal.withUnsafeMutableBufferPointer { realPtr in
            hssImag.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(kFFTDirection_Forward))

                // 3. Magnitude spectrum
                vDSP_zvabs(&splitComplex, 1, &hssMagnitude, 1, vDSP_Length(hssSpectrumSize))
            }
        }

        // 4. Log magnitude: log(1 + mag[k]) — epsilon-safe, avoids log(0)
        for k in 0..<hssSpectrumSize {
            hssLogMag[k] = logf(1.0 + hssMagnitude[k])
        }

        // 5. Harmonic summation: for each candidate bin k, sum log magnitudes
        //    at harmonic positions k, 2k, 3k, 4k.
        //    Addition in log domain ≈ geometric mean. Missing harmonics contribute ~0
        //    instead of zeroing a product — critical for piano through speakers.
        for k in 0..<resultSize {
            var sum: Float = 0
            for h in 1...hssHarmonics {
                sum += hssLogMag[k * h]
            }
            hssResult[k] = sum
        }

        // 6. Peak find within valid frequency range
        let binResolution = sampleRate / Float(analysisSize)  // Hz per bin
        let minBin = max(1, Int(minFrequency / binResolution))
        let maxBin = min(resultSize - 2, Int(maxFrequency / binResolution))
        guard minBin < maxBin else { return 0 }

        var bestBin = minBin
        var bestVal = hssResult[minBin]
        for k in (minBin + 1)...maxBin {
            if hssResult[k] > bestVal {
                bestVal = hssResult[k]
                bestBin = k
            }
        }

        // Reject if peak is negligible (silence/noise)
        guard bestVal > 0.1 else { return 0 }

        // 7. Parabolic interpolation for sub-bin precision
        var refinedBin = Float(bestBin)
        if bestBin > minBin && bestBin < maxBin {
            let alpha = hssResult[bestBin - 1]
            let beta = hssResult[bestBin]
            let gamma = hssResult[bestBin + 1]
            let denom = alpha - 2 * beta + gamma
            if abs(denom) > 1e-10 {
                refinedBin += 0.5 * (alpha - gamma) / denom
            }
        }

        return refinedBin * binResolution
    }

    // MARK: - Arbitration

    /// Arbitrates between YIN (precise but octave-prone) and HSS (coarse but octave-correct).
    private func arbitrate(yinFreq: Float, hssFreq: Float) -> Float {
        // Both failed
        if yinFreq == 0 && hssFreq == 0 { return 0 }

        // One failed — use the other
        if yinFreq == 0 { return hssFreq }
        if hssFreq == 0 { return yinFreq }

        // Both produced a result — check octave agreement
        let ratio = yinFreq / hssFreq

        // Agree (within ~1 semitone) → use YIN (more precise)
        if ratio > 0.94 && ratio < 1.06 { return yinFreq }

        // YIN is one octave too high → correct down using HSS's octave
        if ratio > 1.88 && ratio < 2.12 { return yinFreq / 2.0 }

        // YIN is one octave too low → correct up
        if ratio > 0.47 && ratio < 0.53 { return yinFreq * 2.0 }

        // Disagree by a non-octave amount — trust YIN (more precise)
        return yinFreq
    }

    // MARK: - Result Processing

    /// Called on main thread via DispatchQueue.main.async (serial, ordered delivery).
    private func processResult(frequency: Float, amplitude: Float, onsetDetected: Bool = false) {
        currentFrequency = frequency
        currentAmplitude = amplitude

        guard frequency > 20, frequency < 8000 else {
            currentMIDINote = 0
            currentNoteName = "-"
            onPitchDetected?(0, amplitude, 0, onsetDetected)
            return
        }

        let midi = MIDIHelpers.frequencyToMIDI(frequency)
        currentMIDINote = midi
        currentNoteName = MIDIHelpers.noteLabel(for: midi)

        onPitchDetected?(frequency, amplitude, midi, onsetDetected)
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
