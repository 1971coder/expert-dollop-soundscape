import AVFoundation
import Foundation

/// Broader spectral pad. Each voice is a sine + half-amplitude second harmonic
/// (so the timbre is brighter than DroneSynth's pure-sine voices), passed
/// through a resonant low-pass filter modulated by `padCutoff` / `padResonance`.
/// Apply pulse modulation on the output stage so the pad breathes with the
/// shared pulse rate.
///
/// **Realtime contract.** Render block is allocation-free, lock-free, no
/// logging. Reads from `EngineParameters` once per block — sees parameters
/// that may be ≤ ~6 ms stale because `DroneSynth` is the designated drainer
/// (see `decisions.md` 2026-05-29).
nonisolated final class PadSynth: @unchecked Sendable {
    let node: AVAudioSourceNode
    private let state: PadRenderState

    init(format: AVAudioFormat, parameters: EngineParameters) {
        let state = PadRenderState(parameters: parameters, sampleRate: Float(format.sampleRate))
        self.state = state
        self.node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            state.render(frameCount: Int(frameCount), audioBufferList: audioBufferList)
            return noErr
        }
    }
}

nonisolated private final class PadRenderState: @unchecked Sendable {
    struct Voice {
        var baseFreq: Float
        var phase: Float
    }

    let parameters: EngineParameters
    let sampleRate: Float
    var voices: [Voice]
    var filter = StateVariableFilter()
    var pulse = PulseModulator()

    init(parameters: EngineParameters, sampleRate: Float) {
        self.parameters = parameters
        self.sampleRate = sampleRate
        self.voices = [
            Voice(baseFreq: 130.81, phase: 0),
            Voice(baseFreq: 196.00, phase: 0.5),
            Voice(baseFreq: 246.94, phase: 1.1),
        ]
    }

    func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        let cutoffHz = FilterController.cutoffHz(fromNorm: parameters.padCutoff, minHz: 200, maxHz: 5_000)
        let q = FilterController.qFromNorm(parameters.padResonance)
        let pulseGain = pulse.nextGain(
            rateNorm: parameters.pulseRate,
            depthNorm: parameters.pulseDepth,
            frameCount: frameCount,
            sampleRate: sampleRate
        )
        let masterGain = parameters.masterGain
        let nodeGain: Float = 0.22
        let twoPi: Float = 2 * Float.pi
        let voiceCount = Float(voices.count)
        let sr = sampleRate

        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for buffer in abl {
            guard let dest = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            for frame in 0..<frameCount {
                var sample: Float = 0
                for vIndex in voices.indices {
                    voices[vIndex].phase += twoPi * voices[vIndex].baseFreq / sr
                    if voices[vIndex].phase > twoPi { voices[vIndex].phase -= twoPi }
                    let fund = sinf(voices[vIndex].phase)
                    let harm = 0.5 * sinf(2 * voices[vIndex].phase)
                    sample += fund + harm
                }
                sample /= voiceCount
                let filtered = filter.processLowPass(sample, cutoffHz: cutoffHz, q: q, sampleRate: sr)
                dest[frame] = filtered * nodeGain * pulseGain * masterGain
            }
        }
    }
}
