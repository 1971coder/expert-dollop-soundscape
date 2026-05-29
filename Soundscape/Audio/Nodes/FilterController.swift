import Foundation

/// Chamberlin state-variable filter (SVF) state, plus normalised-parameter helpers.
///
/// **Realtime contract.** `processLowPass` runs on the audio render thread —
/// branchless, allocation-free, single-precision throughout. The Chamberlin SVF
/// is stable for `cutoffHz < sampleRate / 6`; the helpers clamp the cutoff to
/// stay inside that envelope.
///
/// Used internally by `PadSynth` (padCutoff/padResonance), `NoiseGenerator`
/// (noiseColour as cutoff with a fixed gentle Q), and `DroneSynth` (the master
/// `filterCutoff` knob applied at the source output stage). FilterController
/// is therefore not an AVAudioNode of its own — its semantics live inside
/// each source's render block — but its parameter mappings and filter math
/// have one home so they don't drift.
nonisolated struct StateVariableFilter {
    var lowpass: Float = 0
    var bandpass: Float = 0

    @inline(__always)
    mutating func processLowPass(
        _ sample: Float,
        cutoffHz: Float,
        q: Float,
        sampleRate: Float
    ) -> Float {
        let clamped = min(cutoffHz, sampleRate * 0.15)
        let f = 2 * sinf(Float.pi * clamped / sampleRate)
        let damping = 1 / max(q, 0.5)
        let highpass = sample - lowpass - damping * bandpass
        bandpass += f * highpass
        lowpass += f * bandpass
        return lowpass
    }
}

/// Parameter mapping helpers shared by every filter consumer.
nonisolated enum FilterController {
    /// Logarithmic mapping from normalised `0...1` to a Hz range.
    @inline(__always)
    static func cutoffHz(fromNorm value: Float, minHz: Float, maxHz: Float) -> Float {
        let v = min(max(value, 0), 1)
        let logMin = logf(minHz)
        let logMax = logf(maxHz)
        return expf(logMin + (logMax - logMin) * v)
    }

    /// Maps `0...1` to a Q in `0.7 ... 5.0` — `0.7` is no audible resonance,
    /// `5.0` is a mild emphasis short of self-oscillation.
    @inline(__always)
    static func qFromNorm(_ value: Float) -> Float {
        let v = min(max(value, 0), 1)
        return 0.7 + v * 4.3
    }
}
