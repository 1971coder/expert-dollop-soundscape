import AVFoundation
import Foundation

/// Multi-voice sustained drone. Each voice is a sine oscillator with an
/// independent slow LFO modulating its frequency by ≤ `droneDetune` × 1 %.
/// LFO phases are offset per voice to keep voices from beating coherently —
/// the requirements call out "two minutes of audio should not be audibly
/// similar to the previous two minutes."
///
/// **DroneSynth is the designated parameter-pipe drainer.** Once per render
/// block it pops every queued `ParameterDelta` from the shared ring buffer
/// and applies it to `EngineParameters`. NoiseGenerator and PadSynth read
/// from the same `EngineParameters` instance.
///
/// **WP02 additions.** Pulse modulation (so the drone breathes with the
/// shared pulse rate) and the master `filterCutoff` knob applied via a
/// gentle low-pass at the output stage.
nonisolated final class DroneSynth {
    let node: AVAudioSourceNode
    private let state: DroneRenderState

    init(
        format: AVAudioFormat,
        parameters: EngineParameters,
        ringBuffer: ParameterRingBuffer
    ) {
        let state = DroneRenderState(
            parameters: parameters,
            ringBuffer: ringBuffer,
            sampleRate: Float(format.sampleRate)
        )
        self.state = state
        self.node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            state.render(frameCount: Int(frameCount), audioBufferList: audioBufferList)
            return noErr
        }
    }
}

nonisolated private final class DroneRenderState: @unchecked Sendable {
    struct Voice {
        var baseFreq: Float
        var phase: Float
        var lfoPhase: Float
        var lfoRate: Float
    }

    let parameters: EngineParameters
    let ringBuffer: ParameterRingBuffer
    let sampleRate: Float
    var voices: [Voice]
    var filter = StateVariableFilter()
    var pulse = PulseModulator()

    init(parameters: EngineParameters, ringBuffer: ParameterRingBuffer, sampleRate: Float) {
        self.parameters = parameters
        self.ringBuffer = ringBuffer
        self.sampleRate = sampleRate
        let baseFreqs: [Float] = [110.0, 164.81, 220.0]
        self.voices = baseFreqs.enumerated().map { index, freq in
            Voice(
                baseFreq: freq,
                phase: 0,
                lfoPhase: Float(index) * 0.7,
                lfoRate: 0.07 + Float(index) * 0.02
            )
        }
    }

    func render(frameCount: Int, audioBufferList: UnsafeMutablePointer<AudioBufferList>) {
        while let delta = ringBuffer.tryPop() {
            parameters.apply(delta)
        }

        let detune = parameters.droneDetune
        let droneGain = parameters.droneGain
        let masterGain = parameters.masterGain
        let cutoffHz = FilterController.cutoffHz(fromNorm: parameters.filterCutoff, minHz: 200, maxHz: 8_000)
        let q = FilterController.qFromNorm(0)
        let pulseGain = pulse.nextGain(
            rateNorm: parameters.pulseRate,
            depthNorm: parameters.pulseDepth,
            frameCount: frameCount,
            sampleRate: sampleRate
        )
        let nodeGain: Float = 0.3
        let twoPi: Float = 2 * Float.pi
        let voiceCount = Float(voices.count)
        let sr = sampleRate

        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for buffer in abl {
            guard let dest = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            for frame in 0..<frameCount {
                var sample: Float = 0
                for vIndex in voices.indices {
                    let lfo = sinf(voices[vIndex].lfoPhase)
                    let freq = voices[vIndex].baseFreq * (1 + detune * 0.01 * lfo)
                    voices[vIndex].phase += twoPi * freq / sr
                    if voices[vIndex].phase > twoPi { voices[vIndex].phase -= twoPi }
                    sample += sinf(voices[vIndex].phase)

                    voices[vIndex].lfoPhase += twoPi * voices[vIndex].lfoRate / sr
                    if voices[vIndex].lfoPhase > twoPi { voices[vIndex].lfoPhase -= twoPi }
                }
                sample /= voiceCount
                let filtered = filter.processLowPass(sample, cutoffHz: cutoffHz, q: q, sampleRate: sr)
                dest[frame] = filtered * nodeGain * droneGain * pulseGain * masterGain
            }
        }
    }
}
