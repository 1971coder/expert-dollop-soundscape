import Foundation

/// Sub-audible LFO that produces a gain multiplier in `[1 - depth, 1]`.
///
/// **Realtime contract.** `nextGain` runs on the audio render thread —
/// allocation-free, branchless beyond a phase wrap, single `sinf` call.
///
/// Each source node owns its own `PulseModulator` instance (its own phase).
/// Voices intentionally drift apart over long sessions because the LFOs
/// share a `rate` parameter but not a starting phase — keeps the modulation
/// organic rather than mechanically synchronised. Requirements.md §3.1
/// asks for "light rhythmic motion (sub-audible to ~0.2 Hz pulse rate)";
/// the rate mapping below sweeps 0.05–0.5 Hz, with Focus presets sitting
/// near the middle and Sleep presets near the floor.
nonisolated struct PulseModulator {
    var phase: Float = 0

    /// Returns the gain multiplier at the *start* of the next block and
    /// advances the phase by `frameCount` samples. Per-block granularity is
    /// fine for a sub-audible LFO — even at 0.5 Hz and 4096-frame blocks
    /// at 48 kHz, per-block phase change is ~31° (≈ inaudible discontinuity).
    @inline(__always)
    mutating func nextGain(
        rateNorm: Float,
        depthNorm: Float,
        frameCount: Int,
        sampleRate: Float
    ) -> Float {
        let depth = min(max(depthNorm, 0), 1)
        let rateHz = 0.05 + min(max(rateNorm, 0), 1) * 0.45
        let gain = (1 - depth) + depth * (0.5 + 0.5 * sinf(phase))
        phase += 2 * Float.pi * rateHz * Float(frameCount) / sampleRate
        if phase > 2 * Float.pi { phase -= 2 * Float.pi }
        return gain
    }
}
