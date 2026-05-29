import AVFoundation

/// Thin seam around `AVAudioMixerNode`. WP01 leaves it intentionally minimal —
/// master gain is applied inside each source node so the mixer just sums. WP02
/// expands this with per-source ducking and a master limiter at −1 dBTP.
nonisolated final class Mixer {
    let node: AVAudioMixerNode

    init() {
        self.node = AVAudioMixerNode()
        self.node.outputVolume = 1.0
    }
}
