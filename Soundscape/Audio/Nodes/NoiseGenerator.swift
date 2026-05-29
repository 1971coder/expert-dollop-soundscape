import AVFoundation
import Foundation

/// Pink + brown noise generator. The `noiseBalance` parameter blends between
/// them: 0 = pure pink, 1 = pure brown. Brown noise uses a leaky integrator
/// (one-pole high-pass at ~5 Hz) to prevent DC drift — naive integration walks
/// off and silently kills the woofer (CLAUDE.md *Gotchas*).
///
/// **WP02 additions.** `noiseColour` parameter darkens the output via a
/// resonant low-pass (0 = bright / unfiltered, 1 = dark); pulse modulation
/// matches the shared pulse rate.
nonisolated final class NoiseGenerator {
    let node: AVAudioSourceNode
    private let state: NoiseRenderState

    init(format: AVAudioFormat, parameters: EngineParameters, rngSeed: UInt32 = 0xdead_beef) {
        let state = NoiseRenderState(
            parameters: parameters,
            sampleRate: Float(format.sampleRate),
            brownLeak: expf(-2 * Float.pi * 5.0 / Float(format.sampleRate)),
            rng: rngSeed
        )
        self.state = state
        self.node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            state.render(frameCount: Int(frameCount), audioBufferList: audioBufferList)
            return noErr
        }
    }
}

nonisolated private final class NoiseRenderState: @unchecked Sendable {
    let parameters: EngineParameters
    let sampleRate: Float
    let brownLeak: Float
    var rng: UInt32
    var pinkB0: Float = 0
    var pinkB1: Float = 0
    var pinkB2: Float = 0
    var brownLast: Float = 0
    var filter = StateVariableFilter()
    var pulse = PulseModulator()

    init(parameters: EngineParameters, sampleRate: Float, brownLeak: Float, rng: UInt32) {
        self.parameters = parameters
        self.sampleRate = sampleRate
        self.brownLeak = brownLeak
        self.rng = rng
    }

    @inline(__always)
    func white() -> Float {
        var x = rng
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        rng = x
        return Float(Int32(bitPattern: x)) / Float(Int32.max)
    }

    // Paul Kellet's economy pink-noise filter, musicdsp.org.
    @inline(__always)
    func pink() -> Float {
        let w = white()
        pinkB0 = 0.99765 * pinkB0 + w * 0.099_046_0
        pinkB1 = 0.96300 * pinkB1 + w * 0.296_516_4
        pinkB2 = 0.57000 * pinkB2 + w * 1.052_691_3
        return (pinkB0 + pinkB1 + pinkB2 + w * 0.1848) * 0.11
    }

    @inline(__always)
    func brown() -> Float {
        let w = white()
        brownLast = brownLeak * brownLast + (1 - brownLeak) * w
        return brownLast * 8
    }

    func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        let balance = parameters.noiseBalance
        let masterGain = parameters.masterGain
        let cutoffHz = FilterController.cutoffHz(fromNorm: 1 - parameters.noiseColour, minHz: 250, maxHz: 12_000)
        let q = FilterController.qFromNorm(0)
        let pulseGain = pulse.nextGain(
            rateNorm: parameters.pulseRate,
            depthNorm: parameters.pulseDepth,
            frameCount: frameCount,
            sampleRate: sampleRate
        )
        let nodeGain: Float = 0.35
        let sr: Float = sampleRate

        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for buffer in abl {
            guard let dest = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            for frame in 0..<frameCount {
                let p = pink()
                let b = brown()
                let mix = p * (1 - balance) + b * balance
                let filtered = filter.processLowPass(mix, cutoffHz: cutoffHz, q: q, sampleRate: sr)
                dest[frame] = filtered * nodeGain * pulseGain * masterGain
            }
        }
    }
}
